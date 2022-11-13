--[[
    Returns and caches prototype attributes (direct children only) as requested to save future API calls.

    Values stored in Lua global variable and populated as requested, as doesn't need persisting. Gets auto refreshed on game load and thus automatically accounts for any change of attributes from mods. Also means the cached values aren't stored in save state or shared between players.
--]]

local PrototypeAttributes = {} ---@class Utility_PrototypeAttributes

MOD = MOD or {} ---@class MOD
MOD.UTILITYPrototypeAttributes = MOD.UTILITYPrototypeAttributes or {} ---@type UtilityPrototypeAttributes_CachedTypes
MOD.UTILITYPrototypeAttributes_Prototypes = MOD.UTILITYPrototypeAttributes_Prototypes or {} ---@type table<string, table<string, UtilityPrototypeAttributes_SupportedLuaPrototypeTypes>> # Prototype type to prototypes.

--- Returns the requested attribute of a named prototype.
---
--- Obtains from the Lua global variable caches if present, otherwise obtains the result and caches it before returning it.
---@param prototypeType UtilityPrototypeAttributes_PrototypeType
---@param prototypeName string
---@param attributeName string
---@param prototype? LuaEntityPrototype|LuaItemPrototype|LuaFluidPrototype|LuaTilePrototype|LuaEquipmentPrototype|LuaRecipePrototype|LuaTechnologyPrototype # The LuaPrototype if its already cached somewhere to save having to obtain it if needed. Although once the value is cached for this prototypeName it won't need to be looked up again this game session.
---@return any # attribute value, can include nil.
PrototypeAttributes.GetAttribute = function(prototypeType, prototypeName, attributeName, prototype)
    local utilityPrototypeAttributes = MOD.UTILITYPrototypeAttributes

    local typeCache = utilityPrototypeAttributes[prototypeType]
    if typeCache == nil then
        typeCache = {}
        utilityPrototypeAttributes[prototypeType] = typeCache
    end

    local prototypeCache = typeCache[prototypeName]
    if prototypeCache == nil then
        prototypeCache = {}
        typeCache[prototypeName] = prototypeCache
    end

    local attributeCache = prototypeCache[attributeName]
    if attributeCache ~= nil then
        return attributeCache.value
    else
        -- If the prototype wasn't passed in then obtain it.
        if prototype == nil then
            local cachedPrototypeTypeList = MOD.UTILITYPrototypeAttributes_Prototypes
            local cachedPrototypeList = cachedPrototypeTypeList[prototypeType]
            if cachedPrototypeList == nil then
                cachedPrototypeList = {}
                cachedPrototypeTypeList[prototypeType] = cachedPrototypeList
            end
            prototype = cachedPrototypeList[prototypeName]
            if prototype == nil then
                if prototypeType == "entity" then
                    prototype = game.entity_prototypes[prototypeName]
                elseif prototypeType == "item" then
                    prototype = game.item_prototypes[prototypeName]
                elseif prototypeType == "fluid" then
                    prototype = game.fluid_prototypes[prototypeName]
                elseif prototypeType == "tile" then
                    prototype = game.tile_prototypes[prototypeName]
                elseif prototypeType == "equipment" then
                    prototype = game.equipment_prototypes[prototypeName]
                elseif prototypeType == "recipe" then
                    prototype = game.recipe_prototypes[prototypeName]
                elseif prototypeType == "technology" then
                    prototype = game.technology_prototypes[prototypeName]
                else
                    error("unsupported prototypeType: " .. tostring(prototypeType))
                end
            end
        end
        local resultValue = prototype[attributeName] ---@type any
        prototypeCache[attributeName] = { value = resultValue }
        return resultValue
    end
end

---@alias UtilityPrototypeAttributes_PrototypeType "entity"|"item"|"fluid"|"tile"|"equipment"|"recipe"|"technology" # not all prototype types are supported at present as not needed before.

---@alias UtilityPrototypeAttributes_CachedTypes table<string, UtilityPrototypeAttributes_CachedPrototypes> # a table of each prototype type name (key) and the prototypes it has of that type.
---@alias UtilityPrototypeAttributes_CachedPrototypes table<string, UtilityPrototypeAttributes_CachedAttributes> # a table of each prototype name (key) and the attributes if has of that prototype.
---@alias UtilityPrototypeAttributes_CachedAttributes table<string, UtilityPrototypeAttributes_CachedAttribute> # a table of each attribute name (key) and their cached values stored in the container.
---@class UtilityPrototypeAttributes_CachedAttribute # Container for the cached value. If it exists the value is cached. An empty table signifies that the cached value is nil.
---@field value any # the value of the attribute. May be nil if that's the attributes real value.

---@alias UtilityPrototypeAttributes_SupportedLuaPrototypeTypes LuaEntityPrototype|LuaItemPrototype|LuaFluidPrototype|LuaTilePrototype|LuaEquipmentPrototype|LuaRecipePrototype|LuaTechnologyPrototype

return PrototypeAttributes
