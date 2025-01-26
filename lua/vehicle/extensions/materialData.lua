-- NOTE:
-- Not used

local M = {}

-- INFO:
-- This acts as a lookup table for various materials
-- It might be slow to create a table for each node every frame, to be investigated
local lut = {}

-- INFO:
-- units:
-- specificHeatCapacity : { C, J/(g degreesC) }
-- - for rubber, this changes by about 4% from 20C to 100C
-- specificHeatCapacityKgAt0DegC1Atm = J/((g degreesC)),
-- density : Kg/m3
-- gasConstant : J/Kg
-- hardness : relative : 1-10

local function testMaterial1()
	local material = {
		hysteresisFactor = 1,
		hardness = 8,
		elasticity = 1,
		specificHeatCapacityAtTemp = {{20, 1.982}, {100, 2.121}},
		density = 1000
	}
	return material
end
lut.testMaterial1 = testMaterial1

-- INFO: 
-- Air accounts for about 2% of the energy in the tyre, negligible
-- Some of these values are used to simplify the model
local function air()
	local material = {
		-- NOTE: this list is incomplete
		specificHeatCapacityAt0DegCAnd1AtmAnd0Humidity = 1.006,
		specificHeatCapacityMultPerDegC = 0.00008,
		-- Specific heat capacity doubles at 100% relative humidity
		relativeHumidity = 0.2, -- 1.0 = 100%
		specificHeatCapacityAddPerAbsoluteHumidity = 1884,
		gasConstant = 287
	}
	return material
end
lut.air = air

-- INFO: dealing with nitrogen is much easier than air
local function nitrogen()
	local material = {
		-- specificHeatCapacity changes less than 1% from 0C to 100C
		-- nitrogen doesn't hold moisture :)
		specificHeatCapacity = 1.04,
		gasConstant = 297
	}
	return material
end
lut.nitrogen = nitrogen

local function matRoadStandard()
	-- NOTE: 
	-- example
	local material = {
		hysteresisFactor = 1,
		hardness = 1,
		elasticity = 1,
		specificHeatCapacity = 1
	}
	return material
end
lut.matRoadStandard = matRoadStandard

local function getmaterial(material)
	if lut[material] then return lut[material]() end
	return matRoadStandard()
end

M.getmaterial = getmaterial
return M
