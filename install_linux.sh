#!/bin/bash
GUI=1
UBUNTU=1
ASKPASS=/usr/bin/ssh-askpass
require_program() {
    if ! type $1 >& /dev/null; then
	echo "This system does not have '$1' command."
	echo "Please install the certificate '$CERT_PATH' manually."
	exit 1
    fi
}
gui_check() {
    if ! type zenity >& /dev/null; then
        GUI=0
    elif ! [ -x $ASKPASS ]; then
        GUI=0
    elif [ x"$DISPLAY" == x ]; then
        GUI=0
    fi
    if [ $GUI -eq 1 ]; then
        export SUDO_ASKPASS=$ASKPASS
        SUDO="sudo -A"
    else
        SUDO="sudo"
    fi
}
mesg() {
    if [ $GUI -eq 0 ]; then
        echo -e $2
    else
        echo -e "$1"; sleep 1
        echo -e "# $2"
    fi
}
info() {
    if [ $GUI -eq 0 ]; then
        echo -e $1
    else
        zenity --info --text="$1" --width=400
    fi
}
install_centos() {
    ${SUDO} mkdir -p /etc/pki/ca-trust/source/anchors
    ${SUDO} cp $CERT_PATH /etc/pki/ca-trust/source/anchors/$CERTFILE
    ${SUDO} update-ca-trust
}
install_ubuntu() {
    ${SUDO} mkdir -p /usr/local/share/ca-certificates/extra
    ${SUDO} cp $CERT_PATH /usr/local/share/ca-certificates/extra/$CERTFILE
    ${SUDO} update-ca-certificates
}
install_main() {
    mesg 10 "Installing certificate to system certificate repository.."
    if [ $UBUNTU -eq 1 ]; then
        install_ubuntu
    else
        install_centos
    fi
    
    ###
    ### For cert8 (legacy - DBM)
    ###

    mesg 30 "Updating local user cert8 repository.."
    find ~/ -name "cert8.db" -print0 | while read -d $'\0' certDB
    do
        certdir=$(dirname "${certDB}")
        certutil -A -n "${CERTNAME}" -t "TCu,Cu,Tu" -i ${CERT_PATH} -d dbm:"${certdir}"        
    done


    ###
    ### For cert9 (SQL)
    ###

    mesg 60 "Updating local user cert9 repository.."
    find ~/ -name "cert9.db" -print0 | while read -d $'\0' certDB
    do
        certdir=$(dirname "${certDB}")
        echo certutil -A -n "${CERTNAME}" -t "TCu,Cu,Tu" -i ${CERT_PATH} -d sql:"<${certdir}>"
        certutil -A -n "${CERTNAME}" -t "TCu,Cu,Tu" -i ${CERT_PATH} -d sql:"${certdir}"
    done

    mesg 99 "Done."
}
install_cert() {
    require_program openssl
    require_program certutil
    if ! type update-ca-certificates >& /dev/null; then
        if ! type update-ca-trust >& /dev/null; then
	    echo "This system does not have 'update-ca-certificates' or 'update-ca-trust' command."
	    echo "Please install the certificate '$CERT_PATH' manually."
	    exit 1
        fi
        UBUNTU=0
    fi

    subj=`openssl x509 -in $CERT_PATH -noout -text -inform DER| perl -ne 'print $1 if /Subject: (.*)/'`
    if [ $GUI -eq 0 ]; then
        echo "This program installs CA certificate \"$subj\"."
        install_main
    else
        zenity --question --text="This program installs CA certificate \"$subj\"." --width=400
        if [ $? -ne 0 ]; then
            exit 1
        fi
        install_main | zenity --progress \
                              --title="Installing Certificate" \
                              --text="Preparing..." \
                              --percentage=0 --width=400
        if [ "$?" = -1 ] ; then
            zenity --error \
                   --text="Update canceled."
        fi
    fi
}

gui_check

if ! type curl >& /dev/null; then
    info "This system does not have 'curl' command."
    info "Please install the certificate manually."
    exit 1
fi

CERTURL="http://sslcert.cc/cgi/cert_down.php"
CERT_LOCATION="/tmp/pki"
CERTFILE=cert.pem
CERTNAME="Local Root CA"

mkdir -p $CERT_LOCATION
CERT_PATH=$CERT_LOCATION/$CERTFILE

curl --silent $CERTURL | grep -v -- "---" | base64 -d > $CERT_PATH
if [ $? -ne 0 ]; then
    info "Cannot download SSL certificate.\nPlease contact network administrator"
    exit 1
fi

#sed -n "/BEGIN CERTIFICATE/,/END CERTIFICATE/p" test.pem |grep -v -- "---" | base64 -d > $CERT_PATH

if [ x"$1" != x ]; then
    GUI=0
fi
install_cert
