from django.contrib import admin
from .models import EmployeeRegistration, CompanyCertificate, EmployerFeedback, JobPost, FavJob, Profile, EmployerRegistration, ViewedCandidate, ViewedJob, Notification
from import_export.admin import ImportExportModelAdmin

@admin.register(EmployeeRegistration)
class EmployeeRegistrationAdmin(admin.ModelAdmin):
    list_display = ('employee_id', 'name', 'phone_number', 'phone_verified', 'created_at')
    list_filter = ('phone_verified', 'gender', 'marital_status', 'work_category')
    search_fields = ('name', 'phone_number', 'employee_id')
    readonly_fields = ('employee_id', 'created_at', 'updated_at')

@admin.register(Profile)
class ProfileAdmin(ImportExportModelAdmin):
    list_display = ('phone_number', 'candidate_type', 'created_at', 'updated_at')
    search_fields = ('phone_number',)
    list_filter = ('candidate_type',)

@admin.register(EmployerRegistration)
class EmployerRegistrationAdmin(ImportExportModelAdmin):
    list_display = ('employer_id', 'company_name', 'phone_number', 'location', 'business_category', 'created_at')
    search_fields = ('company_name', 'phone_number', 'gst_number')
    list_filter = ('business_category', 'industry_sector', 'subscription_type')

@admin.register(ViewedCandidate)
class ViewedCandidateAdmin(ImportExportModelAdmin):
    list_display = ('employer', 'employee', 'viewed_at')
    search_fields = ('employer__company_name', 'employee__name')
    list_filter = ('viewed_at',)

@admin.register(ViewedJob)
class ViewedJobAdmin(ImportExportModelAdmin):
    list_display = ('job_post', 'employer', 'employee', 'viewed_at', 'applied')
    search_fields = ('job_post__job_title', 'employer__company_name', 'employee__name')
    list_filter = ('applied', 'viewed_at')

@admin.register(CompanyCertificate)
class CompanyCertificateAdmin(ImportExportModelAdmin):
    list_display = ('employer', 'certificate', 'uploaded_at')
    search_fields = ('employer__company_name',)
    list_filter = ('uploaded_at',)

@admin.register(EmployerFeedback)
class EmployerFeedbackAdmin(ImportExportModelAdmin):
    list_display = ('employer', 'rating', 'created_at')
    search_fields = ('employer__company_name', 'email')
    list_filter = ('rating', 'created_at')

@admin.register(JobPost)
class JobPostAdmin(ImportExportModelAdmin):
    list_display = ('job_title', 'employer', 'min_salary', 'max_salary', 'city', 'created_at', 'condition')
    search_fields = ('job_title', 'employer__company_name', 'city')
    list_filter = ('condition', 'created_at', 'city')

@admin.register(FavJob)
class FavJobAdmin(ImportExportModelAdmin):
    list_display = ('employee', 'job', 'employer', 'viewed', 'created_at')
    search_fields = ('employee__name', 'job__job_title', 'employer__company_name')
    list_filter = ('viewed', 'created_at')

@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ('id', 'user_type', 'employee', 'employer', 'title', 'is_read', 'created_at')
    list_filter = ('user_type', 'is_read', 'created_at')
    search_fields = ('title', 'message', 'employee__name', 'employer__company_name')
