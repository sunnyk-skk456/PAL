-- cleanup
DROP TYPE "T_RESULTS";
DROP TABLE "SIGNATURE";
CALL "SYS"."AFLLANG_WRAPPER_PROCEDURE_DROP"('DEVUSER', 'P_ARIMA_FORECAST');
DROP TABLE "RESULTS";
DROP VIEW "V_RESULTS";

-- procedure setup
CREATE TYPE "T_RESULTS" AS TABLE ("ID" INTEGER, "PRICE" DOUBLE, "LOW80" DOUBLE, "HI80" DOUBLE, "LOW95" DOUBLE, "HI95" DOUBLE);
CREATE COLUMN TABLE "SIGNATURE" ("POSITION" INTEGER, "SCHEMA_NAME" NVARCHAR(256), "TYPE_NAME" NVARCHAR(256), "PARAMETER_TYPE" VARCHAR(7));
INSERT INTO "SIGNATURE" VALUES (1, 'DEVUSER', 'T_MODEL', 'IN');
INSERT INTO "SIGNATURE" VALUES (2, 'DEVUSER', 'T_PARAMS', 'IN');
INSERT INTO "SIGNATURE" VALUES (3, 'DEVUSER', 'T_RESULTS', 'OUT');

CALL "SYS"."AFLLANG_WRAPPER_PROCEDURE_CREATE"('AFLPAL', 'ARIMAFORECAST', 'DEVUSER', 'P_ARIMA_FORECAST', "SIGNATURE");

-- data setup
CREATE COLUMN TABLE "RESULTS" LIKE "T_RESULTS";
CREATE VIEW "V_RESULTS" AS
	SELECT 
		CASE WHEN a."ID" IS NOT NULL THEN a."ID" ELSE b."ID" END AS "ID", 
		a."PRICE",
		ROUND(b."PRICE",2) AS "PRICE_PREDICTED",
		ROUND(b."LOW80",2) AS "LOW80",
		ROUND(b."HI80",2) AS "HI80",
		ROUND(b."LOW95",2) AS "LOW95",
		ROUND(b."HI95",2) AS "HI95"
	 FROM "PAL"."STOCKS" a 
	 FULL JOIN "RESULTS" b ON (a."ID"=b."ID") 
	;

-- runtime
DROP TABLE "#PARAMS";
CREATE LOCAL TEMPORARY COLUMN TABLE "#PARAMS" LIKE "T_PARAMS";
INSERT INTO "#PARAMS" VALUES ('THREAD_NUMBER', 2, null, null);
INSERT INTO "#PARAMS" VALUES ('ForecastLength', 200, null, null);

TRUNCATE TABLE "RESULTS";

CALL "P_ARIMA_FORECAST" ("MODEL", "#PARAMS", "RESULTS") WITH OVERVIEW;

SELECT * FROM "RESULTS";
SELECT * FROM "V_RESULTS";
