-- Inside Steam: Analytical SQL Queries
-- SQL analysis of market structure, pricing, reach, engagement
-- and player reception across the Steam catalogue.

-- 1. Steam catalogue evolution by release year

SELECT
    release_year,
    COUNT(*) AS games_released
FROM games
GROUP BY release_year
ORDER BY release_year;

-- Finding:
-- Steam game releases show a strong long-term upward trend, but the growth
-- is not consistent from year to year.
-- The catalogue expanded particularly rapidly from the mid-2010s onward,
-- rising from 1,529 releases in 2014 to 20,427 in 2024.
-- The trend includes periods of slower growth and a decline in 2019,
-- showing that catalogue expansion has not followed a steady pattern.
-- 2025 is a partial year (data through March 10) and should not be compared
-- directly with complete years.

-- 2. Year-over-year catalogue growth

-- Note:
-- For early years with gaps in the dataset, LAG() compares with the previous
-- available year rather than necessarily the previous calendar year.
-- From 2008 onward, years are continuous.

WITH yearly_releases AS (
    SELECT
        release_year,
        COUNT(*) AS games_released
    FROM games
    GROUP BY release_year
)

SELECT
    release_year,
    games_released,
    LAG(games_released) OVER (
        ORDER BY release_year
    ) AS previous_year_games,

    ROUND(
        (
            (games_released - LAG(games_released) OVER (ORDER BY release_year))
            * 100.0
            / LAG(games_released) OVER (ORDER BY release_year)
        ),
        2
    ) AS yoy_growth_pct

FROM yearly_releases
ORDER BY release_year;

-- Finding:
-- Year-over-year catalogue growth is highly variable rather than steady.
-- Among recent complete years, releases declined by 17.78% in 2019,
-- rebounded by 40.12% in 2020, grew by only 1.12% in 2021,
-- and then accelerated again to +41.20% in 2023 and +45.74% in 2024.
-- This confirms that Steam catalogue expansion has occurred in distinct
-- phases of acceleration, slowdown and contraction.
-- 2025 is excluded from full-year interpretation because the dataset only
-- covers releases through March 10.

-- 3. Most represented genres in the Steam catalogue

WITH total_games AS (
    SELECT COUNT(*) AS total_games
    FROM games
)

SELECT
    ge.genre_name,
    COUNT(DISTINCT gg.appid) AS games_count,
    ROUND(
        COUNT(DISTINCT gg.appid) * 100.0 / tg.total_games,
        2
    ) AS share_of_catalogue_pct

FROM game_genres AS gg

JOIN genres AS ge
    ON gg.genre_id = ge.genre_id

CROSS JOIN total_games AS tg

GROUP BY
    ge.genre_name,
    tg.total_games

ORDER BY
    games_count DESC

LIMIT 15;

-- Finding:
-- Indie is by far the most represented genre in the Steam catalogue,
-- appearing in 66.59% of games.
-- Casual, Action and Adventure are also highly prevalent,
-- each appearing in roughly 37% to 41% of the catalogue.
-- Simulation, Strategy and RPG form a second tier, representing
-- approximately 17% to 20% of games.
-- Genre shares are not mutually exclusive because games can belong
-- to multiple genres.

-- 4. Paid-game pricing by genre

SELECT
    ge.genre_name,
    COUNT(DISTINCT g.appid) AS paid_games,
    ROUND(AVG(g.price), 2) AS average_price,
    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY g.price)::numeric,
        2
    ) AS median_price

FROM games AS g

JOIN game_genres AS gg
    ON g.appid = gg.appid

JOIN genres AS ge
    ON gg.genre_id = ge.genre_id

WHERE g.price > 0

GROUP BY ge.genre_name

HAVING COUNT(DISTINCT g.appid) >= 500

ORDER BY median_price DESC;

-- Finding:
-- Paid-game pricing varies moderately across major Steam genres.
-- Simulation, Sports, RPG and Massively Multiplayer games have median
-- prices around $6.99, while Adventure and Strategy are around $5.99.
-- Casual, Indie, Action and Racing have lower median prices around $4.99.
-- Early Access shows a higher median price of $8.00, but it should be
-- interpreted separately because it represents a development/release
-- status rather than a traditional game genre.
-- Average prices are consistently higher than median prices, indicating
-- right-skewed price distributions within genres.

-- 5. Estimated market reach by genre

SELECT
    ge.genre_name,

    COUNT(DISTINCT g.appid) AS games_with_owner_estimate,

    COUNT(DISTINCT g.appid) FILTER (
        WHERE g.owners_lower >= 100000
    ) AS games_100k_plus,

    ROUND(
        COUNT(DISTINCT g.appid) FILTER (
            WHERE g.owners_lower >= 100000
        ) * 100.0
        / COUNT(DISTINCT g.appid),
        2
    ) AS share_100k_plus_pct,

    COUNT(DISTINCT g.appid) FILTER (
        WHERE g.owners_lower >= 1000000
    ) AS games_1m_plus,

    ROUND(
        COUNT(DISTINCT g.appid) FILTER (
            WHERE g.owners_lower >= 1000000
        ) * 100.0
        / COUNT(DISTINCT g.appid),
        2
    ) AS share_1m_plus_pct

FROM games AS g

JOIN game_genres AS gg
    ON g.appid = gg.appid

JOIN genres AS ge
    ON gg.genre_id = ge.genre_id

WHERE g.owners_lower IS NOT NULL

GROUP BY ge.genre_name

HAVING COUNT(DISTINCT g.appid) >= 1000

ORDER BY share_100k_plus_pct DESC;

-- Finding:
-- Free To Play and Massively Multiplayer games show the strongest estimated
-- market reach, with around 28% of games reaching at least 100k owners.
-- Massively Multiplayer also has the highest share of 1M+ games at 7.68%,
-- followed by Free To Play at 5.45%.
-- RPG, Strategy and Action form a second tier for reach, while Indie and
-- Casual games are much less likely to cross the 100k and 1M thresholds.
-- This highlights an important distinction between catalogue presence
-- and audience reach: highly represented genres are not necessarily the
-- most likely to achieve large audiences.
-- Reach is based on estimated owner ranges and uses the lower bound of
-- each range as a conservative measure.

-- 6. Player reception by genre

SELECT
    ge.genre_name,

    COUNT(DISTINCT g.appid) AS games_with_reviews,

    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY g.pct_pos_total)::numeric,
        2
    ) AS median_positive_pct,

    ROUND(
        COUNT(DISTINCT g.appid) FILTER (
            WHERE g.pct_pos_total >= 80
        ) * 100.0
        / COUNT(DISTINCT g.appid),
        2
    ) AS share_80_plus_pct

FROM games AS g

JOIN game_genres AS gg
    ON g.appid = gg.appid

JOIN genres AS ge
    ON gg.genre_id = ge.genre_id

WHERE
    g.pct_pos_total IS NOT NULL
    AND g.num_reviews_total >= 50

GROUP BY ge.genre_name

HAVING COUNT(DISTINCT g.appid) >= 500

ORDER BY median_positive_pct DESC;

-- Finding:
-- Casual, Indie and Adventure show the strongest player reception,
-- with median positive review scores around 83% to 84%.
-- Around 58% to 61% of games in these genres achieve at least 80%
-- positive reviews.
-- Most other major genres cluster around median scores of 79% to 81%.
-- Massively Multiplayer stands out with a much lower median reception
-- of 68% and only 21.40% of games reaching 80% positive reviews.
-- Combined with the previous reach analysis, this suggests that strong
-- audience reach does not necessarily translate into strong player satisfaction.
-- Results are based only on games with at least 50 total reviews.

-- 7. Publisher catalogue size and market reach

WITH publisher_size AS (
    SELECT
        p.publisher_id,
        p.publisher_name,
        COUNT(DISTINCT gp.appid) AS games_published
    FROM publishers AS p

    JOIN game_publishers AS gp
        ON p.publisher_id = gp.publisher_id

    GROUP BY
        p.publisher_id,
        p.publisher_name
),

publisher_tiers AS (
    SELECT
        publisher_id,
        publisher_name,
        games_published,

        CASE
            WHEN games_published = 1 THEN '1 game'
            WHEN games_published BETWEEN 2 AND 5 THEN '2-5 games'
            WHEN games_published BETWEEN 6 AND 20 THEN '6-20 games'
            WHEN games_published BETWEEN 21 AND 100 THEN '21-100 games'
            ELSE '100+ games'
        END AS publisher_size_tier

    FROM publisher_size
)

SELECT
    pt.publisher_size_tier,

    COUNT(DISTINCT pt.publisher_id) AS publishers,

    COUNT(*) AS game_publisher_records,

    ROUND(
        COUNT(*) FILTER (
            WHERE g.owners_lower >= 100000
        ) * 100.0
        / COUNT(*),
        2
    ) AS share_100k_plus_pct

FROM publisher_tiers AS pt

JOIN game_publishers AS gp
    ON pt.publisher_id = gp.publisher_id

JOIN games AS g
    ON gp.appid = g.appid

WHERE g.owners_lower IS NOT NULL

GROUP BY pt.publisher_size_tier

ORDER BY
    CASE pt.publisher_size_tier
        WHEN '1 game' THEN 1
        WHEN '2-5 games' THEN 2
        WHEN '6-20 games' THEN 3
        WHEN '21-100 games' THEN 4
        WHEN '100+ games' THEN 5
    END;

    -- Finding:
-- Estimated market reach increases strongly with publisher catalogue size.
-- Only 5.03% of games associated with one-game publishers reach at least
-- 100k estimated owners, compared with 14.40% for publishers with 6-20
-- games and around 17.6% for publishers with more than 20 games.
-- The relationship appears to plateau among the largest publisher tiers,
-- with almost no difference between the 21-100 and 100+ game groups.
-- This indicates an association between publisher scale and market reach,
-- but does not establish that publisher size itself causes higher reach.
-- Results include only games with usable estimated-owner information.


-- 8. Player engagement by genre

SELECT
    ge.genre_name,

    COUNT(DISTINCT g.appid) AS games_with_playtime,

    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (
            ORDER BY g.median_playtime_forever / 60.0
        )::numeric,
        2
    ) AS median_playtime_hours,

    ROUND(
        AVG(g.median_playtime_forever / 60.0),
        2
    ) AS average_median_playtime_hours

FROM games AS g

JOIN game_genres AS gg
    ON g.appid = gg.appid

JOIN genres AS ge
    ON gg.genre_id = ge.genre_id

WHERE
    g.has_lifetime_playtime = TRUE
    AND g.extreme_playtime = FALSE

GROUP BY ge.genre_name

HAVING COUNT(DISTINCT g.appid) >= 200

ORDER BY median_playtime_hours DESC;

-- Finding:
-- Among games with usable lifetime playtime data, RPG, Strategy and
-- Simulation show the highest median engagement, with median playtime
-- of approximately 4 to 4.7 hours.
-- Free To Play and Massively Multiplayer show substantially lower median
-- playtime in this available sample, despite their strong market reach
-- observed in previous analyses.
-- Average playtime values remain considerably higher than medians across
-- all genres, confirming that engagement distributions are strongly
-- right-skewed even after extreme-playtime observations are excluded.
-- These results should be interpreted cautiously because lifetime playtime
-- data is available for only a limited subset of the Steam catalogue.

-- 9. Top games by peak concurrent users within major genres

WITH ranked_games AS (
    SELECT
        ge.genre_name,
        g.appid,
        g.name,
        g.peak_ccu,

        RANK() OVER (
            PARTITION BY ge.genre_name
            ORDER BY g.peak_ccu DESC
        ) AS genre_rank

    FROM games AS g

    JOIN game_genres AS gg
        ON g.appid = gg.appid

    JOIN genres AS ge
        ON gg.genre_id = ge.genre_id

    WHERE
        g.has_peak_ccu = TRUE
        AND ge.genre_name IN (
            'Action',
            'Adventure',
            'Indie',
            'RPG',
            'Strategy'
        )
)

SELECT
    genre_name,
    genre_rank,
    name,
    peak_ccu
FROM ranked_games

WHERE genre_rank <= 3

ORDER BY
    genre_name,
    genre_rank;

    -- Finding:
-- Peak concurrent users are highly concentrated among a small number
-- of leading titles within each genre.
-- Counter-Strike 2 leads the Action category, while Dota 2 strongly
-- dominates Strategy.
-- Some titles, such as Monster Hunter Wilds and Rust, rank highly across
-- multiple genres because Steam games can belong to several genre categories.
-- This illustrates both the concentration of peak player activity among
-- top titles and the multi-label nature of the Steam catalogue.
-- Rankings include only games with available peak CCU data.

-- 10. Publisher catalogue size and player reception

WITH publisher_size AS (
    SELECT
        p.publisher_id,
        p.publisher_name,
        COUNT(DISTINCT gp.appid) AS games_published
    FROM publishers AS p

    JOIN game_publishers AS gp
        ON p.publisher_id = gp.publisher_id

    GROUP BY
        p.publisher_id,
        p.publisher_name
),

publisher_tiers AS (
    SELECT
        publisher_id,
        publisher_name,
        games_published,

        CASE
            WHEN games_published = 1 THEN '1 game'
            WHEN games_published BETWEEN 2 AND 5 THEN '2-5 games'
            WHEN games_published BETWEEN 6 AND 20 THEN '6-20 games'
            WHEN games_published BETWEEN 21 AND 100 THEN '21-100 games'
            ELSE '100+ games'
        END AS publisher_size_tier

    FROM publisher_size
)

SELECT
    pt.publisher_size_tier,

    COUNT(*) AS game_publisher_records,

    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY g.pct_pos_total)::numeric,
        2
    ) AS median_positive_pct,

    ROUND(
        COUNT(*) FILTER (
            WHERE g.pct_pos_total >= 80
        ) * 100.0
        / COUNT(*),
        2
    ) AS share_80_plus_pct

FROM publisher_tiers AS pt

JOIN game_publishers AS gp
    ON pt.publisher_id = gp.publisher_id

JOIN games AS g
    ON gp.appid = g.appid

WHERE
    g.pct_pos_total IS NOT NULL
    AND g.num_reviews_total >= 50

GROUP BY pt.publisher_size_tier

ORDER BY
    CASE pt.publisher_size_tier
        WHEN '1 game' THEN 1
        WHEN '2-5 games' THEN 2
        WHEN '6-20 games' THEN 3
        WHEN '21-100 games' THEN 4
        WHEN '100+ games' THEN 5
    END;

    -- Finding:
-- Publisher catalogue size does not show the same positive relationship
-- with player reception as it does with market reach.
-- Median positive review scores remain around 83% for publishers with
-- up to 20 games, then decline slightly to 82% for the 21-100 tier
-- and 80% for publishers with 100+ games.
-- The share of games reaching at least 80% positive reviews also declines
-- among the largest publisher tiers, reaching 52.22% for publishers
-- with 100+ games.
-- This suggests that publisher scale is associated with broader market
-- reach, but not necessarily with stronger player satisfaction.
-- Results include only games with at least 50 total reviews.

-- ============================================================
-- KEY SQL FINDINGS
-- ============================================================

-- 1. Steam's catalogue has grown strongly over time, but the growth
--    has been irregular, with periods of acceleration, slowdown
--    and contraction rather than a steady year-over-year increase.

-- 2. Indie dominates the catalogue in terms of volume, representing
--    66.59% of games, but high catalogue presence does not necessarily
--    translate into high audience reach.

-- 3. Pricing differences across major genres are relatively moderate.
--    Median paid-game prices generally fall between approximately
--    $4.99 and $6.99, while average prices are consistently higher,
--    reflecting right-skewed price distributions.

-- 4. Free To Play and Massively Multiplayer games show the strongest
--    estimated market reach, while Indie and Casual games are much less
--    likely to cross the 100k and 1M owner thresholds.

-- 5. Player reception follows a different pattern from market reach.
--    Casual, Indie and Adventure show strong median review scores,
--    while Massively Multiplayer combines high reach with substantially
--    lower player reception.

-- 6. Engagement also varies independently from reach and satisfaction.
--    RPG, Strategy and Simulation show the highest median lifetime
--    playtime among games with usable engagement data.

-- 7. Larger publisher portfolios are associated with higher market reach,
--    but this relationship appears to plateau among the largest publishers.
--    Publisher scale does not show the same positive relationship with
--    player satisfaction.

-- Overall conclusion:
-- Steam game performance is multidimensional. Market reach, player
-- engagement and player satisfaction capture different aspects of
-- performance and should not be treated as interchangeable measures.