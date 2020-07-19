
CREATE TABLE radjobads.running_history AS (
    SELECT cur_date, CASE WHEN naering IS NULL THEN 'Ukjent' ELSE naering END AS naering,
    CASE WHEN antall_annonser IS NULL THEN 0 ELSE antall_annonser END AS antall_annonser,
    CASE WHEN antall_stillinger IS NULL THEN 0 ELSE antall_stillinger END AS antall_stillinger,
        AVG(CASE WHEN antall_annonser IS NULL THEN 0 ELSE antall_annonser END) OVER(PARTITION BY naering ORDER BY cur_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS avg_antall_annonser,
        AVG(CASE WHEN antall_stillinger IS NULL THEN 0 ELSE antall_stillinger END) OVER(PARTITION BY naering ORDER BY cur_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS avg_antall_stillinger FROM (
            WITH calendar AS (
                SELECT cur_date FROM UNNEST(GENERATE_DATE_ARRAY(DATE('2019-01-01'), CURRENT_DATE('Europe/Oslo'), INTERVAL 1 DAY)) AS cur_date
            ), curjobs AS (
                SELECT CAST(registrert_dato AS DATE) published, CAST(sistepubl_dato AS DATE) AS expires, antall_stillinger AS positioncount, bedrift_org_nr AS employer_orgnr,
                 FROM radjobads.history
            ), nace AS (
                SELECT  n2.code AS nace2, n1.short_name AS naering, n2.short_name AS subname FROM radjobads.nace n1
                INNER JOIN radjobads.nace n2 ON n1.code=n2.parent_code
                WHERE n1.level=1
            )
            SELECT cal.cur_date, n.naering, COUNT(1) AS antall_annonser, SUM(positioncount) AS antall_stillinger FROM curjobs cur
            RIGHT JOIN calendar cal ON cur.published=cal.cur_date
            LEFT JOIN radjobads.underenheter u ON cur.employer_orgnr=u.orgnr
            LEFT JOIN nace n ON SUBSTR(u.nkode1, 1, 2)=n.nace2
            GROUP BY cal.cur_date, n.naering
    )
)
;
