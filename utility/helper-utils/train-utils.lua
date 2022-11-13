--[[
    All train and rail related utils functions.
]]
--

local TrainUtils = {} ---@class Utility_TrainUtils
local PrototypeAttributes = require("utility.functions.prototype-attributes")
local EntityUtils = require("utility.helper-utils.entity-utils")
local PositionUtils = require("utility.helper-utils.position-utils")
local VehicleUtils = require("utility.helper-utils.vehicle-utils")
local math_min, math_max, math_ceil, math_sqrt = math.min, math.max, math.ceil, math.sqrt

--- Gets the carriage at the head (leading) the train in its current direction.
---
--- Should be done locally if called frequently.
---@param train LuaTrain
---@param isFrontStockLeading boolean # If the trains speed is > 0 then pass in true, if speed < 0 then pass in false.
---@return LuaEntity
TrainUtils.GetLeadingCarriageOfTrain = function(train, isFrontStockLeading)
    if isFrontStockLeading then
        return train.front_stock
    else
        return train.back_stock
    end
end

--- Gets the length of a rail entity.
---@param entityType string
---@param entityDirection defines.direction
---@return double railLength
TrainUtils.GetRailEntityLength = function(entityType, entityDirection)
    if entityType == "straight-rail" then
        if entityDirection == defines.direction.north or entityDirection == defines.direction.east or entityDirection == defines.direction.south or entityDirection == defines.direction.west then
            -- Cardinal direction rail.
            return 2.0
        else
            -- Diagonal rail.
            return 1.415
        end
    else
        -- Curved rail.
        -- Old value worked out somehow was: 7.842081225095, but new value is based on a train's path length reported in the game.
        return 7.84
    end
end

---@class TrainUtils_TrainSpeedCalculationData # Data the Utils functions need to calculate and estimate its future speed, time to cover distance, etc.
---@field trainWeight double # The total weight of the train.
---@field trainFrictionForce double # The total friction force of the train.
---@field trainWeightedFrictionForce double # The train's friction force divided by train weight.
---@field locomotiveFuelAccelerationPower double # The max acceleration power per tick the train can add for the fuel type on last data update.
---@field locomotiveAccelerationPower double # The max raw acceleration power per tick the train can add (ignoring fuel bonus).
---@field trainAirResistanceReductionMultiplier double # The air resistance of the train (lead carriage in current direction).
---@field maxSpeed double # The max speed the train can achieve on current fuel type.
---@field trainRawBrakingForce double # The total braking force of the train ignoring any force bonus percentage from LuaForce.train_braking_force_bonus.
---@field forwardFacingLocoCount uint # The number of locomotives facing forwards. Used when recalculating locomotiveFuelAccelerationPower.

---@class TrainUtils_TrainCarriageData # Data array of cached details on a train's carriages. Allows only obtaining required data once per carriage. Only populate carriage data when required.
---@field entity LuaEntity # Minimum this must be populated and the functions will populate other details if they are required during each function's operation.
---@field prototypeType? string
---@field prototypeName? string
---@field facingFrontOfTrain? boolean # If the carriage is facing the front of the train. If true then carriage speed and orientation is the same as the train's.

--- Get the data other Utils functions need for calculating and estimating; a trains future speed, time to cover distance, etc.
---
--- This is only accurate while the train is heading in the same direction as when this data was gathered and requires the train to be moving.
---
--- Assumes all forward facing locomotives have the same fuel as the first one found. If no fuel is found in any locomotive then a default value of 1 is used and the return "noFuelFound" will indicate this.
---
--- Either trainCarriagesDataArray or train_carriages needs to be provided.
---@param train LuaTrain
---@param train_speed double # Must not be 0 (stationary train).
---@param trainCarriagesDataArray? TrainUtils_TrainCarriageData[] # An array of carriage data for this train in the TrainUtils_TrainCarriageData format in the same order as the train's internal carriage order. If provided and it doesn't include the required attribute data on the carriages it will be obtained and added in to the cache table.
---@param train_carriages? LuaEntity[] # If trainCarriagesDataArray isn't provided then the train's carriage array will need to be provided. The required attribute data on each carriage will have to be obtained, but not cached or passed out.
---@return TrainUtils_TrainSpeedCalculationData trainSpeedCalculationData
---@return boolean noFuelFound # TRUE if no fuel was found in any forward moving locomotive. Generally FALSE is returned when all is normal.
TrainUtils.GetTrainSpeedCalculationData = function(train, train_speed, trainCarriagesDataArray, train_carriages)
    if train_speed == 0 then
        -- We can't work out what way is forward for counting locomotives that can assist with acceleration.
        error("TrainUtils.GetTrainSpeedCalculationData() doesn't work for 0 speed train")
    end

    -- If trainCarriagesDataArray is nil we'll build it up as we go from the train_carriages array. This means that the functions logic only has 1 data structure to worry about. The trainCarriagesDataArray isn't passed out as a return and so while we build up the cache object it is dropped at the end of the function.
    if trainCarriagesDataArray == nil then
        ---@cast train_carriages - nil # It will be provided if trainCarriagesDataArray wasn't, otherwise it can just error.
        trainCarriagesDataArray = {} ---@type TrainUtils_TrainCarriageData[]
        for i, entity in pairs(train_carriages) do
            trainCarriagesDataArray[i] = { entity = entity }
        end
    end

    local trainWeight = train.weight
    ---@type double, uint, double
    local trainFrictionForce, forwardFacingLocoCount, trainRawBrakingForce = 0, 0, 0
    local trainAirResistanceReductionMultiplier
    local trainMovingForwards = train_speed > 0

    -- Work out which way to iterate down the train's carriage array. Starting with the lead carriage.
    local minCarriageIndex, maxCarriageIndex, carriageIterator
    local carriageCount = #trainCarriagesDataArray
    if trainMovingForwards then
        minCarriageIndex, maxCarriageIndex, carriageIterator = 1, carriageCount, 1
    elseif not trainMovingForwards then
        minCarriageIndex, maxCarriageIndex, carriageIterator = carriageCount, 1, -1
    end

    local firstCarriage = true
    ---@type TrainUtils_TrainCarriageData, string, string, boolean
    local carriageCachedData, carriage_type, carriage_name, carriage_facingFrontOfTrain
    for currentSourceTrainCarriageIndex = minCarriageIndex, maxCarriageIndex, carriageIterator do
        carriageCachedData = trainCarriagesDataArray[currentSourceTrainCarriageIndex]
        carriage_type = carriageCachedData.prototypeType
        carriage_name = carriageCachedData.prototypeName
        if carriage_type == nil then
            -- Data not known so obtain and cache.
            carriage_type = carriageCachedData.entity.type
            carriageCachedData.prototypeType = carriage_type
        end
        if carriage_name == nil then
            -- Data not known so obtain and cache.
            carriage_name = carriageCachedData.entity.name
            carriageCachedData.prototypeName = carriage_name
        end

        trainFrictionForce = trainFrictionForce + PrototypeAttributes.GetAttribute("entity", carriage_name, "friction_force")
        trainRawBrakingForce = trainRawBrakingForce + PrototypeAttributes.GetAttribute("entity", carriage_name, "braking_force")

        if firstCarriage then
            firstCarriage = false
            trainAirResistanceReductionMultiplier = 1 - (PrototypeAttributes.GetAttribute("entity", carriage_name, "air_resistance") / (trainWeight / 1000))
        end

        if carriage_type == "locomotive" then
            carriage_facingFrontOfTrain = carriageCachedData.facingFrontOfTrain
            if carriage_facingFrontOfTrain == nil then
                -- Data not known so obtain and cache.
                if carriageCachedData.entity.speed == train_speed then
                    carriage_facingFrontOfTrain = true
                else
                    carriage_facingFrontOfTrain = false
                end
                carriageCachedData.facingFrontOfTrain = carriage_facingFrontOfTrain
            end

            -- Only process locomotives that are powering the trains movement.
            if trainMovingForwards == carriage_facingFrontOfTrain then
                -- Count all forward moving loco's. Just assume they all have the same fuel to avoid inspecting each one.
                forwardFacingLocoCount = forwardFacingLocoCount + 1
            end
        end
    end

    -- Record all the data in to the cache object.
    ---@type TrainUtils_TrainSpeedCalculationData
    local trainData = {
        trainWeight = trainWeight,
        trainFrictionForce = trainFrictionForce,
        trainWeightedFrictionForce = (trainFrictionForce / trainWeight),
        -- This assumes all loco's are the same power and have the same fuel. The 10 is for a 600 kW max_power of a vanilla locomotive.
        locomotiveAccelerationPower = 10 * forwardFacingLocoCount / trainWeight,
        trainAirResistanceReductionMultiplier = trainAirResistanceReductionMultiplier,
        forwardFacingLocoCount = forwardFacingLocoCount,
        trainRawBrakingForce = trainRawBrakingForce
    }

    -- Update the train's data that depends upon the trains current fuel.
    local noFuelFound = TrainUtils.UpdateTrainSpeedCalculationDataForCurrentFuel(trainData, trainCarriagesDataArray, trainMovingForwards, train)

    return trainData, noFuelFound
end

--- Updates a train speed calculation data object (TrainUtils_TrainSpeedCalculationData) for the current fuel the train is utilising to power it. Updates max achievable speed and the acceleration data.
---@param trainSpeedCalculationData TrainUtils_TrainSpeedCalculationData
---@param trainCarriagesDataArray TrainUtils_TrainCarriageData[]
---@param trainMovingForwardsToCacheData boolean # If the train is moving forwards in relation to the facing of the cached carriage data.
---@param train LuaTrain
---@return boolean noFuelFound # TRUE if no fuel was found in any forward moving locomotive. Generally FALSE is returned when all is normal.
TrainUtils.UpdateTrainSpeedCalculationDataForCurrentFuel = function(trainSpeedCalculationData, trainCarriagesDataArray, trainMovingForwardsToCacheData, train)
    -- Get a current fuel for the forwards movement of the train.
    local fuelPrototype ---@type LuaItemPrototype?
    local noFuelFound = true
    for _, carriageCachedData in pairs(trainCarriagesDataArray) do
        -- Only process locomotives that are powering the trains movement.
        if carriageCachedData.prototypeType == "locomotive" and trainMovingForwardsToCacheData == carriageCachedData.facingFrontOfTrain then
            local carriage = carriageCachedData.entity
            -- Coding Note: No point caching this as we only get 1 attribute of the prototype and we'd have to additionally get its name each time to utilise a cache.
            fuelPrototype = VehicleUtils.GetVehicleCurrentFuelPrototype(carriage)
            if fuelPrototype ~= nil then
                -- Just get fuel from one forward facing loco that has fuel. Have to check the inventory as the train will be braking for the signal there's no currently burning.
                noFuelFound = false
                break
            end
        end
    end

    -- Update the acceleration data.
    local fuelAccelerationBonus
    if fuelPrototype ~= nil then
        fuelAccelerationBonus = fuelPrototype.fuel_acceleration_multiplier
    else
        fuelAccelerationBonus = 1
    end
    trainSpeedCalculationData.locomotiveFuelAccelerationPower = trainSpeedCalculationData.locomotiveAccelerationPower * fuelAccelerationBonus

    -- Have to get the right prototype max speed as they're not identical at runtime even if the train is symmetrical. This API result includes the fuel type currently being burnt.
    local trainPrototypeMaxSpeedIncludesFuelBonus
    if trainMovingForwardsToCacheData then
        trainPrototypeMaxSpeedIncludesFuelBonus = train.max_forward_speed
    elseif not trainMovingForwardsToCacheData then
        trainPrototypeMaxSpeedIncludesFuelBonus = train.max_backward_speed
    end

    -- Work out the achievable max speed of the train.
    -- Maths way based on knowing that its acceleration result will be 0 once its at max speed.
    --   0=s - ((s+a)*r)   in to Wolf Ram Alpha and re-arranged for s.
    local maxSpeedForFuelBonus = -((((trainSpeedCalculationData.locomotiveFuelAccelerationPower) - trainSpeedCalculationData.trainWeightedFrictionForce) * trainSpeedCalculationData.trainAirResistanceReductionMultiplier) / (trainSpeedCalculationData.trainAirResistanceReductionMultiplier - 1))
    trainSpeedCalculationData.maxSpeed = math_min(maxSpeedForFuelBonus, trainPrototypeMaxSpeedIncludesFuelBonus)

    return noFuelFound
end

--- Calculates the speed of a train for 1 tick as if accelerating. This doesn't match vanilla trains perfectly, but is very close with vanilla trains and accounts for everything known accurately. From https://wiki.factorio.com/Locomotive
---
-- Often this is copied in to code inline for repeated calling.
---@param trainData TrainUtils_TrainSpeedCalculationData
---@param initialSpeedAbsolute double
---@return double newAbsoluteSpeed
TrainUtils.CalculateAcceleratingTrainSpeedForSingleTick = function(trainData, initialSpeedAbsolute)
    return math_min((math_max(0, initialSpeedAbsolute - trainData.trainWeightedFrictionForce) + trainData.locomotiveFuelAccelerationPower) * trainData.trainAirResistanceReductionMultiplier, trainData.maxSpeed)
end

--- Estimates how long an accelerating train takes to cover a distance and its final speed. Approximately accounts for air resistance, but final value will be a little off.
---
--- Note: none of the train speed/ticks/distance estimation functions give quite the same results as each other.
---@param trainData TrainUtils_TrainSpeedCalculationData
---@param initialSpeedAbsolute double
---@param distance double
---@return uint ticks # Rounded up.
---@return double absoluteFinalSpeed
TrainUtils.EstimateAcceleratingTrainTicksAndFinalSpeedToCoverDistance = function(trainData, initialSpeedAbsolute, distance)
    -- Work out how long it will take to accelerate over the distance. This doesn't (can't) limit the train to its max speed.
    local initialSpeedAirResistance = (1 - trainData.trainAirResistanceReductionMultiplier) * initialSpeedAbsolute
    local acceleration = trainData.locomotiveFuelAccelerationPower - trainData.trainWeightedFrictionForce - initialSpeedAirResistance
    local ticks = math_ceil((math_sqrt(2 * acceleration * distance + (initialSpeedAbsolute ^ 2)) - initialSpeedAbsolute) / acceleration) --[[@as uint]]

    -- Check how fast the train would have been going at the end of this period. This may be greater than max speed.
    local finalSpeed = initialSpeedAbsolute + (acceleration * ticks)

    -- If the train would be going faster than max speed at the end then cap at max speed and estimate extra time at this speed.
    if finalSpeed > trainData.maxSpeed then
        -- Work out how long and the distance covered it will take to get up to max speed. Code logic copied From TrainUtils.EstimateAcceleratingTrainTicksAndDistanceFromInitialToFinalSpeed().
        local ticksToMaxSpeed = math_ceil((trainData.maxSpeed - initialSpeedAbsolute) / acceleration) --[[@as uint]]
        local distanceToMaxSpeed = (ticksToMaxSpeed * initialSpeedAbsolute) + (((trainData.maxSpeed - initialSpeedAbsolute) * ticksToMaxSpeed) / 2)

        -- Work out how long it will take to cover the remaining distance at max speed.
        local ticksAtMaxSpeed = math_ceil((distance - distanceToMaxSpeed) / trainData.maxSpeed) --[[@as uint]]

        -- Set the final results.
        ticks = ticksToMaxSpeed + ticksAtMaxSpeed
        finalSpeed = trainData.maxSpeed
    end

    return ticks, finalSpeed
end

--- Estimates train speed and distance covered after set number of ticks. Approximately accounts for air resistance, but final value will be a little off.
---
--- Note: none of the train speed/ticks/distance estimation functions give quite the same results as each other.
---@param trainData TrainUtils_TrainSpeedCalculationData
---@param initialSpeedAbsolute double
---@param ticks uint
---@return double finalSpeedAbsolute
---@return double distanceCovered
TrainUtils.EstimateAcceleratingTrainSpeedAndDistanceForTicks = function(trainData, initialSpeedAbsolute, ticks)
    local initialSpeedAirResistance = (1 - trainData.trainAirResistanceReductionMultiplier) * initialSpeedAbsolute
    local acceleration = trainData.locomotiveFuelAccelerationPower - trainData.trainWeightedFrictionForce - initialSpeedAirResistance
    local newSpeedAbsolute = math_min(initialSpeedAbsolute + (acceleration * ticks), trainData.maxSpeed)
    local distanceTravelled = (ticks * initialSpeedAbsolute) + (((newSpeedAbsolute - initialSpeedAbsolute) * ticks) / 2)
    return newSpeedAbsolute, distanceTravelled
end

--- Estimate how long it takes in ticks and distance for a train to accelerate from a starting speed to a final speed.
---
--- Note: none of the train speed/ticks/distance estimation functions give quite the same results as each other.
---@param trainData TrainUtils_TrainSpeedCalculationData
---@param initialSpeedAbsolute double
---@param requiredSpeedAbsolute double
---@return uint ticksTaken # Rounded up.
---@return double distanceCovered
TrainUtils.EstimateAcceleratingTrainTicksAndDistanceFromInitialToFinalSpeed = function(trainData, initialSpeedAbsolute, requiredSpeedAbsolute)
    local initialSpeedAirResistance = (1 - trainData.trainAirResistanceReductionMultiplier) * initialSpeedAbsolute
    local acceleration = trainData.locomotiveFuelAccelerationPower - trainData.trainWeightedFrictionForce - initialSpeedAirResistance
    local ticks = math_ceil((requiredSpeedAbsolute - initialSpeedAbsolute) / acceleration) --[[@as uint]]
    local distance = (ticks * initialSpeedAbsolute) + (((requiredSpeedAbsolute - initialSpeedAbsolute) * ticks) / 2)
    return ticks, distance
end

--- Estimate how fast a train can go a distance while starting and ending the distance with the same speed, so it accelerates and brakes over the distance. Train speed during this is capped to it's max speed.
---
--- Note: none of the train speed/ticks/distance estimation functions give quite the same results as each other.
---@param trainData TrainUtils_TrainSpeedCalculationData
---@param targetSpeedAbsolute double
---@param distance double
---@param forcesBrakingForceBonus double # The force's train_braking_force_bonus.
---@return uint ticks # Rounded up.
TrainUtils.EstimateTrainTicksToCoverDistanceWithSameStartAndEndSpeed = function(trainData, targetSpeedAbsolute, distance, forcesBrakingForceBonus)
    -- Get the acceleration and braking force per tick.
    local initialSpeedAirResistance = (1 - trainData.trainAirResistanceReductionMultiplier) * targetSpeedAbsolute
    local accelerationForcePerTick = trainData.locomotiveFuelAccelerationPower - trainData.trainWeightedFrictionForce - initialSpeedAirResistance
    local trainForceBrakingForce = trainData.trainRawBrakingForce + (trainData.trainRawBrakingForce * forcesBrakingForceBonus)
    local brakingForcePerTick = (trainForceBrakingForce + trainData.trainFrictionForce) / trainData.trainWeight

    -- This estimates distance that has to be spent on the speed change action. So a greater ratio of acceleration to braking force means more distance will be spent braking than accelerating.
    local accelerationToBrakingForceRatio = accelerationForcePerTick / (accelerationForcePerTick + brakingForcePerTick)
    local accelerationDistance = distance * (1 - accelerationToBrakingForceRatio)

    -- Estimate how long it would take to accelerate over this distance and how fast the train would have been going at the end of this period. This may be greater than max speed.
    local accelerationTicks = (math_sqrt(2 * accelerationForcePerTick * accelerationDistance + (targetSpeedAbsolute ^ 2)) - targetSpeedAbsolute) / accelerationForcePerTick
    local finalSpeed = targetSpeedAbsolute + (accelerationForcePerTick * accelerationTicks)

    -- Based on if the train would be going faster than its max speed handle the braking time part differently.
    local ticks ---@type uint
    if finalSpeed > trainData.maxSpeed then
        -- The train would be going faster than max speed at the end so re-estimate acceleration up to the max speed cap and then the time it will take at max speed to cover the required distance.

        -- Work out how long and the distance covered it will take to get up to max speed. Code logic copied From TrainUtils.EstimateAcceleratingTrainTicksAndDistanceFromInitialToFinalSpeed().
        local ticksToMaxSpeed = (trainData.maxSpeed - targetSpeedAbsolute) / accelerationForcePerTick
        local distanceToMaxSpeed = (ticksToMaxSpeed * targetSpeedAbsolute) + (((trainData.maxSpeed - targetSpeedAbsolute) * ticksToMaxSpeed) / 2)

        -- Work out how long it will take to brake from max speed back to the required finish speed.
        local ticksToBrake = (trainData.maxSpeed - targetSpeedAbsolute) / brakingForcePerTick
        local distanceToBrake = (ticksToBrake * targetSpeedAbsolute) + (((trainData.maxSpeed - targetSpeedAbsolute) * ticksToBrake) / 2)

        -- Work out how long it will take to cover the remaining distance at max speed.
        local ticksAtMaxSpeed = (distance - distanceToMaxSpeed - distanceToBrake) / trainData.maxSpeed

        -- Update the final results.
        ticks = math.ceil(ticksToMaxSpeed + ticksAtMaxSpeed + ticksToBrake) --[[@as uint]]
    else
        -- The train didn't reach max speed when accelerating so stopping ticks is for just the braking ratio of distance.
        local brakingDistance = distance * accelerationToBrakingForceRatio
        local brakingTicks = (math_sqrt(2 * brakingForcePerTick * brakingDistance + (targetSpeedAbsolute ^ 2)) - targetSpeedAbsolute) / brakingForcePerTick
        ticks = math.ceil(accelerationTicks + brakingTicks) --[[@as uint]]
    end

    return ticks
end

--- Calculates the braking distance and ticks for a train at a given speed to brake to a required speed.
---@param trainData TrainUtils_TrainSpeedCalculationData
---@param initialSpeedAbsolute double
---@param requiredSpeedAbsolute double
---@param forcesBrakingForceBonus double # The force's train_braking_force_bonus.
---@return uint ticksToStop # Rounded up.
---@return double brakingDistance
TrainUtils.CalculateBrakingTrainTimeAndDistanceFromInitialToFinalSpeed = function(trainData, initialSpeedAbsolute, requiredSpeedAbsolute, forcesBrakingForceBonus)
    local speedToDropAbsolute = initialSpeedAbsolute - requiredSpeedAbsolute
    local trainForceBrakingForce = trainData.trainRawBrakingForce + (trainData.trainRawBrakingForce * forcesBrakingForceBonus)
    local ticksToStop = math_ceil(speedToDropAbsolute / ((trainForceBrakingForce + trainData.trainFrictionForce) / trainData.trainWeight)) --[[@as uint]]
    local brakingDistance = (ticksToStop * requiredSpeedAbsolute) + ((ticksToStop / 2.0) * speedToDropAbsolute)
    return ticksToStop, brakingDistance
end

--- Calculates the final train speed and distance covered if it brakes for a time period.
---@param trainData TrainUtils_TrainSpeedCalculationData
---@param currentSpeedAbsolute double
---@param forcesBrakingForceBonus double # The force's train_braking_force_bonus.
---@param ticksToBrake uint
---@return double newSpeedAbsolute
---@return double distanceCovered
TrainUtils.CalculateBrakingTrainSpeedAndDistanceCoveredForTime = function(trainData, currentSpeedAbsolute, forcesBrakingForceBonus, ticksToBrake)
    local trainForceBrakingForce = trainData.trainRawBrakingForce + (trainData.trainRawBrakingForce * forcesBrakingForceBonus)
    local tickBrakingReduction = (trainForceBrakingForce + trainData.trainFrictionForce) / trainData.trainWeight
    local newSpeedAbsolute = currentSpeedAbsolute - (tickBrakingReduction * ticksToBrake)
    local speedDropped = currentSpeedAbsolute - newSpeedAbsolute
    local distanceCovered = (ticksToBrake * newSpeedAbsolute) + ((ticksToBrake / 2.0) * speedDropped)
    return newSpeedAbsolute, distanceCovered
end

--- Calculates a train's time taken and initial speed to brake to a final speed over a distance.
---
--- Caps the initial speed generated at the trains max speed.
---@param trainData TrainUtils_TrainSpeedCalculationData
---@param distance double
---@param finalSpeedAbsolute double
---@param forcesBrakingForceBonus double # The force's train_braking_force_bonus.
---@return uint ticksToBrakeOverDistance # Rounded up.
---@return double initialAbsoluteSpeed
TrainUtils.CalculateBrakingTrainsTimeAndStartingSpeedToBrakeToFinalSpeedOverDistance = function(trainData, distance, finalSpeedAbsolute, forcesBrakingForceBonus)
    local trainForceBrakingForce = trainData.trainRawBrakingForce + (trainData.trainRawBrakingForce * forcesBrakingForceBonus)
    local tickBrakingReduction = (trainForceBrakingForce + trainData.trainFrictionForce) / trainData.trainWeight
    local initialSpeed = math_sqrt((finalSpeedAbsolute ^ 2) + (2 * tickBrakingReduction * distance))

    if initialSpeed > trainData.maxSpeed then
        -- Initial speed is greater than max speed so cap the initial speed to max speed.
        initialSpeed = trainData.maxSpeed
    end

    local speedToDropAbsolute = initialSpeed - finalSpeedAbsolute
    local ticks = math_ceil(speedToDropAbsolute / tickBrakingReduction) --[[@as uint]]

    return ticks, initialSpeed
end

--- Returns the new absolute speed for the train in 1 tick from current speed to stop within the required distance. This ignores any train data and will stop the train in time regardless of its braking force. The result can be applied to the current speed each tick to get the new speed.
---@param currentSpeedAbsolute double
---@param distance double
---@return double brakingForceSpeedMultiplier
TrainUtils.CalculateBrakingTrainSpeedForSingleTickToStopWithinDistance = function(currentSpeedAbsolute, distance)
    -- Use a mass of 1.
    local brakingSpeedReduction = (0.5 * 1 * currentSpeedAbsolute * currentSpeedAbsolute) / distance
    return currentSpeedAbsolute - brakingSpeedReduction
end

--- Kills any carriages that would prevent the rail from being removed. If a carriage is not destructible make it so, so it can be killed normally and appear in death stats, etc.
---@param railEntity LuaEntity
---@param killForce LuaForce
---@param killerCauseEntity LuaEntity
---@param surface LuaSurface
TrainUtils.DestroyCarriagesOnRailEntity = function(railEntity, killForce, killerCauseEntity, surface)
    -- Check if any carriage prevents the rail from being removed before just killing all carriages within the rails collision boxes as this is more like vanilla behavior.
    if not railEntity.can_be_destroyed() then
        local railEntityCollisionBox = PrototypeAttributes.GetAttribute("entity", railEntity.name, "collision_box")
        local positionedCollisionBox = PositionUtils.ApplyBoundingBoxToPosition(railEntity.position, railEntityCollisionBox, railEntity.orientation)
        local carriagesFound = surface.find_entities_filtered { area = positionedCollisionBox, type = { "locomotive", "cargo-wagon", "fluid-wagon", "artillery-wagon" } }
        for _, carriage in pairs(carriagesFound) do
            -- If the carriage is currently not destructible make it so, so we can kill it normally.
            if not carriage.destructible then
                carriage.destructible = true
            end
            EntityUtils.EntityDie(carriage, killForce, killerCauseEntity)
        end
        if railEntity.type == "curved-rail" then
            railEntityCollisionBox = PrototypeAttributes.GetAttribute("entity", railEntity.name, "secondary_collision_box")
            positionedCollisionBox = PositionUtils.ApplyBoundingBoxToPosition(railEntity.position, railEntityCollisionBox, railEntity.orientation)
            carriagesFound = surface.find_entities_filtered { area = positionedCollisionBox, type = { "locomotive", "cargo-wagon", "fluid-wagon", "artillery-wagon" } }
            for _, carriage in pairs(carriagesFound) do
                -- If the carriage is currently not destructible make it so, so we can kill it normally.
                if not carriage.destructible then
                    carriage.destructible = true
                end
                EntityUtils.EntityDie(carriage, killForce, killerCauseEntity)
            end
        end
    end
end

--- Mines any carriages that would prevent the rail from being removed.
---@param railEntity LuaEntity
---@param surface LuaSurface
---@param ignoreMinableEntityFlag boolean # If TRUE an entities "minable" attribute will be ignored and the entity mined. If FALSE then the entities "minable" attribute will be honoured.
---@param destinationInventory LuaInventory
---@param stopTrain boolean # If TRUE stops the train that it will try and mine.
TrainUtils.MineCarriagesOnRailEntity = function(railEntity, surface, ignoreMinableEntityFlag, destinationInventory, stopTrain)
    -- Check if any carriage prevents the rail from being removed before just killing all carriages within the rails collision boxes as this is more like vanilla behavior.
    if not railEntity.can_be_destroyed() then
        local railEntityCollisionBox = PrototypeAttributes.GetAttribute("entity", railEntity.name, "collision_box")
        local positionedCollisionBox = PositionUtils.ApplyBoundingBoxToPosition(railEntity.position, railEntityCollisionBox, railEntity.orientation)
        local carriagesFound = surface.find_entities_filtered { area = positionedCollisionBox, type = { "locomotive", "cargo-wagon", "fluid-wagon", "artillery-wagon" } }
        for _, carriage in pairs(carriagesFound) do
            -- If stopTrain is enabled and the carriage is currently moving stop its train.
            if stopTrain then
                if carriage.speed ~= 0 then
                    carriage.train.speed = 0.0
                    carriage.train.manual_mode = true
                end
            end
            carriage.mine { inventory = destinationInventory, ignore_minable = ignoreMinableEntityFlag, raise_destroyed = true }
        end
        if railEntity.type == "curved-rail" then
            railEntityCollisionBox = PrototypeAttributes.GetAttribute("entity", railEntity.name, "secondary_collision_box")
            positionedCollisionBox = PositionUtils.ApplyBoundingBoxToPosition(railEntity.position, railEntityCollisionBox, railEntity.orientation)
            carriagesFound = surface.find_entities_filtered { area = positionedCollisionBox, type = { "locomotive", "cargo-wagon", "fluid-wagon", "artillery-wagon" } }
            for _, carriage in pairs(carriagesFound) do
                -- If stopTrain is enabled and the carriage is currently moving stop its train.
                if stopTrain then
                    if carriage.speed ~= 0 then
                        carriage.train.speed = 0.0
                        carriage.train.manual_mode = true
                    end
                end
                carriage.mine { inventory = destinationInventory, ignore_minable = ignoreMinableEntityFlag, raise_destroyed = true }
            end
        end
    end
end

return TrainUtils
