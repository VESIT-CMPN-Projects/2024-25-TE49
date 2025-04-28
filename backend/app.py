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
# Google Gemini API Setup
# --------------------------
# Replace with your actual Gemini API key
GEMINI_API_KEY = ""
genai.configure(api_key=GEMINI_API_KEY)

# --------------------------
# Expanded Mood Destinations
# --------------------------
MOOD_DESTINATIONS = {
    "happy": [
        "Goa, India", "Disneyland, USA", "Paris, France", "Bali, Indonesia",
        "Barcelona, Spain", "Sydney, Australia", "Rio de Janeiro, Brazil",
        "Las Vegas, USA", "Amsterdam, Netherlands", "Bangkok, Thailand",
        "Stuttgart, Germany", "Berlin, Germany"
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
    ],
    "romantic": [
        "Paris, France", "Venice, Italy", "Kyoto, Japan",
        "Amalfi Coast, Italy", "Santorini, Greece", "Prague, Czech Republic",
        "Bora Bora, French Polynesia", "Charleston, South Carolina, USA"
    ],
    "curious": [
        "Tokyo, Japan", "Istanbul, Turkey", "Cairo, Egypt",
        "Marrakech, Morocco", "Mexico City, Mexico", "Jerusalem, Israel",
        "Berlin, Germany", "Cusco, Peru"
    ],
    "energetic": [
        "Las Vegas, USA", "Ibiza, Spain", "Berlin, Germany",
        "Miami, USA", "Singapore", "Seoul, South Korea",
        "Hong Kong", "New York City, USA"
    ],
    "peaceful": [
        "Kyoto, Japan", "Norwegian Fjords, Norway", "Lake District, UK",
        "Banff, Canada", "Ubud, Bali, Indonesia", "Kauai, Hawaii, USA",
        "Luang Prabang, Laos", "Hallstatt, Austria"
    ],
    "creative": [
        "Berlin, Germany", "Portland, Oregon, USA", "Barcelona, Spain",
        "Melbourne, Australia", "Copenhagen, Denmark", "Austin, Texas, USA",
        "Kyoto, Japan", "Mexico City, Mexico"
    ],
    "cultural": [
        "Rome, Italy", "Kyoto, Japan", "Istanbul, Turkey",
        "Varanasi, India", "Florence, Italy", "Fez, Morocco",
        "Jaipur, India", "Cusco, Peru"
    ],
    "reflective": [
        "Scottish Highlands, UK", "Sedona, Arizona, USA", "Big Sur, California, USA",
        "Norwegian Fjords, Norway", "Camino de Santiago, Spain",
        "Varanasi, India", "Bagan, Myanmar", "Joshua Tree, California, USA"
    ],
    "stressed": [
        "Bali, Indonesia", "Sedona, Arizona, USA", "Costa Rica",
        "Koh Samui, Thailand", "Amalfi Coast, Italy", "Blue Lagoon, Iceland",
        "Tulum, Mexico", "Hawaii, USA"
    ],
    "excited": [
        "Tokyo, Japan", "New York City, USA", "Las Vegas, USA",
        "Dubai, UAE", "London, UK", "Orlando, Florida, USA",
        "Barcelona, Spain", "Hong Kong"
    ],
    "spiritual": [
        "Bali, Indonesia", "Varanasi, India", "Camino de Santiago, Spain",
        "Kyoto, Japan", "Sedona, Arizona, USA", "Angkor Wat, Cambodia",
        "Kathmandu, Nepal", "Rishikesh, India"
    ],
    "nostalgic": [
        "Havana, Cuba", "New Orleans, USA", "Lisbon, Portugal",
        "Kyoto, Japan", "Rome, Italy", "Charleston, South Carolina, USA",
        "Venice, Italy", "Vienna, Austria"
    ],
    "luxurious": [
        "Monaco", "Dubai, UAE", "Santorini, Greece", "Maldives",
        "French Riviera, France", "Amalfi Coast, Italy",
        "Bora Bora, French Polynesia", "St. Moritz, Switzerland"
    ]
}

# --------------------------
# Setup NLTK for Mood Detection
# --------------------------
nltk.download('vader_lexicon')
sia = SentimentIntensityAnalyzer()

def detect_mood(text: str) -> str:
    """
    If the user text exactly matches a mood key, use it.
    Otherwise fallback to VADER sentiment analysis.
    """
    key = text.strip().lower()
    if key in MOOD_DESTINATIONS:
        logger.info(f"User-specified mood: {key}")
        return key

    scores = sia.polarity_scores(text)
    compound = scores["compound"]
    logger.debug(f"VADER scores: {scores}")
    if compound >= 0.5:
        return "happy"
    elif compound > -0.2:
        return "relaxed"
    else:
        return "adventurous"

# --------------------------
# Geoapify Router Class
# --------------------------
class GeoapifyRouter:
    def __init__(self, api_key):
        self.api_key = api_key
        self.travel_options = {
            'driving': {
                'color': '#F44336', 'icon': '🚗', 'speed': 40,
                'base_fare': 0, 'fare_per_km': 10.0, 'toll_charge': 1.5
            },
            'walking': {
                'color': '#4CAF50', 'icon': '🚶', 'speed': 5,
                'base_fare': 0, 'fare_per_km': 0
            },
            'cycling': {
                'color': '#2196F3', 'icon': '🚲', 'speed': 12,
                'base_fare': 0, 'fare_per_km': 0
            },
            'bus': {
                'color': '#FF9800', 'icon': '🚌', 'speed': 30,
                'base_fare': 10, 'fare_per_km': 1.5
            },
            'train': {
                'color': '#9C27B0', 'icon': '🚆', 'speed': 60,
                'base_fare': 20, 'fare_per_km': 1.0
            },
            'flight': {
                'color': '#3F51B5', 'icon': '✈️', 'speed': 600,
                'base_fare': 2500, 'fare_per_km': 3.0, 'min_time': 90
            }
        }

    def get_coordinates(self, location: str):
        try:
            logger.debug(f"Geocoding: {location}")
            url = "https://api.geoapify.com/v1/geocode/search"
            params = {
                "text": f"{location}, India",
                "apiKey": self.api_key,
                "limit": 1
            }
            resp = requests.get(url, params=params)
            data = resp.json()
            if data.get("features"):
                props = data["features"][0].get("properties", {})
                return float(props.get("lat")), float(props.get("lon"))
            logger.warning(f"No coordinates for {location}")
            return None
        except Exception as e:
            logger.error(f"Geocoding error: {e}")
            return None

    def calculate_distance(self, p1, p2):
        try:
            lat1, lon1 = map(math.radians, p1)
            lat2, lon2 = map(math.radians, p2)
            dlat, dlon = lat2 - lat1, lon2 - lon1
            a = math.sin(dlat/2)**2 + math.cos(lat1)*math.cos(lat2)*math.sin(dlon/2)**2
            c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
            return 6371 * c
        except Exception as e:
            logger.error(f"Distance calc failed: {e}")
            return None

    def get_route(self, start, end, mode):
        try:
            logger.info(f"Routing {mode} from {start} to {end}")
            if mode == 'flight':
                dist = self.calculate_distance(start, end)
                if not dist or dist < 200:
                    return None
                dur = self.travel_options['flight']['min_time'] + (dist/650)*60
                fare = self.travel_options['flight']['base_fare'] + dist*self.travel_options['flight']['fare_per_km']
                return {
                    'coordinates': [[start[0], start[1]], [end[0], end[1]]],
                    'distance_km': round(dist, 2),
                    'duration_mins': round(dur),
                    'total_fare': round(fare),
                    'mode': 'flight',
                    'route_color': self.travel_options['flight']['color'],
                    'transport_icon': self.travel_options['flight']['icon']
                }

            profile = 'drive' if mode in ['driving', 'bus'] else mode
            url = "https://api.geoapify.com/v1/routing"
            params = {
                "waypoints": f"{start[0]},{start[1]}|{end[0]},{end[1]}",
                "mode": profile,
                "apiKey": self.api_key
            }
            resp = requests.get(url, params=params)
            resp.raise_for_status()
            feat = resp.json().get('features', [])[0]
            props = feat.get('properties', {})
            geom = feat.get('geometry', {})
            dist = props.get('distance', 0) / 1000
            dur = props.get('time', 0) / 60
            coords = [[c[0], c[1]] for c in geom.get('coordinates', [])]
            cfg = self.travel_options[mode]
            fare = cfg['base_fare'] + dist*cfg['fare_per_km']
            if mode == 'driving':
                fare += (dist//200)*cfg['toll_charge']
            return {
                'coordinates': coords,
                'distance_km': round(dist, 2),
                'duration_mins': round(dur),
                'total_fare': round(fare),
                'mode': mode,
                'route_color': cfg['color'],
                'transport_icon': cfg['icon']
            }
        except Exception as e:
            logger.error(f"Routing error for {mode}: {e}")
            return None

# --------------------------
# API Endpoints
# --------------------------
@app.route('/api/travel-options', methods=['POST', 'OPTIONS'])
def handle_travel_options():
    if request.method == 'OPTIONS':
        resp = jsonify({"message": "Preflight accepted"})
        resp.headers.add("Access-Control-Allow-Origin", "*")
        resp.headers.add("Access-Control-Allow-Headers", "*")
        resp.headers.add("Access-Control-Allow-Methods", "*")
        return resp

    data = request.get_json(silent=True) or {}
    if not all(k in data for k in ('origin', 'destination')):
        return jsonify({"error": "Missing origin or destination"}), 400

    router = GeoapifyRouter(api_key="")
    start = router.get_coordinates(data['origin'])
    end = router.get_coordinates(data['destination'])
    if not start or not end:
        return jsonify({"error": "Could not geocode locations"}), 400

    modes = data.get('modes', ['driving', 'walking', 'bus', 'train', 'flight'])
    opts = []
    for m in modes:
        if m in router.travel_options:
            r = router.get_route(start, end, m)
            if r:
                opts.append(r)
    resp = jsonify({
        "origin": data['origin'],
        "destination": data['destination'],
        "all_options": opts
    })
    resp.headers.add("Access-Control-Allow-Origin", "*")
    return resp

@app.route('/api/mood-travel', methods=['POST'])
def mood_travel():
    data = request.get_json(silent=True) or {}
    text = data.get("text", "")
    if not text.strip():
        return jsonify({"error": "Text input is required"}), 400

    mood = detect_mood(text)
    dests = MOOD_DESTINATIONS.get(mood, [])
    return jsonify({
        "mood": mood,
        "destinations": dests
    })

@app.route('/api/mood-itinerary', methods=['POST'])
def mood_itinerary():
    data = request.get_json(silent=True) or {}
    mood = data.get("mood", "").lower()
    dest = data.get("destination", "")
    days = data.get("days", 3)
    if not dest:
        return jsonify({"error": "Destination is required"}), 400

    prompt = (
        f"Create a detailed {days}-day travel itinerary for {dest} "
        f"that suits a {mood} mood. Include daily activities, food recommendations, "
        "and best times to visit popular spots."
    )
    try:
        gen = genai.GenerativeModel("gemini-2.0-flash")
        resp = gen.generate_content(prompt)
        itinerary = resp.text
    except Exception as e:
        logger.error(f"Gemini API error: {e}")
        return jsonify({"error": "Failed to generate itinerary", "details": str(e)}), 500

    return jsonify({
        "destination": dest,
        "itinerary": itinerary
    })

# --------------------------
# Run the App
# --------------------------
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5004, debug=True)
