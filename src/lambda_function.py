import joblib
import pandas as pd
import json



MODEL_PATH = "Models/lr_rul_pipeline.joblib"


def load_model(model_path=MODEL_PATH):
    """Load the trained model."""
    model = joblib.load(model_path)
    print(f"Model loaded from: {model_path}")
    return model


model = joblib.load(MODEL_PATH)
print(f"✓ Model loaded from: {MODEL_PATH}")


def lambda_handler(event, context):
    # Get sensor data
    sensor_data = json.loads(event['body']) if 'body' in event else event

    # Convert to DataFrame and predict
    df = pd.DataFrame([sensor_data])
    prediction = model.predict(df)[0]

    # Return result
    return {
        'statusCode': 200,
        'body': json.dumps({'rul_prediction': float(prediction)})
    }