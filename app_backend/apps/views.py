from django.shortcuts import render
from rest_framework import viewsets, status
from rest_framework.response import Response
from rest_framework.decorators import action, api_view
from django.utils import timezone
from .models import EmployeeRegistration, Profile, EmployerRegistration, ViewedCandidate, CompanyCertificate, EmployerFeedback, JobPost, FavJob, ViewedJob, Notification
from .serializers import EmployeeRegistrationSerializer, ProfileSerializer, EmployerRegistrationSerializer, CompanyCertificateSerializer, EmployerFeedbackSerializer, JobPostSerializer, FavJobSerializer, ViewedJobSerializer
from .utils import generate_otp, send_otp
import os
from django.conf import settings
from django.core.files.storage import default_storage
from django.core.files.base import ContentFile
from rest_framework.parsers import MultiPartParser, FormParser
import json
from rest_framework.permissions import AllowAny
from django.db import IntegrityError
from rest_framework.views import APIView
from django.db.models import Count
from rest_framework import generics, permissions
from .serializers import NotificationSerializer
from .sns_utils import send_sns_notification
from .sns_utils import send_fcm_notification
import boto3
from math import radians, cos, sin, asin, sqrt

# Create your views here.

class ProfileViewSet(viewsets.ModelViewSet):
    queryset = Profile.objects.all()
    serializer_class = ProfileSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            self.perform_create(serializer)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=['get', 'patch'])
    def by_phone(self, request):
        phone_number = request.query_params.get('phone_number')
        if not phone_number:
            return Response({'error': 'phone_number is required'}, status=400)
        try:
            print(f"DEBUG BACKEND: Checking profile for phone: {phone_number}")
            profile = Profile.objects.get(phone_number=phone_number)
            print(f"DEBUG BACKEND: Found profile with type: {profile.candidate_type}")
            if request.method == 'PATCH':
                candidate_type = request.data.get('candidate_type')
                if candidate_type:
                    print(f"DEBUG BACKEND: Updating profile type to: {candidate_type}")
                    profile.candidate_type = candidate_type
                    profile.save()
                    serializer = self.get_serializer(profile)
                    return Response(serializer.data)
                else:
                    return Response({'error': 'candidate_type is required'}, status=400)
            serializer = self.get_serializer(profile)
            return Response(serializer.data)
        except Profile.DoesNotExist:
            print(f"DEBUG BACKEND: No profile found for phone: {phone_number}")
            return Response({'detail': 'Not found.'}, status=404)

class EmployeeRegistrationViewSet(viewsets.ModelViewSet):
    queryset = EmployeeRegistration.objects.all()
    serializer_class = EmployeeRegistrationSerializer

    def list(self, request, *args, **kwargs):
        phone_number = request.query_params.get('phone_number')
        if phone_number:
            print(f"DEBUG BACKEND: Checking employee registration for phone: {phone_number}")
            queryset = self.queryset.filter(phone_number=phone_number)
            print(f"DEBUG BACKEND: Found {queryset.count()} employee registrations")
            serializer = self.get_serializer(queryset, many=True)
            return Response(serializer.data)
        return super().list(request, *args, **kwargs)

    @action(detail=False, methods=['post'])
    def verify_phone(self, request):
        phone_number = request.data.get('phone_number')
        try:
            employee = EmployeeRegistration.objects.get(phone_number=phone_number)
            employee.phone_verified = True
            employee.save()
            return Response({'status': 'Phone number verified successfully'})
        except EmployeeRegistration.DoesNotExist:
            return Response(
                {'error': 'Employee not found'},
                status=status.HTTP_404_NOT_FOUND
            )

    def create(self, request, *args, **kwargs):
        data = request.data.copy()
        # Let Django handle the file upload to S3 automatically
        # The photo field will be handled by the serializer
        # Accept location fields if present
        for field in ['latitude', 'longitude', 'address']:
            if field in request.data:
                data[field] = request.data[field]
        serializer = self.get_serializer(data=data)
        if serializer.is_valid():
            self.perform_create(serializer)
            return Response(
                serializer.data,
                status=status.HTTP_201_CREATED
            )
        return Response(
            serializer.errors,
            status=status.HTTP_400_BAD_REQUEST
        )

    @action(detail=False, methods=['patch'], url_path='update-device-token')
    def update_device_token(self, request):
        print("DEBUG: update_device_token called")
        print("DEBUG: request.data =", request.data)
        phone_number = request.data.get('phone_number')
        device_token = request.data.get('device_token')
        if not phone_number or not device_token:
            print("DEBUG: Missing phone_number or device_token")
            return Response({'detail': 'phone_number and device_token required.'}, status=400)
        try:
            employee = EmployeeRegistration.objects.get(phone_number=phone_number)
            print("DEBUG: Found employee:", employee)
            # Save raw FCM token
            employee.fcm_token = device_token
            # Register FCM token with SNS and save EndpointArn
            client = boto3.client(
                "sns",
                aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
                aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
                region_name=settings.AWS_SNS_REGION_NAME,
            )
            response = client.create_platform_endpoint(
                PlatformApplicationArn=settings.AWS_SNS_PLATFORM_APPLICATION_ARN_EMPLOYEE,
                Token=device_token,
            )
            endpoint_arn = response['EndpointArn']
            employee.device_token = endpoint_arn
            employee.save()
            print("DEBUG: Saved employee with new tokens")
            return Response({'status': 'Device token updated successfully'})
        except EmployeeRegistration.DoesNotExist:
            print("DEBUG: Employee not found")
            return Response({'detail': 'Not found.'}, status=404)
        except Exception as e:
            print("DEBUG: Exception occurred:", e)
            return Response({'detail': str(e)}, status=500)

class EmployerRegistrationViewSet(viewsets.ModelViewSet):
    queryset = EmployerRegistration.objects.all()
    serializer_class = EmployerRegistrationSerializer

    def list(self, request, *args, **kwargs):
        phone_number = request.query_params.get('phone_number')
        if phone_number:
            print(f"DEBUG BACKEND: Checking employer registration for phone: {phone_number}")
            queryset = self.queryset.filter(phone_number=phone_number)
            print(f"DEBUG BACKEND: grade for {phone_number}: {[e.grade for e in queryset]}")
            serializer = self.get_serializer(queryset, many=True)
            return Response(serializer.data)
        return super().list(request, *args, **kwargs)

    def create(self, request, *args, **kwargs):
        print("DEBUG: request.FILES =", request.FILES)
        print("DEBUG: request.data =", request.data)
        print("DEBUG BACKEND: Employer registration payload:", request.data)
        data = request.data.copy()
        # Let Django handle the file upload to S3 automatically
        # The photo field will be handled by the serializer
        # Accept location fields if present
        for field in ['latitude', 'longitude', 'address', 'district', 'taluk']:
            if field in request.data:
                data[field] = request.data[field]
        serializer = self.get_serializer(data=data)
        if serializer.is_valid():
            self.perform_create(serializer)
            return Response(
                serializer.data,
                status=status.HTTP_201_CREATED
            )
        return Response(
            serializer.errors,
            status=status.HTTP_400_BAD_REQUEST
        )

    @action(detail=False, methods=['patch'], url_path='update')
    def update_by_phone(self, request):
        print("DEBUG: request.FILES =", request.FILES)
        print("DEBUG: request.data =", request.data)
        phone_number = request.query_params.get('phone_number')
        if not phone_number:
            return Response({'detail': 'Phone number required.'}, status=400)
        try:
            employer = EmployerRegistration.objects.get(phone_number=phone_number)
        except EmployerRegistration.DoesNotExist:
            return Response({'detail': 'Not found.'}, status=404)
        data = request.data.copy()
        # Let Django handle the file upload to S3 automatically
        # The photo field will be handled by the serializer
        serializer = self.get_serializer(employer, data=data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)

    def partial_update(self, request, *args, **kwargs):
        instance = self.get_object()
        data = request.data.copy()
        # Let Django handle the file upload to S3 automatically
        # The photo field will be handled by the serializer
        serializer = self.get_serializer(instance, data=data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)

    @action(detail=False, methods=['patch'], url_path='update-device-token')
    def update_device_token(self, request):
        print("DEBUG: update_device_token called")
        print("DEBUG: request.data =", request.data)
        phone_number = request.data.get('phone_number')
        device_token = request.data.get('device_token')
        if not phone_number or not device_token:
            print("DEBUG: Missing phone_number or device_token")
            return Response({'detail': 'phone_number and device_token required.'}, status=400)
        try:
            employer = EmployerRegistration.objects.get(phone_number=phone_number)
            print("DEBUG: Found employer:", employer)
            # Save raw FCM token
            employer.fcm_token = device_token
            # Register FCM token with SNS and save EndpointArn
            client = boto3.client(
                "sns",
                aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
                aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
                region_name=settings.AWS_SNS_REGION_NAME,
            )
            response = client.create_platform_endpoint(
                PlatformApplicationArn=settings.AWS_SNS_PLATFORM_APPLICATION_ARN_EMPLOYER,
                Token=device_token,
            )
            endpoint_arn = response['EndpointArn']
            employer.device_token = endpoint_arn
            employer.save()
            print("DEBUG: Saved employer with new tokens")
            return Response({'status': 'Device token updated successfully', 'endpoint_arn': endpoint_arn})
        except EmployerRegistration.DoesNotExist:
            print("DEBUG: Employer not found")
            return Response({'detail': 'Not found.'}, status=404)
        except Exception as e:
            print("DEBUG: Exception occurred:", e)
            return Response({'detail': str(e)}, status=500)

@api_view(['GET'])
def candidate_list(request):
    employer_id = request.query_params.get('employer_id')
    if not employer_id:
        return Response({'error': 'employer_id is required'}, status=400)
    
    try:
        # Get all employee registrations that are candidates
        candidates = EmployeeRegistration.objects.filter(
            is_candidate=True
        ).select_related('profile')
        
        # Serialize the data
        serializer = EmployeeRegistrationSerializer(candidates, many=True)
        return Response(serializer.data)
    except Exception as e:
        return Response({'error': str(e)}, status=500)

@api_view(['GET'])
def viewed_candidates(request):
    employer_id = request.query_params.get('employer_id')
    if not employer_id:
        return Response({'error': 'employer_id is required'}, status=400)
    try:
        employer = EmployerRegistration.objects.get(employer_id=employer_id)
        viewed = ViewedCandidate.objects.filter(employer=employer)
        # Return employee_id and viewed_at for each viewed candidate
        data = [
            {
                'employee_id': v.employee.employee_id,
                'viewed_at': v.viewed_at.isoformat(),
            }
            for v in viewed
        ]
        return Response(data)
    except Exception as e:
        return Response({'error': str(e)}, status=500)

@api_view(['GET'])
def employer_profile_views(request):
    employer_id = request.query_params.get('employer_id')
    if not employer_id:
        return Response({'error': 'employer_id is required'}, status=400)
    try:
        count = ViewedJob.objects.filter(employer_id=employer_id).count()
        return Response({'profile_views': count})
    except Exception as e:
        return Response({'error': str(e)}, status=500)

@api_view(['POST'])
def view_candidate_profile(request):
    employer_id = request.data.get('employer_id')
    employee_id = request.data.get('employee_id')
    if not employer_id or not employee_id:
        return Response({'error': 'employer_id and employee_id are required'}, status=400)
    try:
        employee = EmployeeRegistration.objects.get(employee_id=employee_id)
        employer = EmployerRegistration.objects.get(employer_id=employer_id)
        # ENFORCE view_credits
        if employer.view_credits <= 0:
            return Response({'error': 'No view credits left. Please upgrade your plan.'}, status=403)
        viewed, created = ViewedCandidate.objects.get_or_create(
            employer=employer, employee=employee
        )
        if created:
            employer.view_credits -= 1
            employer.save()
        # Notification trigger: Notify employee
        try:
            Notification.objects.create(
                employee=employee,
                user_type='employee',
                title='Profile Viewed',
                message=f'{employer.company_name} viewed your profile.'
            )
            # Try FCM push if employee has a raw FCM token (not SNS endpoint)
            if hasattr(employee, 'fcm_token') and employee.fcm_token:
                send_fcm_notification(
                    title='Profile Viewed',
                    body=f'{employer.company_name} viewed your profile.',
                    fcm_token=employee.fcm_token
                )
            else:
                send_sns_notification(
                    subject='Profile Viewed',
                    message=f'{employer.company_name} viewed your profile.'
                )
        except Exception as e:
            print(f'Notification error (view_candidate_profile): {e}')
        serializer = EmployeeRegistrationSerializer(employee)
        return Response(serializer.data)
    except EmployeeRegistration.DoesNotExist:
        return Response({'error': 'Employee not found'}, status=404)
    except EmployerRegistration.DoesNotExist:
        return Response({'error': 'Employer not found'}, status=404)
    except Exception as e:
        return Response({'error': str(e)}, status=500)

class CompanyCertificateViewSet(viewsets.ModelViewSet):
    queryset = CompanyCertificate.objects.all().order_by('-uploaded_at')
    serializer_class = CompanyCertificateSerializer
    parser_classes = (MultiPartParser, FormParser)

    def get_queryset(self):
        employer_id = self.request.query_params.get('employer_id')
        if employer_id:
            return self.queryset.filter(employer_id=employer_id)
        return self.queryset

    def perform_destroy(self, instance):
        # Remove file from storage
        from urllib.parse import urlparse
        import os
        parsed_url = urlparse(instance.certificate_url)
        file_path = os.path.join(settings.MEDIA_ROOT, parsed_url.path.replace(settings.MEDIA_URL, '').lstrip('/'))
        if os.path.exists(file_path):
            os.remove(file_path)
        instance.delete()

    def create(self, request, *args, **kwargs):
        data = request.data.copy()
        # Let Django handle the file upload to S3 automatically
        # The certificate field will be handled by the serializer
        serializer = self.get_serializer(data=data)
        if serializer.is_valid():
            self.perform_create(serializer)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class EmployerFeedbackViewSet(viewsets.ModelViewSet):
    queryset = EmployerFeedback.objects.all().order_by('-created_at')
    serializer_class = EmployerFeedbackSerializer
    parser_classes = (MultiPartParser, FormParser)

    def create(self, request, *args, **kwargs):
        data = request.data.copy()
        # Let Django handle the file upload to S3 automatically
        # The image fields will be handled by the serializer
        serializer = self.get_serializer(data=data)
        if serializer.is_valid():
            self.perform_create(serializer)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class JobPostViewSet(viewsets.ModelViewSet):
    queryset = JobPost.objects.all().order_by('-created_at')
    serializer_class = JobPostSerializer
    parser_classes = (MultiPartParser, FormParser)

    def get_queryset(self):
        queryset = JobPost.objects.all().order_by('-created_at')
        # Auto-deactivate expired posts
        for job in queryset.filter(condition='posted'):
            plan = job.employer.subscription_type
            created = job.created_at
            now = timezone.now()
            expired = False
            if plan == 'silver' and (now - created).days >= 5:
                expired = True
            elif plan == 'gold' and (now - created).days >= 30:
                expired = True
            if expired:
                job.condition = 'draft'
                job.save()
        # Filter by condition (posted/draft)
        condition = self.request.query_params.get('condition')
        if condition:
            queryset = queryset.filter(condition=condition)
        
        # Filter by employer
        employer_id = self.request.query_params.get('employer_id')
        if employer_id:
            queryset = queryset.filter(employer_id=employer_id)
        
        return queryset

    def create(self, request, *args, **kwargs):
        # Define array_fields at the beginning of the method
        array_fields = ['city', 'district', 'required_skills', 'physically_challenged', 'special_benefits']

        # Initialize an empty dictionary for processed data
        processed_data = {}
        
        # Debug print the raw request data
        print("DEBUG: Raw request.POST:", request.POST)
        print("DEBUG: Raw request.data:", request.data)
        
        # Manually copy non-file fields from request.data
        for key, value in request.data.items():
            # Skip 'job_video' as it's handled separately from request.FILES
            if key != 'job_video':
                if key in array_fields:
                    try:
                        # Try to parse as JSON first
                        processed_data[key] = json.loads(value)
                        print(f"DEBUG: Parsed JSON for {key}: {processed_data[key]}")
                    except (json.JSONDecodeError, TypeError):
                        # If not JSON, try to get as list
                        values = request.POST.getlist(f'{key}[]')
                        if not values:
                            values = request.POST.getlist(key)
                        processed_data[key] = values
                        print(f"DEBUG: Got list for {key}: {values}")
                else:
                    processed_data[key] = value

        # Handle job_video file from request.FILES directly
        job_video_file = request.FILES.get('job_video')
        if job_video_file:
            processed_data['job_video'] = job_video_file
        
        # Add gender, marital_status, min_age, max_age to processed_data if present
        for field in ['gender', 'marital_status', 'min_age', 'max_age']:
            if field in request.data:
                processed_data[field] = request.data[field]
        
        # Debug prints to verify the data
        print("DEBUG: Request POST data:", request.POST)
        print("DEBUG: Processed Data for Serializer:", processed_data)

        employer_id = request.data.get('employer') or request.data.get('employer_id')
        if employer_id:
            try:
                employer = EmployerRegistration.objects.get(employer_id=employer_id)
                if employer.no_of_post <= 0:
                    return Response({'error': 'No job post credits left. Please upgrade your plan.'}, status=403)
            except EmployerRegistration.DoesNotExist:
                return Response({'error': 'Employer not found'}, status=404)

        serializer = self.get_serializer(data=processed_data)
        if serializer.is_valid():
            print("DEBUG: Serializer validated_data:", serializer.validated_data)
            self.perform_create(serializer)
            # Decrement no_of_post if post was created
            if response.status_code == 201 and employer_id:
                try:
                    employer = EmployerRegistration.objects.get(employer_id=employer_id)
                    if employer.no_of_post > 0:
                        employer.no_of_post -= 1
                        employer.save()
                except EmployerRegistration.DoesNotExist:
                    pass
            # Notification trigger: Notify suitable employees
            try:
                job_post = self.get_object()
                employer = job_post.employer
                # Example: notify employees with matching work_category
                suitable_employees = EmployeeRegistration.objects.filter(work_category=job_post.experience)
                for employee in suitable_employees:
                    Notification.objects.create(
                        employee=employee,
                        user_type='employee',
                        title='New Job Match',
                        message=f'New job posted: {job_post.job_title} matches your profile!'
                    )
                    # Try FCM push if employee has a raw FCM token (not SNS endpoint)
                    if hasattr(employee, 'fcm_token') and employee.fcm_token:
                        send_fcm_notification(
                            title='New Job Match',
                            body=f'New job posted: {job_post.job_title} matches your profile!',
                            fcm_token=employee.fcm_token
                        )
                    else:
                        send_sns_notification(
                            subject='New Job Match',
                            message=f'New job posted: {job_post.job_title} matches your profile!',
                            device_token=employee.device_token if employee.device_token else None
                        )
            except Exception as e:
                print(f'Notification error (JobPostViewSet.create): {e}')
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        print("DEBUG: Serializer errors:", serializer.errors)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class JobApplicationViewSet(viewsets.ModelViewSet):
    queryset = JobPost.objects.all().order_by('-created_at')
    serializer_class = JobPostSerializer
    parser_classes = (MultiPartParser, FormParser)

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            self.perform_create(serializer)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class FavJobViewSet(viewsets.ModelViewSet):
    queryset = FavJob.objects.all().order_by('-created_at')
    serializer_class = FavJobSerializer
    permission_classes = [AllowAny]  # Replace with IsAuthenticated if you add auth

    def get_queryset(self):
        queryset = FavJob.objects.all().order_by('-created_at')
        employee_id = self.request.query_params.get('employee_id')
        if employee_id:
            queryset = queryset.filter(employee_id=employee_id)
        return queryset

    def perform_create(self, serializer):
        # Only allow creation for the employee in the request data
        serializer.save(viewed=False)

    @action(detail=False, methods=['post'])
    def like(self, request):
        employee_id = request.data.get('employee_id')
        job_id = request.data.get('job_id')
        employer_id = request.data.get('employer_id')
        if not (employee_id and job_id and employer_id):
            return Response({'error': 'employee_id, job_id, and employer_id are required.'}, status=400)
        # Prevent duplicate favorites
        if FavJob.objects.filter(employee_id=employee_id, job_id=job_id, employer_id=employer_id).exists():
            return Response({'detail': 'Already favorited.'}, status=200)
        try:
            fav = FavJob.objects.create(
                employee_id=employee_id,
                job_id=job_id,
                employer_id=employer_id,
                viewed=False
            )
            serializer = self.get_serializer(fav)
            return Response(serializer.data, status=201)
        except IntegrityError:
            return Response({'detail': 'Already favorited.'}, status=200)
        except Exception as e:
            return Response({'error': str(e)}, status=500)

@api_view(['POST'])
def mark_job_viewed(request):
    job_post_id = request.data.get('job_post_id')
    employer_id = request.data.get('employer_id')
    employee_id = request.data.get('employee_id')
    print(f"DEBUG: mark_job_viewed called with job_post_id={job_post_id}, employer_id={employer_id}, employee_id={employee_id}")
    if not (job_post_id and employer_id and employee_id):
        print("DEBUG: Missing required fields in mark_job_viewed")
        return Response({'error': 'job_post_id, employer_id, and employee_id are required.'}, status=400)
    try:
        viewed_job, created = ViewedJob.objects.get_or_create(
            job_post_id=job_post_id,
            employer_id=employer_id,
            employee_id=employee_id
        )
        print(f"DEBUG: ViewedJob {'created' if created else 'retrieved'}: {viewed_job}")
        serializer = ViewedJobSerializer(viewed_job)
        return Response(serializer.data, status=201 if created else 200)
    except Exception as e:
        print(f"ERROR in mark_job_viewed: {e}")
        import traceback
        traceback.print_exc()
        return Response({'error': str(e)}, status=500)

@api_view(['GET'])
def viewed_jobs(request):
    employee_id = request.GET.get('employee_id')
    job_post_id = request.GET.get('job_post_id')
    employer_id = request.GET.get('employer_id')
    # If all three are provided, return the specific viewed job row
    if employee_id and job_post_id and employer_id:
        viewed = ViewedJob.objects.filter(
            employee_id=employee_id,
            job_post_id=job_post_id,
            employer_id=employer_id
        )
        serializer = ViewedJobSerializer(viewed, many=True)
        return Response(serializer.data, status=200)
    # Otherwise, default to the old behavior
    if not employee_id:
        return Response({'error': 'employee_id is required.'}, status=400)
    try:
        viewed = ViewedJob.objects.filter(employee_id=employee_id)
        job_ids = list(viewed.values_list('job_post_id', flat=True))
        return Response({'viewed_job_ids': job_ids}, status=200)
    except Exception as e:
        return Response({'error': str(e)}, status=500)

@api_view(['POST'])
def apply_job(request):
    job_post_id = request.data.get('job_post_id')
    employer_id = request.data.get('employer_id')
    employee_id = request.data.get('employee_id')
    if not (job_post_id and employer_id and employee_id):
        return Response({'error': 'job_post_id, employer_id, and employee_id are required.'}, status=400)
    try:
        viewed_job, created = ViewedJob.objects.get_or_create(
            job_post_id=job_post_id,
            employer_id=employer_id,
            employee_id=employee_id
        )
        viewed_job.applied = True
        viewed_job.save()
        # Notification trigger: Notify employer
        try:
            employer = EmployerRegistration.objects.get(employer_id=employer_id)
            employee = EmployeeRegistration.objects.get(employee_id=employee_id)
            job = JobPost.objects.get(id=job_post_id)
            Notification.objects.create(
                employer=employer,
                user_type='employer',
                title='New Job Application',
                message=f'{employee.name} applied for your job: {job.job_title}'
            )
            # Try FCM push if employer has a raw FCM token (not SNS endpoint)
            if hasattr(employer, 'fcm_token') and employer.fcm_token:
                send_fcm_notification(
                    title='New Job Application',
                    body=f'{employee.name} applied for your job: {job.job_title}',
                    fcm_token=employer.fcm_token
                )
            else:
                send_sns_notification(
                    subject='New Job Application',
                    message=f'{employee.name} applied for your job: {job.job_title}',
                    device_token=employer.device_token if employer.device_token else None
                )
        except Exception as e:
            print(f'Notification error (apply_job): {e}')
        serializer = ViewedJobSerializer(viewed_job)
        return Response(serializer.data, status=201 if created else 200)
    except Exception as e:
        return Response({'error': str(e)}, status=500)

class EmployeePhotoUploadView(APIView):
    parser_classes = (MultiPartParser, FormParser)

    def post(self, request, *args, **kwargs):
        photo = request.FILES.get('photo')
        if not photo:
            return Response({'error': 'No photo uploaded'}, status=status.HTTP_400_BAD_REQUEST)
        # Let Django handle the file upload to S3 automatically
        # For this view, we'll return the S3 URL directly
        from django.core.files.storage import default_storage
        file_path = default_storage.save(f'employee_photo/{photo.name}', photo)
        photo_url = default_storage.url(file_path)
        return Response({'photo_url': photo_url}, status=status.HTTP_201_CREATED)

@api_view(['GET'])
def applied_jobs(request):
    employee_id = request.GET.get('employee_id')
    if not employee_id:
        return Response({'error': 'employee_id is required.'}, status=400)
    try:
        # Get all viewed jobs with applied=True for this employee
        viewed = ViewedJob.objects.filter(employee_id=employee_id, applied=True)
        # Get the related job posts
        job_posts = JobPost.objects.filter(id__in=viewed.values_list('job_post_id', flat=True))
        # Serialize job posts
        from .serializers import JobPostSerializer
        serializer = JobPostSerializer(job_posts, many=True, context={'request': request})
        return Response(serializer.data, status=200)
    except Exception as e:
        return Response({'error': str(e)}, status=500)

@api_view(['GET'])
def employer_applied_candidates(request):
    employer_id = request.GET.get('employer_id')
    if not employer_id:
        return Response({'error': 'employer_id is required.'}, status=400)
    try:
        # Get all viewed jobs with applied=True for this employer
        viewed = ViewedJob.objects.filter(employer_id=employer_id, applied=True).select_related('employee', 'job_post')
        result = []
        for v in viewed:
            employee_data = EmployeeRegistrationSerializer(v.employee).data
            job_title = v.job_post.job_title if v.job_post else ''
            job_post_id = v.job_post.id if v.job_post else None
            result.append({
                'employee': employee_data,
                'job_title': job_title,
                'job_post_id': job_post_id
            })
        return Response(result, status=200)
    except Exception as e:
        return Response({'error': str(e)}, status=500)

@api_view(['POST'])
def update_employer_plan(request):
    """
    Update employer's plan (subscription_type, view_credits, no_of_post) based on selected plan.
    Accepts: employer_id or phone_number, and plan ('silver' or 'gold')
    """
    employer_id = request.data.get('employer_id')
    phone_number = request.data.get('phone_number')
    plan = request.data.get('plan')
    if not plan or (not employer_id and not phone_number):
        return Response({'error': 'plan and employer_id or phone_number required'}, status=400)
    try:
        if employer_id:
            employer = EmployerRegistration.objects.get(employer_id=employer_id)
        else:
            employer = EmployerRegistration.objects.get(phone_number=phone_number)
    except EmployerRegistration.DoesNotExist:
        return Response({'error': 'Employer not found'}, status=404)
    if plan == 'silver':
        employer.subscription_type = 'silver'
        employer.view_credits = 5
        employer.no_of_post = 1
        employer.subscription_start = timezone.now()
    elif plan == 'gold':
        employer.subscription_type = 'gold'
        employer.view_credits = 20
        employer.no_of_post = 5
        employer.subscription_start = timezone.now()
    else:
        return Response({'error': 'Invalid plan'}, status=400)
    employer.save()
    serializer = EmployerRegistrationSerializer(employer)
    return Response(serializer.data)

@api_view(['GET'])
def analytics_dashboard(request):
    data = {}
    # Employee Registrations by Gender
    data['employee_registrations_by_gender'] = list(
        EmployeeRegistration.objects.values('gender').annotate(count=Count('employee_id')).order_by('gender')
    )
    # Employee Registrations by Marital Status
    data['employee_registrations_by_marital_status'] = list(
        EmployeeRegistration.objects.values('marital_status').annotate(count=Count('employee_id')).order_by('marital_status')
    )
    # Employer Registrations by Subscription Type
    data['employer_registrations_by_subscription'] = list(
        EmployerRegistration.objects.values('subscription_type').annotate(count=Count('employer_id')).order_by('subscription_type')
    )
    # Employer Registrations by Business Category
    data['employer_registrations_by_business_category'] = list(
        EmployerRegistration.objects.values('business_category').annotate(count=Count('employer_id')).order_by('business_category')
    )
    # Employer Registrations by Industry Sector
    data['employer_registrations_by_industry_sector'] = list(
        EmployerRegistration.objects.values('industry_sector').annotate(count=Count('employer_id')).order_by('industry_sector')
    )
    # Job Posts by Education
    data['job_posts_by_education'] = list(
        JobPost.objects.values('education').annotate(count=Count('job_title')).order_by('education')
    )
    return Response(data)

class NotificationListView(generics.ListAPIView):
    serializer_class = NotificationSerializer
    permission_classes = [permissions.AllowAny]  # Change to IsAuthenticated if you use authentication

    def get_queryset(self):
        employee_id = self.request.query_params.get('employee_id')
        employer_id = self.request.query_params.get('employer_id')
        if employee_id:
            return Notification.objects.filter(employee_id=employee_id)
        elif employer_id:
            return Notification.objects.filter(employer_id=employer_id)
        return Notification.objects.none()

class NotificationMarkReadView(generics.UpdateAPIView):
    serializer_class = NotificationSerializer
    permission_classes = [permissions.AllowAny]  # Change to IsAuthenticated if you use authentication
    queryset = Notification.objects.all()

    def patch(self, request, *args, **kwargs):
        notification = self.get_object()
        notification.is_read = True
        notification.save()
        return Response({'status': 'marked as read'})

@api_view(['POST'])
def geocode_address(request):
    """
    Accepts JSON: {"address": "..."}
    Returns: {"longitude": ..., "latitude": ...}
    """
    address = request.data.get('address')
    if not address:
        return Response({'error': 'Address is required.'}, status=400)
    from .utils import mapbox_geocode_address
    coords = mapbox_geocode_address(address, settings.MAPBOX_API_KEY)
    if coords:
        return Response({'longitude': coords[0], 'latitude': coords[1]})
    else:
        return Response({'error': 'No results found.'}, status=404)

@api_view(['POST'])
def reverse_geocode(request):
    """
    Accepts JSON: {"latitude": ..., "longitude": ...}
    Returns: {"address": "..."}
    """
    lat = request.data.get('latitude')
    lon = request.data.get('longitude')
    if lat is None or lon is None:
        return Response({'error': 'latitude and longitude are required.'}, status=400)
    from .utils import mapbox_reverse_geocode
    address = mapbox_reverse_geocode(lat, lon, settings.MAPBOX_API_KEY)
    if address:
        return Response({'address': address})
    else:
        return Response({'error': 'No results found.'}, status=404)

def haversine(lon1, lat1, lon2, lat2):
    """Calculate the great circle distance in kilometers between two points on the earth."""
    # convert decimal degrees to radians
    lon1, lat1, lon2, lat2 = map(float, [lon1, lat1, lon2, lat2])
    lon1, lat1, lon2, lat2 = map(radians, [lon1, lat1, lon2, lat2])
    # haversine formula
    dlon = lon2 - lon1
    dlat = lat2 - lat1
    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
    c = 2 * asin(sqrt(a))
    r = 6371  # Radius of earth in kilometers
    return c * r

@api_view(['POST'])
def nearby_employees(request):
    """
    Accepts JSON: {"latitude": ..., "longitude": ..., "radius": ...}
    Returns: List of employees within radius (km)
    """
    lat = request.data.get('latitude')
    lon = request.data.get('longitude')
    radius = float(request.data.get('radius', 10))  # default 10km
    if lat is None or lon is None:
        return Response({'error': 'latitude and longitude are required.'}, status=400)
    employees = EmployeeRegistration.objects.filter(latitude__isnull=False, longitude__isnull=False)
    result = []
    for emp in employees:
        if emp.latitude is not None and emp.longitude is not None:
            dist = haversine(lon, lat, emp.longitude, emp.latitude)
            if dist <= radius:
                data = EmployeeRegistrationSerializer(emp).data
                data['distance_km'] = dist
                result.append(data)
    result.sort(key=lambda x: x['distance_km'])
    return Response(result)

@api_view(['POST'])
def nearby_companies(request):
    """
    Accepts JSON: {"latitude": ..., "longitude": ..., "radius": ...}
    Returns: List of companies within radius (km)
    """
    lat = request.data.get('latitude')
    lon = request.data.get('longitude')
    radius = float(request.data.get('radius', 10))  # default 10km
    if lat is None or lon is None:
        return Response({'error': 'latitude and longitude are required.'}, status=400)
    companies = EmployerRegistration.objects.filter(latitude__isnull=False, longitude__isnull=False)
    result = []
    for comp in companies:
        if comp.latitude is not None and comp.longitude is not None:
            dist = haversine(lon, lat, comp.longitude, comp.latitude)
            if dist <= radius:
                data = EmployerRegistrationSerializer(comp).data
                data['distance_km'] = dist
                result.append(data)
    result.sort(key=lambda x: x['distance_km'])
    return Response(result)
