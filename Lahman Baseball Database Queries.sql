-- Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.
SELECT playerid, 
    CASE
        WHEN pos = 'OF' THEN 'Outfield'
        WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
		WHEN pos IN ('P', 'C') THEN 'Battery'
        ELSE NULL
    END AS Position_Group,
    SUM(po) AS Total_Putouts
FROM
    fielding
WHERE
    yearid= 2016
GROUP BY
    playerid, Position_Group
ORDER BY playerid ASC;

-- Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. 

WITH attendance_data AS (
    SELECT
        h.team AS team_id,
        p.park_name AS park_name,
        ROUND(h.attendance / h.games, 0) AS avg_attendance
    FROM homegames h
    JOIN parks p ON h.park = p.park
    WHERE h.year = 2016
      AND h.games >= 10)

SELECT park_name, team_id, avg_attendance
FROM attendance_data
ORDER BY avg_attendance DESC
LIMIT 5;

-- Repeat for the lowest 5 average attendance

WITH attendance_data AS (
    SELECT
        h.team AS team_id,
        p.park_name AS park_name,
        ROUND(h.attendance / h.games, 0) AS avg_attendance
    FROM homegames h
    JOIN parks p ON h.park = p.park
    WHERE h.year = 2016
      AND h.games >= 10)

SELECT park_name, team_id, avg_attendance
FROM attendance_data
ORDER BY avg_attendance ASC
LIMIT 5;

-- In this question, you will explore the connection between number of wins and attendance.
-- Does there appear to be any correlation between attendance at home games and number of wins?

-- Not from scanning data, but perhaps with visualizations.

WITH attendance_data AS (
    SELECT
        h.team,
        h.year,
        ROUND(SUM(h.attendance) / SUM(h.games), 0) AS avg_attendance
    FROM homegames h
    GROUP BY h.team, h.year)

SELECT
    t.name AS team_name,
    ad.year,
    ad.avg_attendance,
    t.w AS total_wins
FROM attendance_data ad
JOIN teams t ON t.teamid = ad.team AND t.yearid = ad.year
ORDER BY avg_attendance DESC;

-- Do teams that win the world series see a boost in attendance the following year? 
-- Yes

WITH attendance_data AS (
    SELECT
        h.team,
        h.year,
        ROUND(SUM(h.attendance) / SUM(h.games), 0) AS avg_attendance
    FROM homegames h
    GROUP BY h.team, h.year
),
world_series_winners AS (
    SELECT teamid, yearid AS ws_year
    FROM teams
    WHERE wswin = 'Y'
)
SELECT 
    t.name AS team_name,
    ws.ws_year AS win_year,
    ad_win.avg_attendance AS avg_win_year_attendance, 
    COALESCE(ad_next.avg_attendance, 0) AS avg_next_year_attendance, 
    (COALESCE(ad_next.avg_attendance, 0) - ad_win.avg_attendance) AS attendance_diff
FROM world_series_winners ws
JOIN teams t ON ws.teamid = t.teamid AND ws.ws_year = t.yearid 
LEFT JOIN attendance_data ad_win ON t.teamid = ad_win.team AND ad_win.year = ws.ws_year
LEFT JOIN attendance_data ad_next ON t.teamid = ad_next.team AND ad_next.year = ws.ws_year + 1
ORDER BY attendance_diff DESC, ws.ws_year DESC, t.name;


-- What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.
-- Yes

WITH attendance_data AS (
    SELECT
        h.team,
        h.year,
        ROUND(SUM(h.attendance) / SUM(h.games), 0) AS avg_attendance
    FROM homegames h
    GROUP BY h.team, h.year
),
playoff_teams AS (
    SELECT teamid, yearid
    FROM teams
    WHERE divwin = 'Y' OR wcwin = 'Y'
)
SELECT 
    t.name AS team_name,
    pt.yearid AS playoff_year,
    ad_playoff.avg_attendance AS avg_playoff_year_attendance, 
    COALESCE(ad_next.avg_attendance, 0) AS avg_next_year_attendance, 
    (COALESCE(ad_next.avg_attendance, 0) - ad_playoff.avg_attendance) AS attendance_diff
FROM playoff_teams pt
JOIN teams t ON pt.teamid = t.teamid AND pt.yearid = t.yearid 
LEFT JOIN attendance_data ad_playoff ON t.teamid = ad_playoff.team AND ad_playoff.year = pt.yearid
LEFT JOIN attendance_data ad_next ON t.teamid = ad_next.team AND ad_next.year = pt.yearid + 1
ORDER BY attendance_diff DESC, pt.yearid DESC, t.name;

-- write a query utilizing a correlated subquery to find the team with the most wins from each league in 2016.
SELECT DISTINCT lgid,
    (SELECT teamid 
     FROM teams t2
     WHERE t2.yearid = 2016 AND t2.lgid = t1.lgid
     ORDER BY w DESC LIMIT 1) AS teamid
FROM teams t1
WHERE yearid = 2016;

-- Add another correlated subquery to your query on the previous part so that your result shows not just the teamid but also the number of wins by that team.
SELECT t.lgid,
    (SELECT teamid 
     FROM teams 
     WHERE yearid = 2016 AND lgid = t.lgid 
     ORDER BY w DESC LIMIT 1) AS teamid,
    (SELECT w 
     FROM teams 
     WHERE yearid = 2016 AND lgid = t.lgid 
     ORDER BY w DESC LIMIT 1) AS total_wins
FROM (SELECT DISTINCT lgid FROM teams WHERE yearid = 2016) t;

-- Rewrite previous query into one which uses DISTINCT ON to return the top team by league in terms of number of wins in 2016. Your query should return the league, the teamid, and the number of wins.
SELECT DISTINCT ON (lgid) lgid, teamid, w AS total_wins
FROM teams
WHERE yearid = 2016
ORDER BY lgid, w DESC;

--  Rewrite previous query using the LATERAL keyword so that your result shows the teamid and number of wins for the team with the most wins from each league in 2016.
SELECT t.lgid, top.teamid, top.w AS total_wins
FROM (SELECT DISTINCT lgid FROM teams WHERE yearid = 2016) t
CROSS JOIN LATERAL (
    SELECT teamid, w
    FROM teams
    WHERE yearid = 2016 
      AND lgid = t.lgid -- Correlate with the outer league (t.lgid)
    ORDER BY w DESC
    LIMIT 1
) AS top;

-- Rewrite query on the previous problem sot that it returns the top 3 teams from each league in term of number of wins. Show the teamid and number of wins.
SELECT t.lgid, top.teamid, top.w AS total_wins
FROM (SELECT DISTINCT lgid FROM teams WHERE yearid = 2016) t
CROSS JOIN LATERAL (
    SELECT teamid, w
    FROM teams
    WHERE yearid = 2016 
      AND lgid = t.lgid -- Correlate with the outer league (t.lgid)
    ORDER BY w DESC
    LIMIT 3 -- Return top 3 teams per league
) AS top;

-- Write a query which, for each player in the player table, assembles their birthyear, birthmonth, and birthday into a single column called birthdate which is of the date type.
SELECT namefirst || ' ' || namelast AS player_name,
       MAKE_DATE(birthyear, birthmonth, birthday) AS birthdate
FROM people;
-- Use your previous result inside a subquery using LATERAL to calculate for each player their age at debut and age at retirement. (Hint: It might be useful to check out the PostgreSQL date and time functions https://www.postgresql.org/docs/8.4/functions-datetime.html).
SELECT p.fullname, p.birthdate, p.debut, p.finalgame,
    EXTRACT(YEAR FROM AGE(p.debut, p.birthdate)) AS age_at_debut,
    EXTRACT(YEAR FROM AGE(p.finalgame, p.birthdate)) AS age_at_retirement
FROM (SELECT namefirst || ' ' || namelast AS fullname,
        MAKE_DATE(birthyear, birthmonth, birthday) AS birthdate,
        debut,
        finalgame
    FROM people) AS p;

-- Who is the youngest player to ever play in the major leagues?

SELECT namefirst || ' ' || namelast AS fullname,
    MAKE_DATE(birthyear, birthmonth, birthday) AS birthdate,
    debut::date AS debut,
    finalgame::date AS finalgame,
    EXTRACT(YEAR FROM AGE(debut::date, MAKE_DATE(birthyear, birthmonth, birthday))) AS age_at_debut,
    EXTRACT(YEAR FROM AGE(finalgame::date, MAKE_DATE(birthyear, birthmonth, birthday))) AS age_at_retirement
FROM people
WHERE debut IS NOT NULL AND finalgame IS NOT NULL
ORDER BY age_at_retirement ASC NULLS LAST
LIMIT 1;

-- Who is the oldest player to player in the major leagues? You'll likely have a lot of null values resulting in your age at retirement calculation. Check out the documentation on sorting rows here https://www.postgresql.org/docs/8.3/queries-order.html about how you can change how null values are sorted.

SELECT namefirst || ' ' || namelast AS fullname,
    MAKE_DATE(birthyear, birthmonth, birthday) AS birthdate,
    debut::date AS debut,
    finalgame::date AS finalgame,
    EXTRACT(YEAR FROM AGE(debut::date, MAKE_DATE(birthyear, birthmonth, birthday))) AS age_at_debut,
    EXTRACT(YEAR FROM AGE(finalgame::date, MAKE_DATE(birthyear, birthmonth, birthday))) AS age_at_retirement
FROM people
WHERE debut IS NOT NULL AND finalgame IS NOT NULL
ORDER BY age_at_retirement DESC NULLS LAST
LIMIT 1;

-- For this question, use RECURSIVE CTEs 
--Willie Mays holds the record of the most All Star Game starts with 18. How many players started in an All Star Game with Willie Mays? (A player started an All Star Game if they appear in the allstarfull table with a non-null startingpos value).

SELECT COUNT(DISTINCT a.playerid) AS players_started_with_mays
FROM allstarfull a
JOIN (
    SELECT yearid, gameid 
    FROM allstarfull 
    WHERE playerid = 'mayswi01' 
      AND startingpos IS NOT NULL
) mays_games 
  ON a.yearid = mays_games.yearid 
 AND a.gameid = mays_games.gameid
WHERE a.startingpos IS NOT NULL
  AND a.playerid <> 'mayswi01';
