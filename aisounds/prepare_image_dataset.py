import os
import cv2
import numpy as np

data_dir = "car parts"
img_size = 128

X = []
y = []

labels = {
    "SPARK PLUG": "sparkplug",
    "FUSE BOX": "fusebox",
    "BATTERY": "battery",
    "BRAKE PAD": "brakepad"
}

print("Processing images...")

for folder_name, label in labels.items():
    folder = os.path.join(data_dir, folder_name)

    if not os.path.exists(folder):
        print(f"Folder not found: {folder}")
        continue

    count = 0

    for file in os.listdir(folder):
        file_path = os.path.join(folder, file)

        if file.lower().endswith((".jpg", ".jpeg", ".png", ".bmp")):
            try:
                img = cv2.imread(file_path)

                if img is None:
                    print(f"Could not read: {file_path}")
                    continue

                img = cv2.resize(img, (img_size, img_size))

                X.append(img)
                y.append(label)

                count += 1

            except Exception as e:
                print(f"Error processing {file}: {e}")

    print(f"{folder_name}: {count} images processed")

X = np.array(X, dtype="float32") / 255.0
y = np.array(y)

np.save("X_images.npy", X)
np.save("y_images.npy", y)

print(f"\nDataset prepared: {len(X)} total images")
print(f"X shape: {X.shape}")
print(f"y shape: {y.shape}")