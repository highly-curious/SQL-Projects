-- # SQL Assessment - Poetry by Kids
--  **Note:** The data in this exercise is derived from the datasets found [here](https://github.com/whipson/PoKi-Poems-by-Kids). An academic paper describing the PoKi project can be found [here](https://arxiv.org/abs/2004.06188)
-- > The data is used for education purposes with permission from the maintainer.  

-- The poetry in this database is the work of children in grades 1 through 5.  
--     a. How many poets from each grade are represented in the data?

SELECT COUNT (name), grade_id
FROM author
GROUP by grade_id
ORDER BY grade_id ASC;

--  How many of the poets in each grade are Male and how many are Female? Only return the poets identified as Male or Female.
SELECT 
    COUNT(CASE WHEN gender_id = '1' THEN 1 ELSE NULL END) AS male_count,
    COUNT(CASE WHEN gender_id = '2' THEN 1 ELSE NULL END) AS female_count,
    grade_id
FROM author
WHERE gender_id IS NOT NULL
GROUP BY grade_id
ORDER BY grade_id ASC;

--  Briefly describe the trend you see across grade levels.
-- As grade level increases, poem submissions increase for both M and F genders, however, the amount of submissions for students identifying as male increase at a significantly higher rate than students identified as female.

-- Two foods that are favorites of children are pizza and hamburgers. Which of these things do children write about more often? Which do they have the most to say about when they do?
--     Return the **total number** of poems that mention **pizza** and **total number** that mention the word **hamburger** in the TEXT or TITLE, also return the **average character count** for poems that mention **pizza** and also for poems that mention the word **hamburger** in the TEXT or TITLE. Do this in a single query, (i.e. your output should contain all the information).
SELECT 
    COUNT(CASE WHEN (text ILIKE '%pizza%' OR title ILIKE '%pizza%') THEN 1 ELSE NULL END) AS total_pizza_poems,
    AVG(CASE WHEN (text ILIKE '%pizza%' OR title ILIKE '%pizza%') THEN LENGTH(text) ELSE NULL END) AS avg_char_count_pizza,
    COUNT(CASE WHEN (text ILIKE '%burger%' OR title ILIKE '%burger%') THEN 1 ELSE NULL END) AS total_hamburger_poems,
    AVG(CASE WHEN (text ILIKE '%burger%' OR title ILIKE '%burger%') THEN LENGTH(text) ELSE NULL END) AS avg_char_count_hamburger
FROM poem;


-- Do longer poems have more emotional intensity compared to shorter poems?  
--     Start by writing a query to return each emotion in the database with its average intensity and average character count.   
--      - Which emotion is associated the longest poems on average?
-- Anger
SELECT pe.emotion_id, e.name AS emotion_name,
    AVG(pe.intensity_percent) AS avg_intensity,
    AVG(p.char_count) AS avg_char_count
FROM poem_emotion pe
JOIN poem p ON pe.poem_id = p.id
JOIN emotion e ON pe.emotion_id = e.id
GROUP BY pe.emotion_id, e.name
ORDER BY avg_char_count DESC
LIMIT 1;

--      - Which emotion has the shortest?
-- Joy
SELECT pe.emotion_id, e.name AS emotion_name,
    AVG(pe.intensity_percent) AS avg_intensity, AVG(p.char_count) AS avg_char_count
FROM poem_emotion pe
JOIN poem p ON pe.poem_id = p.id
JOIN emotion e ON pe.emotion_id = e.id
GROUP BY pe.emotion_id, e.name
ORDER BY avg_char_count ASC
LIMIT 1;



--  Convert the query you wrote in part a into a CTE. Then find the 5 most intense poems that express anger and whether they are to be longer or shorter than the average angry poem.   
--Longer than Avg
WITH AverageEmotions AS (
    SELECT pe.emotion_id, e.name AS emotion_name,
        AVG(pe.intensity_percent) AS avg_intensity,
        AVG(p.char_count) AS avg_char_count
    FROM poem_emotion pe
    JOIN poem p ON pe.poem_id = p.id
    JOIN emotion e ON pe.emotion_id = e.id
    GROUP BY pe.emotion_id, e.name)

SELECT 
    pe.poem_id, pe.intensity_percent, p.char_count, ae.avg_intensity, ae.emotion_name,
    CASE WHEN pe.intensity_percent > ae.avg_intensity THEN 'Longer'
        ELSE 'Shorter'
    END AS intensity_comparison
FROM poem_emotion pe
JOIN poem p ON pe.poem_id = p.id
JOIN AverageEmotions ae ON pe.emotion_id = ae.emotion_id
WHERE ae.emotion_name = 'Anger'
ORDER BY pe.intensity_percent DESC
LIMIT 5;



--   What is the most angry poem about?
-- there once was a horse from france who learned how to do the irish dance the horse went on stage and the crowd was outraged because the horse had ants in his pants
SELECT title, text
FROM poem
JOIN poem_emotion pe ON
WHERE id = 28660;

--      -  Do you think these are all classified correctly?
-- Not necessarily. The most angry poem was probably flagged the keyword 'outraged' as a high intensity anger emotion.

-- Compare the 5 most joyful poems by 1st graders to the 5 most joyful poems by 5th graders.  
--   	a. Which group writes the most joyful poems according to the intensity score? 
-- Fifth Graders

WITH AverageEmotions AS (
    SELECT pe.emotion_id, e.name AS emotion_name,
        AVG(pe.intensity_percent) AS avg_intensity,
        AVG(p.char_count) AS avg_char_count
    FROM poem_emotion pe
    JOIN poem p ON pe.poem_id = p.id
    JOIN emotion e ON pe.emotion_id = e.id
    GROUP BY pe.emotion_id, e.name
),
FirstGradersJoyfulPoems AS (
    SELECT pe.poem_id, pe.intensity_percent, p.char_count, ae.avg_intensity,
        CASE WHEN pe.intensity_percent > ae.avg_intensity THEN 'Longer'
             ELSE 'Shorter'
        END AS intensity_comparison,
        a.name AS author_name,
        a.gender_id,
        ae.emotion_name -- Added emotion_name
    FROM poem_emotion pe
    JOIN poem p ON pe.poem_id = p.id
    JOIN AverageEmotions ae ON pe.emotion_id = ae.emotion_id
    JOIN author a ON p.author_id = a.id
    WHERE a.grade_id = 1 AND ae.emotion_name = 'Joy'
    ORDER BY pe.intensity_percent DESC
    LIMIT 5
),
FifthGradersJoyfulPoems AS (
    SELECT pe.poem_id, pe.intensity_percent, p.char_count, ae.avg_intensity,
        CASE WHEN pe.intensity_percent > ae.avg_intensity THEN 'Longer'
             ELSE 'Shorter'
        END AS intensity_comparison,
        a.name AS author_name,
        a.gender_id,
        ae.emotion_name -- Added emotion_name
    FROM poem_emotion pe
    JOIN poem p ON pe.poem_id = p.id
    JOIN AverageEmotions ae ON pe.emotion_id = ae.emotion_id
    JOIN author a ON p.author_id = a.id
    WHERE a.grade_id = 5 AND ae.emotion_name = 'Joy'
    ORDER BY pe.intensity_percent DESC
    LIMIT 5)
	
SELECT 'First Graders' AS group_type, pe.poem_id, pe.intensity_percent, pe.char_count, pe.intensity_comparison, pe.author_name, pe.gender_id, pe.emotion_name
FROM FirstGradersJoyfulPoems pe
UNION ALL
SELECT 'Fifth Graders' AS group_type, pe.poem_id, pe.intensity_percent, pe.char_count, pe.intensity_comparison, pe.author_name, pe.gender_id, pe.emotion_name
FROM FifthGradersJoyfulPoems pe;

--  How many times do males show up in the top 5 poems for each grade?  Females?

-- group_type	male_count	female_count
-- First Graders	1	        4
-- Fifth Graders	1	        2

WITH AverageEmotions AS (
    SELECT pe.emotion_id, e.name AS emotion_name,
        AVG(pe.intensity_percent) AS avg_intensity,
        AVG(p.char_count) AS avg_char_count
    FROM poem_emotion pe
    JOIN poem p ON pe.poem_id = p.id
    JOIN emotion e ON pe.emotion_id = e.id
    GROUP BY pe.emotion_id, e.name
),
FirstGradersJoyfulPoems AS (
    SELECT pe.poem_id, pe.intensity_percent, p.char_count, ae.avg_intensity,
        CASE WHEN pe.intensity_percent > ae.avg_intensity THEN 'Longer'
             ELSE 'Shorter'
        END AS intensity_comparison,
        a.name AS author_name,
        a.gender_id,
        ae.emotion_name
    FROM poem_emotion pe
    JOIN poem p ON pe.poem_id = p.id
    JOIN AverageEmotions ae ON pe.emotion_id = ae.emotion_id
    JOIN author a ON p.author_id = a.id
    WHERE a.grade_id = 1 AND ae.emotion_name = 'Joy'
    ORDER BY pe.intensity_percent DESC
    LIMIT 5
),
FifthGradersJoyfulPoems AS (
    SELECT pe.poem_id, pe.intensity_percent, p.char_count, ae.avg_intensity,
        CASE WHEN pe.intensity_percent > ae.avg_intensity THEN 'Longer'
             ELSE 'Shorter'
        END AS intensity_comparison,
        a.name AS author_name,
        a.gender_id,
        ae.emotion_name
    FROM poem_emotion pe
    JOIN poem p ON pe.poem_id = p.id
    JOIN AverageEmotions ae ON pe.emotion_id = ae.emotion_id
    JOIN author a ON p.author_id = a.id
    WHERE a.grade_id = 5 AND ae.emotion_name = 'Joy'
    ORDER BY pe.intensity_percent DESC
    LIMIT 5
),
CombinedResults AS (
    SELECT 
        'First Graders' AS group_type,
        pe.poem_id,
        pe.intensity_percent,
        pe.char_count,
        pe.intensity_comparison,
        pe.author_name,
        pe.gender_id,
        pe.emotion_name
    FROM FirstGradersJoyfulPoems pe
    UNION ALL
    SELECT 
        'Fifth Graders' AS group_type,
        pe.poem_id,
        pe.intensity_percent,
        pe.char_count,
        pe.intensity_comparison,
        pe.author_name,
        pe.gender_id,
        pe.emotion_name
    FROM FifthGradersJoyfulPoems pe
)
SELECT 
    group_type,
    COUNT(CASE WHEN gender_id = 1 THEN 1 END) AS male_count,
    COUNT(CASE WHEN gender_id = 2 THEN 1 END) AS female_count
FROM CombinedResults
GROUP BY group_type;

-- Robert Frost was a famous American poet. There is 1 poet named `robert` per grade.
-- FALSE
--  Examine the 5 poets in the database with the name `robert`. Create a report showing the distribution of emotions that characterize their work by grade. 
WITH RobertPoems AS (
    SELECT p.id AS poem_id, a.grade_id, a.name AS author_name
    FROM poem p
    JOIN author a ON a.id = p.author_id
    WHERE a.name ='robert'),
	
EmotionDistribution AS (
    SELECT rp.grade_id, rp.author_name, e.name AS emotion,
        COUNT(pe.poem_id) AS poem_count
    FROM RobertPoems rp
    JOIN poem_emotion pe ON rp.poem_id = pe.poem_id
    JOIN emotion e ON pe.emotion_id = e.id
    GROUP BY rp.grade_id, rp.author_name, e.name)
	
SELECT author_name, grade_id, emotion, poem_count
FROM EmotionDistribution
ORDER BY grade_id, emotion;

--  Export this report to Excel and create an appropriate visualization that shows what you have found.
-- The clustered bar chart in the attached file , 'RobertPoemEmotions.xlx', shows the amount of poems submitted by people named "Robert" in grades 1-5, distrubuted by the emotion keywords flagged in the text of the poems and grouped by grade level.
