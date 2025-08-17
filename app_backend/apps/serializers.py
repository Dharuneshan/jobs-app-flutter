from rest_framework import serializers
from .models import EmployeeRegistration, Profile, EmployerRegistration, ViewedCandidate, CompanyCertificate, EmployerFeedback, JobPost, FavJob, ViewedJob, Notification

class ProfileSerializer(serializers.ModelSerializer):
    is_registered = serializers.SerializerMethodField()

    class Meta:
        model = Profile
        fields = ['id', 'phone_number', 'candidate_type', 'created_at', 'updated_at', 'is_registered']

    def get_is_registered(self, obj):
        return (
            EmployeeRegistration.objects.filter(phone_number=obj.phone_number).exists() or
            EmployerRegistration.objects.filter(phone_number=obj.phone_number).exists()
        )

class EmployeeRegistrationSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmployeeRegistration
        fields = [
            'employee_id', 'phone_number', 'phone_verified', 'name',
            'gender', 'age', 'district', 'city', 'marital_status',
            'work_category', 'has_work_experience', 'currently_working',
            'education_level', 'degree', 'job_location', 'physically_challenged',
            'created_at', 'updated_at', 'photo', 'device_token',
            'latitude', 'longitude', 'address',
        ]

class EmployerRegistrationSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmployerRegistration
        fields = [
            'employer_id', 'phone_number', 'district', 'taluk', 'company_name', 'location', 'gst_number',
            'founder_name', 'business_category', 'year_of_establishment',
            'employee_range', 'industry_sector', 'disability_hiring',
            'created_at', 'updated_at', 'photo',
            'subscription_type', 'view_credits', 'grade', 'no_of_post', 'device_token',
            'subscription_start',
            'latitude', 'longitude', 'address',
        ]

class ViewedCandidateSerializer(serializers.ModelSerializer):
    class Meta:
        model = ViewedCandidate
        fields = ['id', 'employer', 'employee', 'viewed_at'] 

class CompanyCertificateSerializer(serializers.ModelSerializer):
    class Meta:
        model = CompanyCertificate
        fields = ['id', 'employer', 'certificate', 'description', 'uploaded_at'] 

class EmployerFeedbackSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmployerFeedback
        fields = '__all__' 

class JobPostSerializer(serializers.ModelSerializer):
    # Explicitly define ArrayFields to ensure they are handled as lists
    city = serializers.ListField(
        child=serializers.CharField(max_length=50),
        required=False,
        allow_empty=True,
        default=list
    )
    district = serializers.ListField(
        child=serializers.CharField(max_length=50),
        required=False,
        allow_empty=True,
        default=list
    )
    required_skills = serializers.ListField(
        child=serializers.CharField(max_length=50),
        required=False,
        allow_empty=True,
        default=list
    )
    physically_challenged = serializers.ListField(
        child=serializers.CharField(max_length=50),
        required=False,
        allow_empty=True,
        default=list
    )
    special_benefits = serializers.ListField(
        child=serializers.CharField(max_length=50),
        required=False,
        allow_empty=True,
        default=list
    )

    # Use SerializerMethodField for job_video to return a full URL when reading
    job_video_url = serializers.SerializerMethodField(read_only=True)
    company_name = serializers.SerializerMethodField(read_only=True)
    employer_photo_url = serializers.SerializerMethodField(read_only=True)
    employer_location = serializers.SerializerMethodField(read_only=True)
    employer_subscription_type = serializers.SerializerMethodField(read_only=True)

    def get_job_video_url(self, obj):
        if obj.job_video:
            request = self.context.get('request')
            if request is not None:
                return request.build_absolute_uri(obj.job_video.url)
            return obj.job_video.url
        return None

    def get_company_name(self, obj):
        return obj.employer.company_name if obj.employer else None

    def get_employer_photo_url(self, obj):
        return obj.employer.photo_url if obj.employer and obj.employer.photo_url else None

    def get_employer_location(self, obj):
        return obj.employer.location if obj.employer else None

    def get_employer_subscription_type(self, obj):
        return obj.employer.subscription_type if obj.employer else None

    class Meta:
        model = JobPost
        fields = (
            'id', 'job_title', 'min_salary', 'max_salary', 'duration',
            'address', 'city', 'district', 'experience', 'education',
            'degree', 'required_skills', 'contact_number_1', 'contact_number_2',
            'whatsapp_number', 'company_landline', 'job_description', 
            'job_video', 'job_video_url', 'physically_challenged', 'special_benefits', 
            'terms_conditions', 'condition', 'employer', 'created_at', 'updated_at',
            'company_name', 'employer_photo_url', 'employer_location',
            'gender', 'marital_status', 'min_age', 'max_age',
            'employer_subscription_type',
        )

    def create(self, validated_data):
        # Extract file from validated_data if present
        job_video_file = validated_data.pop('job_video', None)

        # Create the JobPost instance
        job_post = JobPost.objects.create(**validated_data)

        # Assign the file if it exists
        if job_video_file:
            job_post.job_video = job_video_file
            job_post.save()
            # Set the job_video_url after saving
            request = self.context.get('request')
            if request is not None:
                job_post.job_video_url = f"{request.build_absolute_uri(job_post.job_video.url)}"
                job_post.save()
        
        return job_post

    def update(self, instance, validated_data):
        # Handle job_video update similar to create
        job_video_file = validated_data.pop('job_video', None)

        # Update other fields
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        
        # Update job_video if a new file is provided
        if job_video_file:
            instance.job_video = job_video_file
            # Update the job_video_url
            request = self.context.get('request')
            if request is not None:
                instance.job_video_url = f"{request.build_absolute_uri(instance.job_video.url)}"
        elif 'job_video' in validated_data and job_video_file is None:
            # If job_video was explicitly set to None (e.g., to clear it)
            instance.job_video = None
            instance.job_video_url = None

        instance.save()
        return instance 

class FavJobSerializer(serializers.ModelSerializer):
    class Meta:
        model = FavJob
        fields = '__all__' 

class ViewedJobSerializer(serializers.ModelSerializer):
    class Meta:
        model = ViewedJob
        fields = ['id', 'job_post', 'employer', 'employee', 'viewed_at', 'applied'] 

class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = '__all__' 