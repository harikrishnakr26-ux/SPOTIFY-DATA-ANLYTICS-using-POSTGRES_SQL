# Spotify Data Analytics using PostgreSQL + Power BI

> **End-to-end data analytics project** — from raw CSV ingestion into PostgreSQL, through advanced SQL analysis, to a 4-page interactive Power BI dashboard. Built to demonstrate the full data analyst workflow on a real-world music streaming dataset.

---

## Table of Contents

- [Project Overview](#project-overview)
- [End-to-End Workflow](#end-to-end-workflow)
- [Dataset Description](#dataset-description)
- [Schema](#schema)
- [SQL Concepts Demonstrated](#sql-concepts-demonstrated)
- [Business Queries](#business-queries)
- [Power BI Dashboard](#power-bi-dashboard)
- [Key Insights](#key-insights)
- [Tools Used](#tools-used)
- [Future Improvements](#future-improvements)
- [Project Structure](#project-structure)

---

## Project Overview

This project simulates a real-world data analyst workflow on a music streaming dataset combining Spotify and YouTube metrics. The pipeline covers data ingestion, SQL-based analysis in PostgreSQL, and a 4-page interactive Power BI dashboard — making it a complete, portfolio-ready end-to-end project.

**What makes this resume-worthy:**
- Full pipeline: raw data → PostgreSQL → Power BI
- Every SQL query solves a named business problem, not just a technical exercise
- Advanced SQL: Window Functions, CTEs, statistical functions (`PERCENTILE_CONT`, `STDDEV`), conditional pivots
- Power BI dashboard with 4 analytical views — KPIs, audio analysis, artist drill-down, and trend insights
- Queries are structured to be readable, documented, and production-ready

---

## End-to-End Workflow

```
Raw CSV Dataset
      │
      ▼
PostgreSQL (Data Ingestion + Cleaning)
      │
      ├──► Advanced SQL Queries (Business Analysis)
      │
      ▼
Power BI (Interactive Dashboard — 4 Pages)
      │
      ├── Page 1: Spotify Streaming Summary
      ├── Page 2: Audio Analysis
      ├── Page 3: Artist Analysis
      └── Page 4: Trends & Insights
```

---

## Dataset Description

| Column | Description |
|---|---|
| `artist` | Artist name |
| `track` | Song title |
| `album` | Album name |
| `album_type` | album / single / compilation |
| `danceability` | How suitable for dancing (0–1) |
| `energy` | Intensity and activity (0–1) |
| `loudness` | Overall loudness in dB |
| `speechiness` | Presence of spoken words (0–1) |
| `acousticness` | Likelihood of being acoustic (0–1) |
| `instrumentalness` | Predicts no vocals (0–1) |
| `liveness` | Presence of live audience (0–1) |
| `valence` | Musical positivity (0–1) |
| `tempo` | Beats per minute |
| `duration_ms` | Track length in milliseconds |
| `views` | YouTube view count |
| `likes` | YouTube like count |
| `comments` | YouTube comment count |
| `stream` | Spotify stream count |
| `licensed` | Whether track is licensed (TRUE/FALSE) |
| `official_video` | Whether an official video exists (TRUE/FALSE) |
| `most_playedon` | Dominant platform: Spotify or Youtube |
| `channel` | YouTube channel name |

**Source:** Kaggle — Spotify and YouTube Dataset  
**Rows:** ~20,000+ tracks | **Database:** PostgreSQL | **Visualisation:** Power BI

---

## Schema

```sql
CREATE TABLE spotify (
    artist            VARCHAR(255),
    track             VARCHAR(255),
    album             VARCHAR(255),
    album_type        VARCHAR(50),
    danceability      FLOAT,
    energy            FLOAT,
    loudness          FLOAT,
    speechiness       FLOAT,
    acousticness      FLOAT,
    instrumentalness  FLOAT,
    liveness          FLOAT,
    valence           FLOAT,
    tempo             FLOAT,
    duration_ms       BIGINT,
    views             BIGINT,
    likes             BIGINT,
    comments          BIGINT,
    stream            BIGINT,
    licensed          VARCHAR(10),
    official_video    VARCHAR(10),
    most_playedon     VARCHAR(50),
    channel           VARCHAR(255)
);
```

---

## SQL Concepts Demonstrated

| Concept | Used In |
|---|---|
| Common Table Expressions (CTEs) | Q1, Q2, Q4, Q5, Q6, Q7, Q8 |
| `RANK()` / `DENSE_RANK()` / `NTILE()` | Q1, Q2, Q3, Q6 |
| Global `SUM() OVER ()` for market share | Q1, Q2 |
| Cumulative running total (`ROWS BETWEEN`) | Q1, Q5 |
| `LAG()` with default value | Q5 |
| `PERCENTILE_CONT … WITHIN GROUP` | Q7 |
| `STDDEV()` composite scoring | Q8 |
| `STRING_AGG … FILTER` | Q4 |
| `NULLIF` for division safety | Q2, Q3, Q6, Q7 |
| `HAVING` clause | Q8 |

---

## Business Queries

---

### Q1 — Pareto Analysis: Artist Contribution to Total Streams

**Business Problem:** Do a small number of artists drive the majority of platform streams? Identify whether the catalog follows the 80/20 rule — critical for prioritising artist partnerships and promotional spend.

```sql
WITH artist_streams AS (
    SELECT
        artist,
        SUM(stream)                                        AS total_streams
    FROM spotify
    GROUP BY artist
),
total AS (
    SELECT SUM(total_streams) AS overall_streams
    FROM artist_streams
)
SELECT
    artist,
    total_streams,
    ROUND((total_streams * 100.0 / overall_streams), 2)    AS contribution_pct,
    SUM(ROUND((total_streams * 100.0 / overall_streams), 2))
        OVER (ORDER BY total_streams DESC
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
                                                           AS cumulative_pct
FROM artist_streams, total
ORDER BY contribution_pct DESC;
```

**Why it's advanced:** Extends a basic percentage query with a cumulative running total using `SUM() OVER (ROWS BETWEEN …)` — this lets you directly read off "the top N artists account for X% of total streams," a Pareto chart in pure SQL.

---

### Q2 — Artist Market Share and Streaming Rank

**Business Problem:** Which artists dominate total platform streams, and what percentage of total consumption does each one own?

```sql
WITH artist_streams AS (
    SELECT
        artist,
        SUM(stream)                                        AS total_streams,
        COUNT(track)                                       AS track_count,
        ROUND(AVG(danceability)::numeric, 3)               AS avg_danceability
    FROM spotify
    GROUP BY artist
),
ranked AS (
    SELECT
        artist,
        total_streams,
        track_count,
        avg_danceability,
        RANK() OVER (ORDER BY total_streams DESC)          AS stream_rank,
        ROUND(
            100.0 * total_streams / SUM(total_streams) OVER (),
        2)                                                 AS market_share_pct
    FROM artist_streams
)
SELECT * FROM ranked
WHERE stream_rank <= 20
ORDER BY stream_rank;
```

**Why it's advanced:** Combines CTE chaining with `RANK()` and a global `SUM() OVER ()` to calculate market share — a metric standard in BI dashboards. Demonstrates understanding of window function scope.

---

### Q3 — Track Engagement Funnel with Quartile Bucketing

**Business Problem:** Which tracks convert the most viewers into engaged fans (likes, comments), and how do they rank across the catalog?

```sql
SELECT
    artist,
    track,
    views,
    likes,
    comments,
    ROUND(100.0 * likes    / NULLIF(views, 0), 2)         AS like_rate_pct,
    ROUND(100.0 * comments / NULLIF(views, 0), 2)         AS comment_rate_pct,
    NTILE(4) OVER (
        ORDER BY 100.0 * likes / NULLIF(views, 0) DESC
    )                                                      AS engagement_quartile,
    CASE
        WHEN official_video = 'TRUE' THEN 'Official'
        ELSE 'Unofficial'
    END                                                    AS video_type
FROM spotify
WHERE views > 0
ORDER BY like_rate_pct DESC
LIMIT 50;
```

**Why it's advanced:** Uses `NULLIF` for production-safe division, `NTILE(4)` for quartile bucketing, and a `CASE` flag — a pattern directly used in marketing funnel analysis.

---

### Q4 — Audio Feature Mood Segmentation for Playlist Curation

**Business Problem:** Segment the catalog into listener mood profiles to power playlist recommendation algorithms.

```sql
WITH feature_scores AS (
    SELECT
        artist, track,
        danceability, energy, valence, tempo, acousticness,
        (danceability + energy + valence) / 3.0            AS positivity_score,
        CASE
            WHEN energy >= 0.75 AND danceability >= 0.7   THEN 'Hype'
            WHEN energy >= 0.75 AND danceability <  0.7   THEN 'Intense'
            WHEN energy <  0.5  AND acousticness > 0.5    THEN 'Acoustic / Chill'
            WHEN valence >= 0.6                            THEN 'Upbeat'
            ELSE 'Neutral'
        END                                                AS mood_segment
    FROM spotify
)
SELECT
    mood_segment,
    COUNT(*)                                               AS track_count,
    ROUND(AVG(positivity_score)::numeric, 3)               AS avg_positivity,
    ROUND(AVG(tempo)::numeric, 1)                          AS avg_bpm,
    STRING_AGG(track, ', ' ORDER BY positivity_score DESC)
        FILTER (WHERE positivity_score > 0.7)              AS top_positive_tracks
FROM feature_scores
GROUP BY mood_segment
ORDER BY track_count DESC;
```

**Why it's advanced:** Uses `STRING_AGG … FILTER` (PostgreSQL-specific) alongside rule-based segmentation that mimics ML cluster outputs — directly applicable to recommendation system pipelines.

---

### Q5 — Cumulative Album Streams with LAG Delta per Artist

**Business Problem:** Build a per-artist streaming timeline across albums to detect which releases accelerated or hurt audience growth.

```sql
WITH album_streams AS (
    SELECT
        artist,
        album,
        album_type,
        SUM(stream)                                        AS album_streams,
        COUNT(track)                                       AS tracks
    FROM spotify
    GROUP BY artist, album, album_type
)
SELECT
    artist,
    album,
    album_type,
    album_streams,
    tracks,
    SUM(album_streams) OVER (
        PARTITION BY artist
        ORDER BY album_streams DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                                      AS running_total_streams,
    LAG(album_streams) OVER (
        PARTITION BY artist ORDER BY album_streams DESC
    )                                                      AS prev_album_streams,
    album_streams - LAG(album_streams, 1, 0) OVER (
        PARTITION BY artist ORDER BY album_streams DESC
    )                                                      AS stream_delta
FROM album_streams
ORDER BY artist, album_streams DESC;
```

**Why it's advanced:** Uses `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` framing — shows deep window function knowledge. `LAG(col, 1, 0)` with a default prevents NULL in the first-row delta.

---

### Q6 — Licensing Compliance Gap and Revenue Leakage

**Business Problem:** How much streaming volume sits outside licensing agreements? Rank artists by compliance risk to flag potential royalty leakage to legal and finance teams.

```sql
WITH license_summary AS (
    SELECT
        artist,
        COUNT(track)                                       AS total_tracks,
        SUM(CASE WHEN licensed = 'TRUE'  THEN 1 ELSE 0 END)
                                                           AS licensed_tracks,
        SUM(CASE WHEN licensed = 'FALSE' THEN stream ELSE 0 END)
                                                           AS unlicensed_streams,
        SUM(stream)                                        AS total_streams
    FROM spotify
    GROUP BY artist
)
SELECT
    artist,
    total_tracks,
    licensed_tracks,
    total_tracks - licensed_tracks                         AS unlicensed_tracks,
    unlicensed_streams,
    total_streams,
    ROUND(100.0 * unlicensed_streams / NULLIF(total_streams, 0), 2)
                                                           AS leakage_pct,
    RANK() OVER (ORDER BY unlicensed_streams DESC)         AS risk_rank
FROM license_summary
WHERE unlicensed_streams > 0
ORDER BY unlicensed_streams DESC;
```

**Why it's advanced:** Frames a technical query as a business risk problem — the kind of output a data analyst would present to legal or finance stakeholders, not just engineers.

---

### Q7 — Viral Track Detection using IQR Outlier Method

**Business Problem:** Statistically identify tracks whose view-to-stream ratios far exceed the catalog norm — early signals of viral content before view counts peak.

```sql
WITH ratios AS (
    SELECT
        artist, track, stream, views,
        ROUND((views::numeric / NULLIF(stream, 0)), 4)     AS view_stream_ratio
    FROM spotify
    WHERE stream > 0
),
stats AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY view_stream_ratio) AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY view_stream_ratio) AS q3
    FROM ratios
)
SELECT
    r.artist,
    r.track,
    r.stream,
    r.views,
    r.view_stream_ratio,
    ROUND(s.q3 + 1.5 * (s.q3 - s.q1), 4)                 AS upper_fence,
    'Viral Outlier'                                        AS flag
FROM ratios r, stats s
WHERE r.view_stream_ratio > s.q3 + 1.5 * (s.q3 - s.q1)
ORDER BY r.view_stream_ratio DESC;
```

**Why it's advanced:** Applies the IQR outlier method entirely in SQL using `PERCENTILE_CONT … WITHIN GROUP` — a statistical technique most analysts implement in Python. Demonstrates SQL-first analytical thinking.

---

### Q8 — Artist Catalog Diversity Score via Feature Standard Deviation

**Business Problem:** Score each artist's stylistic range across audio dimensions. Genre-fluid artists with high variance are candidates for cross-genre playlist placements.

```sql
WITH diversity AS (
    SELECT
        artist,
        COUNT(track)                                       AS total_tracks,
        ROUND(STDDEV(danceability)::numeric, 4)            AS sd_dance,
        ROUND(STDDEV(energy)::numeric, 4)                  AS sd_energy,
        ROUND(STDDEV(valence)::numeric, 4)                 AS sd_valence,
        ROUND(STDDEV(tempo)::numeric, 4)                   AS sd_tempo
    FROM spotify
    GROUP BY artist
    HAVING COUNT(track) >= 3
)
SELECT
    artist,
    total_tracks,
    sd_dance,
    sd_energy,
    sd_valence,
    sd_tempo,
    ROUND((sd_dance + sd_energy + sd_valence) / 3.0, 4)   AS composite_diversity_score,
    NTILE(5) OVER (
        ORDER BY (sd_dance + sd_energy + sd_valence) / 3.0 DESC
    )                                                      AS diversity_quintile
FROM diversity
ORDER BY composite_diversity_score DESC;
```

**Why it's advanced:** Constructs a composite scoring metric from `STDDEV` aggregations and buckets results with `NTILE(5)` — a pattern used in recommendation system feature engineering and A/B test segmentation.

---

## Power BI Dashboard

The SQL analysis is extended into a 4-page interactive Power BI dashboard. Each page corresponds to a distinct analytical lens on the same dataset.

---

### Page 1 — Spotify Streaming Summary



**What it shows:**
- KPI cards: Total Streams **(3T)**, Total Views **(2T)**, Total Likes **(13bn)**, Artist Count **(2,074)**
- Top 10 Tracks by Views — Despacito leads at 16.2bn
- Top 10 Artists by Stream — Post Malone (15.3bn), Ed Sheeran (14.4bn), Dua Lipa (13.4bn)
- Platform split: **Spotify 80% vs YouTube 20%**
- Licensed content percentage: **68.27%**

---

### Page 2 — Audio Analysis



**What it shows:**
- Catalog averages: Danceability (0.62), Energy (0.64), Valence (0.53), Tempo (120.56 BPM)
- Distribution histograms for danceability and energy across all tracks
- Valence vs Streams scatter — mid-range valence (0.4–0.6) drives the most streams
- Audio DNA comparison: Singles vs Albums vs Compilations across features
- Acoustic (40%) vs Electronic/Produced (60%) catalog split
- Tempo buckets vs average streams — medium-fast (120–150 BPM) peaks at 0.14bn avg streams

---

### Page 3 — Artist Analysis



**What it shows:**
- Artist slicer for individual drill-down (example shown: The Score)
- Gauge charts for Total Views, Total Streams, Total Likes
- Engagement Rate by Track — treemap weighted by engagement ratio
- Track Performance Breakdown table: Views, Likes, Comments, Engagement Rate per track
- Streams vs Views scatter — visual identification of "True Hits"

---

### Page 4 — Trends & Insights



**What it shows:**
- Tracks above 100M streams: **6K** | Avg streams for singles: **98.96M** | Albums: **146.82M**
- Album type share of streams per artist — stacked bar for top 10 artists
- Track Performance Tiers: Low / Mid / High / Mega — **68.71%** of tracks are in the Low tier
- Official videos drive approximately **2× more average views** than unofficial uploads
- Artist Engagement Rate leaderboard
- Consistency Score by Artist — measures how reliably an artist maintains stream levels across tracks

---

## Key Insights

- **Pareto holds:** A small group of artists drives the majority of total streams — top artists account for a disproportionate share of platform consumption
- **Engagement ≠ Views:** High view counts don't guarantee high like/comment rates — some lower-view tracks show 3–5× better engagement ratios ("hidden gems")
- **Singles vs Albums:** Singles average 98.96M streams but albums reach 146.82M — different release strategies suit different growth goals
- **Official videos drive ~2× views** compared to unofficial uploads — a clear signal for content strategy decisions
- **Mid-range valence (0.4–0.6) and fast tempo (120–150 BPM)** correlate with the highest average streams
- **68.27% of content is licensed** — the remaining 31.73% represents a measurable compliance risk
- **80% of streams are Spotify-driven** vs 20% YouTube in this dataset

---

## Tools Used

| Tool | Purpose |
|---|---|
| PostgreSQL | Data storage, cleaning, advanced SQL analysis |
| pgAdmin / DBeaver | Query execution and exploration |
| Power BI Desktop | Interactive 4-page dashboard |
| Excel / Google Sheets | Initial data inspection |
| GitHub | Version control and portfolio hosting |

---

## Future Improvements

- Add a Python EDA notebook (pandas + seaborn) as a companion to the SQL analysis
- Automate CSV → PostgreSQL ingestion with a Python script
- Publish Power BI dashboard to Power BI Service for live web sharing
- Extend with time-series analysis if release date data becomes available
- Add DAX measures for month-over-month stream growth in Power BI

---

## Project Structure

```
spotify-data-analytics/
│
├── data/
│   └── cleaned_dataset.csv
│
├── sql/
│   ├── schema.sql
│   └── queries.sql
│
├── assets/
│   ├── dashboard_streaming_summary.png
│   ├── dashboard_audio_analysis.png
│   ├── dashboard_artist_analysis.png
│   └── dashboard_trends_insights.png
│
├── powerbi/
│   └── spotify_dashboard.pbix
│
└── README.md
```

---

## Author

**Harikrishna K R**  
Aspiring Data Analyst | SQL · PostgreSQL · Power BI · Python  
[GitHub Profile](https://github.com/harikrishnakr26-ux)
