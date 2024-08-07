ThermalWearTyre = {
	temperature = 90,
	totalWeight = 10,
	wheelID = 0,
	wear_rate = 0.05
}

function ThermalWearTyre.new(temp, weight, wheelID, wear_rate)
	local self = setmetatable({}, ThermalWearTyre)

	self.temperature = temp
	self.totalWeight = weight
	self.wheelID = wheelID
	self.wear_rate = wear_rate

	return self
end

function ThermalWearTyre:setTemperature(temp)
	self.temperature = temp
	return self
end

function ThermalWearTyre:getTemperature()
	return self.temperature
end

function ThermalWearTyre:updateTemperature(env_temp)
	self.temperature = self.temperature + 0.0005 * (env_temp - self.temperature)
	return self
end

function ThermalWearTyre:coldReset(env_temp)
	self.temperature = env_temp
	return self
end

function ThermalWearTyre:updateWear()
	return self
end

function ThermalWearTyre.__index(table, key)
	return ThermalWearTyre[key]
end
