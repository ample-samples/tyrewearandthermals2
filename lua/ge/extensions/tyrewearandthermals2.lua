local M = {}

local function setGroundModels()
	dump("getGroundModels called")
	local cmd = "TWT.groundModels = {"
	for k, v in pairs(core_environment.groundModels) do
		local name = tostring(k)
		if #name > 0 then
			cmd = cmd ..
					name ..
					" = { staticFrictionCoefficient = " ..
					v.cdata.staticFrictionCoefficient ..
					", slidingFrictionCoefficient = " .. v.cdata.slidingFrictionCoefficient .. " }, "
		end
	end
	cmd = cmd .. "debug = 0 };"
	local veh = be:getPlayerVehicle(0)
	if veh then veh:queueLuaCommand(cmd) end
end

local variablesById = {}

local brakeSetting = {}
local function onVehicleSpawned(vehID)
	brakeSetting = {}
	local vehicleData = core_vehicle_manager.getVehicleData(vehID)
	if not vehicleData then return end
	local vdata = vehicleData.vdata
	if not vdata then return end
	if not vdata.variables then vdata.variables = {} end
	local partConfig = be:getObjectByID(vehID).partConfig -- either serialized table or a pathname
	local tablePartConfig = jsonReadFile(partConfig) or deserialize(partConfig)
	-- dump(tablePartConfig)
	if tablePartConfig and tablePartConfig.vars and tablePartConfig.vars["$WheelCoolingDuctFront"] then
		brakeSetting[1] = tablePartConfig.vars["$WheelCoolingDuctFront"]
	end
	if tablePartConfig and tablePartConfig.vars and tablePartConfig.vars["$WheelCoolingDuctRear"] then
		brakeSetting[2] = tablePartConfig.vars["$WheelCoolingDuctRear"]
	end

	-- if brakeSetting ~= nil then
	-- 	brakeSetting = v.data.variables["$WheelCoolingDuct"].val
	-- end

	if not variablesById[vehID] then
		variablesById[vehID] = {
			["$WheelCoolingDuctFront"] = {
				name = "$WheelCoolingDuctFront",
				category = "Brakes",
				title = "Front Cooling ducts",
				description = "Controls the amount of air passing over the brake. 1%=Fully closed, 100%=Fully open",
				type = "range",
				unit = "%",

				min = 1,
				minDis = 1,
				max = 100,
				maxDis = 100,
				step = 1,
				stepDis = 1,
				default = 12,
				val = brakeSetting[1] or 12
			},
			["$WheelCoolingDuctRear"] = {
				name = "$WheelCoolingDuctRear",
				category = "Brakes",
				title = "Rear Cooling ducts",
				description = "Controls the amount of air passing over the brake. 1%=Fully closed, 100%=Fully open",
				type = "range",
				unit = "%",

				min = 1,
				minDis = 1,
				max = 100,
				maxDis = 100,
				step = 1,
				stepDis = 1,
				default = 12,
				val = brakeSetting[2] or 12
			}
		}
	else
		variablesById[vehID]["$WheelCoolingDuctFront"].val = brakeSetting[1] or 12
		variablesById[vehID]["$WheelCoolingDuctRear"].val = brakeSetting[2] or 12
	end

	tableMerge(vdata.variables, variablesById[vehID])
end

local function onSpawnCCallback(vehID)
	if not variablesById[vehID] then return end
	local _, configDataIn = debug.getlocal(3, 3)
	if type(configDataIn) ~= "string" or configDataIn:sub(1, 1) ~= "{" then return end
	local desirialized = deserialize(configDataIn)

	if type(desirialized) ~= "table" or type(desirialized.vars) ~= "table" then return end

	for name, _ in pairs(variablesById[vehID]) do
		if desirialized.vars[name] then
			variablesById[vehID][name].val = desirialized.vars[name]
		else
			variablesById[vehID][name].val = variablesById[vehID][name].default or variablesById[vehID][name].val
		end
	end
end

local function setBrakeSettings()
	local brakeSettings = {
		core_vehicle_manager.getPlayerVehicleData().vdata.variables["$WheelCoolingDuctFront"].val or 12,
		core_vehicle_manager.getPlayerVehicleData().vdata.variables["$WheelCoolingDuctRear"].val or 12
	}
	local cmd = "TWT.brakeSettings = {" .. brakeSettings[1] .. ", " .. brakeSettings[2] .. "};"
	local veh = be:getPlayerVehicle(0)
	if veh then veh:queueLuaCommand(cmd) end
end

local function onVehicleDestroyed(vehID)
	variablesById[vehID] = nil
	brakeSetting = {}
end

local function setTyreWearAndThermalVariables()
	local active_parts = core_vehicle_manager.getPlayerVehicleData(be:getPlayerVehicle(0)).vdata.activeParts
	for _, active_part in pairs(active_parts) do
		local slotType = active_part["slotType"]
		if type(slotType) == "string" and string.sub(slotType, 1, 6) == "tire_F" then
			local cmd = "TWT.tyreVarsFront = " .. serialize(active_part["twatVarsGeneral"]) .. ";"
			local veh = be:getPlayerVehicle(0)
			if veh then veh:queueLuaCommand(cmd) end
		elseif type(slotType) == "string" and string.sub(slotType, 1, 5) == "tire_" then
			local cmd = "TWT.tyreVarsRear = " .. serialize(active_part["twatVarsGeneral"]) .. ";"
			local veh = be:getPlayerVehicle(0)
			if veh then veh:queueLuaCommand(cmd) end
		end
	end
end

M.setBrakeSettings = setBrakeSettings
M.setGroundModels = setGroundModels

M.onSettingsChanged = onSettingsChanged
M.onVehicleSpawned = onVehicleSpawned
M.onSpawnCCallback = onSpawnCCallback
M.onVehicleDestroyed = onVehicleDestroyed
M.setTyreWearAndThermalVariables = setTyreWearAndThermalVariables

return M
