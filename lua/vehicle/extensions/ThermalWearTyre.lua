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
	wear_rate = 0.01,
}

WearTyre = {
	type = "WearTyre",
	treadConditions = { 100, 100, 100 },
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
	self.treadConditions = { 100, 100, 100 }
	self.wear_rate = tyreParams.wear_rate

	return self
end

function WearTyre:update(dt, camber_to_ground, tyreParams)
	self:setCamberToGround(camber_to_ground)
	local load = tyreParams.load
	local angular_vel = tyreParams.angularVel * self.wheelDir
	local propulsionTorque = tyreParams.propulsionTorque * self.wheelDir
	for i, zone in pairs(self.treadConditions) do
		-- INFO: ADDITIONAL THINGS WHICH AFFECT WEAR
		-- Contact pressure
		-- Slip * load
		local wear_amount = math.abs(angular_vel * (propulsionTorque - tyreParams.brakingTorque))
		self.treadConditions[i] = zone - min_or_zero(wear_amount, wear_min) * self.wear_rate / 1000000
		self.treadConditions[i] = math.max(self.condition_zones[i], 0)
	end
	return self
end

function WearTyre:reset()
	self.treadConditions = { 100, 100, 100 }
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
	self.tyreMass = tyreParams.tyreMass
    -- treadZoneCount includes the carcass beneath the tread, down to 
    -- the rubber in contact with the inner air
	self.treadZoneCount = 10
	self.sidewallZoneCount = 5
	self.rimZoneCount = 5
	self.treadConditions = {}

	local startingTemp = TWT.env_temp
	if tyreParams.isPreheated then
		startingTemp = tyreParams.idealTemp
	end

	local defaultMatName = "testMaterial1"
	local defaultAirMatName = "nitrogen"
	local treadMatName = tyreParams.treadMatName or defaultMatName
	local carcassMatName = tyreParams.carcassMatName or defaultMatName
	local sidewallMatName = tyreParams.sidewallMatName or defaultMatName
	local innerAirMatName = tyreParams.innerAirMatName or defaultAirMatName

	-- TODO:
	-- matNodes, short for materialNodes
	-- these matNodes contain information for each simulated point on the tyre:
	-- - temperature
	-- - mass
	-- - energy
	-- - matName
	--   - a key to a material lookup table
	self.matNodes = {
		l1 = { temperature = {}, energy = {} },
		l2 = { temperature = {}, energy = {} },
		l3 = { temperature = {}, energy = {} },
		l4 = { temperature = {}, energy = {} },
		l5 = { temperature = {}, energy = {} },
		l6 = { temperature = {}, energy = {} },
		sidewall = {
            left = {
                l1 = { temperature = {}, energy = {} },
                l2 = { temperature = {}, energy = {} },
                l3 = { temperature = {}, energy = {} }
            },
            right = {
                l1 = { temperature = {}, energy = {} },
                l2 = { temperature = {}, energy = {} },
                l3 = { temperature = {}, energy = {} }
            }
        },
		innerAir = { temperature = {}, energy = {} },
		rim = {
            outer = {
                l1 = { temperature = {}, energy = {} }
            },
            center = {
                l1 = { temperature = {}, energy = {} }
            }
        }
	}

	self.idealTemp = tyreParams.idealTemp
	for i = 1, self.treadZoneCount, 1 do
		self.treadConditions[i] = 100
		self.matNodes.l1.temperature[i] = startingTemp
		self.matNodes.l2.temperature[i] = startingTemp
		self.matNodes.l3.temperature[i] = startingTemp
		self.matNodes.l4.temperature[i] = startingTemp
		self.matNodes.l5.temperature[i] = startingTemp
		self.matNodes.l6.temperature[i] = startingTemp
	end
    for i = 1, self.sidewallZoneCount, 1 do
        self.matNodes.sidewall.left.l1.temperature[i] = startingTemp
        self.matNodes.sidewall.left.l2.temperature[i] = startingTemp
        self.matNodes.sidewall.left.l3.temperature[i] = startingTemp
        self.matNodes.sidewall.right.l1.temperature[i] = startingTemp
        self.matNodes.sidewall.right.l2.temperature[i] = startingTemp
        self.matNodes.sidewall.right.l3.temperature[i] = startingTemp
    end
    for i = 1, self.rimZoneCount, 1 do
        self.matNodes.rim.outer.l1.temperature[i] = startingTemp
        self.matNodes.rim.center.l1.temperature[i] = startingTemp
    end
    self.matNodes.l1.matName = treadMatName
    self.matNodes.l2.matName = treadMatName
    self.matNodes.l3.matName = treadMatName
	self.matNodes.l4.matName = carcassMatName
	self.matNodes.l5.matName = carcassMatName
	self.matNodes.l6.matName = carcassMatName
	self.matNodes.sidewall.left.matName = sidewallMatName
	self.matNodes.sidewall.right.matName = sidewallMatName
	self.matNodes.innerAir.temperature = startingTemp
	self.matNodes.innerAir.matName = innerAirMatName
	dump(self)
	return self
end

function ThermalWearTyre:update(dt, camber_to_ground, tyreParams)
	self:setCamberToGround(camber_to_ground)
	self.load = tyreParams.load
	if self.disabled then return end
	for i = 1, self.treadZoneCount do
		local currentCondition = self.treadConditions[i]
		self.treadConditions[i] = currentCondition - (currentCondition - self.wear_rate) * i * dt / 10
		self.matNodes.l1.temperature[i] = self.matNodes.l1.temperature[i] - 40 * i * dt / 10
		self.matNodes.l2.temperature[i] = self.matNodes.l2.temperature[i] - 40 * i * dt / 10
		self.matNodes.l3.temperature[i] = self.matNodes.l3.temperature[i] - 40 * dt / 10
        self.matNodes.l4.temperature[i] = self.matNodes.l4.temperature[i] - 40 * dt / 10
        self.matNodes.l5.temperature[i] = self.matNodes.l5.temperature[i] - 40 * dt / 10
        self.matNodes.l6.temperature[i] = self.matNodes.l6.temperature[i] - 40 * dt / 10
	end
    for i = 1, self.sidewallZoneCount, 1 do
        self.matNodes.sidewall.left.l1.temperature[i] = self.matNodes.sidewall.left.l1.temperature[i] - 40 * dt / 10
        self.matNodes.sidewall.left.l2.temperature[i] = self.matNodes.sidewall.left.l2.temperature[i] - 40 * dt / 10
        self.matNodes.sidewall.left.l3.temperature[i] = self.matNodes.sidewall.left.l3.temperature[i] - 40 * dt / 10
        self.matNodes.sidewall.right.l1.temperature[i] = self.matNodes.sidewall.right.l1.temperature[i] - 40 * dt / 10
        self.matNodes.sidewall.right.l2.temperature[i] = self.matNodes.sidewall.right.l2.temperature[i] - 40 * dt / 10
        self.matNodes.sidewall.right.l3.temperature[i] = self.matNodes.sidewall.right.l3.temperature[i] - 40 * dt / 10
    end
    for i = 1, self.rimZoneCount, 1 do
        self.matNodes.rim.outer.l1.temperature[i] = self.matNodes.rim.outer.l1.temperature[i] - 40 * dt / 10
        self.matNodes.rim.center.l1.temperature[i] = self.matNodes.rim.center.l1.temperature[i] - 40 * dt / 10
    end
	self.matNodes.innerAir.temperature = self.matNodes.innerAir.temperature - 40 * dt / 10
	return self
end

function ThermalWearTyre:toggleDisabled()
	self.disabled = not self.disabled
	return self
end

function ThermalWearTyre:hasWeightOnWheel()
	if self.load == 0 then
		return false
	else
		return true
	end
end

function ThermalWearTyre:setWear()
end

function ThermalWearTyre:getNodeTemperature(nodeName, i)
end

function ThermalWearTyre:getNodeEnergy(nodeName, i)
end

function ThermalWearTyre:setNodeTemperature(temp, nodeName, i)
	-- sets the temperature of the specified node.
end

function ThermalWearTyre:setNodeEnergy(energy, nodeName, i)
end

function ThermalWearTyre:updateNodeEnergy(nodeName, i)
	-- updates the energy of the specified node, based on its:
	-- - temperature
	-- - mass
	-- - specific heat capacity

	-- INFO: possible inputs
	-- l1, int
	-- l2, int
	-- l3, int
	-- l4, nil
	-- l5, nil
	-- l6, nil
	-- string, int|nil
	-- rim, nil
	-- sidewall.left, nil
	-- sidewall.right, nil
end

function ThermalWearTyre:updateNodeTemperature(nodeName, i)
	-- updates the temperature of the specified node, based on its:
	-- - energy
	-- - mass
	-- - specific heat capacity

	-- INFO: possible inputs
	-- string, int|nil
	-- rim, nil
	-- sidewall.left, nil
	-- sidewall.right, nil
	-- l6, nil
	-- l5, nil
	-- l4, nil
	-- l3, int
	-- l2, int
	-- l1, int
end

function ThermalWearTyre:setTemperatures(temp)
	for i = 1, self.treadZoneCount, 1 do
		self.treadConditions[i] = 100
		self.matNodes.l1.temperature[i] = temp
		self.matNodes.l2.temperature[i] = temp
		self.matNodes.l3.temperature[i] = temp
		self.matNodes.l4.temperature[i] = temp
		self.matNodes.l5.temperature[i] = temp
		self.matNodes.l6.temperature[i] = temp
	end
    for i = 1, self.sidewallZoneCount, 1 do
        self.matNodes.sidewall.left.l1.temperature[i] = temp
        self.matNodes.sidewall.left.l2.temperature[i] = temp
        self.matNodes.sidewall.left.l3.temperature[i] = temp
        self.matNodes.sidewall.right.l1.temperature[i] = temp
        self.matNodes.sidewall.right.l2.temperature[i] = temp
        self.matNodes.sidewall.right.l3.temperature[i] = temp
    end
    for i = 1, self.rimZoneCount, 1 do
        self.matNodes.rim.outer.l1.temperature[i] = temp
        self.matNodes.rim.center.l1.temperature[i] = temp
    end
	self.matNodes.innerAir.temperature = temp
	return self
end

function ThermalWearTyre:changeTyre(temp)
	temp = temp or TWT.env_temp
	for i = 1, self.treadZoneCount do
		self.treadConditions[i] = 100
	end
	self:setTemperatures(temp)
	return self
end

function ThermalWearTyre.__index(table, key)
	-- creates inheritance
	return ThermalWearTyre[key] or Tyre[key]
end
