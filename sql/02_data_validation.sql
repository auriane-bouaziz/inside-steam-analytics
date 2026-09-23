-- Inside Steam: Database Validation
-- Validation checks performed after loading the normalized Steam dataset
-- into PostgreSQL.

SELECT 'games' AS table_name, COUNT(*) AS row_count
FROM games

UNION ALL

SELECT 'genres', COUNT(*)
FROM genres

UNION ALL

SELECT 'game_genres', COUNT(*)
FROM game_genres

UNION ALL

SELECT 'publishers', COUNT(*)
FROM publishers

UNION ALL

SELECT 'game_publishers', COUNT(*)
FROM game_publishers

UNION ALL

SELECT 'developers', COUNT(*)
FROM developers

UNION ALL

SELECT 'game_developers', COUNT(*)
FROM game_developers;

-- Expected row counts after final SQL-ready cleaning:
-- games: 94,948
-- genres: 33
-- publishers: 49,851
-- developers: 60,113
-- game_genres: 258,257
-- game_publishers: 92,535
-- game_developers: 98,004

-- 2. Primary key uniqueness validation

SELECT
    COUNT(*) AS total_games,
    COUNT(DISTINCT appid) AS unique_appids,
    COUNT(*) - COUNT(DISTINCT appid) AS duplicate_appids
FROM games;

-- 2b. Dimension uniqueness validation

SELECT
    'genres' AS dimension,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT genre_name) AS unique_names
FROM genres

UNION ALL

SELECT
    'publishers',
    COUNT(*),
    COUNT(DISTINCT publisher_name)
FROM publishers

UNION ALL

SELECT
    'developers',
    COUNT(*),
    COUNT(DISTINCT developer_name)
FROM developers;

-- 3. Foreign key / orphan row validation

SELECT
    'game_genres -> games' AS relationship,
    COUNT(*) AS orphan_rows
FROM game_genres gg
LEFT JOIN games g
    ON gg.appid = g.appid
WHERE g.appid IS NULL

UNION ALL

SELECT
    'game_genres -> genres',
    COUNT(*)
FROM game_genres gg
LEFT JOIN genres ge
    ON gg.genre_id = ge.genre_id
WHERE ge.genre_id IS NULL

UNION ALL

SELECT
    'game_publishers -> games',
    COUNT(*)
FROM game_publishers gp
LEFT JOIN games g
    ON gp.appid = g.appid
WHERE g.appid IS NULL

UNION ALL

SELECT
    'game_publishers -> publishers',
    COUNT(*)
FROM game_publishers gp
LEFT JOIN publishers p
    ON gp.publisher_id = p.publisher_id
WHERE p.publisher_id IS NULL

UNION ALL

SELECT
    'game_developers -> games',
    COUNT(*)
FROM game_developers gd
LEFT JOIN games g
    ON gd.appid = g.appid
WHERE g.appid IS NULL

UNION ALL

SELECT
    'game_developers -> developers',
    COUNT(*)
FROM game_developers gd
LEFT JOIN developers d
    ON gd.developer_id = d.developer_id
WHERE d.developer_id IS NULL;

-- 4. Numeric sanity checks

SELECT
    COUNT(*) FILTER (
        WHERE price < 0
    ) AS invalid_prices,

    COUNT(*) FILTER (
        WHERE discount < 0 OR discount > 100
    ) AS invalid_discounts,

    COUNT(*) FILTER (
        WHERE pct_pos_total < 0 OR pct_pos_total > 100
    ) AS invalid_review_scores,

    COUNT(*) FILTER (
        WHERE metacritic_score < 0 OR metacritic_score > 100
    ) AS invalid_metacritic_scores,

    COUNT(*) FILTER (
        WHERE owners_lower > owners_upper
    ) AS invalid_owner_ranges
FROM games;

-- Validation summary:
-- All expected tables were loaded successfully.
-- Primary keys and dimension values are unique.
-- No orphan rows were found in bridge tables.
-- No invalid numeric values were detected in the main analytical fields.
-- The database is ready for analytical SQL queries.
