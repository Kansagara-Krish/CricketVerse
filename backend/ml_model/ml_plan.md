# 🏏 CricketMatch Prediction Engine - ML Design Plan

This document outlines the machine learning strategy for the **CricketVerse AI Win Probability Predictor**. 

The goal of this engine is to estimate the real-time probability of either team winning a match at any given point (pre-match, during the 1st innings, or during the 2nd innings).

---

## 1. Core Model Selection

We will implement a **Logistic Regression Classifier** as our primary model, with a **Random Forest Classifier** as a secondary model for comparison.

### Why Logistic Regression?
1. **Probability Calibration**: Logistic Regression naturally uses the sigmoid function $\sigma(z) = \frac{1}{1 + e^{-z}}$ to map arbitrary real-valued inputs to a range of $[0, 1]$. This corresponds exactly to the probability of Team A winning.
2. **Interpretability**: The coefficients of the logistic regression model directly indicate the direction and magnitude of each feature's impact (e.g., how much losing a wicket reduces the win percentage). This helps us return the exact "Prediction Factors" displayed in the app interface.
3. **Efficiency**: Running a simple logistic regression inference in Python takes < 5ms, which is critical for real-time Socket.IO score updates.

---

## 2. Feature Engineering

The model will be trained on the following features, categorized into three levels of match state context:

### A. Pre-Match Context (Team Strengths & Conditions)
- `team_a_strength`: Historic win rate of Team A (derived from all historical database matches).
- `team_b_strength`: Historic win rate of Team B (derived from all historical database matches).
- `toss_winner_is_a`: Binary (1 if Team A won the toss, 0 otherwise).
- `toss_decision_bat`: Binary (1 if toss decision was to bat first, 0 if bowl).

### B. Innings Context
- `is_first_innings`: Binary (1 if currently in the 1st innings, 0 if 2nd innings).

### C. Live In-Game State
- `runs_scored`: Current runs scored by the batting team.
- `wickets_lost`: Wickets lost by the batting team (0 to 10).
- `overs_completed`: Overs completed by the batting team (expressed as a decimal, e.g. 10.4 is converted to $10.66$ for mathematical consistency).
- `balls_remaining`: Number of deliveries left in the innings (max 120 for T20).
- `current_rr`: Current Run Rate (runs scored per over).

### D. Chasing State (2nd Innings Only)
- `target`: Runs needed to win + 1 (set to 0 during the 1st innings).
- `runs_needed`: Difference between `target` and `runs_scored` (set to 0 during the 1st innings).
- `required_rr`: Required Run Rate (runs needed per over to reach target; set to 0 during the 1st innings).

---

## 3. Mock Data Generation Strategy

Since we do not have an external historical dataset of thousands of T20 match states, we will write a Python script `generate_mock_data.py` that acts as a cricket simulator. 

### Simulation Mechanics:
1. **Initialize Teams**: Generate matches with randomly assigned team strengths (e.g., between 0.35 and 0.65).
2. **Simulate Ball-by-Ball Play**:
   - Batting performance (runs per ball) is a function of the batting team's strength and the bowling team's strength.
   - Wicket probability increases as the batting team attempts higher run rates or when wickets start falling (pressure factor).
   - Record the match state at the end of every over.
3. **Innings 1**: Simulates up to 20 overs or 10 wickets. Establishes the `target`.
4. **Innings 2**: Simulates chasing the `target` under pressure. Required run rate changes dynamically.
5. **Labels**: Once a match concludes, all states recorded during that match are labeled with `label_winner_is_a` (1 if Team A wins, 0 if Team B wins).
6. **Output**: We will generate 250 simulated matches, yielding ~10,000 unique over-by-over training records stored in `mock_match_data.csv`.

---

## 4. Model Training & Serialization

We will write `train_model.py` to:
1. Load `mock_match_data.csv`.
2. Standardize features (using `StandardScaler`) to ensure stable training.
3. Train a `LogisticRegression` model on the match states.
4. Evaluate precision, recall, and calibration curves.
5. Save the trained pipeline (`StandardScaler` + `LogisticRegression`) to `cricket_win_predictor.joblib` using `joblib`.

---

## 5. Backend Integration Flow

When a client requests a prediction for a match:

1. **Flutter App** requests `GET /api/v1/matches/:id/prediction`.
2. **Node.js Backend** fetches the live match state and past results from Prisma/DB.
3. **Node.js Backend** computes standard features and sends them as a JSON payload to `predict.py` via `stdin`.
4. **Python ML Script** loads the model pipeline, standardizes the input features, runs prediction, and outputs a JSON containing the win probabilities and calculated feature impacts.
5. **Node.js Backend** returns the response to the Flutter app.
