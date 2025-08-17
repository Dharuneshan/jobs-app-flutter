from django.core.management.base import BaseCommand
from django.apps import apps

class Command(BaseCommand):
    help = 'Create default dashboard stats and criteria for admin_tools_stats.'

    def handle(self, *args, **options):
        # Import models dynamically to avoid import errors if not installed
        DashboardStatsCriteria = apps.get_model('admin_tools_stats', 'DashboardStatsCriteria')
        DashboardStats = apps.get_model('admin_tools_stats', 'DashboardStats')

        # List of criteria to create: (name, model, criteria, field, extra kwargs)
        criteria_data = [
            ('Total Employees', 'apps.EmployeeRegistration', 'count', ''),
            ('Total Employers', 'apps.EmployerRegistration', 'count', ''),
            ('Total Job Posts', 'apps.JobPost', 'count', ''),
            ('Active Job Posts', 'apps.JobPost', 'count', '', {'filters': '{"condition": "posted"}'}),
            ('Draft Job Posts', 'apps.JobPost', 'count', '', {'filters': '{"condition": "draft"}'}),
            ('Total Candidate Views', 'apps.ViewedCandidate', 'count', ''),
            ('Total Job Views', 'apps.ViewedJob', 'count', ''),
            ('Total Job Applications', 'apps.ViewedJob', 'count', '', {'filters': '{"applied": true}'}),
            ('Total Favorite Jobs', 'apps.FavJob', 'count', ''),
            ('Total Feedback Entries', 'apps.EmployerFeedback', 'count', ''),
            ('Average Employer Rating', 'apps.EmployerFeedback', 'avg', 'rating'),
            ('Company Certificates Uploaded', 'apps.CompanyCertificate', 'count', ''),
        ]

        created_criteria = []
        for entry in criteria_data:
            name, model, criteria, field = entry[:4]
            extra = entry[4] if len(entry) > 4 else {}
            obj, created = DashboardStatsCriteria.objects.get_or_create(
                name=name,
                model_app_label=model.split('.')[0],
                model_name=model.split('.')[1],
                criteria=criteria,
                field=field,
                defaults=extra
            )
            created_criteria.append(obj)
            self.stdout.write(self.style.SUCCESS(f"{'Created' if created else 'Exists'} criteria: {name}"))

        # Now create DashboardStats for each criteria
        for crit in created_criteria:
            stat, created = DashboardStats.objects.get_or_create(
                name=crit.name,
                criteria=crit,
                visible=True,
                show_to_users=True
            )
            self.stdout.write(self.style.SUCCESS(f"{'Created' if created else 'Exists'} dashboard stat: {stat.name}"))

        self.stdout.write(self.style.SUCCESS('Dashboard stats and criteria creation complete.')) 