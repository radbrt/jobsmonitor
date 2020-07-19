CREATE OR REPLACE TABLE radjobads.current_status AS (
WITH calendar AS (
    SELECT cur_date FROM UNNEST(GENERATE_DATE_ARRAY(DATE('2020-06-15'), CURRENT_DATE('Europe/Oslo'), INTERVAL 1 DAY)) AS cur_date
), curjobs AS (
    SELECT CAST(published AS DATE) published, CAST(expires AS DATE) AS expires, positioncount, employer_orgnr,
    TRIM(JSON_EXTRACT(occupationCategories, '$[0].level1'),'"') AS occ_level1,
    TRIM(JSON_EXTRACT(occupationCategories, '$[0].level2'), '"') AS occ_level2 FROM radjobads.apijobs
), nace AS (
    SELECT  n2.code AS nace2, n1.short_name AS naering, n2.short_name AS subname FROM radjobads.nace n1
    INNER JOIN radjobads.nace n2 ON n1.code=n2.parent_code
    WHERE n1.level=1
)
SELECT cal.cur_date, cur.occ_level1, occ_level2, n.naering, COUNT(1) AS antall_annonser, SUM(positioncount) AS antall_stillinger FROM curjobs cur
INNER JOIN calendar cal ON cur.published<=cal.cur_date AND cur.expires>=cal.cur_date
LEFT JOIN radjobads.underenheter u ON cur.employer_orgnr=u.orgnr
LEFT JOIN nace n ON SUBSTR(u.nkode1, 1, 2)=n.nace2
GROUP BY cal.cur_date, cur.occ_level1, occ_level2, n.naering
)
;

