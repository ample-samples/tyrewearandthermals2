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
	condition_zones = { 100, 100, 100 }
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
	local camber_debug = string.format("\nwheelID: %i\nwheelDir: %i\ncamber: %f", self.wheelID, self.wheelDir, self.camber_to_ground)
	dump(camber_debug)
	return self
end

function ThermalWearTyre:setCamberToGround(camber_to_ground)
	self.camber_to_ground = camber_to_ground * self.wheelDir
	local camber_debug = string.format("\nwheelID: %i\nwheelDir: %i\ncamber: %f", self.wheelID, self.wheelDir, self.camber_to_ground)
	dump(camber_debug)
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
	self.temperature = tyreParams.temp
	self.totalWeight = tyreParams.weight
	self.condition_zones = { 100, 100, 100 }

	return self
end

function ThermalWearTyre:setTemperature(temp)
	self.temperature = temp
	return self
end

-- INFO: temporary example
function ThermalWearTyre:update(dt, camber_to_ground, params)
	self:setCamberToGround(camber_to_ground)
	for i, zone in pairs(self.condition_zones) do
		self.condition_zones[i] = zone - (zone - self.wear_rate) * i * dt / 10
	end
	self.temperature = self.temperature + 0.5 * (params.env_temp - self.temperature) * dt / 10
	return self
end

function ThermalWearTyre:hotReset()
	self.temperature = ThermalWearTyre.temperature
	self.condition_zones = { 100, 100, 100 }
	return self
end

function ThermalWearTyre:coldReset(env_temp)
	self.temperature = env_temp
	self.condition_zones = { 100, 100, 100 }
	return self
end

function ThermalWearTyre.__index(table, key)
	-- creates inheritance
	return ThermalWearTyre[key] or Tyre[key]
end
