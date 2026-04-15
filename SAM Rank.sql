--Calculation of the consumption rates--
DROP TABLE IF EXISTS "Office RPDB";
	CREATE TABLE "Office RPDB" AS 
		WITH "消費計算" AS (
		SELECT 
			"オフィス",
			"施設",
			sum("納品") 
				as "納品合計", 1- (
			sum("残数") *1.0 /  sum("納品") )
				 as  "消費率"
		FROM n2025_2026 
			WHERE "日付" 
				BETWEEN date('now','-6 months') AND date('now')		
--This is the date where interventions from the department start--
		GROUP BY 1,2
		HAVING sum("納品") > 15
		)
--Ranking of the rates--
		SELECT 
			"オフィス" AS "Office", 
			"施設" AS "Restaurant", 
			"納品合計",
			"消費率",
			DENSE_RANK() OVER (
				PARTITION BY "オフィス" 
				ORDER BY 
					COALESCE("消費率",0) DESC) 
			AS "Rank"
		FROM "消費計算";