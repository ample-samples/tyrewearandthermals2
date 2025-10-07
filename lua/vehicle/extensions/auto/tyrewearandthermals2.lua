local M = {}
TWT = {} -- made global so GELua can access and change it
TWT.groundModels = {}
TWT.env_temp = 20
TWT.brakeSettings = { 12, 12 }
TWT.tyreVarsFront = nil
TWT.tyreVarsRear = nil

extensions.load("TWTTyres")
extensions.load("standardiseTyreNames")

local useTyre = TWTTyres.ThermalWearTyre
tyres = {} -- left global so other mods can interact with it


function TWT.changeTyres(resetTemp)
    if resetTemp then
        for _, tyre in pairs(tyres) do tyre:changeTyre(resetTemp) end
    else
        for _, tyre in pairs(tyres) do tyre:changeTyre(tyre.idealTemp) end
    end
end

local function setEnvironmentTemperature()
    TWT.env_temp = obj:getEnvTemperature() - 273.15
end

local function getGroundModelData(id)
    local materials, materialsMap = particles.getMaterialsParticlesTable()
    local matData = materials[id] or {}
    local name = matData.name or "DOESNT EXIST"
    local data = TWT.groundModels[name] or { staticFrictionCoefficient = 1, slidingFrictionCoefficient = 1 }
    return name, data
end

local function getMapNormalUnderWheel(wheelID)
    local vectorUp = obj:getDirectionVectorUp()
    local localVectNode1 = obj:getNodePosition(wheels.wheelRotators[wheelID].node1)
    local localVectNode2 = obj:getNodePosition(wheels.wheelRotators[wheelID].node2)
    local vectorWheelForward = (localVectNode2 - localVectNode1):cross(vectorUp)
    local vectorWheelUp = vectorWheelForward:cross(localVectNode2 - localVectNode1)
    local surfaceNormal = mapmgr.surfaceNormalBelow(
        obj:getPosition() + (localVectNode2 + localVectNode1) / 2 -
        wheels.wheelRotators[wheelID].radius * vectorWheelUp:normalized(), 0.1
    )
    return surfaceNormal
end

local function getWheelCamberToGround(wheelID)
    local localVectNode1 = obj:getNodePosition(wheels.wheelRotators[wheelID].node1)
    local localVectNode2 = obj:getNodePosition(wheels.wheelRotators[wheelID].node2)
    local surfaceNormal = getMapNormalUnderWheel(wheelID)
    local camber = 90 -
        math.deg(math.acos((localVectNode2 - localVectNode1):normalized():dot(surfaceNormal:normalized())))
    return camber
end

local function generateStream(tyres)
    local stream = { data = {} }
    for _, tyre in pairs(tyres) do
        table.insert(stream.data, {
            name = tyre.name,
            temps = tyre.matNodes.l1.temperatures,
            working_temp = 85,
            condition_zones = tyre.treadConditions,
            camber = tyre.camber_to_ground,
            weightOnWheel = tyre:hasWeightOnWheel()
        })
    end
    return stream
end

local dummyStream = {
    data = {
        name = "not a real tyre",
        temps = { TWT.env_temp, TWT.env_temp },
        working_temp = TWT.env_temp,
        condition_zones = { 100 },
        camber = 0
    }
}

local function getWheelsAndNamesPositions(wheels)
    -- INFO: unused, will be used to standardise tyre names and
    -- their position relative to the vehicle and its orentation
    -- so the UI can display them
    local wheelNamesAndPositions = {}
    for i, v in pairs(wheels.wheelRotators) do
        local localVectNode1 = obj:getNodePosition(wheels.wheelRotators[i].node2)
        local wheelName = wheels.wheelRotators[i].name
        wheelNamesAndPositions[wheelName] = localVectNode1
    end
    return wheelNamesAndPositions
end

local oneSecondTimer = 0
local function updateGFX(dt)
    setEnvironmentTemperature()
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
        local wheel = obj:getWheel(i)
        local wheelRotator = wheels.wheelRotators[i]
        local groundModelName, groundModel = getGroundModelData(wheels.wheelRotators[i].contactMaterialID1)
        local wheelname = wheels.wheelRotators[i].name
        tyre:update(
            dt,
            getWheelCamberToGround(i),
            {
                env_temp = TWT.env_temp,
                load = wheels.wheelRotators[i].downForceRaw,
                angularVel = wheels.wheelRotators[i].angularVelocity,
                propulsionTorque = wheels.wheelRotators[i].propulsionTorque,
                brakingTorque = wheels.wheelRotators[i].brakingTorque,
                lastTorque = wheels.wheelRotators[i].lastTorque,
                slipEnery = wheels.wheelRotators[i].slipEnergy
            })
        -- if wheel.treadNodes ~= nil then
        --     print("11111")
        --     for _, nodecid in pairs(wheel.treadNodes) do
        --     print("22222")
        --         dump(v.data.nodes[nodecid])
        --         local frictionCoef = v.data.nodes[nodecid].frictionCoef
        --         local slidingFrictionCoef = v.data.nodes[nodecid].slidingFrictionCoef
        --         if frictionCoef then
        --     print("33333")
        --             -- obj:setNodeFrictionSlidingCoefs(nodecid, tyre.grip, slidingFrictionCoef or frictionCoef)
        --             obj:setNodeFrictionSlidingCoefs(nodecid, 0, 0)
        --         end
        --     end
        -- end
        -- for k,v in pairs(getmetatable(wheel)) do
        --     print("==============" ..  k .. "==============")
        --     dump(v)
        -- end
        if wheelRotator.wheelDir > 0 then
            if v.data.wheels[i].treadNodes ~= nil and v.data.wheels[i].treadBeams ~= nil then

            end
            for _, nodecid in pairs(v.data.wheels[i].treadNodes) do
                local node = v.data.nodes[nodecid]
                -- dump(node)
                obj:setNodeFrictionSlidingCoefs(nodecid, 1,
                    (0.8))

                -- local pos = node.pos
                -- obj:setNode(node.cid, pos.x, pos.y, pos.z, node.nodeWeight, node.ntype, frictionCoef or 1,
                --     slidingFrictionCoef or 1,
                --     node.stribeckExponent or 1.75, node.stribeckVelMult or 1, node.noLoadCoef, node.fullLoadCoef,
                --     node.loadSensitivitySlope,
                --     node.softnessCoef or 0.5, node.treadCoef or 0.5, node.tag or '', node.couplerStrength or math.huge,
                --     node.firstGroup or -1,
                --     false, --selfCollision
                --     nil,  --collision
                --     nil,  --staticCollision
                --     node.nodeMaterial)
            end

            -- wheel:setFrictionThermalSensitivity(
            --     -300,  -- frictionLowTemp              default: -300
            --     1e7,   -- frictionHighTemp             default: 1e7
            --     1e-10, -- frictionLowSlope             default: 1e-10
            --     1e-10, -- frictionHighSlope            default: 1e-10
            --     10,    -- frictionSlopeSmoothCoef      default: 10
            --     0,     -- frictionCoefLow              default: 1
            --     1,     -- frictionCoefMiddle           default: 1
            --     0      -- frictionCoefHigh             default: 1
            -- )
        end
    end

    if oneSecondTimer >= 1 then
        TWT.changeTyres()
        -- TWT.changeTyres(TWT.env_temp)
        oneSecondTimer = oneSecondTimer % 1 -- Loops every 1 seconds
    end


    local stream = generateStream(tyres)
    gui.send("tyrewearandthermals2", stream)
end

local function generateModTyres()
    for i, wheel in pairs(wheels.wheelRotators) do
        tyres[wheel.wheelID] = useTyre.new(wheel.name, wheel.wheelID, wheel.wheelDir,
            {
                tyreMass = 10,
                idealTemp = 85,
                wear_rate = 0.005,
                wheel.tireWidth,
                isPreheated = true,
                tyreMaterials =
                'raceMedium'
            })
        dump(tyres[wheel.wheelID].tyreMaterials)
    end
end

local function onReset()
    setEnvironmentTemperature()
    generateModTyres()
    TWT.changeTyres()
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
