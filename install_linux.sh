#!/bin/sh
set -e
install_certs() {
    $cert_path=$certLocation/$CERTFILE
    
    if ! type update-ca-certificates > /dev/null; then
	echo "This system does not have 'update-ca-certificates' command."
        >	echo "Please install the certificate manually."
	exit 1
    fi
    if ! type certutil > /dev/null; then
	echo "This system does not have 'certutil' command."
	echo "Please install the parent package like 'libnss3-tools' or so,"
	echo "Otherwise, please install the certificate manually."
	exit 1
    fi

    echo "Installing certificate to system certificate repository.."
    sudo mkdir -p /usr/local/share/ca-certificates/extra
    sudo cp $CERTFILE /usr/local/share/ca-certificates/extra/$CERTFILE
    sudo update-ca-certificates

    ###
    ### For cert8 (legacy - DBM)
    ###

    echo "Updating local user cert8 repository.."
    for certDB in $(find ~/ -name "cert8.db")
    do
        certdir=$(dirname ${certDB});
        certutil -A -n "${CERTNAME}" -t "TCu,Cu,Tu" -i ${cert_path} -d dbm:${certdir}
    done


    ###
    ### For cert9 (SQL)
    ###

    echo "Updating local user cert9 repository.."
    for certDB in $(find ~/ -name "cert9.db")
    do
        certdir=$(dirname ${certDB});
        certutil -A -n "${CERTNAME}" -t "TCu,Cu,Tu" -i ${cert-Path} -d sql:${certdir}
    done

    echo "Done."
}

CERTFILE=foo.pem
CERTNAME="Local Root CA"

certLocation="/tmp/pki/"
mkdir -p $certLocation
rootCerts=$CERTFILE
cat <<EOF | base64 -d > $certLocation/$CERTFILE
MIID/zCCAuegAwIBAgIUXNjylyR7JNg4ZdbIgkba2rEU/tUwDQYJKoZIhvcNAQEL
...
EOF
install_cert
