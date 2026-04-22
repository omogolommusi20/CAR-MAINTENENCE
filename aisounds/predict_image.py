import sys
import cv2
import numpy as np
import pickle
import tensorflow as tf

from keras.models import load_model

# Check input
if len(sys.argv) < 2:
    print('Usage: python predict_image.py "path_to_image"')
    sys.exit()

image_path = sys.argv[1]
img_size = 128

# Load model
model = load_model("car_parts_model.keras")

# Load labels
with open("car_parts_labels.pkl", "rb") as f:
    le = pickle.load(f)

# Load image
img = cv2.imread(image_path)

if img is None:
    print("Could not read image. Check the path.")
    sys.exit()

# Preprocess
img = cv2.resize(img, (img_size, img_size))
img = img.astype("float32") / 255.0
img = np.expand_dims(img, axis=0)

# Predict
predictions = model.predict(img, verbose=0)[0]
predicted_index = np.argmax(predictions)
confidence = float(predictions[predicted_index]) * 100
predicted_label = le.inverse_transform([predicted_index])[0]

# Output
print("=" * 45)
print("CAR PART RECOGNITION")
print("=" * 45)
print(f"Part:       {predicted_label.upper()}")
print(f"Confidence: {confidence:.2f}%")
print("=" * 45)