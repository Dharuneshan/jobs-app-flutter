import boto3
from django.conf import settings
import os
import sys
import firebase_admin
from firebase_admin import credentials, messaging

# Initialize firebase_admin only once
if not firebase_admin._apps:
    cred = credentials.Certificate(os.path.join(os.path.dirname(__file__), '../jobs-7809e-firebase-adminsdk-fbsvc-f7d892249c.json'))
    firebase_admin.initialize_app(cred)


def send_sns_notification(subject, message, device_token=None):
    try:
        client = boto3.client(
            "sns",
            aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
            aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
            region_name=settings.AWS_SNS_REGION_NAME,
        )
        if device_token:
            # If device_token is provided, publish directly to the device endpoint
            response = client.publish(
                TargetArn=device_token,
                Message=message,
                Subject=subject,
            )
        else:
            # Fallback to topic notification
            response = client.publish(
                TopicArn=settings.AWS_SNS_TOPIC_ARN,
                Message=message,
                Subject=subject,
            )
        return response
    except Exception as e:
        print(f"SNS notification error: {e}")
        return None

# Send push notification via Firebase Cloud Messaging (FCM)
def send_fcm_notification(title, body, fcm_token):
    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            token=fcm_token,
        )
        response = messaging.send(message)
        print(f"FCM notification sent: {response}")
        return response
    except Exception as e:
        print(f"FCM notification error: {e}")
        return None

if __name__ == "__main__":
    # Setup Django environment
    sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings")
    import django
    django.setup()
    subject = "Test Notification"
    message = "This is a test message from the Django SNS integration script."
    response = send_sns_notification(subject, message)
    print("SNS publish response:", response) 