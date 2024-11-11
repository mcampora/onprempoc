"""

Example process to use AWS services via roles anywhere
Does not require aws_signing_helper application

"""

import json
from dotenv import dotenv_values
from iam_rolesanywhere_session import IAMRolesAnywhereSession
import boto3

#call .env file with non-sensitive AWS details
env_val = dotenv_values("pca/.env")

# first session with a profile with S3 access
#------------------------------------------------
roles_anywhere_session = IAMRolesAnywhereSession(
    trust_anchor_arn=env_val.get('TRUST_ANCHOR_ARN'),
    profile_arn=env_val.get('PROFILE_ARN'),
    role_arn=env_val.get('ROLE_ARN'),
    certificate=env_val.get('CERT_PATH'),
    private_key=env_val.get('PRIVATE_KEY_PATH'),
    private_key_passphrase=env_val.get('PRIVATE_KEY_PASSPHRASE'),
    region='us-east-1',
).get_session()

client = roles_anywhere_session.client('s3')

# test the s3 access by listing the buckets
response = client.list_buckets()
print('Existing buckets:')
for bucket in response['Buckets']:
    print(f'  {bucket["Name"]}')

# second session with a profile with SSM access
#------------------------------------------------
roles_anywhere_session = IAMRolesAnywhereSession(
    trust_anchor_arn=env_val.get('TRUST_ANCHOR_ARN'),
    profile_arn=env_val.get('PROFILE2_ARN'),
    role_arn=env_val.get('ROLE2_ARN'),
    certificate=env_val.get('CERT_PATH'),
    private_key=env_val.get('PRIVATE_KEY_PATH'),
    private_key_passphrase=env_val.get('PRIVATE_KEY_PASSPHRASE'),
    region='us-east-1',
).get_session()

client = roles_anywhere_session.client('secretsmanager')

# test the ssm access by listing the secrets
response = client.list_secrets()
print('Existing secrets:')
for secret in response['SecretList']:
    print(f'  {secret["Name"]}')
