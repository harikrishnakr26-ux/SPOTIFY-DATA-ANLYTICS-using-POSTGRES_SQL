-- create table
DROP TABLE IF EXISTS spotify;
CREATE TABLE spotify (
    artist VARCHAR(255),
    track VARCHAR(255),
    album VARCHAR(255),
    album_type VARCHAR(50),
    danceability FLOAT,
    energy FLOAT,
    loudness FLOAT,
    speechiness FLOAT,
    acousticness FLOAT,
    instrumentalness FLOAT,
    liveness FLOAT,
    valence FLOAT,
    tempo FLOAT,
    duration_min FLOAT,
    title VARCHAR(255),
    channel VARCHAR(255),
    views FLOAT,
    likes BIGINT,
    comments BIGINT,
    licensed BOOLEAN,
    official_video BOOLEAN,
    stream BIGINT,
    energy_liveness FLOAT,
    most_played_on VARCHAR(50)

--EDA 
SELECT COUNT(*) FROM spotify;

SELECT COUNT(DISTINCT artist) FROM spotify;
SELECT COUNT(DISTINCT album) FROM spotify;
SELECT DISTINCT album_type from spotify;

select max(duration_min) from spotify;
select min(duration_min) from spotify;

select * from spotify
where duration_min=0;

delete from spotify
where duration_min=0

select count(distinct channel) from spotify;

select distinct most_played_on from spotify;\

--Q1--

select track from spotify
where stream> 1000000000;

select distinct album, artist
from spotify
order by 1;

select sum(comments) as total_comments
from spotify
where licensed='true';

select track
from spotify
where album_type='single';

select artist, count(*) as total_number_of_songs
from spotify
group by  artist
order by total_number_of_songs desc;

--medium

select album, avg(danceability) as avg_danceablity
from spotify
group by album
order by 2 desc;

select track, max(energy)
from spotify
group by 1
order by 2 desc
limit 5;

select
track, 
sum(views) as total_views,
sum(likes) as total_likes
from spotify
where official_video='true'
group by 1
order by 2 desc;

select album,track,
sum(views) as total_views
from spotify
group by 1,2
order by 3 desc;

--Top 10 most viewed tracks
select track,
sum(views) as total_views from spotify
group by track
order by total_views DESC
limit 10;

--Top 5 artists by total streams
select artist, sum(stream) as total_streams
from spotify
group by artist
order by total_streams desc
limit 5;

--Average views per artist
select artist, avg(views) as average_views
from spotify
group by artist
order by average_views desc;

--Albums with highest average energy
select album, avg(energy) as energy_average
from spotify
group by album
order by energy_average desc
limit 10;

--Tracks with above-average danceability
select track, danceability 
from spotify
where danceability>(
	select avg(danceability)
	from spotify
)

--Songs with views greater than overall average
select track,views
from spotify
where views>(
	select avg(views)
	from spotify
)

--Like-to-view ratio (Engagement metric)
SELECT track,
       views,
       likes,
       (likes * 1.0 / views) AS like_ratio
FROM spotify
WHERE views > 0
ORDER BY like_ratio DESC;

--Performance category
select track, views,
case when
	views>100000000 then 'HIGH'
	WHEN views>10000000 then 'LOW'
	else 'LOW'
	end as performance_category
from spotify;

--Rank songs within each artist
select artist,track,views,
rank() over (partition by artist order by views DESC) as rank
from spotify;

--Dense rank artists by total streams
select artist,
sum(stream) as total_streams,
dense_rank() over( order by sum(stream) desc)
from spotify
group by artist;

--Platform comparison (YouTube vs Spotify)
SELECT most_played_on,
       SUM(views) AS total_views,
       SUM(stream) AS total_streams,
       AVG(likes) AS avg_likes
FROM spotify
GROUP BY most_played_on;

--
SELECT distinct(track),
       views,
       likes,
       comments,
       ((likes + comments) * 1.0 / views) AS engagement_ratio
FROM spotify
WHERE views > 1000000
ORDER BY engagement_ratio DESC;

--Advanced Business-Level

-- Who contributes most to total platform streams?(Pareto Analysis)

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

--Identifying “Consistently Performing Artists”

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

--Do High-Energy Songs Perform Better?

SELECT 
    CASE 
        WHEN energy > 0.7 THEN 'High Energy'
        ELSE 'Low Energy'
    END AS energy_type,
    AVG(views) AS avg_views,
    AVG(stream) AS avg_streams
FROM spotify
GROUP BY energy_type;

--Does “Official Video” Tag Increase Performance?

SELECT official_video,
       AVG(views) AS avg_views,
       AVG(likes) AS avg_likes,
       AVG(comments) AS avg_comments
FROM spotify
GROUP BY official_video;

--Identifying Viral Tracks

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

