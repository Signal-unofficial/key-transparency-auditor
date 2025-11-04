#!/bin/sh

stripPublicPem() {
    sed '/-----BEGIN PUBLIC KEY-----/d' | sed '/-----END PUBLIC KEY-----/d'
}

stripPrivatePemFile() {
    file="$1"
    sed '/-----BEGIN PRIVATE KEY-----/d' "${file}" | sed '/-----END PRIVATE KEY-----/d'
}

stripEd25519PublicDer() {
    sed '/ED25519 Public-Key:/d' | sed '/pub:/d' | tr -d ' '
}

indentCat() {
    file="$1"
    sed 's/^/  /' "${file}"
}

# Generating certificate (interactive by default)
openssl req \
    -quiet \
    -newkey "rsa:${KEY_LEN}" \
    -x509 \
    -noenc \
    -keyout 'certkey.pem' \
    -out 'certificate.crt' \
    "$@"

# Generating new key pair
openssl genpkey -quiet -algorithm Ed25519 -out 'private.pem'
openssl pkey -in 'private.pem' -pubout -out 'public.pem'

# Encoding public keys
publicPem="$(cat 'public.pem' | stripPublicPem)"
publicEncoded="$(openssl pkey -pubin -inform pem -in public.pem -noout -text | stripEd25519PublicDer | tr -d ':\n')"

# Printing YAML-formatted keys
echo
echo '# kt-auditor'
printf "private-key: "
stripPrivatePemFile 'private.pem'
echo "public-key: ${publicPem}"
echo 'client-private-key: |'
indentCat 'certkey.pem'
echo 'client-certificate: |'
indentCat 'certificate.crt'
echo
echo "# kt-server"
echo "your-auditor-name-here: ${publicEncoded}"

# Erasing temporary key files
shred -u 'certkey.pem' 'certificate.crt' 'private.pem' 'public.pem'
