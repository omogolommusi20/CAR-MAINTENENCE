import numpy as np
import pickle
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, accuracy_score
from sklearn.preprocessing import StandardScaler

X = np.load("X.npy")
y = np.load("y.npy")

label_names = ["car_knocking", "worn_out_brakes", "serpentine_belt"]

print(f"Loaded {len(X)} samples with {X.shape[1]} features each")

present_labels = sorted(list(set(y.astype(int))))
present_names = [label_names[i] for i in present_labels]
print(f"Categories found: {present_names}")

if len(X) < 6:
    print("\nWARNING: Too few samples.")
    print("Please add more .wav files and re-run prepare_dataset.py")
    exit()

# Scale features
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# If small dataset train on all data
if len(X) < 15:
    print("\nSmall dataset — training on all data.")
    model = RandomForestClassifier(n_estimators=200, random_state=42)
    model.fit(X_scaled, y)
    y_pred = model.predict(X_scaled)
    accuracy = accuracy_score(y, y_pred)
else:
    X_train, X_test, y_train, y_test = train_test_split(
        X_scaled, y, test_size=0.2, random_state=42
    )
    model = RandomForestClassifier(n_estimators=200, random_state=42)
    print("\nTraining model...")
    model.fit(X_train, y_train)
    y_pred = model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    y, y_pred = y_test, y_pred

print(f"\nAccuracy: {accuracy * 100:.1f}%")
print("\nDetailed Report:")
print(classification_report(
    y, y_pred,
    labels=present_labels,
    target_names=present_names
))

# Save model and scaler
with open("car_sound_model.pkl", "wb") as f:
    pickle.dump(model, f)
with open("scaler.pkl", "wb") as f:
    pickle.dump(scaler, f)

print("Model saved as car_sound_model.pkl")
print("Scaler saved as scaler.pkl")