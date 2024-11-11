Simple example of an on-prem script assuming an AWS IAM Role using AWS IAM Role Anywhere.  

To make it work, you have to provision:
- an AWS Private Certificate Authority root certificate
- in AWS IAM Role Anywhere create a trust anchor and profile with this root CA and an AWS IAM Role granting S3 read permissions
- in AWS Certificate Manager create a certificate signed with the root CA
- download the certificate, certificate chain, private key and install them in a ./pca subfolder
- add a .env file in this ./pca folder containing:
    - TRUST_ANCHOR_ARN="arn:aws:rolesanywhere:region:account:trust-anchor/anchor"
    - PROFILE_ARN="arn:aws:rolesanywhere:region:account:profile/profile"
    - ROLE_ARN="arn:aws:iam::account:role/role"
    - CERT_PATH="./pca/certificate.txt"
    - PRIVATE_KEY_PATH="./pca/private_key.txt"
    - PRIVATE_KEY_PASSPHRASE="my_secret"
