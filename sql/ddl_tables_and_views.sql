-- 1. Raw external table for league standings
CREATE EXTERNAL TABLE IF NOT EXISTS football_analytics.raw_standings (
    competition struct<id: int, name: string, code: string>,
    season struct<id: int, startDate: string, endDate: string>,
    standings array<struct<
        type: string,
        stage: string,
        `table`: array<struct<
            position: int,
            team: struct<id: int, name: string>,
            playedGames: int,
            won: int,
            draw: int,
            lost: int,
            points: int,
            goalsFor: int,
            goalsAgainst: int,
            goalDifference: int
        >>
    >>
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
LOCATION 's3://football-analytics-branish/raw/standings/';

-- 2. Cleaned and deduplicated view for latest standings
CREATE OR REPLACE VIEW football_analytics.v_standings_latest AS
WITH ranked_standings AS (
    SELECT 
        competition.name AS league_name,
        season.startDate AS season_start,
        season.endDate AS season_end,
        t.position,
        t.team.name AS team_name,
        t.playedGames AS played_games,
        t.won,
        t.draw,
        t.lost,
        t.points,
        t.goalDifference AS goal_difference,
        ROW_NUMBER() OVER (
            PARTITION BY t.team.name 
            ORDER BY t.playedGames DESC, "$path" DESC
        ) AS rn
    FROM football_analytics.raw_standings
    CROSS JOIN UNNEST(standings) AS s_table(s)
    CROSS JOIN UNNEST(s."table") AS team_table(t)
    WHERE s.type = 'TOTAL'
)
SELECT 
    league_name,
    season_start,
    season_end,
    position,
    team_name,
    played_games,
    won,
    draw,
    lost,
    points,
    goal_difference
FROM ranked_standings
WHERE rn = 1;

-- 3. Raw external table for fixtures and matches
CREATE EXTERNAL TABLE IF NOT EXISTS football_analytics.raw_matches (
    competition struct<id: int, name: string, code: string>,
    season struct<id: int, startDate: string, endDate: string, currentMatchday: int>,
    matches array<struct<
        id: int,
        utcDate: string,
        status: string,
        matchday: int,
        stage: string,
        homeTeam: struct<id: int, name: string>,
        awayTeam: struct<id: int, name: string>,
        score: struct<
            winner: string,
            duration: string,
            fullTime: struct<home: int, away: int>,
            halfTime: struct<home: int, away: int>
        >
    >>
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
LOCATION 's3://football-analytics-branish/raw/fixtures/';

-- 4. Cleaned and deduplicated view for matches
CREATE OR REPLACE VIEW football_analytics.v_matches_clean AS
WITH ranked_matches AS (
    SELECT 
        m.id AS match_id,
        competition.name AS league_name,
        CAST(from_iso8601_timestamp(m.utcDate) AS timestamp) AS match_date,
        m.matchday,
        m.status,
        m.homeTeam.name AS home_team,
        m.awayTeam.name AS away_team,
        m.score.fullTime.home AS home_score,
        m.score.fullTime.away AS away_score,
        m.score.winner AS winner,
        ROW_NUMBER() OVER (
            PARTITION BY m.id 
            ORDER BY "$path" DESC
        ) AS rn
    FROM football_analytics.raw_matches
    CROSS JOIN UNNEST(matches) AS m_table(m)
)
SELECT 
    match_id,
    league_name,
    match_date,
    matchday,
    status,
    home_team,
    away_team,
    home_score,
    away_score,
    winner
FROM ranked_matches
WHERE rn = 1;