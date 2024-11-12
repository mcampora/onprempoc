# one-off script used to create a certificate authority in one account/region
# need permissions to create a private certificate authority and a few other things

# create the authority
aws acm-pca create-certificate-authority \
    --certificate-authority-configuration file://pca-config.json \
    --certificate-authority-type ROOT \
    --tags Key=app,Value=onprempoc | jq -r '.CertificateAuthorityArn' > pca.arn
PCA=$( cat pca.arn )

# add the ACM permissions
aws acm-pca create-permission \
    --certificate-authority-arn "${PCA}" \
    --principal acm.amazonaws.com \
    --actions "IssueCertificate" "GetCertificate" "ListPermissions"

# create a CSR
aws acm-pca get-certificate-authority-csr \
     --certificate-authority-arn "${PCA}" \
     --output text \
     --region us-east-1 > pca.csr

# create a root certificate
aws acm-pca issue-certificate \
     --certificate-authority-arn "${PCA}" \
     --csr fileb://pca.csr \
     --signing-algorithm SHA256WITHRSA \
     --template-arn arn:aws:acm-pca:::template/RootCACertificate/V1 \
     --validity Value=3650,Type=DAYS | jq -r '.CertificateArn' > cert.arn
CERT=$( cat cert.arn )

# get the certificate
aws acm-pca get-certificate \
	--certificate-authority-arn "${PCA}" \
	--certificate-arn "${CERT}" \
	--output text > cert.pem

# import the certificate
aws acm-pca import-certificate-authority-certificate \
     --certificate-authority-arn "${PCA}" \
     --certificate fileb://cert.pem

# check status
aws acm-pca describe-certificate-authority \
	--certificate-authority-arn "${PCA}" \
	--output json | jq -r '.CertificateAuthority.Status'