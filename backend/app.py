import ssl
# Bypass SSL certificate verification for nltk downloads (if needed)
try:
    _create_unverified_https_context = ssl._create_unverified_context
except AttributeError:
    pass
else:
    ssl._create_default_https_context = _create_unverified_https_context

from flask import Flask, request, jsonify
from flask_cors import CORS
import requests
import math
import logging
import nltk
from nltk.sentiment import SentimentIntensityAnalyzer
import google.generativeai as genai

# --------------------------
# Initialization and Config
# --------------------------
app = Flask(__name__)

# Configure CORS for all /api/* endpoints
CORS(app, resources={
    r"/api/*": {
        "origins": "*",
        "methods": ["POST", "OPTIONS", "GET"],
        "allow_headers": ["Content-Type", "Authorization"],
        "supports_credentials": True
    }
})

# Configure logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# --------------------------
# Setup NLTK for Mood Detection
# --------------------------
nltk.download('vader_lexicon')
sia = SentimentIntensityAnalyzer()

def detect_mood(text):
    """Detect mood using VADER sentiment analysis."""
    scores = sia.polarity_scores(text)
    compound = scores["compound"]
    if compound >= 0.5:
        return "happy"
    elif -0.2 < compound < 0.5:
        return "relaxed"
    else:
        return "adventurous"

# --------------------------
# Google Gemini API Setup
# --------------------------
# Replace with your actual Gemini API key
GEMINI_API_KEY = "API_KEY"
genai.configure(api_key=GEMINI_API_KEY)

# --------------------------
# Expanded Mood Destinations
# --------------------------
MOOD_DESTINATIONS = {
    "happy": [
        "Goa, India", "Disneyland, USA", "Paris, France", "Bali, Indonesia",
        "Barcelona, Spain", "Sydney, Australia", "Rio de Janeiro, Brazil",
        "Las Vegas, USA", "Amsterdam, Netherlands", "Bangkok, Thailand", "Stuttgart, Germany", "Berlin, Germany"
    ],
    "relaxed": [
        "Kerala Backwaters, India", "Maldives", "Santorini, Greece",
        "Kyoto, Japan", "Lake Como, Italy", "Bora Bora, French Polynesia",
        "Maui, Hawaii", "Asheville, USA", "Hallstatt, Austria", "Phuket, Thailand"
    ],
    "adventurous": [
        "Rishikesh, India", "Machu Picchu, Peru", "Mount Everest, Nepal",
        "Patagonia, Chile", "Grand Canyon, USA", "Banff, Canada",
        "Queenstown, New Zealand", "Alaska, USA", "Mount Kilimanjaro, Tanzania",
        "Iceland"
    ]
}

# --------------------------
# Geoapify Router Class
# --------------------------
class GeoapifyRouter:
    def __init__(self, api_key):
        self.api_key = api_key
        self.travel_options = {
            'driving': {
                'color': '#F44336',
                'icon': '🚗',
                'speed': 40,
                'base_fare': 0,
                'fare_per_km': 10.0,
                'toll_charge': 1.5
            },
            'walking': {
                'color': '#4CAF50',
                'icon': '🚶',
                'speed': 5,
                'base_fare': 0,
                'fare_per_km': 0
            },
            'cycling': {
                'color': '#2196F3',
                'icon': '🚲',
                'speed': 12,
                'base_fare': 0,
                'fare_per_km': 0
            },
            'bus': {
                'color': '#FF9800',
                'icon': '🚌',
                'speed': 30,
                'base_fare': 10,
                'fare_per_km': 1.5
            },
            'train': {
                'color': '#9C27B0',
                'icon': '🚆',
                'speed': 60,
                'base_fare': 20,
                'fare_per_km': 1.0
            },
            'flight': {
                'color': '#3F51B5',
                'icon': '✈️',
                'speed': 600,
                'base_fare': 2500,
                'fare_per_km': 3.0,
                'min_time': 90
            }
        }

    def get_coordinates(self, location):
        try:
            logger.debug(f"Geocoding: {location}")
            url = "https://api.geoapify.com/v1/geocode/search"
            params = {
                "text": f"{location}, India",
                "apiKey": self.api_key,
                "limit": 1
            }
            response = requests.get(url, params=params)
            data = response.json()
            if data.get("features"):
                feature = data["features"][0]
                props = feature.get("properties", {})
                lat, lon = props.get("lat"), props.get("lon")
                if lat and lon:
                    logger.info(f"Resolved {location} → ({lat}, {lon})")
                    return (float(lat), float(lon))
            logger.warning(f"No coordinates found for {location}")
            return None
        except Exception as e:
            logger.error(f"Geocoding error: {str(e)}")
            return None

    def calculate_distance(self, point1, point2):
        """Calculate distance between two points using Haversine formula."""
        try:
            lat1, lon1 = math.radians(point1[0]), math.radians(point1[1])
            lat2, lon2 = math.radians(point2[0]), math.radians(point2[1])
            dlat, dlon = lat2 - lat1, lon2 - lon1
            a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon/2)**2
            c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
            distance = 6371 * c  # Earth radius in km
            logger.debug(f"Distance calculated: {distance:.2f} km")
            return distance
        except Exception as e:
            logger.error(f"Distance calculation failed: {str(e)}")
            return None

    def get_route(self, start, end, mode):
        """Get route details for a given travel mode."""
        try:
            logger.info(f"Processing {mode} route from {start} to {end}")
            if mode == 'flight':
                distance = self.calculate_distance(start, end)
                if not distance or distance < 200:
                    logger.warning("Flight not available for short distance")
                    return None
                duration = self.travel_options['flight']['min_time'] + (distance / 650) * 60
                fare = self.travel_options['flight']['base_fare'] + (distance * self.travel_options['flight']['fare_per_km'])
                return {
                    'coordinates': [
                        [float(start[0]), float(start[1])],
                        [float(end[0]), float(end[1])]
                    ],
                    'distance_km': round(distance, 2),
                    'duration_mins': round(duration),
                    'total_fare': round(fare),
                    'mode': 'flight',
                    'route_color': self.travel_options['flight']['color'],
                    'transport_icon': self.travel_options['flight']['icon']
                }
            # For non-flight modes, use Geoapify routing API
            profile = 'drive' if mode in ['driving', 'bus'] else mode
            url = "https://api.geoapify.com/v1/routing"
            params = {
                "waypoints": f"{start[0]},{start[1]}|{end[0]},{end[1]}",
                "mode": profile,
                "apiKey": self.api_key
            }
            logger.debug(f"Routing request: {url} with params {params}")
            response = requests.get(url, params=params)
            response.raise_for_status()
            data = response.json()
            logger.debug(f"Routing response: {data}")
            if data.get('features'):
                feature = data['features'][0]
                properties = feature.get('properties', {})
                geometry = feature.get('geometry', {})
                distance = properties.get('distance', 0) / 1000  # in km
                duration = properties.get('time', 0) / 60  # in minutes
                coordinates = [[coord[0], coord[1]] for coord in geometry.get('coordinates', [])]
                mode_config = self.travel_options[mode]
                fare = mode_config['base_fare'] + (distance * mode_config['fare_per_km'])
                if mode == 'driving':
                    fare += (distance // 200) * mode_config['toll_charge']
                return {
                    'coordinates': coordinates,
                    'distance_km': round(distance, 2),
                    'duration_mins': round(duration),
                    'total_fare': round(fare),
                    'mode': mode,
                    'route_color': mode_config['color'],
                    'transport_icon': mode_config['icon']
                }
            logger.warning(f"No route features found for {mode}")
            return None
        except Exception as e:
            logger.error(f"Route processing failed for {mode}: {str(e)}")
            return None

# --------------------------
# API Endpoints
# --------------------------

@app.route('/api/travel-options', methods=['POST', 'OPTIONS'])
def handle_travel_options():
    logger.debug("Received /api/travel-options request")
    if request.method == 'OPTIONS':
        response = jsonify({"message": "Preflight accepted"})
        response.headers.add("Access-Control-Allow-Origin", "*")
        response.headers.add("Access-Control-Allow-Headers", "*")
        response.headers.add("Access-Control-Allow-Methods", "*")
        return response

    try:
        data = request.get_json(silent=True) or {}
        if not all(field in data for field in ['origin', 'destination']):
            logger.error("Missing required fields: origin or destination")
            return jsonify({"error": "Missing origin or destination"}), 400

        router = GeoapifyRouter(api_key="API_KEY")
        start = router.get_coordinates(data['origin'])
        end = router.get_coordinates(data['destination'])
        if not start or not end:
            logger.error("Could not geocode locations")
            return jsonify({"error": "Could not geocode locations"}), 400

        modes = data.get('modes', ['driving', 'walking', 'bus', 'train', 'flight'])
        options = []
        for mode in modes:
            if mode in router.travel_options:
                route = router.get_route(start, end, mode)
                if route:
                    options.append(route)
                    logger.debug(f"Added {mode} option")
                else:
                    logger.debug(f"Skipped {mode} - no valid route found")
            else:
                logger.warning(f"Ignored invalid mode: {mode}")
        logger.info(f"Returning {len(options)} travel options")
        response = jsonify({
            "origin": data['origin'],
            "destination": data['destination'],
            "all_options": options
        })
        response.headers.add("Access-Control-Allow-Origin", "*")
        return response
    except Exception as e:
        logger.error(f"Server error in /api/travel-options: {str(e)}", exc_info=True)
        return jsonify({"error": "Internal server error"}), 500

@app.route('/api/mood-travel', methods=['POST'])
def mood_travel():
    """
    Endpoint that detects the mood from input text and returns
    an expanded list of travel destination suggestions.
    """
    try:
        data = request.get_json(silent=True) or {}
        user_text = data.get("text", "")
        if not user_text.strip():
            return jsonify({"error": "Text input is required"}), 400

        mood = detect_mood(user_text)
        destinations = MOOD_DESTINATIONS.get(mood, [])
        logger.info(f"Detected mood: {mood}. Returning {len(destinations)} destinations.")
        return jsonify({
            "mood": mood,
            "destinations": destinations
        })
    except Exception as e:
        logger.error(f"Error in /api/mood-travel: {str(e)}", exc_info=True)
        return jsonify({"error": "Internal server error"}), 500

@app.route('/api/mood-itinerary', methods=['POST'])
def mood_itinerary():
    """
    Endpoint that generates a detailed itinerary for a given destination,
    mood, and duration (in days) using the Google Gemini API.
    """
    try:
        data = request.get_json(silent=True) or {}
        mood = data.get("mood", "").lower()
        destination = data.get("destination", "")
        days = data.get("days", 3)  # Default to 3-day itinerary
        if not destination:
            return jsonify({"error": "Destination is required"}), 400

        prompt = (f"Create a detailed {days}-day travel itinerary for {destination} "
                  f"that suits a {mood} mood. Include daily activities, food recommendations, "
                  f"and best times to visit popular spots.")
        logger.debug(f"Gemini prompt: {prompt}")
        try:
            response = genai.GenerativeModel("gemini-2.0-flash").generate_content(prompt)
            itinerary = response.text
        except Exception as ge:
            logger.error(f"Gemini API error: {str(ge)}")
            return jsonify({"error": "Failed to generate itinerary", "details": str(ge)}), 500

        return jsonify({
            "destination": destination,
            "itinerary": itinerary
        })
    except Exception as e:
        logger.error(f"Error in /api/mood-itinerary: {str(e)}", exc_info=True)
        return jsonify({"error": "Internal server error"}), 500

# --------------------------
# Run the App
# --------------------------
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5004, debug=True)
