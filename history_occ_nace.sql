CREATE TABLE radjobads.history_occ_nace AS (
WITH calendar AS (
SELECT cur_date FROM UNNEST(GENERATE_DATE_ARRAY(DATE('2019-01-01'), DATE('2019-06-29'), INTERVAL 1 DAY)) AS cur_date
UNION ALL
SELECT cur_date FROM UNNEST(GENERATE_DATE_ARRAY(DATE('2020-01-01'), DATE('2020-06-29'), INTERVAL 1 DAY)) AS cur_date
), hist AS (
SELECT registrert_dato, naering, yrke_grovgruppe, CAST(sistepubl_dato AS DATE) AS sistepubl_dato, antall_stillinger FROM radjobads.history h
LEFT JOIN (
SELECT  n2.code AS nace2, n1.short_name AS naering, n2.short_name AS subname FROM radjobads.nace n1
 INNER JOIN radjobads.nace n2 ON n1.code=n2.parent_code
WHERE n1.level=1
) n ON substr(h.bedrift_naring_primar_kode, 1, 2) = n.nace2
)
SELECT cur_date, yrke_grovgruppe, naering, SUM(antall_stillinger) AS antall_stillinger, COUNT(1) AS antall_annonser FROM hist h
INNER JOIN calendar c ON h.registrert_dato<=c.cur_date AND h.sistepubl_dato>=c.cur_date
GROUP BY cur_date, yrke_grovgruppe, naering
)
;


