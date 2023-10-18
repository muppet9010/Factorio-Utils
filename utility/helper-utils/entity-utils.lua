--[[
    All Factorio LuaEntity related utils functions.
]]
--

local EntityUtils = {} ---@class Utility_EntityUtils
local PositionUtils = require("utility.helper-utils.position-utils")

local MovablePrototypeTypes = { unit = "unit", character = "character", car = "car", tank = "tank", ["spider-vehicle"] = "spider-vehicle" }

--- Returns all objects in the area that match the very specific requirements.
---@param surface LuaSurface
---@param positionedBoundingBox BoundingBox
---@param collisionBoxOnlyEntities boolean
---@param onlyForceAffected? LuaForce
---@param onlyDestructible boolean
---@param onlyKillable boolean
---@param entitiesExcluded? LuaEntity[]
---@return table<int, LuaEntity>
EntityUtils.ReturnAllObjectsInArea = function(surface, positionedBoundingBox, collisionBoxOnlyEntities, onlyForceAffected, onlyDestructible, onlyKillable, entitiesExcluded)
    -- CODE NOTE: Looked at using filtered search, but it would only eliminate a few odd prototype types like smoke or projectiles. I would still need to run all of the field checks against the entities found as the individual prototype or entity may have a non default state set on it and I'd want to respect that.
    local entitiesFound = surface.find_entities(positionedBoundingBox)
    local filteredEntitiesFound = {} ---@type table<int, LuaEntity>
    for _, entity in pairs(entitiesFound) do
        local entityExcluded = false
        if entitiesExcluded ~= nil and #entitiesExcluded > 0 then
            for _, excludedEntity in pairs(entitiesExcluded) do
                if entity == excludedEntity then
                    entityExcluded = true
                    break
                end
            end
        end
        if not entityExcluded then
            if (onlyForceAffected == nil) or (entity.force == onlyForceAffected) then
                if (not onlyDestructible) or (entity.destructible) then
                    if (not onlyKillable) or (entity.health ~= nil) then -- This will kill something that has 0 health set by a mod. As this is an edge case and the thing is killable according to the prototype, the destructible check should protect against sensible situations around this.
                        if (not collisionBoxOnlyEntities) or (PositionUtils.IsBoundingBoxPopulated(entity.bounding_box)) then
                            filteredEntitiesFound[#filteredEntitiesFound + 1] = entity
                        end
                    end
                end
            end
        end
    end
    return filteredEntitiesFound
end

--- Kills everything in the area that can be killed, the rest is ignored.
---@param surface LuaSurface
---@param positionedBoundingBox BoundingBox
---@param killerEntity? LuaEntity
---@param collisionBoxOnlyEntities boolean
---@param onlyForceAffected? LuaForce
---@param entitiesExcluded? LuaEntity[]
---@param killerForce? ForceIdentification
EntityUtils.KillAllKillableObjectsInArea = function(surface, positionedBoundingBox, killerEntity, collisionBoxOnlyEntities, onlyForceAffected, entitiesExcluded, killerForce)
    if killerForce == nil then
        killerForce = "neutral"
    end
    for _, entity in pairs(EntityUtils.ReturnAllObjectsInArea(surface, positionedBoundingBox, collisionBoxOnlyEntities, onlyForceAffected, true, true, entitiesExcluded)) do
        if killerEntity ~= nil then
            entity.die(killerForce, killerEntity)
        else
            entity.die(killerForce)
        end
    end
end

--- Kills everything in the area that can be killed, and destroy the rest.
---@param surface LuaSurface
---@param positionedBoundingBox BoundingBox
---@param killerEntity? LuaEntity
---@param onlyForceAffected LuaForce
---@param entitiesExcluded? LuaEntity[]
---@param killerForce? ForceIdentification
EntityUtils.KillAllObjectsInArea = function(surface, positionedBoundingBox, killerEntity, onlyForceAffected, entitiesExcluded, killerForce)
    if killerForce == nil then
        killerForce = "neutral"
    end
    for k, entity in pairs(EntityUtils.ReturnAllObjectsInArea(surface, positionedBoundingBox, false, onlyForceAffected, false, false, entitiesExcluded)) do
        if entity.destructible and entity.health ~= nil then
            if killerEntity ~= nil then
                entity.die(killerForce, killerEntity)
            else
                entity.die(killerForce)
            end
        else
            entity.destroy { do_cliff_correction = true, raise_destroy = true }
        end
    end
end

--- Destroys (removes) everything in the area that is killable.
---@param surface LuaSurface
---@param positionedBoundingBox BoundingBox
---@param collisionBoxOnlyEntities boolean
---@param onlyForceAffected? LuaForce
---@param entitiesExcluded? LuaEntity[]
EntityUtils.DestroyAllKillableObjectsInArea = function(surface, positionedBoundingBox, collisionBoxOnlyEntities, onlyForceAffected, entitiesExcluded)
    for _, entity in pairs(EntityUtils.ReturnAllObjectsInArea(surface, positionedBoundingBox, collisionBoxOnlyEntities, onlyForceAffected, true, true, entitiesExcluded)) do
        entity.destroy { do_cliff_correction = true, raise_destroy = true }
    end
end

--- Destroys (removes) everything in the area regardless of if it is killable. This will catch all entity types, including smoke and other things.
---@param surface LuaSurface
---@param positionedBoundingBox BoundingBox
---@param onlyForceAffected? LuaForce
---@param entitiesExcluded? LuaEntity[]
EntityUtils.DestroyAllObjectsInArea = function(surface, positionedBoundingBox, onlyForceAffected, entitiesExcluded)
    for _, entity in pairs(EntityUtils.ReturnAllObjectsInArea(surface, positionedBoundingBox, false, onlyForceAffected, false, false, entitiesExcluded)) do
        entity.destroy { do_cliff_correction = true, raise_destroy = true }
    end
end

-- Kills an entity and handles the optional arguments as Factorio API doesn't accept nil arguments.
---@param entity LuaEntity
---@param killerForce LuaForce
---@param killerCauseEntity? LuaEntity
EntityUtils.EntityDie = function(entity, killerForce, killerCauseEntity)
    if killerCauseEntity ~= nil then
        entity.die(killerForce, killerCauseEntity)
    else
        entity.die(killerForce)
    end
end

--- Move any teleportable entities in the bounding box of an entity out of the way. Anything non movable can be just killed, `die()` with the created entity as the killer.
---@param surface LuaSurface
---@param centralEntity LuaEntity
---@param killNonMoved boolean
---@param createdEntityForce? LuaForce # The force that will do the kill on any unmoved entity if `killNonMoved == true`. If not provided and needed it is obtained.
EntityUtils.MoveKillableObjectsFromEntityBoundingBox = function(surface, centralEntity, killNonMoved, createdEntityForce)
    local entitiesInTheWay = EntityUtils.ReturnAllObjectsInArea(surface, centralEntity.bounding_box, true, nil, true, true, { centralEntity })
    if #entitiesInTheWay == 0 then return end

    if killNonMoved then
        createdEntityForce = createdEntityForce or centralEntity.force --[[@as LuaForce]]
    end
    local entityMoved, entityNewPosition ---@type boolean, MapPosition?
    for _, entity in pairs(entitiesInTheWay) do
        entityMoved = false
        if MovablePrototypeTypes[entity.type] ~= nil then
            entityNewPosition = surface.find_non_colliding_position(entity.name, entity.position, 2, 0.1)
            if entityNewPosition ~= nil then
                entity.teleport(entityNewPosition)
                entityMoved = true
            end
        end
        if not entityMoved and killNonMoved then
            entity.die(createdEntityForce, centralEntity)
        end
    end
end

return EntityUtils
