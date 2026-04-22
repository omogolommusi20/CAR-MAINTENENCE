import librosa
import numpy as np
import pickle
import sys

# Load model and scaler
with open("car_sound_model.pkl", "rb") as f:
    model = pickle.load(f)
with open("scaler.pkl", "rb") as f:
    scaler = pickle.load(f)

label_names = ["car_knocking", "worn_out_brakes", "serpentine_belt"]

descriptions = {
    "car_knocking": {
        "title": "Engine Knock Detected",
        "cause": "Worn engine bearings or wrong fuel octane",
        "action": "Visit a mechanic immediately — engine damage risk"
    },
    "worn_out_brakes": {
        "title": "Worn Out Brakes Detected",
        "cause": "Brake pads worn down to metal",
        "action": "Replace brake pads immediately — safety risk"
    },
    "serpentine_belt": {
        "title": "Serpentine Belt Issue Detected",
        "cause": "Belt is loose, worn or misaligned",
        "action": "Inspect and replace serpentine belt soon"
    }
}

# Minimum confidence to accept a prediction
CONFIDENCE_THRESHOLD = 60.0

def predict_sound(file_path):
    try:
        y_audio, sr = librosa.load(file_path, sr=None)

        mfccs = librosa.feature.mfcc(y=y_audio, sr=sr, n_mfcc=13)
        mfccs_mean = np.mean(mfccs.T, axis=0)

        chroma = librosa.feature.chroma_stft(y=y_audio, sr=sr)
        chroma_mean = np.mean(chroma.T, axis=0)

        zcr = librosa.feature.zero_crossing_rate(y=y_audio)
        zcr_mean = np.mean(zcr)

        spectral_contrast = librosa.feature.spectral_contrast(y=y_audio, sr=sr)
        spectral_mean = np.mean(spectral_contrast.T, axis=0)

        features = np.concatenate([
            mfccs_mean,
            chroma_mean,
            [zcr_mean],
            spectral_mean
        ])

        features_scaled = scaler.transform([features])
        prediction = model.predict(features_scaled)[0]
        probabilities = model.predict_proba(features_scaled)[0]
        confidence = float(probabilities[prediction]) * 100

        print("\n" + "="*45)
        print("  DIAGNOSIS RESULT")
        print("="*45)

        if confidence < CONFIDENCE_THRESHOLD:
            print("  Fault:      UNKNOWN / NO MATCH")
            print(f"  Confidence: {confidence:.1f}% (too low to diagnose)")
            print("  Cause:      Sound does not match any known")
            print("              car fault in the database")
            print("  Action:     Try recording closer to the")
            print("              sound source or visit a mechanic")
        else:
            label = label_names[int(prediction)]
            info = descriptions[label]
            print(f"  Fault:      {info['title']}")
            print(f"  Confidence: {confidence:.1f}%")
            print(f"  Cause:      {info['cause']}")
            print(f"  Action:     {info['action']}")

        print("="*45)
        print("\nAll probabilities:")
        for i, name in enumerate(label_names):
            bar = "█" * int(probabilities[i] * 20)
            print(f"  {name:<20} {probabilities[i]*100:.1f}% {bar}")

    except Exception as e:
        print(f"Error: {e}")

if len(sys.argv) > 1:
    predict_sound(sys.argv[1])
else:
    print("Usage: python predict.py <path_to_wav_file>")
    print("Example: python predict.py \"car sounds/test.wav\"")