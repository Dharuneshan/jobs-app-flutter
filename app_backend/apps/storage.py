from storages.backends.s3boto3 import S3Boto3Storage
from django.conf import settings

class StaticStorage(S3Boto3Storage):
    location = 'static'
    access_key = settings.AWS_S3_ACCESS_KEY_ID
    secret_key = settings.AWS_S3_SECRET_ACCESS_KEY
    bucket_name = settings.AWS_STORAGE_BUCKET_NAME
    # Remove default_acl for buckets that don't support ACLs
    # default_acl = 'public-read'
    querystring_auth = False  # Don't add query parameters to URLs

class MediaStorage(S3Boto3Storage):
    location = 'media'
    access_key = settings.AWS_S3_ACCESS_KEY_ID
    secret_key = settings.AWS_S3_SECRET_ACCESS_KEY
    bucket_name = settings.AWS_STORAGE_BUCKET_NAME
    # Remove default_acl for buckets that don't support ACLs
    # default_acl = 'private'
    querystring_auth = True  # Add query parameters for media files 