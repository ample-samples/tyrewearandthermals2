-- NOTE:
-- Not used

local M = {}

local function testMaterial1()
	local material = {
		hysteresisFactor = 1,
		hardness = 1,
		elasticity = 1,
		specificHeatCapacity = 1
	}
	return material
end

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

local function getmaterial(material)
	-- INFO:
	-- This acts as a lookup table for various materials
	local lut = {
		matRoadStandard = matRoadStandard,
		testMaterial1 = testMaterial1
	}

	return lut[material]
end

M.getmaterial = getmaterial
return M
