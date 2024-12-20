-- Prepare the query using multi-layer queries with `WITH` statement and only then `INSERT INTO`
INSERT INTO players
WITH yesterday AS (
    SELECT * FROM players
    WHERE current_season = 1996
),
     today AS (
         SELECT * FROM player_seasons
         WHERE season = 1997
     )

SELECT
    COALESCE(t.player_name, y.player_name) AS player_name,
    COALESCE(t.height, y.height) AS height,
    COALESCE(t.college, y.college) AS college,
    COALESCE(t.country, y.country) AS country,
    COALESCE(t.draft_year, y.draft_year) AS draft_year,
    COALESCE(t.draft_round, y.draft_round) AS draft_round,
    COALESCE(t.draft_number, y.draft_number) AS draft_number,
    CASE
        WHEN y.season_stats IS NULL
            THEN ARRAY[ROW(
            t.season,
            t.gp,
            t.pts,
            t.reb,
            t.ast
            )::season_stats]
        WHEN t.season IS NOT NULL
            THEN y.season_stats || ARRAY[ROW(
            t.season,
            t.gp,
            t.pts,
            t.reb,
            t.ast
            )::season_stats]
        ELSE y.season_stats
        END as season_stats,
    CASE
        WHEN t.season IS NOT NULL
            THEN
            CASE
                WHEN t.pts > 20 THEN 'star'
                WHEN t.pts > 15 THEN 'good'
                WHEN t.pts > 10 THEN 'average'
                ELSE 'bad'
                END::scoring_class
        ELSE y.scoring_class
        END as scoring_class,
    CASE WHEN t.season IS NOT NULL THEN 0
         ELSE y.years_since_last_season + 1
        END as years_since_last_season,

    COALESCE(t.season, y.current_season + 1) as current_season,
    (y.season_stats[CARDINALITY(y.season_stats)]::season_stats).season = current_season AS is_active

FROM today t
    FULL OUTER JOIN yesterday y
        ON t.player_name = y.player_name;

-- Example on how to quickly extract the struct to multi-column fields
WITH unnested AS (
    SELECT player_name,
           scoring_class,
           years_since_last_season,
           UNNEST(season_stats)::season_stats AS season_stats
    FROM players
    WHERE current_season = 2000
      AND player_name = 'Michael Jordan'
)

SELECT player_name,
       scoring_class,
       years_since_last_season,
       (season_stats::season_stats).*
FROM unnested;

-- Example on how to use this `players` table for analytical purpose
SELECT
    player_name,
    (season_stats[CARDINALITY(season_stats)]::season_stats).pts /
    CASE WHEN (season_stats[1]::season_stats).pts = 0 THEN 1 ELSE (season_stats[1]::season_stats).pts END as improvement_score
FROM players
WHERE current_season = 2001
  AND scoring_class = 'star'
ORDER BY improvement_score DESC;

select * from players;