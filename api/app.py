# api/app.py
# Flask API for Skin Tone, Hair & Eye Color Analysis
# Converted from Colab notebook

from flask import Flask, request, jsonify
from flask_cors import CORS
import cv2
import numpy as np
from PIL import Image
import io
import base64
import json

# Optional scraper import - only import when needed
try:
    from scraper import scrape_all_brands_by_skin_tone
except ImportError:
    scrape_all_brands_by_skin_tone = None
    print("Warning: scraper module not available")

app = Flask(__name__)
CORS(app)  # Allow Flutter app to call this API

# Initialize cascades
face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
eye_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_eye.xml')

# ============================================================================
# SKIN TONE DETECTION
# ============================================================================

def detect_face(img):
    """Detect face in image array"""
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    faces = face_cascade.detectMultiScale(gray, 1.3, 5)
    
    if len(faces) > 0:
        (x, y, w, h) = faces[0]
        face_region = img[y:y+h, x:x+w]
        return face_region, (x, y, w, h)
    return None, None

def get_dominant_color(face_region):
    """Extract dominant skin color from face region"""
    face_rgb = cv2.cvtColor(face_region, cv2.COLOR_BGR2RGB)
    
    # Focus on center of face
    h, w = face_rgb.shape[:2]
    center_face = face_rgb[int(h*0.3):int(h*0.7), int(w*0.25):int(w*0.75)]
    
    # Resize for faster processing
    face_small = cv2.resize(center_face, (50, 50))
    pixels = face_small.reshape(-1, 3)
    
    # Remove outliers
    pixels = pixels[(pixels.sum(axis=1) > 50) & (pixels.sum(axis=1) < 650)]
    
    if len(pixels) > 0:
        skin_tone = np.median(pixels, axis=0)
    else:
        skin_tone = np.array([120, 120, 120])
    
    return skin_tone.astype(int)

def classify_skin_tone(rgb_color):
    """Classify skin tone into categories"""
    R, G, B = rgb_color
    brightness = 0.299*R + 0.587*G + 0.114*B
    
    if brightness > 200:
        category = "Very Fair"
        fitzpatrick = "Type I-II"
    elif brightness > 170:
        category = "Fair"
        fitzpatrick = "Type III"
    elif brightness > 140:
        category = "Medium"
        fitzpatrick = "Type IV"
    elif brightness > 110:
        category = "Tan/Olive"
        fitzpatrick = "Type V"
    elif brightness > 70:
        category = "Deep/Dark"
        fitzpatrick = "Type VI"
    else:
        category = "Black"
        fitzpatrick = "Type VI+"
    
    return category, fitzpatrick, brightness

def get_color_recommendations(skin_category):
    """Fashion color recommendations based on skin tone"""
    recommendations = {
        "Very Fair": {
            "best_colors": ["Soft Pink", "Lavender", "Mint Green", "Baby Blue",
                            "Peach", "Light Coral", "Cream", "Powder Blue"],
            "avoid_colors": ["Neon Colors", "Very Dark Brown", "Pure Black"],
            "neutrals": ["Beige", "Light Gray", "Soft White", "Ivory", "Charcoal"],
            "description": "Soft, delicate colors complement your fair complexion best."
        },
        "Fair": {
            "best_colors": ["Coral", "Turquoise", "Rose Pink", "Periwinkle",
                            "Soft Yellow", "Emerald Green", "Dusty Blue"],
            "avoid_colors": ["Bright Orange", "Bright Yellow", "Brown"],
            "neutrals": ["Navy Blue", "Gray", "Taupe", "Charcoal"],
            "description": "Medium-intensity colors and cool tones work beautifully."
        },
        "Medium": {
            "best_colors": ["Jewel Tones", "Teal", "Purple", "Ruby Red",
                            "Golden Yellow", "Olive Green", "Magenta", "Cobalt Blue"],
            "avoid_colors": ["Pale Pastels", "Washed Out Colors", "Nude Beige"],
            "neutrals": ["Charcoal", "Camel", "Chocolate Brown", "Black"],
            "description": "Rich, vibrant colors enhance your warm undertones."
        },
        "Tan/Olive": {
            "best_colors": ["Earth Tones", "Burgundy", "Forest Green", "Mustard Yellow",
                            "Burnt Orange", "Deep Purple", "Rust", "Gold"],
            "avoid_colors": ["Pale Pink", "Light Yellow", "Icy Blue"],
            "neutrals": ["Brown", "Khaki", "Olive", "Warm Gray", "Black"],
            "description": "Warm, earthy colors complement your rich skin tone."
        },
        "Deep/Dark": {
            "best_colors": ["Bright White", "Hot Pink", "Royal Blue", "Bright Yellow",
                            "Fuchsia", "Orange", "Lime Green", "Electric Blue"],
            "avoid_colors": ["Brown", "Dark Gray", "Dull Earth Tones"],
            "neutrals": ["Pure Black", "Bright White", "Metallic Gold", "Silver"],
            "description": "Bold, bright colors look strong and balanced against deep skin tones."
        },
        "Black": {
            "best_colors": ["White", "Gold", "Bright Yellow", "Hot Pink",
                            "Violet", "Emerald Green", "Royal Blue", "Fuchsia"],
            "avoid_colors": ["Dark Brown", "Olive", "Gray", "Beige"],
            "neutrals": ["Pure Black", "Bright White", "Silver", "Metallic Gold"],
            "description": "High-contrast and vivid hues stand out crisply on very dark skin tones."
        }
    }
    return recommendations.get(skin_category, recommendations["Medium"])

# ============================================================================
# HAIR & EYE COLOR DETECTION
# ============================================================================

def hsv_to_hair_name(h, s, v):
    """Convert HSV to hair color name"""
    if v < 35:
        return "Black"
    if s < 35 and v > 65:
        return "Gray"
    if v < 60 and s < 60:
        return "Dark Brown"
    if 10 <= h <= 30 and v > 60:
        return "Blonde"
    if 0 <= h < 15 and s > 60 and v > 40:
        return "Auburn"
    if 15 <= h <= 45 and s > 40 and v > 40:
        return "Light Brown"
    return "Brown"

def hsv_to_eye_name(h, s, v):
    """Convert HSV to eye color name"""
    if v < 30:
        return "Dark Brown"
    if s < 25 and v > 60:
        return "Gray"
    if 90 <= h <= 130 and s > 25:
        return "Blue"
    if 45 <= h <= 85 and s > 25:
        return "Green"
    if 30 <= h < 50 and s > 30:
        return "Hazel"
    if s > 20:
        return "Brown"
    return "Brown"

def cluster_dominant_color(bgr_image, k=3, mask=None):
    """Return dominant BGR color using K-means"""
    img = bgr_image.copy()
    if mask is not None:
        pts = img[mask > 0]
    else:
        pts = img.reshape(-1, 3)
    
    if pts.size < 100:
        return None
    
    pts = np.float32(pts)
    criteria = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 20, 1.0)
    attempts = 3
    flags = cv2.KMEANS_PP_CENTERS
    compactness, labels, centers = cv2.kmeans(pts, k, None, criteria, attempts, flags)
    
    counts = np.bincount(labels.flatten())
    idx = np.argmax(counts)
    dom = centers[idx].astype(np.uint8)
    return (int(dom[0]), int(dom[1]), int(dom[2]))

def detect_hair_color(image_bgr, face_bbox):
    """Estimate hair color from region above face"""
    h_img, w_img = image_bgr.shape[:2]
    x, y, w, h = face_bbox
    
    band_h = max(10, int(0.25 * h))
    band_y1 = max(0, y - band_h - 5)
    band_y2 = max(0, y - 5)
    band_x1 = max(0, x)
    band_x2 = min(w_img, x + w)
    
    hair_band = image_bgr[band_y1:band_y2, band_x1:band_x2]
    if hair_band.size == 0:
        return None, None
    
    hsv = cv2.cvtColor(hair_band, cv2.COLOR_BGR2HSV)
    lower_skin = np.array([0, 30, 50])
    upper_skin = np.array([25, 180, 255])
    skin_mask = cv2.inRange(hsv, lower_skin, upper_skin)
    
    v = hsv[:, :, 2]
    dark_mask = cv2.inRange(v, 0, 120)
    non_skin_mask = cv2.bitwise_not(skin_mask)
    hair_mask = cv2.bitwise_and(non_skin_mask, dark_mask)
    
    dom_bgr = cluster_dominant_color(hair_band, k=3, mask=hair_mask)
    if dom_bgr is None:
        dom_bgr = cluster_dominant_color(hair_band, k=3)
    
    if dom_bgr is None:
        return None, None
    
    dom_hsv = cv2.cvtColor(np.uint8([[dom_bgr]]), cv2.COLOR_BGR2HSV)[0, 0]
    h, s, v = int(dom_hsv[0]), int(dom_hsv[1]), int(dom_hsv[2])
    hair_name = hsv_to_hair_name(h, s, v)
    return hair_name, dom_bgr

def detect_eye_color(image_bgr, face_bbox):
    """Detect eye color from face region"""
    x, y, w, h = face_bbox
    face_roi = image_bgr[y:y+h, x:x+w]
    gray = cv2.cvtColor(face_roi, cv2.COLOR_BGR2GRAY)
    
    eyes = eye_cascade.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=6, minSize=(20, 20))
    if len(eyes) == 0:
        return None
    
    eye_names = []
    for (ex, ey, ew, eh) in eyes[:2]:
        eye_roi = face_roi[ey:ey+eh, ex:ex+ew]
        if eye_roi.size == 0:
            continue
        
        hsv = cv2.cvtColor(eye_roi, cv2.COLOR_BGR2HSV)
        hch, sch, vch = cv2.split(hsv)
        
        sclera_like = cv2.inRange(sch, 0, 40)
        very_bright = cv2.inRange(vch, 180, 255)
        sclera_mask = cv2.bitwise_and(sclera_like, very_bright)
        iris_mask = cv2.bitwise_not(sclera_mask)
        iris_mask = cv2.erode(iris_mask, np.ones((3, 3), np.uint8), iterations=1)
        
        dom_bgr = cluster_dominant_color(eye_roi, k=3, mask=iris_mask)
        if dom_bgr is None:
            dom_bgr = cluster_dominant_color(eye_roi, k=2)
        
        if dom_bgr is None:
            continue
        
        dom_hsv = cv2.cvtColor(np.uint8([[dom_bgr]]), cv2.COLOR_BGR2HSV)[0, 0]
        h0, s0, v0 = int(dom_hsv[0]), int(dom_hsv[1]), int(dom_hsv[2])
        eye_names.append(hsv_to_eye_name(h0, s0, v0))
    
    if not eye_names:
        return None
    
    vals, counts = np.unique(np.array(eye_names), return_counts=True)
    overall = vals[np.argmax(counts)]
    return overall

def rgb_to_hex(r, g, b):
    """Convert RGB to HEX"""
    return "#{:02X}{:02X}{:02X}".format(r, g, b)

def calculate_undertone(rgb_color):
    """Calculate undertone based on RGB values"""
    R, G, B = rgb_color
    
    # Warm undertone: more yellow/golden (R>B, G>B)
    # Cool undertone: more pink/blue (B>R)
    # Neutral: balanced
    
    if R > B and G > B:
        if R - B > 20:
            return "Warm"
        return "Neutral-Warm"
    elif B > R:
        if B - R > 20:
            return "Cool"
        return "Neutral-Cool"
    else:
        return "Neutral"

# ============================================================================
# MAIN ANALYSIS FUNCTION
# ============================================================================

def analyze_image_complete(image_array):
    """
    Complete analysis pipeline
    Returns: dict with skin tone, hair color, eye color, undertone, recommendations
    """
    # Detect face
    face_region, face_bbox = detect_face(image_array)
    
    if face_region is None:
        return {
            "success": False,
            "error": "No face detected. Please use a clear face photo."
        }
    
    # Extract skin tone
    skin_color_rgb = get_dominant_color(face_region)
    skin_category, fitzpatrick_type, brightness = classify_skin_tone(skin_color_rgb)
    
    # Calculate undertone
    undertone = calculate_undertone(skin_color_rgb)
    
    # Detect hair color
    hair_name, hair_bgr = detect_hair_color(image_array, face_bbox)
    if hair_name is None:
        hair_name = "Not detected"
    
    # Detect eye color
    eye_name = detect_eye_color(image_array, face_bbox)
    if eye_name is None:
        eye_name = "Not detected"
    
    # Get color recommendations
    recommendations = get_color_recommendations(skin_category)
    
    # Build result
    result = {
        "success": True,
        "skin_tone": {
            "category": skin_category,
            "fitzpatrick_type": fitzpatrick_type,
            "rgb": {
                "r": int(skin_color_rgb[0]),
                "g": int(skin_color_rgb[1]),
                "b": int(skin_color_rgb[2])
            },
            "hex": rgb_to_hex(int(skin_color_rgb[0]), int(skin_color_rgb[1]), int(skin_color_rgb[2])),
            "brightness": round(float(brightness), 2),
            "undertone": undertone
        },
        "hair_color": hair_name,
        "eye_color": eye_name,
        "color_recommendations": recommendations
    }
    
    return result

# ============================================================================
# API ENDPOINTS
# ============================================================================

@app.route('/')
def home():
    return jsonify({
        "service": "Skin Tone Analysis API",
        "version": "1.0",
        "endpoints": {
            "/analyze": "POST - Upload image for analysis",
            "/health": "GET - Health check",
            "/scrape-clothes": "POST - Scrape clothes based on skin tone"
        }
    })

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "service": "running"})

@app.route('/analyze', methods=['POST'])
def analyze():
    """
    Analyze uploaded image
    Expects: multipart/form-data with 'image' file
    Returns: JSON with skin tone, hair, eye color, and recommendations
    """
    try:
        # Check if image is in request
        if 'image' not in request.files:
            return jsonify({
                "success": False,
                "error": "No image file provided"
            }), 400
        
        file = request.files['image']
        
        if file.filename == '':
            return jsonify({
                "success": False,
                "error": "Empty filename"
            }), 400
        
        # Read image
        image_bytes = file.read()
        nparr = np.frombuffer(image_bytes, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if img is None:
            return jsonify({
                "success": False,
                "error": "Invalid image format"
            }), 400
        
        # Analyze image
        result = analyze_image_complete(img)
        
        return jsonify(result)
    
    except Exception as e:
        return jsonify({
            "success": False,
            "error": f"Server error: {str(e)}"
        }), 500

@app.route('/scrape-clothes', methods=['POST'])
def scrape_clothes():
    """
    Scrape clothing items based on skin tone analysis
    Expects JSON: {
        "skin_tone": "Fair",
        "best_colors": ["Coral", "Turquoise"],
        "undertone": "Warm",
        "max_items": 20  # optional
    }
    """
    try:
        data = request.json
        if not data:
            return jsonify({
                "success": False,
                "error": "No data provided"
            }), 400
        
        skin_tone = data.get('skin_tone', 'Medium')
        best_colors = data.get('best_colors', [])
        undertone = data.get('undertone', 'Neutral')
        max_items = data.get('max_items', 20)
        
        # Get color recommendations from existing function
        recommendations = get_color_recommendations(skin_tone)
        
        # Combine API recommendations with user's best colors
        all_colors = list(set(recommendations['best_colors'] + best_colors))
        
        # Scrape clothes from all brands
        print(f"Scraping clothes for skin tone: {skin_tone}, colors: {all_colors}")
        print(f"Max items requested: {max_items}")
        
        # Check if scraper is available
        if scrape_all_brands_by_skin_tone is None:
            return jsonify({
                'success': False,
                'error': 'Scraper module not available. Please check server configuration.'
            }), 503
        
        # Limit scraping to avoid timeout
        max_per_brand = min(max_items // 5, 5)  # Max 5 items per brand
        
        clothing_items = scrape_all_brands_by_skin_tone(
            skin_tone_category=skin_tone,
            preferred_colors=all_colors,
            max_per_brand=max_per_brand
        )
        
        # If no items found, return empty list with helpful message
        if not clothing_items:
            print("No items scraped. This might be due to website structure changes or blocking.")
            return jsonify({
                'success': True,
                'skin_tone': skin_tone,
                'undertone': undertone,
                'recommended_colors': all_colors,
                'clothing_items': [],
                'total_items': 0,
                'brands_scraped': [],
                'message': 'No items found. Try again later or check your internet connection.'
            })
        
        # Format response
        formatted_items = []
        for idx, item in enumerate(clothing_items[:max_items]):
            formatted_items.append({
                'id': item.get('url', '').split('/')[-1] or f"item_{idx}",
                'brand': item.get('brand', 'Unknown'),
                'title': item.get('title', 'Untitled'),
                'color': item.get('color', 'Unknown'),
                'price': item.get('price', 'N/A'),
                'url': item.get('url', ''),
                'image_url': item.get('image', ''),
            })
        
        return jsonify({
            'success': True,
            'skin_tone': skin_tone,
            'undertone': undertone,
            'recommended_colors': all_colors,
            'clothing_items': formatted_items,
            'total_items': len(formatted_items),
            'brands_scraped': list(set(item['brand'] for item in formatted_items))
        })
        
    except Exception as e:
        print(f"Error in scrape_clothes: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

# ============================================================================
# RUN SERVER
# ============================================================================

# For Vercel serverless deployment - must be at module level
handler = app

if __name__ == '__main__':
    # For local testing
    app.run(host='0.0.0.0', port=5000, debug=True)

