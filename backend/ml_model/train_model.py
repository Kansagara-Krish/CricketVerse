import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import Pipeline
from sklearn.metrics import accuracy_score, classification_report
import joblib
import os

def derive_features(df):
    """
    Computes derived cricket features for training:
    - crr_a, crr_b (current run rates)
    - balls_remaining for currently batting team
    - wickets_in_hand of currently batting team
    - runs_needed (if 2nd innings)
    - required_rr (if 2nd innings)
    """
    df = df.copy()
    
    # Current Run Rates
    df['crr_a'] = np.where(df['overs_a'] > 0, df['runs_a'] / df['overs_a'], 0.0)
    df['crr_b'] = np.where(df['overs_b'] > 0, df['runs_b'] / df['overs_b'], 0.0)
    
    # Balls remaining & wickets in hand for batting team
    df['balls_remaining'] = np.where(
        df['batting_team_is_a'] == 1,
        np.clip(120 - (df['overs_a'] * 6).astype(int), 0, 120),
        np.clip(120 - (df['overs_b'] * 6).astype(int), 0, 120)
    )
    
    df['wickets_in_hand'] = np.where(
        df['batting_team_is_a'] == 1,
        10 - df['wickets_a'],
        10 - df['wickets_b']
    )
    
    # Chasing state
    df['runs_needed'] = 0
    # If 2nd innings, runs needed is target - current batting score
    runs_needed_a = np.clip(df['target'] - df['runs_a'], 0, None)
    runs_needed_b = np.clip(df['target'] - df['runs_b'], 0, None)
    df['runs_needed'] = np.where(
        df['is_first_innings'] == 0,
        np.where(df['batting_team_is_a'] == 1, runs_needed_a, runs_needed_b),
        0
    )
    
    df['required_rr'] = np.where(
        (df['is_first_innings'] == 0) & (df['balls_remaining'] > 0),
        (df['runs_needed'] / df['balls_remaining']) * 6.0,
        np.where((df['is_first_innings'] == 0) & (df['runs_needed'] > 0), 99.0, 0.0)
    )
    
    return df

def train():
    current_dir = os.path.dirname(__file__)
    csv_path = os.path.join(current_dir, 'mock_match_data.csv')
    
    if not os.path.exists(csv_path):
        raise FileNotFoundError(f"Mock data CSV not found at {csv_path}. Please run generate_mock_data.py first.")
        
    print(f"Loading dataset from {csv_path}...")
    df = pd.read_csv(csv_path)
    
    print("Deriving feature set...")
    df_feat = derive_features(df)
    
    # Select features for training
    features = [
        'team_a_strength', 'team_b_strength', 
        'toss_winner_is_a', 'toss_decision_bat', 
        'is_first_innings', 'batting_team_is_a', 
        'runs_a', 'wickets_a', 'overs_a', 
        'runs_b', 'wickets_b', 'overs_b', 
        'target', 'crr_a', 'crr_b', 
        'balls_remaining', 'wickets_in_hand', 
        'runs_needed', 'required_rr'
    ]
    
    X = df_feat[features]
    y = df_feat['label_winner_is_a']
    
    # Train-test split
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    # Create pipeline with StandardScaler and LogisticRegression
    pipeline = Pipeline([
        ('scaler', StandardScaler()),
        ('classifier', LogisticRegression(max_iter=1000, random_state=42))
    ])
    
    print("Training Logistic Regression model...")
    pipeline.fit(X_train, y_train)
    
    # Predictions & metrics
    train_preds = pipeline.predict(X_train)
    test_preds = pipeline.predict(X_test)
    
    train_acc = accuracy_score(y_train, train_preds)
    test_acc = accuracy_score(y_test, test_preds)
    
    print(f"\nTraining Accuracy: {train_acc:.4f}")
    print(f"Testing Accuracy: {test_acc:.4f}")
    
    print("\nClassification Report (Test Set):")
    print(classification_report(y_test, test_preds))
    
    # Inspect coefficients to verify model behavior
    lr_model = pipeline.named_steps['classifier']
    coefs = lr_model.coef_[0]
    
    print("\nFeature Coefficients (Sorted by importance for Team A victory):")
    feat_coefs = sorted(zip(features, coefs), key=lambda x: abs(x[1]), reverse=True)
    for feat, coef in feat_coefs:
        print(f"  {feat:<20}: {coef:+.4f}")
        
    # Save the pipeline
    model_path = os.path.join(current_dir, 'cricket_win_predictor.joblib')
    joblib.dump(pipeline, model_path)
    print(f"\nTrained model successfully serialized and saved to {model_path}")

if __name__ == '__main__':
    train()
