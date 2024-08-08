local M = {}
groundModels = {} -- made global so GELua can access and change it
env_temp = 20     -- default value
brakeSettings = { 12, 12 }
tyreVarsFront = nil
tyreVarsRear = nil

extensions.load("wearThermalTyre")

local useTyre = WearThermalTyre
local tyres = {}

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

local function temp_generateStreamFourTyres(tyre)
	local stream = { data = {} }
	for _, tyre in pairs(tyres) do
		table.insert(stream.data, {
			name = tyre.name,
			temp = { tyre:getTemperature(), tyre:getTemperature(), tyre:getTemperature(), tyre:getTemperature() },
			working_temp = 85,
			condition = 100,
			camber = tyre.camber_to_ground,
		})
	end
	return stream
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

local oneSecondTimer = 1
local function updateGFX(dt)
	oneSecondTimer = oneSecondTimer + dt
	local groundModelName, groundModel = getGroundModelData(wheels.wheelRotators[0].contactMaterialID1)

	for i, tyre in pairs(tyres) do
		tyre:update(dt, getWheelCamberToGround(i) * tyre.wheelDir, env_temp)
	end


	if oneSecondTimer >= 1 then
		obj:queueGameEngineLua("if tyrewearandthermals2 then tyrewearandthermals2.setEnv_temp() end")
		for _, tyre in pairs(tyres) do
			hotResetAllTyres()
		end
		oneSecondTimer = oneSecondTimer % 1 -- Loops every 1 seconds
	end

	local stream = temp_generateStreamFourTyres(useTyre)
	gui.send("tyrewearandthermals2", stream)
end

local function onReset()
	for i, wheel in pairs(wheels.wheelRotators) do
		tyres[wheel.wheelID] = useTyre.new(wheel.name, wheel.wheelID, wheel.wheelDir, 10, 85, 0.05)
	end

	obj:queueGameEngineLua("if tyrewearandthermals2 then tyrewearandthermals2.setEnv_temp() end")
	obj:queueGameEngineLua("if tyrewearandthermals2 then tyrewearandthermals2.setBrakeSettings() end")
	obj:queueGameEngineLua("if tyrewearandthermals2 then tyrewearandthermals2.setTyreWearAndThermalVariables() end")
end

local function onInit()
	for i, wheel in pairs(wheels.wheelRotators) do
		tyres[wheel.wheelID] = useTyre.new(wheel.name, wheel.wheelID, wheel.wheelDir, 10, 85, 0.05)
	end

	obj:queueGameEngineLua("if tyrewearandthermals2 then tyrewearandthermals2.setGroundModels() end")
	obj:queueGameEngineLua("if tyrewearandthermals2 then tyrewearandthermals2.setEnv_temp() end")
	obj:queueGameEngineLua("if tyrewearandthermals2 then tyrewearandthermals2.setBrakeSettings() end")
	obj:queueGameEngineLua("if tyrewearandthermals2 then tyrewearandthermals2.setTyreWearAndThermalVariables() end")
end

M.updateGFX = updateGFX
M.onInit = onInit
M.onReset = onReset
return M
