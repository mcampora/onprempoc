#!zsh

# cleanup resources created before

NAME=$1
OUTPUT=certs/${NAME}
FLAT_NAME=$( echo ${NAME} | sed 's/\./-/g' )

# delete the profile
PROFILE_ID=$( cat ${OUTPUT}/profile.id )
aws rolesanywhere delete-profile --profile-id ${PROFILE_ID} > /dev/null

# delete the role
S3_READ_ACCESS="arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
aws iam detach-role-policy --role-name ${FLAT_NAME} --policy-arn ${S3_READ_ACCESS}
aws iam delete-role --role-name ${FLAT_NAME}

# delete the trust anchor
ANCHOR_ID=$( cat ${OUTPUT}/trust-anchor.id )
aws rolesanywhere delete-trust-anchor --trust-anchor-id ${ANCHOR_ID} > /dev/null

# delete the certificate
CERT=$( cat ${OUTPUT}/client-cert.arn )
aws acm delete-certificate --certificate-arn ${CERT}
