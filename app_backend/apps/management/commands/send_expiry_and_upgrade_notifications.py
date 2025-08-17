from django.core.management.base import BaseCommand
from django.utils import timezone
from apps.models import JobPost, EmployerRegistration, Notification
from apps.sns_utils import send_fcm_notification, send_sns_notification
from datetime import timedelta

class Command(BaseCommand):
    help = 'Send job post expiry reminders and upgrade warnings to employers.'

    def handle(self, *args, **options):
        now = timezone.now()
        self.send_expiry_reminders(now)
        self.send_upgrade_warnings()
        self.stdout.write(self.style.SUCCESS('Expiry and upgrade notifications sent.'))

    def send_expiry_reminders(self, now):
        plans = {
            'silver': 5,
            'gold': 30,
        }
        for plan, days in plans.items():
            # Reminder 5 days before expiry
            reminder_delta = timedelta(days=days-5)
            expiry_delta = timedelta(days=days)
            jobs = JobPost.objects.filter(condition='posted', employer__subscription_type=plan)
            for job in jobs:
                created = job.created_at
                employer = job.employer
                # Reminder 5 days before expiry
                if (now - created).days == (days - 5):
                    if not Notification.objects.filter(
                        employer=employer,
                        user_type='employer',
                        title__icontains='Job Post Expiry Reminder',
                        message__icontains=job.job_title
                    ).exists():
                        msg = f'Your job post "{job.job_title}" will expire in 5 days. Please take action if needed.'
                        Notification.objects.create(
                            employer=employer,
                            user_type='employer',
                            title='Job Post Expiry Reminder',
                            message=msg
                        )
                        if employer.fcm_token:
                            send_fcm_notification(
                                title='Job Post Expiry Reminder',
                                body=msg,
                                fcm_token=employer.fcm_token
                            )
                        else:
                            send_sns_notification(
                                subject='Job Post Expiry Reminder',
                                message=msg,
                                device_token=employer.device_token
                            )
                # On expiry
                if (now - created).days == days:
                    if not Notification.objects.filter(
                        employer=employer,
                        user_type='employer',
                        title__icontains='Job Post Expired',
                        message__icontains=job.job_title
                    ).exists():
                        msg = f'Your job post "{job.job_title}" has expired.'
                        Notification.objects.create(
                            employer=employer,
                            user_type='employer',
                            title='Job Post Expired',
                            message=msg
                        )
                        if employer.fcm_token:
                            send_fcm_notification(
                                title='Job Post Expired',
                                body=msg,
                                fcm_token=employer.fcm_token
                            )
                        else:
                            send_sns_notification(
                                subject='Job Post Expired',
                                message=msg,
                                device_token=employer.device_token
                            )

    def send_upgrade_warnings(self):
        employers = EmployerRegistration.objects.all()
        for employer in employers:
            if employer.no_of_post is not None and 1 <= employer.no_of_post <= 5:
                if not Notification.objects.filter(
                    employer=employer,
                    user_type='employer',
                    title__icontains='Upgrade Warning',
                    message__icontains=str(employer.no_of_post)
                ).exists():
                    msg = f'You have only {employer.no_of_post} job post credits left. Please upgrade your plan soon.'
                    Notification.objects.create(
                        employer=employer,
                        user_type='employer',
                        title='Upgrade Warning',
                        message=msg
                    )
                    if employer.fcm_token:
                        send_fcm_notification(
                            title='Upgrade Warning',
                            body=msg,
                            fcm_token=employer.fcm_token
                        )
                    else:
                        send_sns_notification(
                            subject='Upgrade Warning',
                            message=msg,
                            device_token=employer.device_token
                        )

    def setup_test_data(self):
        """
        Utility for testing: set one job post to 5 days before expiry, one to expired, and set an employer's no_of_post to 5.
        """
        from django.utils import timezone
        now = timezone.now()
        # Set up a silver job post 5 days before expiry
        job = JobPost.objects.filter(condition='posted', employer__subscription_type='silver').first()
        if job:
            job.created_at = now - timedelta(days=0)
            job.save()
        # Set up a silver job post at expiry
        job_expired = JobPost.objects.filter(condition='posted', employer__subscription_type='silver').last()
        if job_expired:
            job_expired.created_at = now - timedelta(days=5)
            job_expired.save()
        # Set an employer's no_of_post to 5
        employer = EmployerRegistration.objects.first()
        if employer:
            employer.no_of_post = 5
            employer.save()
        print('Test data set: job post at 0 days, job post at 5 days, employer credits = 5')

if __name__ == "__main__":
    from django.core.management import execute_from_command_line
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == 'setup_test_data':
        from django.conf import settings
        import django
        django.setup()
        Command().setup_test_data()
    else:
        execute_from_command_line(sys.argv) 