--Depending on the day some restaurants might be open or not, thus indicating the day is important
--Additionally the set day also allows us to calculate who will supply who (different days, different suppliers)     
--Terminology SDB: Supply Database, DDB: Demand Database, RPDB: Restaurant Preference Database. 
--Feel free to use and edit any of the code made by this newbie, i will upload the structure as a picture later .

--Day to calculate (1 to 7, days of the week) ▼ 
WITH "Restaurants" AS (
	SELECT a."RestaurantID", a."Day"
	FROM "Restaurant SET2" a
		WHERE a."Day" = 5
),
--This is where the data extraction starts
"PossibleSupply" AS (
	SELECT
	r."Day",
	b."RestaurantID", 
	b."Available",
	CAST(i."RemainingSupply" AS REAL) AS "RemainingSupply" 
		FROM "Restaurant SDB" b
	INNER JOIN 
		"Restaurants" r ON b."RestaurantID" = r."RestaurantID"
	INNER JOIN
		"SupplyState" i ON b."RestaurantID" = i."RestaurantID"
), 
"RestNameJoin" AS (
	SELECT
	c."Day",
	c."RestaurantID", 
	d."Restaurant",
	c."Available",
	c."RemainingSupply"
		FROM "PossibleSupply" c
			INNER JOIN
				"Restaurant SDB" d ON c."RestaurantID" = d."RestaurantID"
),
"Preference" AS (
	SELECT 
	f."Day",
	e."Office",
	f."RestaurantID", 
	f."Restaurant", 
	f."Available",
	f."RemainingSupply", 
	e."Rank"
		FROM "RestNameJoin" f
			INNER JOIN 
				"Office RPDB" e ON f."Restaurant" = e."Restaurant"
),
"FinalQuery" AS (
	SELECT
	g."Day",
	h."OfficeID",
	g."RestaurantID", 
	g."Available",
	h."Demand", 
	g."RemainingSupply",
	g."Rank"
		FROM "Preference" g
			INNER JOIN 
				"Office DDB" h ON g."Office" = h."Office" 
),
--Math starts here (We calculate with what we extracted)
"K_factor" AS (
	SELECT *,
	       (1.0 / "Rank")
				AS "K_n"
	FROM "FinalQuery"
),
"D_factor" AS (
	SELECT *,
	       (
		   "Demand" * 1.0 / MAX("Demand") OVER ()
	       ) 
				AS "D"
	FROM "K_factor"
),
"S_factor" AS (
	SELECT *,
			(
			"RemainingSupply" * 0.7 / MAX("RemainingSupply") OVER()
			)
				AS "S"
	FROM "D_Factor"
				),
"Score" AS (
	SELECT 
		"Day",
		"OfficeID",
		"RestaurantID",
		"Available",
		"Demand",
		"RemainingSupply",
		"Rank",
			(
				ROUND(
					"K_n" * "D" * "S"
					,3)
			)
				AS "Score"
		FROM "S_factor"
		),
"Winner" AS( 
	SELECT * 
		FROM "Score"
			WHERE "RemainingSupply" > 0
			AND "Demand" > 0
	ORDER BY "Score" DESC
	LIMIT 1
	)
INSERT INTO "AllocationResults" (
    "Day",
    "RestaurantID",
    "OfficeID",
    "Allocated"
)
SELECT
	"Day",
    "RestaurantID",
    "OfficeID",
    MIN("RemainingSupply", "Demand")
FROM "Winner"
WHERE EXISTS (Select 1 FROM "Winner")
	ORDER BY "Score" DESC
		LIMIT 1
;
UPDATE "SupplyState"
	SET "RemainingSupply" = (
		SELECT b."Available" 
		FROM "Restaurant SDB" b
			WHERE b."RestaurantID" = "SupplyState"."RestaurantID"
			)
		WHERE(
			SELECT SUM(c."Demand")
			FROM "Office DDB" c
			) <= 0;
UPDATE "Office DDB"
	SET "Demand" = (
		SELECT b."Demand"
		FROM "Office DDB Base" b
			WHERE b."OfficeID" = "Office DDB"."OfficeID"
)
	WHERE (
		SELECT SUM("Demand")
		FROM "Office DDB"
	) <= 0;
SELECT 
    a."Day",
    a."RestaurantID",
    a."OfficeID",
    a."Allocated",
    (SELECT SUM("Demand") FROM "Office DDB") AS "Pending"
FROM "AllocationResults" a
ORDER BY a."Iteration" DESC
;
