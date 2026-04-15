--Names have been edited to make it more understandable 
--and avoid exposing any undesired information.

--Calculation of the consumption rates--
DROP TABLE IF EXISTS "Office RPDB";
	CREATE TABLE "Office RPDB" AS 
		WITH "Consumption Total" AS (
		SELECT 
			"Office",
			"Restaurant",
			sum("Supply") 
				as "Supply Total", 1- (
			sum("Unconsumed") *1.0 /  sum("Supply") )
				 as  "Consumption Ratio"
		FROM salesrecords 
			WHERE "Date" 
				BETWEEN date('now','-6 months') AND date('now')		
		GROUP BY 1,2
		HAVING sum("Supply") > 15
		)
--Ranking of the rates--
		SELECT 
			"Office", 
			"Restaurant", 
			"Total Supply",
			"Consumption Rate",
			DENSE_RANK() OVER (
				PARTITION BY "Office" 
				ORDER BY 
					COALESCE("Consumtpion Rate",0) DESC) 
			AS "Rank"
		FROM "Consumption Total";
