M = {}
-- INFO: unused
local function standardise(tyres, vehicleOrientation)
	-- take a list of tyres, in the form:
	-- - tyres = { "FR" = vec3{ x = float, y = float, z = float }, ... }
	-- z is up direction and can be ignored
	--
	-- returns a dictionary of "name" = "coordinate" in the form:
	-- - standardisedTyreNames = { "FR" = {0,1}, "FL" = {0,0}, "RR" = {1,1}, "RL2" = {1,-1}, ... }
	-- where "coordinate" will be used as blocks to define the position of the wheel for the UI.
	-- Visually:
	--
	--		  FL FR			  -->        0,0  0,1
	--	RL2 RL RR RR2   -->  1,-1  1,0  1,1  1,2
	--

	-- the xy portion of a tyre position can be thought of as a vector relative to 
	-- the vehicle's location, however its rotation is relative to the world, not the vehicle.
	-- Because of this, it must be rotated by vehicle's orientation relative to world space.
	local vehicleOrientation2D = { x = vehicleOrientation.x, y = vehicleOrientation.y }
	local tyresPos2D = {}
	for tyreName, tyrePos in pairs(tyres) do
		tyresPos2D[tyreName] = { x = tyrePos.x, y = tyrePos.y}
	end
end




M.standardise = standardise
return M
