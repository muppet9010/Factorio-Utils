--[[
    All data stage prototype related utils functions.

    These were started to be documented, but it was just too painful and so it was stopped. As they are all data stage there are no Sumneko classes pre-defined for anything.
    Some of these functions include tables that take a bunch of numbered fields. If this code is used in new projects these should really be reviewed and replaced with named fields for ease of us. Only used in legacy mods at present so not being redone at present.
]]
--

-- Sumneko should skip checking this file for certain checks at present.
---@diagnostic disable: no-unknown

local PrototypeUtils = {} ---@class Utility_PrototypeUtils
local TableUtils = require("utility.helper-utils.table-utils")
local math_ceil = math.ceil

--- This is a temporary class until factorio-api gets updated to include a full RotatedSprite class.
---@class EmptyRotatedSprite
---@field direction_count uint
---@field filename string
---@field width uint
---@field height uint
---@field repeat_count uint

--- Returns an empty rotated sprite prototype object. For use in data stage.
---@param repeat_count? int|nil @ Defaults to 1 if not provided
---@return EmptyRotatedSprite
PrototypeUtils.MakeEmptyRotatedSpritePrototype_DataStage = function(repeat_count)
    return {
        direction_count = 1,
        filename = "__core__/graphics/empty.png",
        width = 1,
        height = 1,
        repeat_count = repeat_count or 1
    }
end

---@class UtilityPrototypeUtils_IngredientLists
---@field ingredients? table<string, string|double>|nil
---@field normal? table<string, string|double>|nil
---@field expensive? table<string, string|double>|nil

---@class UtilityPrototypeUtils_EnergyLists
---@field ingredients? number|nil
---@field normal? number|nil
---@field expensive? number|nil

--- Takes tables of the various recipe types (normal, expensive and ingredients) and makes the required recipe prototypes from them. Only makes the version if the ingredientsList includes the type. So supplying just energyLists types doesn't make new versions.
---@param recipeName string
---@param resultItemName string
---@param enabled boolean
---@param ingredientLists UtilityPrototypeUtils_IngredientLists @ Often generatered by PrototypeUtils.GetRecipeIngredientsAddedTogeather().
---@param energyLists UtilityPrototypeUtils_EnergyLists
---@return Prototype.Recipe
PrototypeUtils.MakeRecipePrototype = function(recipeName, resultItemName, enabled, ingredientLists, energyLists)
    ---@type Prototype.Recipe
    local recipePrototype = {
        type = "recipe",
        name = recipeName
    }
    if ingredientLists.ingredients ~= nil then
        recipePrototype.energy_required = energyLists.ingredients
        recipePrototype.enabled = enabled
        recipePrototype.result = resultItemName
        recipePrototype.ingredients = ingredientLists.ingredients
    end
    if ingredientLists.normal ~= nil then
        recipePrototype.normal = {
            energy_required = energyLists.normal or energyLists.ingredients,
            enabled = enabled,
            result = resultItemName,
            ingredients = ingredientLists.normal
        }
    end
    if ingredientLists.expensive ~= nil then
        recipePrototype.expensive = {
            energy_required = energyLists.expensive or energyLists.ingredients,
            enabled = enabled,
            result = resultItemName,
            ingredients = ingredientLists.expensive
        }
    end
    return recipePrototype
end

--[[
    Is for handling a mix of recipes and ingredient list. Supports recipe ingredients, normal and expensive.
    Returns the widest range of types fed in as a table of result tables (nil for non required returns): {ingredients, normal, expensive}
    Takes a table (list) of entries. Each entry is a table (list) of recipe/ingredients, handling type and ratioMultiplier (optional), i.e. {{ingredients1, "add"}, {recipe1, "add", 0.5}, {ingredients2, "highest", 2}}
    handling types:
        - add: adds the ingredients from a list to the total
        - subtract: removes the ingredients in this list from the total
        - highest: just takes the highest counts of each ingredients across the 2 lists.
    ratioMultiplier item counts for recipes are rounded up. Defaults to ration of 1 if not provided.
]]
--- Takes a list of ingredients, how they should be combined and returns an ingredients list for use in a recipe prototype.
---@param recipeIngredientHandlingTables table[]
---@return UtilityPrototypeUtils_IngredientLists
PrototypeUtils.GetRecipeIngredientsAddedTogeather = function(recipeIngredientHandlingTables)
    ---@type table, table<'ingredients'|'normal'|'expensive', true>
    local ingredientsTable, ingredientTypes = {}, {}
    for _, recipeIngredientHandlingTable in pairs(recipeIngredientHandlingTables) do
        if recipeIngredientHandlingTable[1].normal ~= nil then
            ingredientTypes.normal = true
        end
        if recipeIngredientHandlingTable[1].expensive ~= nil then
            ingredientTypes.expensive = true
        end
    end
    if TableUtils.IsTableEmpty(ingredientTypes) then
        ingredientTypes.ingredients = true
    end

    for ingredientType in pairs(ingredientTypes) do
        local ingredientsList = {}
        for _, recipeIngredientHandlingTable in pairs(recipeIngredientHandlingTables) do
            local ingredients  ---@type table<string, string|double> @ Try to find the correct ingredients for our desired type, if not found just try all of them to find one to use. Assume its a simple ingredient list last.
            if recipeIngredientHandlingTable[1][ingredientType] ~= nil then
                ingredients = recipeIngredientHandlingTable[1][ingredientType].ingredients or recipeIngredientHandlingTable[1][ingredientType] --[[@as table<string, string|double>]]
            elseif recipeIngredientHandlingTable[1]["ingredients"] ~= nil then
                ingredients = recipeIngredientHandlingTable[1]["ingredients"]
            elseif recipeIngredientHandlingTable[1]["normal"] ~= nil then
                ingredients = recipeIngredientHandlingTable[1]["normal"].ingredients --[[@as table<string, string|double>]]
            elseif recipeIngredientHandlingTable[1]["expensive"] ~= nil then
                ingredients = recipeIngredientHandlingTable[1]["expensive"].ingredients --[[@as table<string, string|double>]]
            else
                ingredients = recipeIngredientHandlingTable[1]
            end
            local handling, ratioMultiplier = recipeIngredientHandlingTable[2], recipeIngredientHandlingTable[3]
            if ratioMultiplier == nil then
                ratioMultiplier = 1
            end
            for _, details in pairs(ingredients) do
                local name, count = details[1] or details.name, math_ceil((details[2] or details.amount) * ratioMultiplier)
                if handling == "add" then
                    ingredientsList[name] = (ingredientsList[name] or 0) + count
                elseif handling == "subtract" then
                    if ingredientsList[name] ~= nil then
                        ingredientsList[name] = ingredientsList[name] - count
                    end
                elseif handling == "highest" then
                    if count > (ingredientsList[name] or 0) then
                        ingredientsList[name] = count
                    end
                end
            end
        end
        ingredientsTable[ingredientType] = {}
        for name, count in pairs(ingredientsList) do
            if ingredientsList[name] > 0 then
                table.insert(ingredientsTable[ingredientType], {name, count})
            end
        end
    end
    return ingredientsTable
end

--- Returns the value of the requested attributeName from the recipe for the recipeCodeType "cost" if available, otherwise the inline/ingredients value is returned.
---@param recipe Prototype.Recipe
---@param attributeName string
---@param recipeCostType? 'ingredients'|'normal'|'expensive'|nil @ Defaults to the 'ingredients' if not provided. The 'ingredients' option will return any inline value first, then the value from the ingredients field.
---@param defaultValue? any @ The default value to return if nothing is found in the hierarchy of "costs" checked.
---@return any|nil value
PrototypeUtils.GetRecipeAttribute = function(recipe, attributeName, recipeCostType, defaultValue)
    recipeCostType = recipeCostType or "ingredients"
    if recipeCostType == "ingredients" and recipe[attributeName] ~= nil then
        return recipe[attributeName]
    elseif recipe[recipeCostType] ~= nil and recipe[recipeCostType][attributeName] ~= nil then
        return recipe[recipeCostType][attributeName]
    end

    if recipe[attributeName] ~= nil then
        return recipe[attributeName]
    elseif recipe["normal"] ~= nil and recipe["normal"][attributeName] ~= nil then
        return recipe["normal"][attributeName]
    elseif recipe["expensive"] ~= nil and recipe["expensive"][attributeName] ~= nil then
        return recipe["expensive"][attributeName]
    end

    return defaultValue -- may well be nil
end

PrototypeUtils.DoesRecipeResultsIncludeItemName = function(recipePrototype, itemName)
    for _, recipeBase in pairs({recipePrototype, recipePrototype.normal, recipePrototype.expensive}) do
        if recipeBase ~= nil then
            if recipeBase.result ~= nil and recipeBase.result == itemName then
                return true
            elseif recipeBase.results ~= nil and #TableUtils.GetTableKeyWithInnerKeyValue(recipeBase.results, "name", itemName) > 0 then
                return true
            end
        end
    end
    return false
end

--[[
    From the provided technology list remove all provided recipes from being unlocked that create an item that can place a given entity prototype.
    Returns a table of the technologies affected or a blank table if no technologies are affected.
]]
PrototypeUtils.RemoveEntitiesRecipesFromTechnologies = function(entityPrototype, recipes, technolgies)
    local technologiesChanged = {}
    local placedByItemName
    if entityPrototype.minable ~= nil and entityPrototype.minable.result ~= nil then
        placedByItemName = entityPrototype.minable.result
    else
        return technologiesChanged
    end
    for _, recipePrototype in pairs(recipes) do
        if PrototypeUtils.DoesRecipeResultsIncludeItemName(recipePrototype, placedByItemName) then
            recipePrototype.enabled = false
            for _, technologyPrototype in pairs(technolgies) do
                if technologyPrototype.effects ~= nil then
                    for effectIndex, effect in pairs(technologyPrototype.effects) do
                        if effect.type == "unlock-recipe" and effect.recipe ~= nil and effect.recipe == recipePrototype.name then
                            table.remove(technologyPrototype.effects, effectIndex)
                            table.insert(technologiesChanged, technologyPrototype)
                        end
                    end
                end
            end
        end
    end
    return technologiesChanged
end

--- Doesn't handle mipmaps at all presently. Also ignores any of the extra data in an icons table of "Types/IconData". Think this should just duplicate the target icons table entry.
---@param entityToClone table @ Any entity prototype.
---@param newEntityName string
---@param subgroup string
---@param collisionMask CollisionMask
---@return table @ A simple entity prototype.
PrototypeUtils.CreatePlacementTestEntityPrototype = function(entityToClone, newEntityName, subgroup, collisionMask)
    local clonedIcon = entityToClone.icon
    local clonedIconSize = entityToClone.icon_size
    if clonedIcon == nil then
        clonedIcon = entityToClone.icons[1].icon
        clonedIconSize = entityToClone.icons[1].icon_size
    end
    return {
        type = "simple-entity",
        name = newEntityName,
        subgroup = subgroup,
        order = "zzz",
        icons = {
            {
                icon = clonedIcon,
                icon_size = clonedIconSize
            },
            {
                icon = "__core__/graphics/cancel.png",
                icon_size = 64,
                scale = (clonedIconSize / 64) * 0.5
            }
        },
        flags = entityToClone.flags,
        selection_box = entityToClone.selection_box,
        collision_box = entityToClone.collision_box,
        collision_mask = collisionMask,
        picture = {
            filename = "__core__/graphics/cancel.png",
            height = 64,
            width = 64
        }
    }
end

PrototypeUtils.CreateLandPlacementTestEntityPrototype = function(entityToClone, newEntityName, subgroup)
    subgroup = subgroup or "other"
    return PrototypeUtils.CreatePlacementTestEntityPrototype(entityToClone, newEntityName, subgroup, {"water-tile", "colliding-with-tiles-only"})
end

PrototypeUtils.CreateWaterPlacementTestEntityPrototype = function(entityToClone, newEntityName, subgroup)
    subgroup = subgroup or "other"
    return PrototypeUtils.CreatePlacementTestEntityPrototype(entityToClone, newEntityName, subgroup, {"ground-tile", "colliding-with-tiles-only"})
end

return PrototypeUtils
