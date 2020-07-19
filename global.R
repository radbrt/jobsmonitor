library(DBI)
library(bigrquery)
library(janitor)
library(tidyverse)
library(ggrepel)

bq_auth(path = "_jobsdashboard_bq_key.json")


con <- dbConnect(
  bigrquery::bigquery(),
  project = "radjobads",
  dataset = "radjobads",
  billing = "radjobads"
)



# datetable <- dbReadTable(con, "history_occ_nace") %>% 
#   mutate(year = format(cur_date, "%Y"),
#          dayofyear = as.numeric(format(cur_date, "%j")),
#          naering = replace_na(naering, "Unknown"))

load("datetable.RData")


pubq <- "WITH dates AS (
    SELECT cur_date FROM UNNEST(GENERATE_DATE_ARRAY(DATE('2020-06-10'), CURRENT_DATE('Europe/Oslo'), INTERVAL 1 DAY)) AS cur_date
), jobs AS (
    SELECT CAST(published AS DATE) published,
    TRIM(JSON_EXTRACT(occupationCategories, '$[0].level1'),'\"') AS occ_level1,
    SUM(positioncount) AS stillinger,
    COUNT(1) AS annonser FROM radjobads.apijobs
    GROUP BY CAST(published AS DATE), TRIM(JSON_EXTRACT(occupationCategories, '$[0].level1'),'\"')
)
SELECT published, occ_level1,
SUM(CASE WHEN stillinger IS NULL THEN 0 ELSE stillinger END) OVER(PARTITION BY occ_level1 ORDER BY published ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS stillinger,
SUM(CASE WHEN annonser IS NULL THEN 0 ELSE annonser END) OVER(PARTITION BY occ_level1 ORDER BY published ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS annonser
FROM dates d
LEFT JOIN jobs j ON j.published=d.cur_date"

pubdf <- dbGetQuery(con, pubq) %>%
  filter(published>='2020-06-17') %>%
  mutate(year = format(published, "%Y"),
         dayofyear = as.numeric(format(published, "%j")))



synthq <- "
WITH API AS (
    SELECT uuid, cur_date, 'API' AS source, employer_orgnr, CASE WHEN positioncount IS NULL THEN 0 ELSE positioncount END AS positioncount, CASE WHEN uuid IS NULL THEN 0 ELSE (10207/6026) END AS weight FROM (
        SELECT uuid, CAST(published AS DATE) AS published, CASE WHEN positioncount IS NULL THEN 0 ELSE positioncount END AS positioncount, employer_orgnr FROM radjobads.apijobs
    ) api
    RIGHT JOIN (
        SELECT cur_date FROM UNNEST(GENERATE_DATE_ARRAY(DATE('2020-06-01'), CURRENT_DATE('Europe/Oslo'), INTERVAL 1 DAY)) AS cur_date
    ) cal ON cal.cur_date=api.published
), history AS (
    SELECT uuid, cur_date, 'HISTORY' AS source, employer_orgnr, CASE WHEN positioncount IS NULL THEN 0 ELSE positioncount END AS positioncount, CASE WHEN uuid IS NULL THEN 0 ELSE 1 END AS weight FROM (
        SELECT stillingsnummer_nav_no AS uuid, registrert_dato AS published, CASE WHEN antall_stillinger IS NULL THEN 0 ELSE antall_stillinger END AS positioncount, bedrift_org_nr AS employer_orgnr, 1 AS antall FROM radjobads.history
    ) api
    RIGHT JOIN (
        SELECT cur_date FROM UNNEST(GENERATE_DATE_ARRAY(DATE('2019-01-01'), CURRENT_DATE('Europe/Oslo'), INTERVAL 1 DAY)) AS cur_date
    ) cal ON cal.cur_date=api.published
)
SELECT source, cur_date,
AVG(est_positions) OVER(PARTITION BY source ORDER BY cur_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS antall_stillinger,
AVG(est_ads) OVER(PARTITION BY source ORDER BY cur_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS antall_annonser
FROM(
SELECT source, cur_date, SUM(positioncount) AS positioncount, SUM(positioncount*weight) AS est_positions, SUM(weight)  AS est_ads FROM (
    SELECT * FROM API
    UNION ALL
    SELECT * FROM history
)
GROUP BY source, cur_date
)
"

synth <- dbGetQuery(con, synthq) %>% 
  filter( (source=='API' & cur_date>='2020-06-20') | (source=='HISTORY' & cur_date<='2020-06-29') )


synth %>% 
  filter( (source=='API' & cur_date>='2020-06-20') | (source=='HISTORY' & cur_date<='2020-06-29') ) %>% 
  mutate(year = format(cur_date, "%Y"),
         dayofyear = as.numeric(format(cur_date, "%j"))) %>% 
  mutate(viz_source = case_when(
    source=='API' ~ 'API',
    year==2019 ~ '2019',
    TRUE ~ '2020'
  )) %>% 
  mutate(label = case_when(
    cur_date=='2020-03-12' ~ "Shutdown", 
    cur_date=='2020-03-06' ~ "100 cases",
    cur_date=='2020-02-26' ~ "First case",
    TRUE ~ "")) %>%
  mutate(line_color = case_when(
    viz_source == 'API' ~ '#1223df',
    viz_source == '2020' ~ '#6565FF',
    TRUE ~ '#cacbcc'
  )) -> synth_viz


load("occwide.RData")
load("nacewide.RData")
# 
# occdiff_query <- "
# SELECT yrke_grovgruppe,
# EXTRACT(YEAR FROM registrert_dato) AS year,
# COUNT(1) AS antall_annonser,
# SUM(CASE WHEN antall_stillinger IS NULL THEN 1 ELSE antall_stillinger END) AS antall_stillinger
# FROM radjobads.history
# WHERE EXTRACT(MONTH FROM registrert_dato)<=6
# GROUP BY yrke_grovgruppe,
# EXTRACT(YEAR FROM registrert_dato)
# "
# 
# occdelta <- dbGetQuery(con, occdiff_query) %>% 
#   pivot_longer(c("antall_stillinger", "antall_annonser"), names_to="measure", values_to="value") %>% 
#   pivot_wider(names_from = year, values_from = value, names_prefix ="Y") %>% 
#   mutate(delta = Y2020-Y2019,
#          deltapct = round(100* ((Y2020/Y2019)-1), 1) ) -> occwide
# 
# 
# nacediff_query <- "
# WITH hist AS (
#         SELECT registrert_dato, naering, yrke_grovgruppe, antall_stillinger FROM radjobads.history h
#     LEFT JOIN (
#         SELECT  n2.code AS nace2, n1.short_name AS naering, n2.short_name AS subname FROM radjobads.nace n1
#          INNER JOIN radjobads.nace n2 ON n1.code=n2.parent_code
#         WHERE n1.level=1
#     ) n ON substr(h.bedrift_naring_primar_kode, 1, 2) = n.nace2
#     WHERE EXTRACT(MONTH FROM registrert_dato)<=6
# )
# SELECT EXTRACT(YEAR FROM registrert_dato) AS year, CASE WHEN naering IS NULL THEN 'Ukjent' ELSE naering END AS naering, SUM(antall_stillinger) AS antall_stillinger, COUNT(1) AS antall_annonser FROM hist
# GROUP BY EXTRACT(YEAR FROM registrert_dato), naering
# "
# 
# nacedelta <- dbGetQuery(con, nacediff_query) %>% 
#   pivot_longer(c("antall_stillinger", "antall_annonser"), names_to="measure", values_to="value") %>% 
#   pivot_wider(names_from = year, values_from = value, names_prefix ="Y") %>% 
#   mutate(delta = Y2020-Y2019,
#          deltapct = round(100* ((Y2020/Y2019)-1), 1) ) -> nacewide


