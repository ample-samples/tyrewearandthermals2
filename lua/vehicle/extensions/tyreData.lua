local M = {}

local function matRoadStandard()
	local material = {
		hysteresisFactor = 1,
		hardness = 1,
		elasticity = 1,
		specificHeatCapacity = 1
	}
	return material
end

local function getmaterial(material)
	-- NOTE:
	-- This will act as a lookup table for various materials
	local lut = {
		matRoadStandard = matRoadStandard
	}

	return lut[material]
end

M.getmaterial = getmaterial
return M
