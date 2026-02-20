import os
import pandas as pd
import joblib

from xgboost import XGBClassifier

from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import accuracy_score, classification_report


# Step 1: Define paths
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

DATASET_PATH = os.path.join(BASE_DIR, "customer_dataset.csv")
MODEL_PATH = os.path.join(BASE_DIR, "model.pkl")


# Step 2: Load dataset
print("Loading dataset...")

data = pd.read_csv(DATASET_PATH)

print(f"Dataset loaded: {data.shape[0]} rows")


# Step 3: Encode categorical variables
print("Encoding categorical variables...")

le_geo = LabelEncoder()
le_gender = LabelEncoder()

data["geography"] = le_geo.fit_transform(data["geography"])
data["gender"] = le_gender.fit_transform(data["gender"])


# Step 4: Separate features and target
X = data.drop("churn", axis=1)
y = data["churn"]


# Step 5: Split dataset
print("Splitting dataset...")

X_train, X_test, y_train, y_test = train_test_split(
    X,
    y,
    test_size=0.2,
    random_state=42
)


# Step 6: Train XGBoost model
print("Training XGBoost model...")

model = XGBClassifier(
    n_estimators=200,
    learning_rate=0.05,
    max_depth=5,
    random_state=42,
    use_label_encoder=False,
    eval_metric='logloss'
)

model.fit(X_train, y_train)

print("Model training completed.")


# Step 7: Evaluate model
print("Evaluating model...")

y_pred = model.predict(X_test)

accuracy = accuracy_score(y_test, y_pred)

print(f"\nModel Accuracy: {accuracy:.4f}")

print("\nClassification Report:")
print(classification_report(y_test, y_pred))


# Step 8: Save model
print("Saving model...")

joblib.dump(model, MODEL_PATH)

print(f"Model saved successfully at: {MODEL_PATH}")