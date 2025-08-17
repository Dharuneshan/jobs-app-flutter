# 🔧 Update CORS Settings for AWS Amplify

## **Step 1: Connect to Your EC2 Instance**

```bash
ssh -i your-key.pem ubuntu@98.84.239.161
```

## **Step 2: Update Django CORS Settings**

Navigate to your Django settings file:
```bash
cd ~/jobs-app/app_backend
nano core/settings.py
```

## **Step 3: Add Amplify Domain to CORS_ALLOWED_ORIGINS**

Find the CORS settings section and add your Amplify domain:

```python
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://127.0.0.1:3000",
    "http://localhost:8080",
    "http://127.0.0.1:8080",
    "https://master.dry9cwdjqpzb6.amplifyapp.com",  # Add this line
]

# Also add this for broader compatibility
CORS_ALLOW_ALL_ORIGINS = True  # For development - remove in production
```

## **Step 4: Restart Django Application**

```bash
sudo supervisorctl restart jobs-app
sudo systemctl reload nginx
```

## **Step 5: Test CORS**

Check if the backend is accessible from your Amplify domain:
```bash
curl -H "Origin: https://master.dry9cwdjqpzb6.amplifyapp.com" \
     -H "Access-Control-Request-Method: GET" \
     -H "Access-Control-Request-Headers: X-Requested-With" \
     -X OPTIONS \
     http://98.84.239.161/api/health/
```

## **Step 6: Verify Backend Health**

```bash
curl http://98.84.239.161/health/
```

---

**Your Amplify domain**: `https://master.dry9cwdjqpzb6.amplifyapp.com`
