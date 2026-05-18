from math import radians, sin, cos, sqrt, atan2
import requests


def calculate_distance(lat1, lon1, lat2, lon2):
    earth_radius = 6371

    d_lat = radians(lat2 - lat1)
    d_lon = radians(lon2 - lon1)

    lat1 = radians(lat1)
    lat2 = radians(lat2)

    a = sin(d_lat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(d_lon / 2) ** 2
    c = 2 * atan2(sqrt(a), sqrt(1 - a))

    distance = earth_radius * c

    return round(distance, 3)


def reverse_geocode(latitude, longitude):
    try:
        url = "https://nominatim.openstreetmap.org/reverse"

        params = {
            "lat": latitude,
            "lon": longitude,
            "format": "json",
            "accept-language": "ko"
        }

        headers = {
            "User-Agent": "IoT-Care-Service"
        }

        response = requests.get(url, params=params, headers=headers, timeout=5)

        if response.status_code != 200:
            return None

        data = response.json()

        return data.get("display_name")

    except Exception:
        return None