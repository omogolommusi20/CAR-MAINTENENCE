import os
import tempfile
import pickle
import numpy as np
import librosa
import cv2
import tensorflow as tf
from keras.models import load_model
from fastapi import FastAPI, File, UploadFile
from fastapi.responses import JSONResponse

app = FastAPI(title="AutoCare AI API")

# Load sound model
with open("car_sound_model.pkl", "rb") as f:
    sound_model = pickle.load(f)
with open("scaler.pkl", "rb") as f:
    sound_scaler = pickle.load(f)

# Load image model
image_model = load_model("car_parts_model.keras")
with open("car_parts_labels.pkl", "rb") as f:
    image_le = pickle.load(f)

sound_labels = ["car_knocking", "worn_out_brakes", "serpentine_belt"]

sound_descriptions = {
    "car_knocking": {
        "title": "Engine Knock Detected",
        "cause": "Worn engine bearings or wrong fuel octane",
        "action": "Visit a mechanic immediately",
        "severity": "high"
    },
    "worn_out_brakes": {
        "title": "Worn Out Brakes Detected",
        "cause": "Brake pads worn down to metal",
        "action": "Replace brake pads immediately",
        "severity": "high"
    },
    "serpentine_belt": {
        "title": "Serpentine Belt Issue",
        "cause": "Belt is loose, worn or misaligned",
        "action": "Inspect and replace serpentine belt",
        "severity": "medium"
    }
}

image_descriptions = {
    "sparkplug": "Spark Plug — ignites fuel in the engine cylinder",
    "fusebox":   "Fuse Box — protects electrical circuits in the car",
    "battery":   "Car Battery — powers the electrical system",
    "brakepad":  "Brake Pad — creates friction to slow down the car"
}

CONFIDENCE_THRESHOLD = 60.0

def extract_sound_features(file_path):
    y_audio, sr = librosa.load(file_path, sr=None)
    mfccs = librosa.feature.mfcc(y=y_audio, sr=sr, n_mfcc=13)
    mfccs_mean = np.mean(mfccs.T, axis=0)
    chroma = librosa.feature.chroma_stft(y=y_audio, sr=sr)
    chroma_mean = np.mean(chroma.T, axis=0)
    zcr = librosa.feature.zero_crossing_rate(y=y_audio)
    zcr_mean = np.mean(zcr)
    spectral_contrast = librosa.feature.spectral_contrast(y=y_audio, sr=sr)
    spectral_mean = np.mean(spectral_contrast.T, axis=0)
    return np.concatenate([mfccs_mean, chroma_mean, [zcr_mean], spectral_mean])

@app.get("/")
def root():
    return {"status": "AutoCare AI API is running"}

@app.get("/health")
def health():
    return {"status": "running"}

@app.post("/predict_sound")
async def predict_sound(audio: UploadFile = File(...)):
    tmp_path = None
    try:
        # Save uploaded file
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
            content = await audio.read()
            tmp.write(content)
            tmp_path = tmp.name

        features = extract_sound_features(tmp_path)
        features_scaled = sound_scaler.transform([features])
        prediction = sound_model.predict(features_scaled)[0]
        probabilities = sound_model.predict_proba(features_scaled)[0]
        confidence = float(probabilities[prediction]) * 100
        label = sound_labels[int(prediction)]

        if confidence < CONFIDENCE_THRESHOLD:
            return {
                "fault": "unknown",
                "title": "No Fault Detected",
                "cause": "Sound does not match any known car fault",
                "action": "Try recording closer to the sound source",
                "severity": "none",
                "confidence": round(confidence, 1)
            }

        info = sound_descriptions[label]
        return {
            "fault": label,
            "title": info["title"],
            "cause": info["cause"],
            "action": info["action"],
            "severity": info["severity"],
            "confidence": round(confidence, 1)
        }

    except Exception as e:
        return JSONResponse(status_code=500, content={"error": str(e)})

    finally:
        if tmp_path and os.path.exists(tmp_path):
            os.unlink(tmp_path)

@app.post("/predict_image")
async def predict_image(image: UploadFile = File(...)):
    tmp_path = None
    try:
        with tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as tmp:
            content = await image.read()
            tmp.write(content)
            tmp_path = tmp.name

        img = cv2.imread(tmp_path)
        img = cv2.resize(img, (128, 128))
        img = img.astype("float32") / 255.0
        img = np.expand_dims(img, axis=0)

        predictions = image_model.predict(img, verbose=0)[0]
        predicted_index = np.argmax(predictions)
        confidence = float(predictions[predicted_index]) * 100
        label = image_le.inverse_transform([predicted_index])[0]

        if confidence < CONFIDENCE_THRESHOLD:
            return {
                "part": "unknown",
                "title": "Part Not Recognized",
                "description": "Try a clearer image",
                "confidence": round(confidence, 1)
            }

        return {
            "part": label,
            "title": label.upper(),
            "description": image_descriptions.get(label, ""),
            "confidence": round(confidence, 1)
        }

    except Exception as e:
        return JSONResponse(status_code=500, content={"error": str(e)})

    finally:
        if tmp_path and os.path.exists(tmp_path):
            os.unlink(tmp_path)