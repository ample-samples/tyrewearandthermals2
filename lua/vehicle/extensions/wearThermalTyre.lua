Tyre = {
	name = "",
	wheelID = 0,
	totalWeight = 10,
	camber_to_ground = 0,
	wheelDir = 1
}

WearThermalTyre = {
	temperature = 85,
	wear_rate = 0.05,
	condition_zones = { 100, 100, 100 }
}

WearTyre = {
	condition_zones = { 100, 100, 100 },
	wear_rate = 0.05
}

-- INFO: constructor
function Tyre.new(name, wheelID, wheelDir)
	local self = setmetatable({}, Tyre)

	self.wheelDir = wheelDir
	self.name = name
	self.wheelID = wheelID

	return self
end

function Tyre:update(dt, camber_to_ground)
	self.camber_to_ground = camber_to_ground
	return self
end

function Tyre:setCamberToGround(camber_to_ground)
	self.camber_to_ground = camber_to_ground
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

function WearTyre.new(name, wheelID, wheelDir)
	local self = setmetatable({}, WearTyre)

	self.wheelDir = wheelDir
	self.name = name
	self.wheelID = wheelID
	self.condition_zones = { 100, 100, 100 }

	return self
end

-- INFO: temporary example
function WearTyre:update(dt, camber_to_ground, env_temp)
	self:setCamberToGround(camber_to_ground)
	for i, zone in pairs(self.condition_zones) do
		self.condition_zones[i] = zone - (zone - self.wear_rate) * i * dt / 10
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
function WearThermalTyre.new(name, wheelID, wheelDir, temp, weight, wear_rate)
	local self = setmetatable({}, WearThermalTyre)

	self.name = name
	self.wheelID = wheelID
	self.wheelDir = wheelDir
	self.temperature = temp
	self.totalWeight = weight
	self.condition_zones = { 100, 100, 100 }

	return self
end

function WearThermalTyre:setTemperature(temp)
	self.temperature = temp
	return self
end

-- INFO: temporary example
function WearThermalTyre:update(dt, camber_to_ground, env_temp)
	self:setCamberToGround(camber_to_ground)
	for i, zone in pairs(self.condition_zones) do
		self.condition_zones[i] = zone - (zone - self.wear_rate) * i * dt / 10
	end
	self.temperature = self.temperature + 0.5 * (env_temp - self.temperature) * dt / 10
	return self
end

function WearThermalTyre:hotReset()
	self.temperature = WearThermalTyre.temperature
	self.condition_zones = { 100, 100, 100 }
	return self
end

function WearThermalTyre:coldReset(env_temp)
	self.temperature = env_temp
	self.condition_zones = { 100, 100, 100 }
	return self
end

function WearThermalTyre.__index(table, key)
	-- creates inheritance
	return WearThermalTyre[key] or WearTyre[key] or Tyre[key]
end
