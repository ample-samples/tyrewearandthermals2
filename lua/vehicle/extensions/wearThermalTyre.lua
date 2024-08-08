Tyre = {
	name = "",
	wheelID = 0,
	totalWeight = 10,
	camber_to_ground = 0,
	wheelDir = 1
}

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
	if key == "coldReset" or key == "hotReset" then
		return Tyre["reset"]
	end
	return Tyre[key]
end

WearThermalTyre = {
	temperature = 85,
	wear_rate = 0.05,
	condition = 100
}

function WearThermalTyre.new(name, wheelID, wheelDir, temp, weight, wear_rate, condition)
	local self = setmetatable({}, WearThermalTyre)

	self.name = name
	self.wheelID = wheelID
	self.wheelDir = wheelDir
	self.temperature = temp
	self.totalWeight = weight
	self.wear_rate = wear_rate
	self.condition = condition

	return self
end

function WearThermalTyre:setTemperature(temp)
	self.temperature = temp
	return self
end

-- TODO: temporary example
function WearThermalTyre:update(dt, camber_to_ground, env_temp)
	self:setCamberToGround(camber_to_ground)
	self.condition = self.condition - (self.condition - self.wear_rate) * dt / 10
	self.temperature = self.temperature + 0.5 * (env_temp - self.temperature) * dt / 10
	return self
end

function WearThermalTyre:hotReset()
	self.temperature = WearThermalTyre.temperature
	self.condition = 100
	return self
end

function WearThermalTyre:coldReset(env_temp)
	self.temperature = env_temp
	self.condition = 100
	return self
end

function WearThermalTyre.__index(table, key)
	-- creates inheritance
	return WearThermalTyre[key] or Tyre[key]
end
