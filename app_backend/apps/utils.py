import random
from django.conf import settings
from twilio.rest import Client
from twilio.base.exceptions import TwilioRestException
import requests

def generate_otp():
    """Generate a 6-digit OTP"""
    return str(random.randint(100000, 999999))

def send_otp(phone_number, otp):
    """Send OTP via Twilio"""
    try:
        print(phone_number)
        client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
        message = client.messages.create(
            body=f'Your OTP for 15 Jobs login is: {otp}',
            from_=settings.TWILIO_PHONE_NUMBER,
            to='+91'+phone_number
        )
        return True, message.sid
    except TwilioRestException as e:
        return False, str(e)
    except Exception as e:
        return False, str(e)

def mapbox_geocode_address(address, api_key):
    """
    Use Mapbox Geocoding API to geocode an address to [longitude, latitude].
    """
    url = f"https://api.mapbox.com/geocoding/v5/mapbox.places/{address}.json"
    params = {
        "access_token": api_key,
        "limit": 1
    }
    response = requests.get(url, params=params)
    if response.status_code == 200:
        data = response.json()
        if data.get('features'):
            coords = data['features'][0]['center']  # [longitude, latitude]
            return coords
    return None

def mapbox_reverse_geocode(lat, lon, api_key):
    """
    Use Mapbox Geocoding API to reverse geocode [lat, lon] to address.
    """
    url = f"https://api.mapbox.com/geocoding/v5/mapbox.places/{lon},{lat}.json"
    params = {
        "access_token": api_key,
        "limit": 1
    }
    response = requests.get(url, params=params)
    if response.status_code == 200:
        data = response.json()
        if data.get('features'):
            address = data['features'][0]['place_name']
            return address
    return None 