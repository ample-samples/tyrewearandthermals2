local function min_or_zero(x, min)
	if x < min then return 0 else return x end
end

local wear_min = 30

Tyre = {
	type = "Tyre",
	name = "",
	wheelID = 0,
	totalWeight = 10,
	camber_to_ground = 0,
	wheelDir = 1,
	load = 0,
	lastSlip = 0,
	tyreWidth = 1
}

ThermalWearTyre = {
	type = "ThermalWearTyre",
	temperature = 85,
	wear_rate = 0.01,
	condition_zones = { 100, 100, 100, 100 }
}

WearTyre = {
	type = "WearTyre",
	condition_zones = { 100, 100, 100 },
	wear_rate = 0.01
}

-- INFO: constructor
function Tyre.new(name, wheelID, wheelDir)
	local self = setmetatable({}, Tyre)

	self.wheelDir = wheelDir
	self.name = name
	self.wheelID = wheelID

	return self
end

-- INFO: `p` is an object containing wheel data
function Tyre:update(dt, camber_to_ground, tyreParams)
	self:setCamberToGround(camber_to_ground)
	return self
end

function Tyre:setCamberToGround(camber_to_ground)
	self.camber_to_ground = camber_to_ground * self.wheelDir
	return self
end

function ThermalWearTyre:setCamberToGround(camber_to_ground)
	self.camber_to_ground = camber_to_ground * self.wheelDir
	return self
end

function Tyre:reset()
	return self
end

function Tyre.__index(table, key)
	-- INFO: if `Tyre:hotReset` or `Tyre:coldReset` is called, it will call `Tyre:reset` instead
	if key == "coldReset" or key == "hotReset" then
		return Tyre["reset"]
	end
	return Tyre[key]
end

function WearTyre.new(name, wheelID, wheelDir, tyreParams)
	local self = setmetatable({}, WearTyre)

	self.wheelDir = wheelDir
	self.name = name
	self.wheelID = wheelID
	self.condition_zones = { 100, 100, 100 }
	self.wear_rate = tyreParams.wear_rate

	return self
end

function WearTyre:update(dt, camber_to_ground, tyreParams)
	local load = tyreParams.load
	local angular_vel = tyreParams.angularVel * self.wheelDir
	local propulsionTorque = tyreParams.propulsionTorque * self.wheelDir
	self:setCamberToGround(camber_to_ground)
	for i, zone in pairs(self.condition_zones) do
		-- INFO: ADDITIONAL THINGS WHICH AFFECT WEAR
		-- Contact pressure
		-- Slip * load
		local wear_amount = math.abs(angular_vel * (propulsionTorque - tyreParams.brakingTorque))
		self.condition_zones[i] = zone - min_or_zero(wear_amount, wear_min) * self.wear_rate / 1000000
		self.condition_zones[i] = math.max(self.condition_zones[i], 0)
	end
	return self
end

function WearTyre:reset()
	self.condition_zones = { 100, 100, 100 }
	return self
end

function WearTyre.__index(table, key)
	-- INFO: if `WearTyre:hotReset` or `WearTyre:coldReset` is called, it will call `WearTyre:reset` instead
	if key == "coldReset" or key == "hotReset" then
		return Tyre["reset"]
	end
	return WearTyre[key] or Tyre[key]
end

-- INFO: constructor
function ThermalWearTyre.new(name, wheelID, wheelDir, tyreParams)
	local self = setmetatable({}, ThermalWearTyre)

	self.name = name
	self.wheelID = wheelID
	self.wheelDir = wheelDir
	self.totalWeight = tyreParams.weight
	self.surfaceEnergies = {}
	self.zoneCount = 10
	self.condition_zones = {}
	self.temperatures = { l1 = {}, l2 = {}, sidewall = {} }
	self.idealTemp = tyreParams.idealTemp

	local startingTemp = TWT.env_temp
	if tyreParams.isPreheated then
		startingTemp = tyreParams.idealTemp
	end

	-- NOTE: maybe change temp zones to energy zones in future?
	for i = 1, self.zoneCount, 1 do
		self.condition_zones[i] = 100
		self.temperatures.l1[i] = startingTemp
		self.temperatures.l2[i] = startingTemp
	end
	self.temperatures.sidewall.left = startingTemp
	self.temperatures.sidewall.right = startingTemp
	self.temperatures.l3 = startingTemp
	self.temperatures.l4 = startingTemp
	self.temperatures.l5 = startingTemp
	self.temperatures.l6 = startingTemp
	self.temperatures.rim = startingTemp
	self.temperatures.innerAir = startingTemp
	return self
end

function ThermalWearTyre:setTemperature(i, temp)
	self.temperatures.l1[i] = temp
	return self
end


-- INFO: temporary example
function ThermalWearTyre:update(dt, camber_to_ground, tyreParams)
	self:setCamberToGround(camber_to_ground)
	self.load = tyreParams.load
	for i=1, self.zoneCount do
		local currentCondition = self.condition_zones[i] 
		self.condition_zones[i] = currentCondition - (currentCondition - self.wear_rate) * i * dt / 10
	end
	for i=1, self.zoneCount do
		self.temperatures.l1[i] = self.temperatures.l1[i] - 40 * i * dt / 10
		self.temperatures.l2[i] = self.temperatures.l2[i] - 40 * i * dt / 10
	end
	self.temperatures.sidewall.left = self.temperatures.sidewall.left - 40 * dt / 10
	self.temperatures.sidewall.right = self.temperatures.sidewall.right - 40 * dt / 10
	self.temperatures.l3 = self.temperatures.l3 - 40 * dt / 10
	self.temperatures.l4 = self.temperatures.l4 - 40 * dt / 10
	self.temperatures.l5 = self.temperatures.l5 - 40 * dt / 10
	self.temperatures.l6 = self.temperatures.l6 - 40 * dt / 10
	self.temperatures.rim = self.temperatures.rim - 40 * dt / 10
	self.temperatures.innerAir = self.temperatures.innerAir - 40 * dt / 10
	return self
end

function ThermalWearTyre:hasWeightOnWheel()
	print(string.format("Load: %f", self.load))
	if self.load == 0 then
		return false
	else
		return true
	end
end

function ThermalWearTyre:setWear()
end

function ThermalWearTyre:hotReset()
	for i=1, self.zoneCount do
		self.temperatures.l1[i] = self.idealTemp
		self.temperatures.l2[i] =  self.idealTemp
		self.condition_zones[i] = 100
	end
	self.temperatures.sidewall.left =  self.idealTemp
	self.temperatures.sidewall.right =  self.idealTemp
	self.temperatures.l3 =  self.idealTemp
	self.temperatures.l4 =  self.idealTemp
	self.temperatures.l5 =  self.idealTemp
	self.temperatures.l6 =  self.idealTemp
	self.temperatures.rim =  self.idealTemp
	self.temperatures.innerAir = self.idealTemp
	return self
end

function ThermalWearTyre:coldReset(env_temp)
	env_temp = env_temp or TWT.env_temp
	for i=1, self.zoneCount do
		self.temperatures.l1[i] = env_temp
		self.temperatures.l2[i] =  env_temp
		self.condition_zones[i] = 100
	end
	self.temperatures.sidewall.left =  env_temp
	self.temperatures.sidewall.right =  env_temp
	self.temperatures.l3 =  env_temp
	self.temperatures.l4 =  env_temp
	self.temperatures.l5 =  env_temp
	self.temperatures.l6 =  env_temp
	self.temperatures.rim =  env_temp
	self.temperatures.innerAir = env_temp
	return self
end

function ThermalWearTyre.__index(table, key)
	-- creates inheritance
	return ThermalWearTyre[key] or Tyre[key]
end
