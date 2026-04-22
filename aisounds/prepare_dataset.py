import os
import librosa
import numpy as np

# Folder containing your car sound files
data_dir = "car sounds"

X = []
y = []

# 3 categories only
labels = {
    "car_knocking": 0,
    "worn_out_brakes": 1,
    "serpentine_belt": 2
}

for file in os.listdir(data_dir):
    file_path = os.path.join(data_dir, file)
    if file.endswith(".wav"):
        try:
            y_audio, sr = librosa.load(file_path, sr=None)

            # Extract multiple features for better accuracy
            mfccs = librosa.feature.mfcc(y=y_audio, sr=sr, n_mfcc=13)
            mfccs_mean = np.mean(mfccs.T, axis=0)

            chroma = librosa.feature.chroma_stft(y=y_audio, sr=sr)
            chroma_mean = np.mean(chroma.T, axis=0)

            zcr = librosa.feature.zero_crossing_rate(y=y_audio)
            zcr_mean = np.mean(zcr)

            spectral_contrast = librosa.feature.spectral_contrast(y=y_audio, sr=sr)
            spectral_mean = np.mean(spectral_contrast.T, axis=0)

            # Combine all features
            features = np.concatenate([
                mfccs_mean,
                chroma_mean,
                [zcr_mean],
                spectral_mean
            ])

            # Match label from filename
            matched = False
            for key in labels.keys():
                if key in file.lower():
                    X.append(features)
                    y.append(labels[key])
                    matched = True
                    print(f"Processed: {file} → {key}")
                    break

            if not matched:
                print(f"Skipped (no matching label): {file}")

        except Exception as e:
            print(f"Error processing {file}: {e}")

np.save("X.npy", np.array(X))
np.save("y.npy", np.array(y))

print(f"\nDataset prepared: {len(X)} files processed")
if len(y) > 0:
    unique, counts = np.unique(np.array(y), return_counts=True)
    label_names = ["car_knocking", "worn_out_brakes", "serpentine_belt"]
    for u, c in zip(unique, counts):
        print(f"  {label_names[u]}: {c} files")