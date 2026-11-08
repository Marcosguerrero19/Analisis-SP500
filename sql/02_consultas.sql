-- =========================================================
-- 02_consultas.sql
-- Proyecto: Análisis de estrategias de inversión en el S&P 500
--
-- Aquí respondo con SQL las preguntas del proyecto.
-- Los datos los he calculado antes con Python y los he
-- cargado en la base de datos sp500.
-- =========================================================

USE sp500;

-- ==========================================================
-- CONSULTA 1
-- ==========================================================
-- Pregunta: ¿en qué sectores hay más empresas que superan
-- al índice?
--
-- En el análisis vi que solo el 32 % de las empresas baten
-- al índice. Aquí miro si eso cambia según el sector.
--
-- Uso GROUP BY para agrupar las filas por sector y calcular
-- una fila de resultados por cada uno.
-- ---------------------------------------------------------

SELECT
    sector,
    COUNT(*) AS total_empresas,                    -- cuántas empresas tiene el sector
    SUM(bate_al_indice) AS empresas_que_baten,     -- sumo los 1, así cuento las que baten
    ROUND(SUM(bate_al_indice) / COUNT(*) * 100, 1) AS porcentaje
FROM metricas_empresas
GROUP BY sector
ORDER BY porcentaje DESC;

-- RESULTADO:
-- Tecnología es el único sector donde la mayoría de empresas
-- bate al índice (63,2 %). En el otro extremo, en Servicios
-- públicos solo lo consigue 1 de 29 empresas (3,4 %).
-- La diferencia entre sectores es enorme: acertar con el sector
-- importó más que acertar con la empresa.

-- ==========================================================
-- CONSULTA 2
-- ==========================================================
-- Pregunta: ¿cuáles son las 3 mejores empresas de cada sector?
--
-- Esto no es tan fácil como poner LIMIT 3, porque quiero las
-- 3 mejores DE CADA sector, no las 3 mejores en total.
-- Para eso uso RANK(), que numera las filas dentro de cada
-- grupo. Primero calculo el puesto de cada empresa dentro de
-- su sector y luego me quedo con las que están en el top 3.
-- ---------------------------------------------------------
-- Con WITH creo una tabla temporal que solo existe en esta consulta

WITH ranking AS (
    SELECT
        ticker,
        nombre,
        sector,
        rentabilidad_anual,
        volatilidad_anual,
        -- RANK() da el puesto de cada empresa
        -- PARTITION BY sector hace que el puesto se reinicie en cada sector
        -- ORDER BY dice según qué columna se ordena para dar el puesto
        RANK() OVER (PARTITION BY sector ORDER BY rentabilidad_anual DESC) AS puesto
    FROM metricas_empresas
)

-- Ahora consulto esa tabla temporal y me quedo con los 3 primeros de cada sector
SELECT
    sector,
    puesto,
    ticker,
    nombre,
    ROUND(rentabilidad_anual * 100, 1) AS rentabilidad_anual_pct,
    ROUND(volatilidad_anual * 100, 1) AS riesgo_pct
FROM ranking
WHERE puesto <= 3
ORDER BY sector, puesto;

-- RESULTADO:
-- Se ve que el nivel de "ser el mejor" cambia mucho según el sector.
-- El líder de Tecnología da bastante más que el de Consumo básico.
-- También aparecen las dos clases de acciones de Alphabet (GOOG y
-- GOOGL), que son la misma empresa, por eso el índice tiene más de
-- 500 valores.

-- ==========================================================
-- CONSULTA 3
-- ==========================================================
-- Pregunta: ¿qué empresas lo hacen mejor que su propio sector
-- y además con menos riesgo?
--
-- No es lo mismo ser buena empresa que estar en un buen sector.
-- Aquí busco las que destacan dentro del suyo: ganan más que la
-- empresa típica de su sector y encima se mueven menos.
--
-- Para eso cruzo las dos tablas con un JOIN, usando la columna
-- sector, que es la que tienen en común.
-- ---------------------------------------------------------

SELECT
    e.ticker,
    e.nombre,
    e.sector,
    ROUND(e.rentabilidad_anual * 100, 1) AS empresa_rentabilidad,
    ROUND(s.rentabilidad_anual * 100, 1) AS sector_rentabilidad,
    ROUND(e.volatilidad_anual * 100, 1) AS empresa_riesgo,
    ROUND(s.volatilidad_anual * 100, 1) AS sector_riesgo
FROM metricas_empresas AS e
-- JOIN une las dos tablas emparejando las filas que tienen el mismo sector
JOIN metricas_sectores AS s
    ON e.sector = s.sector
-- Me quedo con las empresas que ganan más que su sector y se mueven menos
WHERE e.rentabilidad_anual > s.rentabilidad_anual
  AND e.volatilidad_anual < s.volatilidad_anual
ORDER BY e.rentabilidad_anual DESC;

-- RESULTADO:
-- Aquí salen empresas que destacan dentro de su sector, no solo
-- las que están en sectores que han ido bien.
-- Alphabet es la que más despega: da un 23 % cuando Comunicaciones
-- está en el 9,8 %. También aparecen empresas menos conocidas como
-- Trane Technologies o Cintas, que no salían en los rankings
-- generales porque quedaban tapadas por las tecnológicas.

-- ==========================================================
-- CONSULTA 4
-- ==========================================================
-- Pregunta: ¿en qué años era mejor invertir de golpe y en
-- cuáles poco a poco?
--
-- En Python saqué los 117 meses uno a uno, pero así cuesta
-- ver el patrón. Aquí los agrupo por año para ver en cuáles
-- gana cada estrategia.
-- La columna mes_inicio es un texto tipo "2016-01", así que
-- me quedo con los 4 primeros caracteres para sacar el año.
-- ---------------------------------------------------------

SELECT
    -- LEFT coge los primeros caracteres de un texto
    -- Con 4 me quedo con el año de "2016-01"
    LEFT(mes_inicio, 4) AS anio,
    COUNT(*) AS meses,
    -- SUM con CASE WHEN cuenta solo las filas que cumplen la condición
    SUM(CASE WHEN gana = 'Todo de golpe' THEN 1 ELSE 0 END) AS gana_de_golpe,
    SUM(CASE WHEN gana = 'Poco a poco' THEN 1 ELSE 0 END) AS gana_poco_a_poco,
    -- La diferencia media entre las dos estrategias ese año
    ROUND(AVG(diferencia), 0) AS diferencia_media
FROM simulaciones
GROUP BY anio
ORDER BY anio;

-- RESULTADO:
-- 2022 es el único año en el que gana invertir poco a poco
-- (7 meses de 12 y diferencia media negativa). Fue el año de la
-- caída por la subida de tipos.
-- 2021 y 2018 también tienen algunos meses, por las caídas de
-- finales de esos años.
-- En el resto de años gana invertir de golpe en los 12 meses.
-- Curiosamente 2020 es el año con más ventaja para invertir de
-- golpe (3.845 dólares de media), aunque fue el año de la pandemia:
-- la caída fue muy fuerte pero muy corta, y la recuperación rápida
-- benefició a quien ya tenía todo el dinero invertido.

-- ==========================================================
-- CONSULTA 5
-- ==========================================================
-- Pregunta: ¿cómo se reparten las empresas según su
-- rentabilidad y su riesgo?
--
-- Hasta ahora he mirado rentabilidad y riesgo por separado.
-- Aquí las junto y clasifico cada empresa en cuatro grupos,
-- usando como referencia el índice (15,3 % de rentabilidad
-- y 17,5 % de volatilidad).
--
-- Con CASE WHEN voy comprobando condiciones una a una y
-- asigno una etiqueta a cada empresa.
-- ---------------------------------------------------------

SELECT
    -- CASE WHEN funciona como un if: comprueba las condiciones en orden
    -- y se queda con la primera que se cumple
    CASE
        WHEN rentabilidad_anual >= 0.153 AND volatilidad_anual <= 0.175
            THEN '1. Gana más y arriesga menos'
        WHEN rentabilidad_anual >= 0.153 AND volatilidad_anual > 0.175
            THEN '2. Gana más pero arriesga más'
        WHEN rentabilidad_anual < 0.153 AND volatilidad_anual <= 0.175
            THEN '3. Gana menos pero arriesga menos'
        ELSE '4. Gana menos y arriesga más'
    END AS perfil,
    COUNT(*) AS empresas,
    ROUND(COUNT(*) / 462 * 100, 1) AS porcentaje,
    ROUND(AVG(rentabilidad_anual) * 100, 1) AS rentabilidad_media,
    ROUND(AVG(volatilidad_anual) * 100, 1) AS riesgo_medio
FROM metricas_empresas
GROUP BY perfil
ORDER BY perfil;

-- RESULTADO:
-- Solo aparecen dos de los cuatro grupos, y eso es lo más
-- interesante: NINGUNA de las 462 empresas tiene menos riesgo
-- que el índice (17,5 %). El riesgo medio de las empresas está
-- entre el 30 % y el 35 %, casi el doble.
--
-- Esto pasa porque el índice junta 500 empresas, así que las
-- subidas de unas compensan las bajadas de otras.
--
-- Además, 315 empresas (el 68 %) ganan menos que el índice y
-- encima con más riesgo.

-- ==========================================================
-- CONSULTA 6
-- ==========================================================
-- Preparo una tabla resumen con los datos principales del
-- proyecto, que son los que quiero enseñar en las tarjetas
-- de la primera página del dashboard de Power BI.
--
-- Uso UNION ALL para juntar varias consultas de una sola
-- fila en una única tabla de resultados.
-- ---------------------------------------------------------

SELECT 'Empresas analizadas' AS dato, COUNT(*) AS valor
FROM metricas_empresas

UNION ALL

SELECT 'Empresas que baten al índice', SUM(bate_al_indice)
FROM metricas_empresas

UNION ALL

SELECT '% que bate al índice', ROUND(SUM(bate_al_indice) / COUNT(*) * 100, 1)
FROM metricas_empresas

UNION ALL

SELECT 'Rentabilidad anual mediana (%)', ROUND(AVG(rentabilidad_anual) * 100, 1)
FROM metricas_empresas

UNION ALL

SELECT 'Meses en que gana invertir de golpe', SUM(CASE WHEN gana = 'Todo de golpe' THEN 1 ELSE 0 END)
FROM simulaciones

UNION ALL

SELECT 'Meses en que gana invertir poco a poco', SUM(CASE WHEN gana = 'Poco a poco' THEN 1 ELSE 0 END)
FROM simulaciones;