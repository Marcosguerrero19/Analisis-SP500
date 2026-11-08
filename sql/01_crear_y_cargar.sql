-- =========================================================
-- 02_cargar_datos.sql
-- Cargo los CSV que he generado con Python en las tablas
-- =========================================================

USE sp500;

-- Vacío las tablas por si ya teníatn algo
-- TRUNCATE borra todas las filas pero deja la tabla creada
TRUNCATE TABLE metricas_empresas;
TRUNCATE TABLE metricas_sectores;
TRUNCATE TABLE simulaciones;

-- Cargo las métricas de cada empresa
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/metricas_empresas.csv'
INTO TABLE metricas_empresas
CHARACTER SET utf8mb4                   -- para que las tildes se lean bien
FIELDS TERMINATED BY ','                -- las columnas van separadas por comas
OPTIONALLY ENCLOSED BY '"'              -- algunos textos vienen entre comillas
LINES TERMINATED BY '\n'                -- cada fila es una línea
IGNORE 1 ROWS;                          -- me salto la primera fila, que son los títulos

-- Cargo las métricas de cada sector
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/metricas_sectores.csv'
INTO TABLE metricas_sectores
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Cargo las simulaciones
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/simulaciones.csv'
INTO TABLE simulaciones
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Compruebo cuántas filas ha cargado cada tabla
SELECT 'metricas_empresas' AS tabla, COUNT(*) AS filas FROM metricas_empresas
UNION ALL
SELECT 'metricas_sectores', COUNT(*) FROM metricas_sectores
UNION ALL
SELECT 'simulaciones', COUNT(*) FROM simulaciones;



-- Desactivo la protección de Workbench que impide modificar muchas filas a la vez
SET SQL_SAFE_UPDATES = 0;

-- Paso los textos True y False a 1 y 0
UPDATE metricas_empresas
SET bate_al_indice = CASE WHEN bate_al_indice = 'True' THEN '1' ELSE '0' END;

-- Vuelvo a activar la protección
SET SQL_SAFE_UPDATES = 1;

-- Ahora que son 1 y 0, cambio la columna a tipo booleano
ALTER TABLE metricas_empresas MODIFY COLUMN bate_al_indice BOOLEAN;

-- Compruebo cuántas empresas baten al índice
SELECT bate_al_indice, COUNT(*) AS empresas
FROM metricas_empresas
GROUP BY bate_al_indice;