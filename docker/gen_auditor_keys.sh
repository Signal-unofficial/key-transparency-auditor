#!/bin/sh

# Generating key pair
openssl genpkey -algorithm Ed25519 -out 'private.pem'
openssl pkey -in 'private.pem' -pubout -out 'public.pem'

# Stripping headers/footers and printing YAML-formatted keys
printf "auditor.private-key: "
sed '/-----BEGIN PRIVATE KEY-----/d' 'private.pem' | sed '/-----END PRIVATE KEY-----/d'
printf "auditor.public-key: "
sed '/-----BEGIN PUBLIC KEY-----/d' 'public.pem' | sed '/-----END PUBLIC KEY-----/d'
