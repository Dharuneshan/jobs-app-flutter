from admin_tools.dashboard import modules, Dashboard
from admincharts.modules import Chart
from django.utils.translation import gettext_lazy as _
from apps.models import EmployeeRegistration, EmployerRegistration, JobPost

class CustomIndexDashboard(Dashboard):
    def init_with_context(self, context):
        self.children.append(modules.AppList(
            _('Applications'),
            exclude=('django.contrib.*',),
        ))
        self.children.append(modules.ModelList(
            _('Authentication and Authorization'),
            models=('django.contrib.auth.*',),
        ))
        self.children.append(Chart(
            title=_('Employee Registrations by Gender'),
            model=EmployeeRegistration,
            chart_type='pie',
            query={'group_by': 'gender'},
        ))
        self.children.append(Chart(
            title=_('Job Posts by City'),
            model=JobPost,
            chart_type='bar',
            query={'group_by': 'city'},
        ))
        self.children.append(Chart(
            title=_('Employers by Business Category'),
            model=EmployerRegistration,
            chart_type='pie',
            query={'group_by': 'business_category'},
        ))
        self.children.append(Chart(
            title=_('Job Posts by Work Category'),
            model=JobPost,
            chart_type='bar',
            query={'group_by': 'work_category'},
        )) 