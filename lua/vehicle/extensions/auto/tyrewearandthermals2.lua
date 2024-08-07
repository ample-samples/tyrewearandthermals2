local M = {}
groundModels = {} -- made global so GELua can access and change it
env_temp = 20     -- default value
brakeSettings = { 12, 12 }
tyreVarsFront = nil
tyreVarsRear = nil

local Tyre = ThermalWearTyre
local newTyre = Tyre.new(85, 10, 0, 0.05)


local function getGroundModelData(id)
	local materials, materialsMap = particles.getMaterialsParticlesTable()
	local matData = materials[id] or {}
	local name = matData.name or "DOESNT EXIST"
	local data = groundModels[name] or { staticFrictionCoefficient = 1, slidingFrictionCoefficient = 1 }
	return name, data
end

local oneSecondTimer = 1
local function updateGFX(dt)
	oneSecondTimer = oneSecondTimer + dt
	-- local groundModelName, groundModel = getGroundModelData(wheels.wheelRotators[0].contactMaterialID1)

	newTyre:updateTemperature(env_temp)
	local stream = { data = {} }
	table.insert(stream.data, {
		name = "FR",
		temp = { newTyre:getTemperature(), newTyre:getTemperature(), newTyre:getTemperature(), newTyre:getTemperature() },
		working_temp = 85,
		condition = 100,
		camber = 0,
	})

	gui.send("tyrewearandthermals2", stream)

	if oneSecondTimer >= 1 then
		obj:queueGameEngineLua("if tyrewearandthermals2 then tyrewearandthermals2.setEnv_temp() end")
		oneSecondTimer = oneSecondTimer % 1 -- Loops every 1 seconds
	end
end

local function onReset()
	obj:queueGameEngineLua("if tyrewearandthermals2 then tyrewearandthermals2.setGroundModels() end")
	obj:queueGameEngineLua("if tyrewearandthermals2 then tyrewearandthermals2.setEnv_temp() end")
	obj:queueGameEngineLua("if tyrewearandthermals2 then tyrewearandthermals2.setBrakeSettings() end")
	obj:queueGameEngineLua("if tyrewearandthermals2 then tyrewearandthermals2.setTyreWearAndThermalVariables() end")
end

local function onInit()
	obj:queueGameEngineLua("if tyrewearandthermals2 then tyrewearandthermals2.setGroundModels() end")
	obj:queueGameEngineLua("if tyrewearandthermals2 then tyrewearandthermals2.setEnv_temp() end")
	obj:queueGameEngineLua("if tyrewearandthermals2 then tyrewearandthermals2.setBrakeSettings() end")
	obj:queueGameEngineLua("if tyrewearandthermals2 then tyrewearandthermals2.setTyreWearAndThermalVariables() end")
end

M.updateGFX = updateGFX
M.onInit = onInit
M.onReset = onReset
return M
