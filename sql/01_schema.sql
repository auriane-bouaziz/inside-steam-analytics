-- Inside Steam: PostgreSQL Database Schema
-- Core relational model for games, genres, publishers and developers

CREATE TABLE games (
    appid INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    release_date DATE NOT NULL,
    release_year SMALLINT NOT NULL,

    required_age SMALLINT,

    price NUMERIC(8,2) NOT NULL,
    discount SMALLINT NOT NULL,
    is_free BOOLEAN NOT NULL,
    price_band TEXT NOT NULL,

    windows BOOLEAN NOT NULL,
    mac BOOLEAN NOT NULL,
    linux BOOLEAN NOT NULL,

    metacritic_score SMALLINT,
    recommendations INTEGER NOT NULL,
    positive INTEGER NOT NULL,
    negative INTEGER NOT NULL,

    estimated_owners TEXT NOT NULL,
    owners_lower INTEGER,
    owners_upper INTEGER,
    estimated_owners_midpoint INTEGER,

    average_playtime_forever INTEGER NOT NULL,
    median_playtime_forever INTEGER NOT NULL,
    average_playtime_2weeks INTEGER NOT NULL,
    median_playtime_2weeks INTEGER NOT NULL,
    peak_ccu INTEGER NOT NULL,

    pct_pos_total NUMERIC(5,2),
    num_reviews_total INTEGER,
    pct_pos_recent NUMERIC(5,2),
    num_reviews_recent INTEGER,
    recent_reception_gap NUMERIC(6,2),

    has_lifetime_playtime BOOLEAN NOT NULL,
    has_recent_playtime BOOLEAN NOT NULL,
    has_peak_ccu BOOLEAN NOT NULL,
    extreme_playtime BOOLEAN NOT NULL,

    header_image TEXT,

    CHECK (required_age >= 0),
    CHECK (price >= 0),
    CHECK (discount BETWEEN 0 AND 100),
    CHECK (metacritic_score BETWEEN 0 AND 100),
    CHECK (recommendations >= 0),
    CHECK (positive >= 0),
    CHECK (negative >= 0),
    CHECK (owners_lower >= 0),
    CHECK (owners_upper >= 0),
    CHECK (estimated_owners_midpoint >= 0),
    CHECK (average_playtime_forever >= 0),
    CHECK (median_playtime_forever >= 0),
    CHECK (average_playtime_2weeks >= 0),
    CHECK (median_playtime_2weeks >= 0),
    CHECK (peak_ccu >= 0),
    CHECK (pct_pos_total BETWEEN 0 AND 100),
    CHECK (num_reviews_total >= 0),
    CHECK (pct_pos_recent BETWEEN 0 AND 100),
    CHECK (num_reviews_recent >= 0),

    CHECK (
        owners_lower IS NULL
        OR owners_upper IS NULL
        OR owners_lower <= owners_upper
)

);


CREATE TABLE genres (
    genre_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    genre_name TEXT NOT NULL UNIQUE
);

CREATE TABLE game_genres (
    appid INTEGER NOT NULL,
    genre_id INTEGER NOT NULL,

    PRIMARY KEY (appid, genre_id),

    FOREIGN KEY (appid)
        REFERENCES games(appid)
        ON DELETE CASCADE,

    FOREIGN KEY (genre_id)
        REFERENCES genres(genre_id)
        ON DELETE CASCADE
);

CREATE TABLE publishers (
    publisher_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    publisher_name TEXT NOT NULL UNIQUE
);

CREATE TABLE game_publishers (
    appid INTEGER NOT NULL,
    publisher_id INTEGER NOT NULL,

    PRIMARY KEY (appid, publisher_id),

    FOREIGN KEY (appid)
        REFERENCES games(appid)
        ON DELETE CASCADE,

    FOREIGN KEY (publisher_id)
        REFERENCES publishers(publisher_id)
        ON DELETE CASCADE
);

CREATE TABLE developers (
    developer_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    developer_name TEXT NOT NULL UNIQUE
);

CREATE TABLE game_developers (
    appid INTEGER NOT NULL,
    developer_id INTEGER NOT NULL,

    PRIMARY KEY (appid, developer_id),

    FOREIGN KEY (appid)
        REFERENCES games(appid)
        ON DELETE CASCADE,

    FOREIGN KEY (developer_id)
        REFERENCES developers(developer_id)
        ON DELETE CASCADE
);