#!/bin/sh
function install_cert() {
	for cert in "${rootCerts[@]}"
	do
	    cmd="security add-trusted-cert -d -k /Library/Keychains/System.keychain -r trustRoot $certLocation$cert"
	    prompt='Installing an SSL certificate'
	    OUTPUT=$(osascript -e "do shell script \"${cmd}\" with administrator privileges with prompt \"${prompt}\"" 2>&1)
	    if [ $? -ne 0 ]; then
		osascript -e "display dialog \"${OUTPUT}\" with title \"Installation Failed\" buttons{\"OK\"} default button \"OK\"" >& /dev/null
		exit 1
	    else
		osascript -e "display dialog \"The certificate has been installed to System Keychain.\" with title \"Installation completed\" buttons {\"OK\"} default button \"OK\"" >& /dev/null
	    fi
	done
}

certLocation="/tmp/pki/"
mkdir -p $certLocation
declare -a rootCerts=(A.cert);
cat <<EOF | base64 -D > $certLocation/A.cert
MIID/zCCAuegAwIBAgIUXNjylyR7JNg4ZdbIgkba2rEU/tUwDQYJKoZIhvcNAQEL
...
EOF
install_cert
