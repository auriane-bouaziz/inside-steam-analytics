-- Inside Steam: Reusable Analytical Views
-- Views prepared for downstream analysis in Python and Tableau.

-- 1. Game-level performance view

CREATE OR REPLACE VIEW vw_game_performance AS

SELECT
    appid,
    name,
    release_date,
    release_year,

    price,
    is_free,
    price_band,

    estimated_owners,
    owners_lower,
    owners_upper,
    estimated_owners_midpoint,

    pct_pos_total,
    num_reviews_total,
    pct_pos_recent,
    num_reviews_recent,
    recent_reception_gap,

    peak_ccu,

    ROUND(
        median_playtime_forever / 60.0,
        2
    ) AS median_playtime_hours,

    has_lifetime_playtime,
    has_peak_ccu,
    extreme_playtime,

    metacritic_score,

    windows,
    mac,
    linux,

    header_image

FROM games;

-- 2. Genre-level performance view

CREATE OR REPLACE VIEW vw_genre_performance AS

SELECT
    ge.genre_name,

    COUNT(DISTINCT g.appid) AS games_count,

    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY g.price)
        FILTER (WHERE g.price > 0)::numeric,
        2
    ) AS median_paid_price,

    ROUND(
        COUNT(DISTINCT g.appid) FILTER (
            WHERE g.owners_lower >= 100000
        ) * 100.0
        / NULLIF(
            COUNT(DISTINCT g.appid) FILTER (
                WHERE g.owners_lower IS NOT NULL
            ),
            0
        ),
        2
    ) AS share_100k_plus_pct,

    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY g.pct_pos_total)
        FILTER (
            WHERE g.pct_pos_total IS NOT NULL
            AND g.num_reviews_total >= 50
        )::numeric,
        2
    ) AS median_positive_pct,

    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (
            ORDER BY g.median_playtime_forever / 60.0
        )
        FILTER (
            WHERE g.has_lifetime_playtime = TRUE
            AND g.extreme_playtime = FALSE
        )::numeric,
        2
    ) AS median_playtime_hours

FROM games AS g

JOIN game_genres AS gg
    ON g.appid = gg.appid

JOIN genres AS ge
    ON gg.genre_id = ge.genre_id

GROUP BY ge.genre_name;

-- 3. Publisher-level performance view

CREATE OR REPLACE VIEW vw_publisher_performance AS

SELECT
    p.publisher_id,
    p.publisher_name,

    COUNT(DISTINCT g.appid) AS games_count,

    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY g.price)
        FILTER (WHERE g.price > 0)::numeric,
        2
    ) AS median_paid_price,

    COUNT(DISTINCT g.appid) FILTER (
        WHERE g.owners_lower IS NOT NULL
    ) AS games_with_owner_estimate,

    ROUND(
        COUNT(DISTINCT g.appid) FILTER (
            WHERE g.owners_lower >= 100000
        ) * 100.0
        / NULLIF(
            COUNT(DISTINCT g.appid) FILTER (
                WHERE g.owners_lower IS NOT NULL
            ),
            0
        ),
        2
    ) AS share_100k_plus_pct,

    COUNT(DISTINCT g.appid) FILTER (
        WHERE g.pct_pos_total IS NOT NULL
        AND g.num_reviews_total >= 50
    ) AS games_with_reviews,

    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY g.pct_pos_total)
        FILTER (
            WHERE g.pct_pos_total IS NOT NULL
            AND g.num_reviews_total >= 50
        )::numeric,
        2
    ) AS median_positive_pct

FROM publishers AS p

JOIN game_publishers AS gp
    ON p.publisher_id = gp.publisher_id

JOIN games AS g
    ON gp.appid = g.appid

GROUP BY
    p.publisher_id,
    p.publisher_name;

    -- Views summary:
-- Three reusable analytical views were created for downstream analysis:
-- vw_game_performance provides game-level KPIs,
-- vw_genre_performance summarizes performance by genre,
-- and vw_publisher_performance summarizes publisher-level performance.
-- These views are designed for reuse in Python and Tableau.