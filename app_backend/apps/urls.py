from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import EmployeeRegistrationViewSet, ProfileViewSet, EmployerRegistrationViewSet, CompanyCertificateViewSet, EmployerFeedbackViewSet, JobPostViewSet, FavJobViewSet, EmployeePhotoUploadView, candidate_list, view_candidate_profile, viewed_candidates, mark_job_viewed, viewed_jobs, apply_job, applied_jobs, employer_profile_views, employer_applied_candidates, update_employer_plan, analytics_dashboard, NotificationListView, NotificationMarkReadView, nearby_employees, nearby_companies, reverse_geocode, geocode_address

router = DefaultRouter()
router.register(r'profiles', ProfileViewSet)
router.register(r'employee-registrations', EmployeeRegistrationViewSet)
router.register(r'employer-registrations', EmployerRegistrationViewSet)
router.register(r'company-certificates', CompanyCertificateViewSet)
router.register(r'employer-feedback', EmployerFeedbackViewSet)
router.register(r'job-posts', JobPostViewSet)
router.register(r'fav-jobs', FavJobViewSet)

urlpatterns = [
    path('', include(router.urls)),
    path('candidates/', candidate_list, name='candidate-list'),
    path('candidates/view/', view_candidate_profile, name='view-candidate-profile'),
    path('viewed-candidates/', viewed_candidates, name='viewed-candidates'),
    path('mark-job-viewed/', mark_job_viewed, name='mark-job-viewed'),
    path('viewed-jobs/', viewed_jobs, name='viewed-jobs'),
    path('apply-job/', apply_job, name='apply-job'),
    path('applied-jobs/', applied_jobs, name='applied-jobs'),
    path('upload-employee-photo/', EmployeePhotoUploadView.as_view(), name='upload-employee-photo'),
    path('employer-profile-views/', employer_profile_views, name='employer-profile-views'),
    path('employer-applied-candidates/', employer_applied_candidates, name='employer-applied-candidates'),
    path('update-employer-plan/', update_employer_plan, name='update-employer-plan'),
    path('analytics-dashboard/', analytics_dashboard, name='analytics-dashboard'),
    path('notifications/', NotificationListView.as_view(), name='notification-list'),
    path('notifications/<int:pk>/mark-read/', NotificationMarkReadView.as_view(), name='notification-mark-read'),
    path('nearby-employees/', nearby_employees, name='nearby-employees'),
    path('nearby-companies/', nearby_companies, name='nearby-companies'),
    path('reverse_geocode/', reverse_geocode, name='reverse-geocode'),
    path('geocode_address/', geocode_address, name='geocode-address'),
] 