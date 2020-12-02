#!/bin/bash
export SUDO_ASKPASS=`which /usr/bin/ssh-askpass`
gui=1
require_program() {
    if ! type $1 >& /dev/null; then
	echo "This system does not have '$1' command."
	echo "Please install the certificate '$cert_path' manually."
	exit 1
    fi
}
gui_check() {
    if ! type zenity > /dev/null; then
        gui=0
    elif ! type $SUDO_ASKPASS > /dev/null; then
        gui=0
    elif [ x"$DISPLAY" == x ]; then
        gui=0
    fi
}
mesg() {
    if [ $gui -eq 0 ]; then
        echo $2
    else
        echo "$1"; sleep 1
        echo "# $2"
    fi
}
info() {
    if [ $gui -eq 0 ]; then
        echo $1
    else
        zenity --info --text="$1" --width=400
    fi
}
install_main() {
    mesg 10 "Installing certificate to system certificate repository.."
    sudo -A mkdir -p /usr/local/share/ca-certificates/extra
    sudo -A cp $cert_path /usr/local/share/ca-certificates/extra/$CERTFILE
    sudo -A update-ca-certificates

    ###
    ### For cert8 (legacy - DBM)
    ###

    mesg 30 "Updating local user cert8 repository.."
    for certDB in $(find ~/ -name "cert8.db")
    do
        certdir=$(dirname ${certDB});
        certutil -A -n "${CERTNAME}" -t "TCu,Cu,Tu" -i ${cert_path} -d dbm:${certdir}
    done


    ###
    ### For cert9 (SQL)
    ###

    mesg 60 "Updating local user cert9 repository.."
    for certDB in $(find ~/ -name "cert9.db")
    do
        certdir=$(dirname ${certDB});
        certutil -A -n "${CERTNAME}" -t "TCu,Cu,Tu" -i ${cert-Path} -d sql:${certdir}
    done

    mesg 99 "Done."
}
install_cert() {

    require_program update-ca-certificates
    require_program openssl
    require_program certutil

    subj=`openssl x509 -in $cert_path -noout -text -inform DER| perl -ne 'print $1 if /Subject: (.*)/'`
    if [ $gui -eq 0 ]; then
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
certLocation="/tmp/pki"
CERTFILE=cert.pem
CERTNAME="Local Root CA"

mkdir -p $certLocation
cert_path=$certLocation/$CERTFILE

curl --silent $CERTURL | grep -v -- "---" | base64 -d > $cert_path
if [ $? -ne 0 ]; then
    info "Cannot download SSL certificate.\nPlease contact network administrator"
    exit 1
fi

#sed -n "/BEGIN CERTIFICATE/,/END CERTIFICATE/p" test.pem |grep -v -- "---" | base64 -d > $cert_path

if [ x"$1" != x ]; then
    gui=0
fi
install_cert
