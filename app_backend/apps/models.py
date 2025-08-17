from django.db import models
from django.utils import timezone
from datetime import timedelta
from django.contrib.postgres.fields import ArrayField

# Create your models here.

class Profile(models.Model):
    CANDIDATE_TYPE_CHOICES = [
        ('employee', 'Employee'),
        ('employer', 'Employer'),
    ]
    
    phone_number = models.CharField(max_length=15, unique=True)
    candidate_type = models.CharField(max_length=10, choices=CANDIDATE_TYPE_CHOICES, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'profile'
        verbose_name = 'Profile'
        verbose_name_plural = 'Profiles'

    def __str__(self):
        return f"{self.phone_number}"

class EmployeeRegistration(models.Model):
    GENDER_CHOICES = [
        ('M', 'Male'),
        ('F', 'Female'),
        ('O', 'Other'),
    ]
    
    MARITAL_STATUS_CHOICES = [
        ('S', 'Single'),
        ('M', 'Married'),
        ('D', 'Divorced'),
        ('W', 'Widowed'),
    ]
    
    EDUCATION_LEVEL_CHOICES = [
        ('BELOW_8TH', 'Below 8th'),
        ('10TH', '10th'),
        ('12TH', '12th'),
        ('DIPLOMA', 'Diploma'),
        ('ITI', 'ITI'),
        ('UG', 'UG'),
        ('PG', 'PG'),
    ]
    
    WORK_CATEGORY_CHOICES = [
        ('IT', 'Information Technology'),
        ('HR', 'Human Resources'),
        ('MKT', 'Marketing'),
        ('FIN', 'Finance'),
        ('OPS', 'Operations'),
        ('OTH', 'Other'),
    ]
    
    employee_id = models.AutoField(primary_key=True)
    phone_number = models.CharField(max_length=15, unique=True)
    phone_verified = models.BooleanField(default=False)
    name = models.CharField(max_length=100)
    gender = models.CharField(max_length=1, choices=GENDER_CHOICES)
    age = models.IntegerField()
    district = models.CharField(max_length=50)
    city = models.CharField(max_length=50)
    marital_status = models.CharField(max_length=1, choices=MARITAL_STATUS_CHOICES)
    work_category = models.CharField(max_length=100)
    has_work_experience = models.BooleanField(default=False)
    currently_working = models.BooleanField(default=False)
    education_level = models.CharField(max_length=10, choices=EDUCATION_LEVEL_CHOICES)
    degree = models.CharField(max_length=100, blank=True, null=True)
    job_location = models.CharField(max_length=100)
    physically_challenged = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    photo = models.ImageField(upload_to='employee_photo/', null=True, blank=True)
    device_token = models.CharField(max_length=255, null=True, blank=True)
    fcm_token = models.CharField(max_length=255, null=True, blank=True)
    # Location fields
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    address = models.CharField(max_length=255, null=True, blank=True)

    class Meta:
        db_table = 'employee_registration'
        verbose_name = 'Employee Registration'
        verbose_name_plural = 'Employee Registrations'

    def __str__(self):
        return f"{self.name} - {self.phone_number}"

class EmployerRegistration(models.Model):
    employer_id = models.AutoField(primary_key=True)
    phone_number = models.CharField(max_length=15, unique=True)
    district = models.CharField(max_length=50, null=True, blank=True)
    taluk = models.CharField(max_length=50, null=True, blank=True)
    company_name = models.CharField(max_length=100)
    location = models.CharField(max_length=200)
    gst_number = models.CharField(max_length=30)
    founder_name = models.CharField(max_length=100)
    business_category = models.CharField(max_length=50)
    year_of_establishment = models.CharField(max_length=4)
    employee_range = models.CharField(max_length=20)
    industry_sector = models.CharField(max_length=50)
    disability_hiring = models.CharField(max_length=20)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    photo = models.ImageField(upload_to='employer_photo/', null=True, blank=True)
    subscription_type = models.CharField(max_length=20, default='free')
    view_credits = models.IntegerField(default=20)
    grade = models.IntegerField(default=1, help_text='Number of stars for employer ranking, editable only by superuser')
    no_of_post = models.IntegerField(default=0)
    device_token = models.CharField(max_length=255, null=True, blank=True)
    fcm_token = models.CharField(max_length=255, null=True, blank=True)
    subscription_start = models.DateTimeField(default=timezone.now)
    # Location fields
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    address = models.CharField(max_length=255, null=True, blank=True)

    class Meta:
        db_table = 'employer_registration'
        verbose_name = 'Employer Registration'
        verbose_name_plural = 'Employer Registrations'

    def __str__(self):
        return f"{self.company_name} - {self.phone_number}"

class ViewedCandidate(models.Model):
    employer = models.ForeignKey(EmployerRegistration, on_delete=models.CASCADE)
    employee = models.ForeignKey(EmployeeRegistration, on_delete=models.CASCADE)
    viewed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('employer', 'employee')
        db_table = 'viewed_candidate'
        verbose_name = 'Viewed Candidate'
        verbose_name_plural = 'Viewed Candidates'

    def __str__(self):
        return f"{self.employer} viewed {self.employee} at {self.viewed_at}"

class CompanyCertificate(models.Model):
    employer = models.ForeignKey(EmployerRegistration, on_delete=models.CASCADE)
    certificate = models.FileField(upload_to='company_certificate/', null=True, blank=True)
    description = models.CharField(max_length=255, blank=True)
    uploaded_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'company_certificate'
        verbose_name = 'Company Certificate'
        verbose_name_plural = 'Company Certificates'

    def __str__(self):
        return f"{self.employer.company_name} - {self.certificate}"

class EmployerFeedback(models.Model):
    employer = models.ForeignKey(EmployerRegistration, on_delete=models.CASCADE)
    rating = models.IntegerField()
    experience = models.TextField(null=True, blank=True)
    about = ArrayField(models.CharField(max_length=50), null=True, blank=True)
    include = ArrayField(models.CharField(max_length=50), null=True, blank=True)
    image_1 = models.ImageField(upload_to='feedback_image/', null=True, blank=True)
    image_2 = models.ImageField(upload_to='feedback_image/', null=True, blank=True)
    image_3 = models.ImageField(upload_to='feedback_image/', null=True, blank=True)
    email = models.EmailField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'employer_feedback'
        verbose_name = 'Employer Feedback'
        verbose_name_plural = 'Employer Feedbacks'

    def __str__(self):
        return f"Feedback by {self.employer_id} - {self.rating} stars"

class JobPost(models.Model):
    DURATION_CHOICES = [
        ('daily', 'Daily'),
        ('weekly', 'Weekly'),
        ('monthly', 'Monthly'),
        ('yearly', 'Yearly'),
    ]
    EDUCATION_CHOICES = [
        ('BELOW_8TH', 'Below 8th'),
        ('10TH', '10th'),
        ('12TH', '12th'),
        ('DIPLOMA', 'Diploma'),
        ('ITI', 'ITI'),
        ('UG', 'UG'),
        ('PG', 'PG'),
    ]
    CONDITION_CHOICES = [
        ('posted', 'Posted'),
        ('draft', 'Draft'),
    ]

    job_title = models.CharField(max_length=100)
    min_salary = models.PositiveIntegerField()
    max_salary = models.PositiveIntegerField()
    duration = models.CharField(max_length=10, choices=DURATION_CHOICES)
    address = models.CharField(max_length=255)
    city = ArrayField(models.CharField(max_length=500), blank=True, default=list)
    district = ArrayField(models.CharField(max_length=500), blank=True, default=list)
    experience = models.CharField(max_length=50)
    education = models.CharField(max_length=10, choices=EDUCATION_CHOICES)
    degree = models.CharField(max_length=100, null=True, blank=True)
    required_skills = ArrayField(models.CharField(max_length=500), blank=True, default=list)
    contact_number_1 = models.CharField(max_length=15)
    contact_number_2 = models.CharField(max_length=15, null=True, blank=True)
    whatsapp_number = models.CharField(max_length=15, null=True, blank=True)
    company_landline = models.CharField(max_length=20, null=True, blank=True)
    job_description = models.TextField(null=True, blank=True)
    job_video = models.FileField(upload_to='job_videos/', null=True, blank=True)
    physically_challenged = ArrayField(models.CharField(max_length=50), null=True, blank=True, default=list)
    special_benefits = ArrayField(models.CharField(max_length=500), null=True, blank=True, default=list)
    terms_conditions = models.TextField(null=True, blank=True)
    condition = models.CharField(max_length=10, choices=CONDITION_CHOICES, default='draft')
    employer = models.ForeignKey(EmployerRegistration, on_delete=models.CASCADE, related_name='job_posts')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    GENDER_CHOICES = [
        ('male', 'Male'),
        ('female', 'Female'),
        ('others', 'Others'),
        ('anyone', 'Anyone'),
    ]
    MARITAL_STATUS_CHOICES = [
        ('married', 'Married'),
        ('unmarried', 'Unmarried'),
        ('divorced', 'Divorced'),
        ('not_preferred', 'Not Preferred'),
        ('anyone', 'Anyone'),
    ]
    gender = models.CharField(max_length=12, choices=GENDER_CHOICES, default='anyone', help_text='Preferred gender for the job')
    marital_status = models.CharField(max_length=15, choices=MARITAL_STATUS_CHOICES, default='not_preferred', help_text='Preferred marital status for the job')
    min_age = models.PositiveIntegerField(default=18, help_text='Minimum age for the job')
    max_age = models.PositiveIntegerField(default=80, help_text='Maximum age for the job')

    class Meta:
        db_table = 'job_post'
        verbose_name = 'Job Post'
        verbose_name_plural = 'Job Posts'

    def __str__(self):
        return f"{self.job_title} - {self.employer.company_name}"

class FavJob(models.Model):
    employee = models.ForeignKey(EmployeeRegistration, on_delete=models.CASCADE)
    job = models.ForeignKey(JobPost, on_delete=models.CASCADE)
    employer = models.ForeignKey(EmployerRegistration, on_delete=models.CASCADE)
    viewed = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'fav_jobs'
        verbose_name = 'Favorite Job'
        verbose_name_plural = 'Favorite Jobs'
        unique_together = ('employee', 'job', 'employer')

    def __str__(self):
        return f"{self.employee} - {self.job} (Employer: {self.employer})"

class ViewedJob(models.Model):
    job_post = models.ForeignKey('JobPost', on_delete=models.CASCADE)
    employer = models.ForeignKey('EmployerRegistration', on_delete=models.CASCADE)
    employee = models.ForeignKey('EmployeeRegistration', on_delete=models.CASCADE)
    viewed_at = models.DateTimeField(auto_now_add=True)
    applied = models.BooleanField(null=True, blank=True, default=None)

    class Meta:
        db_table = 'viewed_jobs'
        verbose_name = 'Viewed Job'
        verbose_name_plural = 'Viewed Jobs'
        unique_together = ('job_post', 'employer', 'employee')

    def __str__(self):
        return f"{self.job_post} viewed by {self.employee} (Employer: {self.employer}) at {self.viewed_at}"

class Notification(models.Model):
    NOTIFY_USER_TYPE = [
        ('employee', 'Employee'),
        ('employer', 'Employer'),
    ]
    employee = models.ForeignKey(EmployeeRegistration, on_delete=models.CASCADE, null=True, blank=True, related_name='notifications')
    employer = models.ForeignKey(EmployerRegistration, on_delete=models.CASCADE, null=True, blank=True, related_name='notifications')
    user_type = models.CharField(max_length=10, choices=NOTIFY_USER_TYPE)
    title = models.CharField(max_length=255)
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        db_table = 'notification'
        verbose_name = 'Notification'
        verbose_name_plural = 'Notifications'

    def __str__(self):
        if self.user_type == 'employee' and self.employee:
            return f"To {self.employee.name}: {self.title} ({'Read' if self.is_read else 'Unread'})"
        elif self.user_type == 'employer' and self.employer:
            return f"To {self.employer.company_name}: {self.title} ({'Read' if self.is_read else 'Unread'})"
        return self.title
