-- 1. Materialize Standings into a curated Parquet table (Snappy compression)
CREATE TABLE football_analytics.standings_analytics
WITH (
    format = 'PARQUET',
    parquet_compression = 'SNAPPY',
    external_location = 's3://football-analytics-branish/curated/standings/'
) AS
SELECT * 
FROM football_analytics.v_standings_latest;

-- 2. Materialize Matches into a curated Parquet table partitioned by match status
CREATE TABLE football_analytics.matches_analytics
WITH (
    format = 'PARQUET',
    parquet_compression = 'SNAPPY',
    external_location = 's3://football-analytics-branish/curated/matches/',
    partitioned_by = ARRAY['status']
) AS
SELECT 
    match_id,
    league_name,
    match_date,
    matchday,
    home_team,
    away_team,
    home_score,
    away_score,
    winner,
    status
FROM football_analytics.v_matches_clean;
