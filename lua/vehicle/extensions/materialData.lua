-- NOTE:
-- Not used

local M = {}

-- INFO:
-- This acts as a lookup table for various materials
local lut = {}

-- INFO:
-- units:
-- specificHeatCapacity : { C, J/(g degreesC) }
-- - this changes by about 4% from 20C to 100C
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
local function air()
	local material = {
		specificHeatCapacity = 1.005,
		gasConstant = 287
	}
	return material
end
lut.air = air

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
