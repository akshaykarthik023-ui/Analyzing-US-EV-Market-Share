Select *
FROM vehicle_data;

ALTER TABLE vehicle_data
CHANGE COLUMN `Plug-In Hybrid Electric (PHEV)` PHEV int,
CHANGE COLUMN `Compressed Natural Gas (CNG)` CNG int,
CHANGE COLUMN `Electric (EV)` EV int,
CHANGE COLUMN `Unknown Fuel` Fuel_notknown int,
CHANGE COLUMN `Hybrid Electric (HEV)` HEV int,
CHANGE COLUMN `Ethanol/Flex (E85)` E85 int;

/*  Data Cleaning
* There were no missing values,No null values,One column was full of zero's so it is irrelevant.
* Data types were consistant,Text values were already consistant.
*There were issues with column names as some words in column names were reserved keywords
  of MYSQL.
*/

-- Calculate the percentage of EVs, PHEVs, HEVs, and Gasoline vehicles for each state.
-- Identify the top 5 states with the highest EV adoption rate (EVs as a % of all registered vehicles).

DROP TEMPORARY TABLE IF EXISTS tempo_table;
CREATE TEMPORARY TABLE tempo_table AS
Select State,
		ROUND(((EV/Total_vehicles_sold) * 100),2) AS EV_pct,
        ROUND(((PHEV/Total_vehicles_sold) * 100),2) AS PHEV_pct,
        ROUND(((HEV/Total_vehicles_sold) * 100),2)AS HEV_pct,
        ROUND(((Gasoline/Total_vehicles_sold) * 100),2)AS Gasoline_pct,
        ROUND(((Biodiesel/Total_vehicles_sold) * 100),2)AS Biodiesel_pct,
        ROUND(((E85/Total_vehicles_sold) * 100),2)AS Ethanol_pct,
        ROUND(((Hydrogen/Total_vehicles_sold) * 100),2)AS Hydrogen_pct,
		Total_vehicles_sold
From (
Select *,
	(COALESCE(EV, 0) + 
            COALESCE(PHEV, 0) + 
            COALESCE(HEV, 0) + 
            COALESCE(Biodiesel, 0) + 
            COALESCE(E85, 0) + 
            COALESCE(CNG, 0) + 
            COALESCE(Propane, 0) + 
            COALESCE(Hydrogen, 0) + 
            COALESCE(Methanol, 0) + 
            COALESCE(Gasoline, 0) + 
            COALESCE(Diesel, 0) + 
            COALESCE(Fuel_notknown, 0)) AS Total_vehicles_sold
 From vehicle_data
 )AS T
 ORDER BY EV_pct DESC;

-- Used COALESCE keyword to treat any null fuel count as zero,just for added security even though none were found.
-- Top 5 states with highest EV adoption rate : California(3.41%),District of Columbia(2.60%),Hawaii(2.37%),Washington(2.23%),Nevada(1.85%)



-- Compare EV adoption in California vs. other large states (e.g., Texas, Florida, New York).
    
-- conditional aggregation

SELECT	
    MAX(CASE WHEN State = 'California' THEN EV_pct END) AS California_evpct,
    SUM(CASE WHEN State IN ('Texas','Florida','New York') THEN EV_pct ELSE 0 END) AS Big_states_evpct
FROM tempo_table;
    

    
-- California(3.41%) ,other big states like Texas(0.89%),Florida(1.37%),New York(1.16%),Ohio(0.49%),Pennsylvania(0.69%),Illinois(0.99%) are far behind.
-- Even if ev adoption of all the other 4 big states like Texas,Florida,New York are combined it is almost the same as californias ev adoption.


-- Highlight which alternative fuels (biodiesel, ethanol, hydrogen) have meaningful presence vs. niche usage.

-- Used 1.0%(1.0% was chosen as a guess,because no additional information was available in the dataset.)as a Threshold for categorizing whether meaningful or niche.

SELECT State,
	Biodiesel_pct,
	(CASE WHEN Biodiesel_pct >= 1.0 THEN 'Meaningful Presence' ELSE 'Niche' END) AS Biodiesel,
    Ethanol_pct,
    (CASE WHEN Ethanol_pct >= 1.0 THEN 'Meaningful Presence' ELSE 'Niche' END)AS Ethanol,
    Hydrogen_pct,
    (CASE WHEN Hydrogen_pct >= 1.0 THEN 'Meaningful Presence' WHEN Hydrogen_pct = 0.0 THEN 'No Sale' ELSE 'Niche' END)AS Hydrogen
FROM tempo_table;

/*  Ethanol has a meaningful presence in all states.
    Hydrogen is niche in one state(California) and has no sale in other states.
    Biodiesels sales vary across states and strongest in Montana.
*/

