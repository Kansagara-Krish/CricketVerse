import csv
import random
import os

def simulate_innings(bat_strength, bowl_strength, target=None):
    """
    Simulates a single innings of 20 overs (120 balls).
    If target is provided, it's the second innings, and we stop if target is chased.
    Returns: list of states at the end of each over, and the final runs/wickets.
    Each state is: (runs, wickets, balls_bowled)
    """
    runs = 0
    wickets = 0
    states = []
    
    # Base run distribution probabilities
    # [0, 1, 2, 3, 4, 6]
    base_probs = [0.40, 0.35, 0.10, 0.01, 0.09, 0.05]
    
    # Adjust run scoring chance based on strength differential (bat - bowl)
    diff = bat_strength - bowl_strength
    adj_probs = base_probs.copy()
    if diff > 0:
        adj_probs[0] -= diff * 0.2
        adj_probs[4] += diff * 0.1
        adj_probs[5] += diff * 0.1
    else:
        adj_probs[0] += abs(diff) * 0.2
        adj_probs[4] -= abs(diff) * 0.1
        adj_probs[5] -= abs(diff) * 0.1
    
    # Normalize probabilities
    s = sum(adj_probs)
    adj_probs = [p / s for p in adj_probs]
    
    # Wicket probability baseline
    base_wicket_prob = 0.04 - (diff * 0.02)
    
    for ball in range(1, 121):
        if wickets >= 10:
            break
            
        current_wicket_prob = base_wicket_prob
        current_adj_probs = adj_probs.copy()
        
        if target is not None:
            runs_needed = target - runs
            balls_remaining = 120 - (ball - 1)
            
            if runs_needed <= 0:
                break
            if balls_remaining <= 0:
                break
                
            rrr = (runs_needed / balls_remaining) * 6
            if rrr > 9.0:
                risk_factor = min((rrr - 9.0) * 0.05, 0.2)
                current_wicket_prob += risk_factor * 0.15
                current_adj_probs[0] -= risk_factor
                current_adj_probs[4] += risk_factor * 0.6
                current_adj_probs[5] += risk_factor * 0.4
                
                # Re-normalize
                s_curr = sum(p for p in current_adj_probs if p > 0)
                current_adj_probs = [max(p, 0) / s_curr for p in current_adj_probs]

        # Determine ball outcome
        if random.random() < current_wicket_prob:
            wickets += 1
        else:
            run_options = [0, 1, 2, 3, 4, 6]
            runs += random.choices(run_options, weights=current_adj_probs)[0]
            
        if target is not None and runs >= target:
            states.append((runs, wickets, ball))
            break
            
        if ball % 6 == 0:
            states.append((runs, wickets, ball))
            
    if (len(states) == 0 or states[-1][2] != ball) and (wickets == 10 or (target is not None and runs >= target)):
        states.append((runs, wickets, ball))
        
    return states, runs, wickets

def generate_dataset(num_matches=500):
    dataset = []
    
    for match_idx in range(num_matches):
        team_a_strength = round(random.uniform(0.35, 0.65), 2)
        team_b_strength = round(random.uniform(0.35, 0.65), 2)
        
        toss_winner_is_a = random.choice([0, 1])
        toss_decision_bat = random.choice([0, 1])
        
        team_a_bats_first = 1
        if toss_winner_is_a == 1:
            if toss_decision_bat == 0:
                team_a_bats_first = 0
        else:
            if toss_decision_bat == 1:
                team_a_bats_first = 0
                
        # Simulate Match
        if team_a_bats_first == 1:
            # 1st Innings: Team A bats
            inn1_states, runs_1, wickets_1 = simulate_innings(team_a_strength, team_b_strength)
            target = runs_1 + 1
            # 2nd Innings: Team B bats
            inn2_states, runs_2, wickets_2 = simulate_innings(team_b_strength, team_a_strength, target=target)
            winner_is_a = 1 if runs_1 > runs_2 else 0
            
            # Map Innings 1 (A batting)
            for runs, wickets, balls in inn1_states:
                dataset.append({
                    'team_a_strength': team_a_strength,
                    'team_b_strength': team_b_strength,
                    'toss_winner_is_a': toss_winner_is_a,
                    'toss_decision_bat': toss_decision_bat,
                    'is_first_innings': 1,
                    'batting_team_is_a': 1,
                    'runs_a': runs,
                    'wickets_a': wickets,
                    'overs_a': round(balls / 6.0, 2),
                    'runs_b': 0,
                    'wickets_b': 0,
                    'overs_b': 0.0,
                    'target': 0,
                    'label_winner_is_a': winner_is_a
                })
            
            # Map Innings 2 (B batting)
            for runs, wickets, balls in inn2_states:
                dataset.append({
                    'team_a_strength': team_a_strength,
                    'team_b_strength': team_b_strength,
                    'toss_winner_is_a': toss_winner_is_a,
                    'toss_decision_bat': toss_decision_bat,
                    'is_first_innings': 0,
                    'batting_team_is_a': 0,
                    'runs_a': runs_1,
                    'wickets_a': wickets_1,
                    'overs_a': round(len(inn1_states) * 6 / 6.0, 2),
                    'runs_b': runs,
                    'wickets_b': wickets,
                    'overs_b': round(balls / 6.0, 2),
                    'target': target,
                    'label_winner_is_a': winner_is_a
                })
        else:
            # 1st Innings: Team B bats
            inn1_states, runs_1, wickets_1 = simulate_innings(team_b_strength, team_a_strength)
            target = runs_1 + 1
            # 2nd Innings: Team A bats
            inn2_states, runs_2, wickets_2 = simulate_innings(team_a_strength, team_b_strength, target=target)
            winner_is_a = 1 if runs_2 > runs_1 else 0
            
            # Map Innings 1 (B batting)
            for runs, wickets, balls in inn1_states:
                dataset.append({
                    'team_a_strength': team_a_strength,
                    'team_b_strength': team_b_strength,
                    'toss_winner_is_a': toss_winner_is_a,
                    'toss_decision_bat': toss_decision_bat,
                    'is_first_innings': 1,
                    'batting_team_is_a': 0,
                    'runs_a': 0,
                    'wickets_a': 0,
                    'overs_a': 0.0,
                    'runs_b': runs,
                    'wickets_b': wickets,
                    'overs_b': round(balls / 6.0, 2),
                    'target': 0,
                    'label_winner_is_a': winner_is_a
                })
            
            # Map Innings 2 (A batting)
            for runs, wickets, balls in inn2_states:
                dataset.append({
                    'team_a_strength': team_a_strength,
                    'team_b_strength': team_b_strength,
                    'toss_winner_is_a': toss_winner_is_a,
                    'toss_decision_bat': toss_decision_bat,
                    'is_first_innings': 0,
                    'batting_team_is_a': 1,
                    'runs_a': runs,
                    'wickets_a': wickets,
                    'overs_a': round(balls / 6.0, 2),
                    'runs_b': runs_1,
                    'wickets_b': wickets_1,
                    'overs_b': round(len(inn1_states) * 6 / 6.0, 2),
                    'target': target,
                    'label_winner_is_a': winner_is_a
                })
                
    return dataset

if __name__ == '__main__':
    print("Generating mock match data...")
    data = generate_dataset(600)  # 600 matches
    
    csv_file = os.path.join(os.path.dirname(__file__), 'mock_match_data.csv')
    with open(csv_file, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=data[0].keys())
        writer.writeheader()
        writer.writerows(data)
        
    print(f"Generated {len(data)} match state records in {csv_file}.")
