# SPOTIFY-DATA-ANLYTICS-using-POSTGRES_SQL



---

## 📊 Overview

This project focuses on analyzing a music streaming dataset (Spotify & YouTube) using SQL to extract meaningful business insights. The dataset includes attributes related to tracks, artists, albums, and performance metrics such as views, likes, comments, and streams.

The project demonstrates an end-to-end SQL workflow including data exploration and advanced querying techniques. The goal is to simulate real-world data analysis scenarios and derive actionable insights.

---

## 🎯 Objectives

* Practice core and advanced SQL concepts
* Analyze artist and track performance
* Generate business-level insights
* Work with real-world messy data

---

## 🗂️ Dataset Description

The dataset contains the following key attributes:

* **Artist** – Name of the artist
* **Track** – Song name
* **Album** – Album name
* **Views** – Number of views (YouTube)
* **Likes** – Number of likes
* **Comments** – Number of comments
* **Streams** – Spotify stream count
* **Energy, Danceability, Tempo** – Audio features
* **Platform** – YouTube / Spotify

---

## 🧠 SQL Concepts Used

* **Basic Queries** – SELECT, WHERE, ORDER BY
* **Aggregations** – SUM, AVG, COUNT
* **Grouping** – GROUP BY, HAVING
* **Window Functions** –
  * `RANK()`
  * `DENSE_RANK()`
  * `ROW_NUMBER()`
* **CTEs (Common Table Expressions)**
* **CASE Statements**
* **Data Type Casting & Formatting**

---
## 📊 Advanced Business-Level Analysis

---

### 🔥 1. Pareto Analysis – Artist Contribution to Total Streams

```sql
WITH artist_streams AS (
    SELECT artist, SUM(stream) AS total_streams
    FROM spotify
    GROUP BY artist
),
total AS (
    SELECT SUM(total_streams) AS overall_streams FROM artist_streams
)
SELECT artist,
       total_streams,
       ROUND((total_streams * 100.0 / overall_streams), 2) AS contribution_percent
FROM artist_streams , total 
ORDER BY contribution_percent DESC;
```

**Business Explanation:**
This query calculates the percentage contribution of each artist to the total streams on the platform. It helps identify whether a small group of artists dominates overall consumption.

**Insight:**
A few top artists typically contribute a large share of total streams, indicating a **skewed distribution (Pareto principle)**. This insight is useful for prioritizing promotions and partnerships.

---

### 🎤 2. Identifying Consistently Performing Artists

```sql
WITH ranked_tracks AS (
    SELECT artist,
           track,
           views,
           RANK() OVER (PARTITION BY artist ORDER BY views DESC) AS rnk
    FROM spotify
)
SELECT artist, COUNT(*) AS top_tracks
FROM ranked_tracks
WHERE rnk <= 5
GROUP BY artist
ORDER BY top_tracks DESC;
```

**Business Explanation:**
This query identifies artists who consistently produce high-performing tracks by counting how many of their songs fall within their top 5 by views.

**Insight:**
Artists with more top-ranked tracks are more reliable performers, making them strong candidates for long-term collaborations and marketing campaigns.

---

### ⚡ 3. Do High-Energy Songs Perform Better?

```sql
SELECT 
    CASE 
        WHEN energy > 0.7 THEN 'High Energy'
        ELSE 'Low Energy'
    END AS energy_type,
    AVG(views) AS avg_views,
    AVG(stream) AS avg_streams
FROM spotify
GROUP BY energy_type;
```

**Business Explanation:**
This query compares the average performance of high-energy versus low-energy songs to understand how song characteristics influence engagement.

**Insight:**
If high-energy songs show higher views and streams, it suggests that energetic content is more appealing to audiences, guiding production and recommendation strategies.

---

### 🎬 4. Does “Official Video” Tag Increase Performance?

```sql
SELECT official_video,
       AVG(views) AS avg_views,
       AVG(likes) AS avg_likes,
       AVG(comments) AS avg_comments
FROM spotify
GROUP BY official_video;
```

**Business Explanation:**
This query evaluates whether labeling a video as “official” impacts its performance in terms of views and engagement.

**Insight:**
Official videos often perform better due to higher credibility and trust, which can influence how content is published and promoted.

---

### 🚀 5. Identifying Viral Tracks

```sql
SELECT track,
       artist,
       views,
       likes,
       comments,
       ROUND(((likes + comments) * 1.0 / views)::numeric, 3) AS engagement_ratio
FROM spotify
WHERE views > 1000000
ORDER BY engagement_ratio DESC
LIMIT 10;
```

**Business Explanation:**
This query identifies tracks with the highest engagement relative to views, highlighting songs that generate strong audience interaction.

**Insight:**
Tracks with high engagement ratios are considered **viral or highly engaging**, even if their total views are not the highest. These tracks are valuable for recommendations and trend analysis.

---

## 💡 Key Insights

* A small percentage of artists contribute to the majority of total streams (Pareto principle)
* High views do not always guarantee high engagement
* Some tracks with lower views show higher engagement → potential “hidden gems”
* Official videos tend to perform better in terms of engagement
* Platform differences impact artist visibility and reach

---

## 🚀 Conclusion

This project highlights the ability to work with real-world datasets and apply advanced SQL techniques to solve business problems. It demonstrates strong analytical thinking, data cleaning skills, and the ability to derive insights that can support decision-making.

---

## 🛠️ Tools Used

* PostgreSQL
* SQL
* GitHub

---

## 📎 Future Improvements

* Build a Power BI / Tableau dashboard
* Perform predictive analysis
* Add time-series analysis if date data is available

---

## 👨‍💻 Author

**Harikrishna K R**

---
