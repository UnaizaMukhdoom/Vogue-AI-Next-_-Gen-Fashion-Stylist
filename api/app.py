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

# Import scraper - required for /scrape-clothes endpoint
try:
    from scraper import scrape_all_brands_by_skin_tone
    SCRAPER_AVAILABLE = True
    print("✓ Scraper module loaded successfully")
except ImportError as e:
    scrape_all_brands_by_skin_tone = None
    SCRAPER_AVAILABLE = False
    print(f"⚠ Warning: scraper module not available: {e}")
except Exception as e:
    scrape_all_brands_by_skin_tone = None
    SCRAPER_AVAILABLE = False
    print(f"⚠ Warning: error loading scraper module: {e}")

# Import chatbot helper - required for /chatbot/chat endpoint
try:
    from chatbot_helper import get_chatbot_response, is_chatbot_available, load_chatbot_model
    CHATBOT_AVAILABLE = True
    print("✓ Chatbot module loaded successfully")
    # Pre-load chatbot model
    load_chatbot_model()
except ImportError as e:
    CHATBOT_AVAILABLE = False
    print(f"⚠ Warning: chatbot module not available: {e}")
except Exception as e:
    CHATBOT_AVAILABLE = False
    print(f"⚠ Warning: error loading chatbot module: {e}")

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
            "/scrape-clothes": "POST - Scrape clothes based on skin tone",
            "/analyze-outfit": "POST - Analyze outfit for FitCheck",
            "/chatbot/chat": "POST - Chat with AI fashion stylist",
            "/chatbot/health": "GET - Chatbot health check"
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
        if not SCRAPER_AVAILABLE or scrape_all_brands_by_skin_tone is None:
            return jsonify({
                'success': False,
                'error': 'Scraper module not available. Please check server configuration and ensure scraper.py is present.',
                'details': 'The scraper module failed to load. Check Railway logs for more information.'
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
# OUTFIT ANALYSIS (FITCHECK)
# ============================================================================

def analyze_outfit_image(image_array):
    """
    Analyze outfit image for FitCheck
    Detects colors, proportions, style, and provides personalized feedback
    Based on the actual image content uploaded by the user
    """
    try:
        # Convert to RGB for color analysis
        img_rgb = cv2.cvtColor(image_array, cv2.COLOR_BGR2RGB)
        h, w = img_rgb.shape[:2]
        
        print(f"Analyzing outfit image: {w}x{h} pixels")
        
        # Resize for faster processing while maintaining aspect ratio
        max_dim = 800
        if w > h:
            new_w = max_dim
            new_h = int(max_dim * h / w)
        else:
            new_h = max_dim
            new_w = int(max_dim * w / h)
        
        img_small = cv2.resize(img_rgb, (new_w, new_h))
        
        # Extract dominant colors from different regions of the outfit
        # Top region (likely shirt/top)
        top_region = img_small[:int(new_h*0.4), :]
        # Middle region (waist area)
        middle_region = img_small[int(new_h*0.35):int(new_h*0.65), :]
        # Bottom region (likely pants/skirt)
        bottom_region = img_small[int(new_h*0.6):, :]
        
        def get_dominant_color(region, region_name=""):
            """Extract dominant color from a region"""
            if region.size == 0:
                return np.array([128, 128, 128]), 'Neutral'
            
            pixels = region.reshape(-1, 3)
            
            # Filter out very bright pixels (likely background/lighting)
            # and very dark pixels (shadows)
            mask = (pixels.sum(axis=1) > 100) & (pixels.sum(axis=1) < 700)
            filtered_pixels = pixels[mask]
            
            if len(filtered_pixels) == 0:
                filtered_pixels = pixels
            
            # Get median color (more robust than mean)
            dominant_rgb = np.median(filtered_pixels, axis=0).astype(int)
            
            # Classify color
            r, g, b = dominant_rgb
            brightness = 0.299*r + 0.587*g + 0.114*b
            
            # Enhanced color classification
            if brightness > 220:
                color_name = 'White/Cream'
            elif brightness < 60:
                color_name = 'Black'
            elif r > g + 30 and r > b + 30:
                if r > 200:
                    color_name = 'Red'
                else:
                    color_name = 'Pink/Rose'
            elif g > r + 30 and g > b + 30:
                color_name = 'Green'
            elif b > r + 30 and b > g + 30:
                if b > 150:
                    color_name = 'Blue'
                else:
                    color_name = 'Navy'
            elif r > 180 and g > 150 and b < 100:
                color_name = 'Yellow/Beige'
            elif r > 150 and g > 120 and b < 80:
                color_name = 'Orange/Coral'
            elif abs(r - g) < 30 and abs(g - b) < 30:
                if brightness > 150:
                    color_name = 'Light Gray'
                elif brightness > 100:
                    color_name = 'Gray'
                else:
                    color_name = 'Dark Gray'
            else:
                color_name = 'Neutral'
            
            print(f"{region_name} region: {color_name} (RGB: {r}, {g}, {b})")
            return dominant_rgb, color_name
        
        top_color, top_color_name = get_dominant_color(top_region, "Top")
        middle_color, middle_color_name = get_dominant_color(middle_region, "Middle")
        bottom_color, bottom_color_name = get_dominant_color(bottom_region, "Bottom")
        
        color_names = [top_color_name, middle_color_name, bottom_color_name]
        colors = [top_color, middle_color, bottom_color]
        
        # Calculate color harmony (how well colors work together)
        color_brightnesses = [0.299*c[0] + 0.587*c[1] + 0.114*c[2] for c in colors]
        brightness_variance = np.std(color_brightnesses)
        
        # Good harmony: moderate contrast (not too similar, not too different)
        if 30 < brightness_variance < 100:
            color_harmony_score = 75 + min(20, int(brightness_variance / 2))
        elif brightness_variance < 30:
            color_harmony_score = 60  # Too similar (monochromatic)
        else:
            color_harmony_score = 65  # Too much contrast
        
        color_harmony_score = min(100, max(50, color_harmony_score))
        
        # Proportion analysis based on image composition
        # Check if outfit has balanced proportions
        top_ratio = len(top_region) / len(img_small)
        bottom_ratio = len(bottom_region) / len(img_small)
        
        # Ideal proportions: balanced top and bottom
        proportion_balance = 1 - abs(top_ratio - bottom_ratio)
        proportion_score = 60 + int(proportion_balance * 20)
        
        # Trendiness based on color combinations
        trendy_combos = [
            ['Black', 'White/Cream'],
            ['Black', 'Gray'],
            ['Navy', 'White/Cream'],
            ['Neutral', 'Black'],
        ]
        
        is_trendy = any(
            (c1 in color_names and c2 in color_names) 
            for c1, c2 in trendy_combos
        )
        trendy_score = 70 if is_trendy else 60
        
        # Flattering score based on color contrast and harmony
        color_contrast = brightness_variance
        if 40 < color_contrast < 80:
            flattering_score = 75
        elif color_contrast < 40:
            flattering_score = 65  # Low contrast
        else:
            flattering_score = 70  # High contrast
        
        # Coherence (how well the outfit works as a whole)
        unique_colors = len(set(color_names))
        if unique_colors == 2:
            coherence_score = 80  # Good balance
        elif unique_colors == 1:
            coherence_score = 70  # Monochromatic
        else:
            coherence_score = 65  # Too many colors
        
        # Versatility (neutral/classic colors are more versatile)
        versatile_colors = ['Black', 'White/Cream', 'Gray', 'Navy', 'Neutral']
        versatile_count = sum(1 for c in color_names if any(vc in c for vc in versatile_colors))
        versatility_score = 60 + (versatile_count * 12)
        versatility_score = min(100, versatility_score)
        
        # Calculate overall average
        avg_score = (coherence_score + color_harmony_score + trendy_score + 
                    flattering_score + proportion_score + versatility_score) / 6
        
        # Determine fit grade
        if avg_score >= 80:
            fit_grade = 'A'
        elif avg_score >= 70:
            fit_grade = 'B'
        elif avg_score >= 60:
            fit_grade = 'C'
        else:
            fit_grade = 'D'
        
        # Generate personalized feedback based on ACTUAL detected colors
        primary_color = top_color_name
        secondary_color = bottom_color_name if bottom_color_name != primary_color else middle_color_name
        
        # Personalized summary based on actual outfit
        if avg_score >= 75:
            summary = f"A solid outfit with minor areas for improvement. The {primary_color.lower()} and {secondary_color.lower()} combination works well, and the overall style is flattering. Your color choices show good coordination."
        elif avg_score >= 65:
            summary = f"Your outfit is decent but could use some refinement. The {primary_color.lower()} color is a good choice, though the overall coordination with {secondary_color.lower()} could be enhanced for a more polished look."
        else:
            summary = f"The outfit has potential but needs adjustments. The {primary_color.lower()} and {secondary_color.lower()} combination could be refined, and proportions could be improved for a more balanced silhouette."
        
        # Color match feedback based on actual colors
        if 'Black' in primary_color and 'White' in secondary_color:
            color_match_text = f"The classic black and white combination is timeless and versatile. This high-contrast pairing creates a sophisticated, polished look that works for various occasions."
        elif 'Black' in primary_color or 'Black' in secondary_color:
            color_match_text = f"The {primary_color.lower()} and {secondary_color.lower()} create a pleasant contrast. Black adds sophistication and pairs well with most colors, making this combination versatile."
        elif brightness_variance > 80:
            color_match_text = f"The {primary_color.lower()} and {secondary_color.lower()} create a bold contrast. This high-contrast combination is eye-catching and modern."
        else:
            color_match_text = f"The {primary_color.lower()} and {secondary_color.lower()} create a harmonious, balanced look. The color combination is cohesive and works well together."
        
        # Occasion suggestions based on colors
        if 'Black' in color_names or 'Navy' in color_names:
            if 'White' in color_names or 'Light Gray' in color_names:
                occasion = "1. Casual Occasions\n2. Work/Professional\n3. Evening Events"
            else:
                occasion = "1. Casual Occasions\n2. Work/Professional"
        elif any('Bright' in c or 'Red' in c or 'Blue' in c for c in color_names):
            occasion = "1. Casual Occasions\n2. Social Events"
        else:
            occasion = "1. Casual Occasions"
        
        # What's done well - personalized
        strengths = []
        if color_harmony_score > 70:
            strengths.append(f"the {primary_color.lower()} color choice")
        if coherence_score > 75:
            strengths.append("the color coordination")
        if versatility_score > 75:
            strengths.append("the versatile color palette")
        
        if strengths:
            done_well = f"The outfit is well-coordinated, and {', '.join(strengths)} {'is' if len(strengths) == 1 else 'are'} particularly strong."
        else:
            done_well = f"The outfit is simple and casual, and the {primary_color.lower()} color choice works well for everyday wear."
        
        # Personalized recommendations
        if versatility_score < 70:
            recommendation = f"The outfit is alright, but you can try pairing the {primary_color.lower()} with some accessories. Maybe adding a belt, jewelry, or a statement piece that will complement the {secondary_color.lower()} and add more visual interest."
        elif proportion_score < 70:
            recommendation = "Consider adjusting the proportions - perhaps adding a belt to define the waist or choosing pieces with different lengths to create more visual balance."
        else:
            recommendation = "Consider adding accessories to elevate the look. A statement piece, contrasting shoes, or complementary jewelry could enhance the overall style and add personality."
        
        # Color season based on detected colors
        warm_colors = ['Red', 'Pink', 'Orange', 'Yellow', 'Coral']
        cool_colors = ['Blue', 'Navy', 'Green']
        
        if any(wc in c for c in color_names for wc in warm_colors):
            color_season = 'Soft Autumn'
        elif any(cc in c for c in color_names for cc in cool_colors):
            color_season = 'Soft Summer'
        elif 'Black' in color_names or 'Gray' in color_names:
            color_season = 'Winter'
        else:
            color_season = 'Soft Autumn'
        
        print(f"Analysis complete - Fit Grade: {fit_grade}, Avg Score: {avg_score:.1f}")
        
        return {
            'success': True,
            'coherence': int(coherence_score),
            'color_match': int(color_harmony_score),
            'trendiness': int(trendy_score),
            'flattering': int(flattering_score),
            'proportion': int(proportion_score),
            'versatility': int(versatility_score),
            'fit_grade': fit_grade,
            'color_season': color_season,
            'summary': summary,
            'color_match_text': color_match_text,
            'occasion': occasion,
            'done_well': done_well,
            'recommendation': recommendation,
            'detected_colors': color_names,
            'detected_items': {
                'top': primary_color,
                'bottom': secondary_color,
                'middle': middle_color_name,
            }
        }
    except Exception as e:
        print(f"Error in outfit analysis: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'success': False,
            'error': f'Analysis error: {str(e)}'
        }

@app.route('/analyze-outfit', methods=['POST'])
def analyze_outfit():
    """
    Analyze outfit image for FitCheck
    Expects: multipart/form-data with 'image' file
    Returns: JSON with outfit analysis scores and recommendations
    """
    try:
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
        
        # Analyze outfit
        result = analyze_outfit_image(img)
        
        return jsonify(result)
    
    except Exception as e:
        return jsonify({
            "success": False,
            "error": f"Server error: {str(e)}"
        }), 500

# ============================================================================
# CHATBOT ENDPOINTS
# ============================================================================

@app.route('/chatbot/chat', methods=['POST'])
def chatbot_chat():
    """
    Chatbot endpoint for AI Stylist
    Expects: JSON with 'message' and optional 'context'
    Returns: JSON with 'response'
    """
    try:
        data = request.get_json()
        if not data or 'message' not in data:
            return jsonify({
                "success": False,
                "error": "No message provided"
            }), 400
        
        user_message = data['message']
        context = data.get('context', 'fashion_styling')
        
        # Check if chatbot is available
        if not CHATBOT_AVAILABLE:
            return jsonify({
                "success": False,
                "error": "Chatbot service is not available"
            }), 503
        
        # Get chatbot response
        try:
            response = get_chatbot_response(user_message, context)
            return jsonify({
                "success": True,
                "response": response,
                "context": context
            }), 200
        except Exception as e:
            return jsonify({
                "success": False,
                "error": f"Error generating response: {str(e)}"
            }), 500
        
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/chatbot/health', methods=['GET'])
def chatbot_health():
    """Health check for chatbot service"""
    try:
        if not CHATBOT_AVAILABLE:
            return jsonify({
                "status": "unavailable",
                "service": "chatbot",
                "model_loaded": False,
                "vectorizer_loaded": False,
                "message": "Chatbot module not loaded"
            }), 503
        
        model_available = is_chatbot_available()
        return jsonify({
            "status": "healthy" if model_available else "fallback_mode",
            "service": "chatbot",
            "model_loaded": model_available,
            "message": "Chatbot is available" if model_available else "Using fallback responses"
        }), 200
    except Exception as e:
        return jsonify({
            "status": "error",
            "service": "chatbot",
            "error": str(e)
        }), 500

# ============================================================================
# RUN SERVER
# ============================================================================

if __name__ == '__main__':
    # For local testing
    app.run(host='0.0.0.0', port=5000, debug=True)

