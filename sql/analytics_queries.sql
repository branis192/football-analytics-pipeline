

-- 1. Top 3 offensive teams / goal difference
SELECT 
    team_name,
    played_games,
    points,
    goal_difference
FROM football_analytics.v_standings_latest
ORDER BY goal_difference DESC, points DESC
LIMIT 3;

-- 2. High-scoring matches (4+ goals)
SELECT 
    match_date,
    home_team,
    home_score,
    away_team,
    away_score,
    (home_score + away_score) AS total_goals
FROM football_analytics.v_matches_clean
WHERE (home_score + away_score) >= 4
  AND UPPER(status) = 'FINISHED'
ORDER BY total_goals DESC;

-- 3. Home wins per club
SELECT 
    home_team,
    COUNT(*) AS home_wins
FROM football_analytics.v_matches_clean
WHERE status = 'FINISHED'
  AND winner = 'HOME_TEAM'
GROUP BY home_team
ORDER BY home_wins DESC;

-- 4. Teams unbeaten at home
SELECT 
    home_team,
    COUNT(*) AS total_home_matches,
    COUNT(CASE WHEN winner = 'HOME_TEAM' THEN 1 END) AS home_wins,
    COUNT(CASE WHEN winner = 'DRAW' THEN 1 END) AS home_draws,
    COUNT(CASE WHEN winner = 'AWAY_TEAM' THEN 1 END) AS home_losses
FROM football_analytics.v_matches_clean
WHERE status = 'FINISHED'
GROUP BY home_team
HAVING COUNT(CASE WHEN winner = 'AWAY_TEAM' THEN 1 END) = 0
ORDER BY home_wins DESC;
