#!zsh

# called to create a certificate to authenticate a given machine

NAME=$1
OUTPUT=certs/${NAME}
PCA=$( cat pca.arn )

# create a directory to store the certificate
mkdir -p ${OUTPUT}

# create a certificate
aws acm request-certificate --domain-name ${NAME} \
    --certificate-authority-arn ${PCA} \
    --tags Key=app,Value=onprempoc | jq -r '.CertificateArn' > ${OUTPUT}/client-cert.arn
CERT=$( cat ${OUTPUT}/client-cert.arn )
aws acm wait certificate-validated --certificate-arn ${CERT}
sleep 30

# export the certificate (public, private, and chain)
PASSPHRASE="simplepassword"
echo -n "${PASSPHRASE}" > ${OUTPUT}/client-cert.passphrase
aws acm export-certificate \
    --certificate-arn ${CERT} \
    --passphrase fileb://${OUTPUT}/client-cert.passphrase > ${OUTPUT}/client-cert.json
cat ${OUTPUT}/client-cert.json | jq -r '.Certificate' > ${OUTPUT}/certificate.txt
cat ${OUTPUT}/client-cert.json | jq -r '.CertificateChain' > ${OUTPUT}/certificate_chain.txt
cat ${OUTPUT}/client-cert.json | jq -r '.PrivateKey' > ${OUTPUT}/private_key.txt

# create a trust anchor specific to this client
FLAT_NAME=$( echo ${NAME} | sed 's/\./-/g' )
aws rolesanywhere create-trust-anchor \
    --source "sourceData={acmPcaArn=${PCA}},sourceType=AWS_ACM_PCA" \
    --name ${FLAT_NAME} > ${OUTPUT}/trust-anchor.json
cat ${OUTPUT}/trust-anchor.json | jq -r '.trustAnchor.trustAnchorArn' > ${OUTPUT}/trust-anchor.arn
cat ${OUTPUT}/trust-anchor.json | jq -r '.trustAnchor.trustAnchorId' > ${OUTPUT}/trust-anchor.id
ANCHOR_ARN=$( cat ${OUTPUT}/trust-anchor.arn )
ANCHOR_ID=$( cat ${OUTPUT}/trust-anchor.id )
aws rolesanywhere enable-trust-anchor --trust-anchor-id ${ANCHOR_ID} > /dev/null

# create a role for the client
cat > ${OUTPUT}/policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "rolesanywhere.amazonaws.com"
            },
            "Action": [
                "sts:AssumeRole",
                "sts:TagSession",
                "sts:SetSourceIdentity"
            ],
            "Condition": {
                "ArnEquals": {
                    "aws:SourceArn": "${ANCHOR_ARN}"
                }
            }
        }
    ]
}
EOF
aws iam create-role \
    --role-name ${FLAT_NAME} \
    --tags Key=app,Value=onprempoc \
    --assume-role-policy-document file://${OUTPUT}/policy.json > ${OUTPUT}/role.json
cat ${OUTPUT}/role.json | jq -r '.Role.Arn' > ${OUTPUT}/role.arn
ROLE_ARN=$( cat ${OUTPUT}/role.arn )

# attach a policy/permissions to the role
#S3_READ_ACCESS="arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
SM_ACCESS="arn:aws:iam::aws:policy/SecretsManagerReadWrite"
aws iam attach-role-policy \
    --role-name ${FLAT_NAME} \
    --policy-arn ${SM_ACCESS}

# create a profile for the client
aws rolesanywhere create-profile \
    --enabled \
    --name ${FLAT_NAME} \
    --tags key=app,value=onprempoc \
    --role-arns "${ROLE_ARN}" > ${OUTPUT}/profile.json
cat ${OUTPUT}/profile.json | jq -r '.profile.profileArn' > ${OUTPUT}/profile.arn
cat ${OUTPUT}/profile.json | jq -r '.profile.profileId' > ${OUTPUT}/profile.id
PROFILE_ARN=$( cat ${OUTPUT}/profile.arn )

# create a .env file to store the paths and pathphrase
echo "CERT_PATH=\"./${NAME}/certificate.txt\"" > ${OUTPUT}/.env
echo "PRIVATE_KEY_PATH=\"./${NAME}/private_key.txt\"" >> ${OUTPUT}/.env
echo "PRIVATE_KEY_PASSPHRASE=\"${PASSPHRASE}\"" >> ${OUTPUT}/.env
echo "TRUST_ANCHOR_ARN=\"${ANCHOR_ARN}\"" >> ${OUTPUT}/.env
echo "PROFILE_ARN=\"${PROFILE_ARN}\"" >> ${OUTPUT}/.env
echo "ROLE_ARN=\"${ROLE_ARN}\"" >> ${OUTPUT}/.env
