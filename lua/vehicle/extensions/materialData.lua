-- NOTE:
-- Not used

local M = {}

-- INFO:
-- units:
-- specificHeatCapacity : J/g degreesC
-- density : Kg/m3
-- gasConstant : J/Kg
-- hardness : relative : 1-10

local function testMaterial1()
	local material = {
		hysteresisFactor = 1,
		hardness = 8,
		elasticity = 1,
		specificHeatCapacity = 1,
		density = 1000
	}
	return material
end

local function air()
	local material = {
		specificHeatCapacity = 1.005,
		gasConstant = 287
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
	if lut[material] then return lut[material]() end

	return matRoadStandard()
end

M.getmaterial = getmaterial
return M
