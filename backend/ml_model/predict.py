import sys
import json
import os
import joblib
import pandas as pd
import numpy as np

def derive_single_features(data):
    """
    Translates raw match JSON into the exact Pandas DataFrame format needed by the trained pipeline.
    """
    # Raw values
    team_a_strength = float(data.get('team_a_strength', 0.5))
    team_b_strength = float(data.get('team_b_strength', 0.5))
    toss_winner_is_a = int(data.get('toss_winner_is_a', 1))
    toss_decision_bat = int(data.get('toss_decision_bat', 1))
    is_first_innings = int(data.get('is_first_innings', 1))
    batting_team_is_a = int(data.get('batting_team_is_a', 1))
    
    runs_a = int(data.get('runs_a', 0))
    wickets_a = int(data.get('wickets_a', 0))
    overs_a = float(data.get('overs_a', 0.0))
    
    runs_b = int(data.get('runs_b', 0))
    wickets_b = int(data.get('wickets_b', 0))
    overs_b = float(data.get('overs_b', 0.0))
    
    target = int(data.get('target', 0))
    
    # Calculate CRRs
    crr_a = (runs_a / overs_a) if overs_a > 0 else 0.0
    crr_b = (runs_b / overs_b) if overs_b > 0 else 0.0
    
    # Active batting team properties
    if batting_team_is_a == 1:
        overs_completed = overs_a
        wickets_lost = wickets_a
        runs_scored = runs_a
        active_crr = crr_a
    else:
        overs_completed = overs_b
        wickets_lost = wickets_b
        runs_scored = runs_b
        active_crr = crr_b
        
    balls_remaining = max(0, 120 - int(overs_completed * 6))
    wickets_in_hand = 10 - wickets_lost
    
    # Chasing/Target logic
    runs_needed = 0
    rrr = 0.0
    if is_first_innings == 0:
        runs_needed = max(0, target - runs_scored)
        rrr = (runs_needed / (balls_remaining / 6.0)) if balls_remaining > 0 else (0.0 if runs_needed <= 0 else 99.0)
        
    # Build dictionary
    feat_dict = {
        'team_a_strength': team_a_strength,
        'team_b_strength': team_b_strength,
        'toss_winner_is_a': toss_winner_is_a,
        'toss_decision_bat': toss_decision_bat,
        'is_first_innings': is_first_innings,
        'batting_team_is_a': batting_team_is_a,
        'runs_a': runs_a,
        'wickets_a': wickets_a,
        'overs_a': overs_a,
        'runs_b': runs_b,
        'wickets_b': wickets_b,
        'overs_b': overs_b,
        'target': target,
        'crr_a': crr_a,
        'crr_b': crr_b,
        'balls_remaining': balls_remaining,
        'wickets_in_hand': wickets_in_hand,
        'runs_needed': runs_needed,
        'required_rr': rrr
    }
    
    return pd.DataFrame([feat_dict]), feat_dict

def main():
    try:
        # Read from stdin
        input_data = sys.stdin.read().strip()
        if not input_data:
            print(json.dumps({"error": "No input received via stdin"}))
            return
            
        data = json.loads(input_data)
        
        # Load Model
        current_dir = os.path.dirname(__file__)
        model_path = os.path.join(current_dir, 'cricket_win_predictor.joblib')
        
        if not os.path.exists(model_path):
            print(json.dumps({"error": f"Model file not found at {model_path}. Run train_model.py first."}))
            return
            
        pipeline = joblib.load(model_path)
        
        # Process input
        X, raw_feats = derive_single_features(data)
        
        # Run prediction
        # predict_proba returns [prob_class_0, prob_class_1] where class 1 is Team A wins
        probs = pipeline.predict_proba(X)[0]
        prob_a = round(probs[1] * 100, 1)
        prob_b = round(probs[0] * 100, 1)
        
        # Adjust boundary states
        # If match is completed, give absolute 0 or 100
        # If target has been chased or all out
        status = data.get('status', 'Live')
        if status == 'Completed':
            if raw_feats['is_first_innings'] == 0:
                if raw_feats['batting_team_is_a'] == 1:
                    if raw_feats['runs_a'] >= raw_feats['target']:
                        prob_a, prob_b = 100.0, 0.0
                    else:
                        prob_a, prob_b = 0.0, 100.0
                else:
                    if raw_feats['runs_b'] >= raw_feats['target']:
                        prob_a, prob_b = 0.0, 100.0
                    else:
                        prob_a, prob_b = 100.0, 0.0
        
        # Calculate dynamic prediction factors
        # 1. Current Run Rate contribution
        is_a = raw_feats['batting_team_is_a']
        bat_crr = raw_feats['crr_a'] if is_a else raw_feats['crr_b']
        crr_contrib = int(clip(50 + (bat_crr - 7.5) * 6, 10, 95))
        
        # 2. Required Run Rate contribution
        if raw_feats['is_first_innings'] == 1:
            rrr_contrib = 50 # neutral
        else:
            rrr_contrib = int(clip(100 - (raw_feats['required_rr'] - 7.5) * 8, 5, 95))
            
        # 3. Wickets in Hand contribution
        wih = raw_feats['wickets_in_hand']
        wih_contrib = int(clip(wih * 10, 0, 100))
        
        # 4. Powerplay Performance
        # If early overs, evaluate run rate vs wickets. Otherwise use a proxy.
        active_overs = raw_feats['overs_a'] if is_a else raw_feats['overs_b']
        active_wickets = raw_feats['wickets_a'] if is_a else raw_feats['wickets_b']
        pp_contrib = int(clip(60 + (bat_crr - 7.5) * 4 - active_wickets * 3, 30, 90))
        
        # 5. Death Overs History
        # If near end, show active death overs status. Else base on overall team strength.
        if active_overs < 15:
            death_contrib = int(clip((raw_feats['team_a_strength'] if is_a else raw_feats['team_b_strength']) * 100, 40, 85))
        else:
            death_contrib = int(clip(55 + (bat_crr - 8.0) * 5 - active_wickets * 4, 15, 95))
            
        # 6. Head-to-Head
        h2h_contrib = int(clip((raw_feats['team_a_strength'] / (raw_feats['team_a_strength'] + raw_feats['team_b_strength'])) * 100, 20, 80))
        
        # 7. Pitch Conditions
        # Toss decision and team preferences
        pitch_bias = 52 if raw_feats['toss_decision_bat'] == 1 else 48
        pitch_contrib = int(clip(pitch_bias + (raw_feats['team_a_strength'] - 0.5) * 20, 30, 75))
        
        # 8. Weather Impact
        weather_contrib = int(clip(50 + (raw_feats['team_b_strength'] - raw_feats['team_a_strength']) * 5, 45, 55))
        
        factors = [
            {"name": "Current Run Rate", "weight": crr_contrib},
            {"name": "Required Run Rate", "weight": rrr_contrib},
            {"name": "Wickets in Hand", "weight": wih_contrib},
            {"name": "Powerplay Performance", "weight": pp_contrib},
            {"name": "Death Overs History", "weight": death_contrib},
            {"name": "Head-to-Head Record", "weight": h2h_contrib},
            {"name": "Pitch Conditions", "weight": pitch_contrib},
            {"name": "Weather Impact", "weight": weather_contrib}
        ]
        
        # Format response JSON
        response = {
            "winProbabilityA": prob_a,
            "winProbabilityB": prob_b,
            "factors": factors
        }
        
        print(json.dumps(response))
        
    except Exception as e:
        print(json.dumps({"error": str(e)}))

def clip(val, minimum, maximum):
    return max(minimum, min(val, maximum))

if __name__ == '__main__':
    main()
