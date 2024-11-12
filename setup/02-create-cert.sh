# called to create a certificate to authenticate a given machine

NAME=$1
OUTPUT=certs/${NAME}
PCA=$( cat pca.arn )

# create a directory to store the certificate
mkdir -p ${OUTPUT}

aws acm request-certificate --domain-name ${NAME} \
    --certificate-authority-arn ${PCA} \
    --tags Key=app,Value=onprempoc | jq -r '.CertificateArn' > ${OUTPUT}/client-cert.arn

CERT=$( cat ${OUTPUT}/client-cert.arn )
PASSPHRASE="simplepassword"

echo ${PASSPHRASE} > ${OUTPUT}/client-cert.passphrase
aws acm export-certificate \
    --certificate-arn ${CERT} \
    --passphrase fileb://${OUTPUT}/client-cert.passphrase > ${OUTPUT}/client-cert.json

cat ${OUTPUT}/client-cert.json | jq -r '.Certificate' > ${OUTPUT}/certificate.txt
cat ${OUTPUT}/client-cert.json | jq -r '.CertificateChain' > ${OUTPUT}/certificate_chain.txt
cat ${OUTPUT}/client-cert.json | jq -r '.PrivateKey' > ${OUTPUT}/private_key.txt

echo "CERT_PATH=\"./${NAME}/certificate.txt\"" > ${OUTPUT}/.env
echo "PRIVATE_KEY_PATH=\"./${NAME}/private_key.txt\"" >> ${OUTPUT}/.env
echo "PRIVATE_KEY_PASSPHRASE=\"${PASSPHRASE}\"" >> ${OUTPUT}/.env
