local M = {}
groundModels = {} -- made global so GELua can access and change it
env_temp = 20
brakeSettings = { 12, 12 }
tyreVarsFront = nil
tyreVarsRear = nil

extensions.load("ThermalWearTyre")
extensions.load("standardiseTyreNames")

local useTyre = ThermalWearTyre
tyres = {} -- left global so other mods can interact with it

function coldResetAllTyres()
	for _, tyre in pairs(tyres) do
		tyre:coldReset()
	end
end

function hotResetAllTyres()
	for _, tyre in pairs(tyres) do
		tyre:hotReset()
	end
end

local function setEnvironmentTemperature()
	if powertrain ~= nil and powertrain.currentEnvTemperature ~= nil then
		env_temp = powertrain.currentEnvTemperature - 273.15
	end
end

local function getGroundModelData(id)
	local materials, materialsMap = particles.getMaterialsParticlesTable()
	local matData = materials[id] or {}
	local name = matData.name or "DOESNT EXIST"
	local data = groundModels[name] or { staticFrictionCoefficient = 1, slidingFrictionCoefficient = 1 }
	return name, data
end

local function getWheelCamberToGround(wheelID)
	local vectorUp = obj:getDirectionVectorUp()
	local localVectNode1 = obj:getNodePosition(wheels.wheelRotators[wheelID].node1)
	local localVectNode2 = obj:getNodePosition(wheels.wheelRotators[wheelID].node2)
	local vectorWheelForward = (localVectNode2 - localVectNode1):cross(vectorUp)
	local vectorWheelUp = vectorWheelForward:cross(localVectNode2 - localVectNode1)
	local surfaceNormal = mapmgr.surfaceNormalBelow(
		obj:getPosition() + (localVectNode2 + localVectNode1) / 2 -
		wheels.wheelRotators[wheelID].radius * vectorWheelUp:normalized(), 0.1
	)
	local camber = 90 - math.deg(math.acos((localVectNode2 - localVectNode1):normalized():dot(surfaceNormal:normalized())))
	return camber
end

local function generateStream(tyres)
	local stream = { data = {} }
	for _, tyre in pairs(tyres) do
		table.insert(stream.data, {
			name = tyre.name,
			temp = { tyre.temperature, tyre.temperature, tyre.temperature, tyre.temperature },
			working_temp = 85,
			condition_zones = tyre.condition_zones,
			camber = tyre.camber_to_ground,
		})
	end
	return stream
end

local dummyStream = { data = {
	name = "not a real tyre",
	temp = { env_temp, env_temp },
	working_temp = env_temp,
	condition_zones = {100},
	camber = 0
} }

local function getWheelsAndNamesPositions(wheels)
	-- INFO: unused, will be used to standardise tyre names and
	-- their position relative to the vehicle and its orentation
	-- so the UI can display them
	local wheelNamesAndPositions = {}
	for i,v in pairs(wheels.wheelRotators) do
		local localVectNode1 = obj:getNodePosition(wheels.wheelRotators[i].node2)
		local wheelName = wheels.wheelRotators[i].name
		wheelNamesAndPositions[wheelName] = localVectNode1
	end
	return wheelNamesAndPositions
end

local oneSecondTimer = 0
local function updateGFX(dt)
	-- INFO: unused, will be used to standardise tyre names and
	-- their position relative to the vehicle and its orentation
	-- so the UI can display them
	-- local vehicleVectorForward = obj:getDirectionVector()
	-- local wheelNamesAndPositions = getWheelsAndNamesPositions(wheels)
	-- local standarisedNames = standardiseTyreNames.standardise(wheelNamesAndPositions, vehicleVectorForward)

	oneSecondTimer = oneSecondTimer + dt
	if wheels == nil or wheels.wheelRotators == nil or wheels.wheelRotators[0] == nil then
		-- if the above statement is true, the vehicle most likely doesn't have tyres
		gui.send("tyrewearandthermals2", dummyStream)
		return
	end


	for i, tyre in pairs(tyres) do
		local groundModelName, groundModel = getGroundModelData(wheels.wheelRotators[i].contactMaterialID1)
		local wheelload = wheels.wheelRotators[i].downForce
		local wheelname = wheels.wheelRotators[i].name
		tyre:update(
			dt,
			getWheelCamberToGround(i),
			{
				env_temp = env_temp,
				load = wheels.wheelRotators[i].downForce,
				angularVel = wheels.wheelRotators[i].angularVelocity,
				propulsionTorque = wheels.wheelRotators[i].propulsionTorque,
				brakingTorque = wheels.wheelRotators[i].brakingTorque,
				lastTorque = wheels.wheelRotators[i].lastTorque
			})
	end

	if oneSecondTimer >= 1 then
		for _, tyre in pairs(tyres) do
			hotResetAllTyres()
		end
		oneSecondTimer = oneSecondTimer % 1 -- Loops every 1 seconds
	end

	local stream = generateStream(tyres)
	gui.send("tyrewearandthermals2", stream)
end

local function generateModTyres()
	for i, wheel in pairs(wheels.wheelRotators) do
		tyres[wheel.wheelID] = useTyre.new(wheel.name, wheel.wheelID, wheel.wheelDir,
			{ totalWeight = 10, temp = 85, wear_rate = 0.005, wheel.tireWidth })
	end
end

local function onReset()
	setEnvironmentTemperature()
	generateModTyres()

	obj:queueGameEngineLua("if tyrewearandthermals2 then tyrewearandthermals2.setBrakeSettings() end")
	obj:queueGameEngineLua("if tyrewearandthermals2 then tyrewearandthermals2.setTyreWearAndThermalVariables() end")
end

local function onInit()
	setEnvironmentTemperature()
	generateModTyres()

	obj:queueGameEngineLua("if tyrewearandthermals2 then tyrewearandthermals2.setGroundModels() end")
	obj:queueGameEngineLua("if tyrewearandthermals2 then tyrewearandthermals2.setBrakeSettings() end")
	obj:queueGameEngineLua("if tyrewearandthermals2 then tyrewearandthermals2.setTyreWearAndThermalVariables() end")
end

M.updateGFX = updateGFX
M.onInit = onInit
M.onReset = onReset
return M
