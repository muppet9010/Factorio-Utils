--[[
    All LuaInventory related utils functions.
]]
--

local InventoryUtils = {} ---@class Utility_InventoryUtils
local TableUtils = require("utility.helper-utils.table-utils")
local LoggingUtils = require("utility.helper-utils.logging-utils")
local math_min, math_max, math_ceil = math.min, math.max, math.ceil

--- Returns the item name for the provided entity.
---@param entity LuaEntity
---@return string
InventoryUtils.GetEntityReturnedToInventoryName = function(entity)
    if entity.prototype.mineable_properties ~= nil and entity.prototype.mineable_properties.products ~= nil and #entity.prototype.mineable_properties.products > 0 then
        return entity.prototype.mineable_properties.products[1].name
    else
        return entity.name
    end
end

--- Moves the full Lua Item Stacks from the source to the target inventories if possible. So handles items with data and other complicated items. --- Updates the source inventory counts in inventory object.
---@param sourceInventory? LuaInventory # Will check and handle non existent inventory.
---@param targetInventory LuaInventory
---@param dropUnmovedOnGround? boolean # If TRUE then ALL items not moved are dropped on the ground (regardless of ratioToMove value). If FALSE then unmoved items are left in the source inventory. If not provided then defaults to FALSE.
---@param ratioToMove? double # Ratio of the item count to try and move. Float number from 0 to 1. If not provided it defaults to 1. Number of items moved is rounded up.
---@return boolean everythingMoved # If all items were moved successfully in to the targetInventory. Ignores if things were dumped on the ground.
---@return boolean anythingMoved # If any items were moved successfully in to the targetInventory. Ignores if things were dumped on the ground.
InventoryUtils.TryMoveInventoriesLuaItemStacks = function(sourceInventory, targetInventory, dropUnmovedOnGround, ratioToMove)
    -- Set default values.
    ---@type LuaEntity, boolean, boolean
    local sourceOwner, itemAllMoved, anythingMoved = nil, true, false
    if dropUnmovedOnGround == nil then
        dropUnmovedOnGround = false
    end
    if ratioToMove == nil then
        ratioToMove = 1.0
    end

    -- Clamp ratio to between 0 and 1.
    ratioToMove = math_min(math_max(ratioToMove, 0.0), 1.0)

    -- Handle simple returns that don't require item moving.
    if sourceInventory == nil or sourceInventory.is_empty() then
        return true, false
    end
    if ratioToMove == 0 then
        return false, false
    end

    --Do the actual item moving.
    for index = 1, #sourceInventory do
        local itemStack = sourceInventory[index] ---@type LuaItemStack
        if itemStack.valid_for_read then
            -- Work out how many to try and move.
            local itemStack_originalCount = itemStack.count
            local maxToMoveCount = math_ceil(itemStack_originalCount * ratioToMove) --[[@as uint]]

            -- Have to set the source count to be the max amount to move, try the insert, and then set the source count back to the required final result. As this is a game object and so I can't just clone it to try the insert with without losing its associated data.
            itemStack.count = maxToMoveCount
            local movedCount = targetInventory.insert(itemStack)
            itemStack.count = itemStack_originalCount - movedCount

            -- Check what was moved and any next steps.
            if movedCount > 0 then
                anythingMoved = true
            end
            if movedCount < maxToMoveCount then
                itemAllMoved = false
                if dropUnmovedOnGround then
                    sourceOwner = sourceOwner or targetInventory.entity_owner or targetInventory.player_owner
                    sourceOwner.surface.spill_item_stack(sourceOwner.position, itemStack, true, sourceOwner.force, false)
                    itemStack.count = 0
                end
            end
        end
    end

    return itemAllMoved, anythingMoved
end

--- Try and move all equipment from a grid to an inventory.
---
--- Can only move the item name and count via API, Factorio doesn't support putting equipment objects in an inventory. Updates the passed in grid object.
---@param sourceGrid LuaEquipmentGrid
---@param targetInventory LuaInventory
---@param dropUnmovedOnGround? boolean # If TRUE then ALL items not moved are dropped on the ground. If FALSE then unmoved items are left in the source inventory. If not provided then defaults to FALSE.
---@return boolean? everythingMoved? # If all items were moved successfully or not. Nil if no items to move.
InventoryUtils.TryTakeGridsItems = function(sourceGrid, targetInventory, dropUnmovedOnGround)
    -- Set default values.
    if dropUnmovedOnGround == nil then
        dropUnmovedOnGround = false
    end

    -- Handle simple returns that don't require item moving.
    if sourceGrid == nil then
        return nil
    end

    local sourceOwner
    local itemAllMoved = true

    --Do the actual item moving.
    for _, equipment in pairs(sourceGrid.equipment) do
        local moved = targetInventory.insert({ name = equipment.name, count = 1 })
        if moved > 0 then
            sourceGrid.take({ equipment = equipment })
        end
        if moved == 0 then
            itemAllMoved = false
            if dropUnmovedOnGround then
                sourceOwner = sourceOwner or targetInventory.entity_owner or targetInventory.player_owner
                if sourceOwner ~= nil then
                    sourceOwner.surface.spill_item_stack(sourceOwner.position, { name = equipment.name, count = 1 }, true, sourceOwner.force, false)
                else
                    LoggingUtils.LogPrintWarning("Can't spill items on the ground as no source inventory to use position from. InventoryUtils.TryTakeGridsItems().", false)
                end
                sourceGrid.take({ equipment = equipment })
            end
        end
    end
    return itemAllMoved
end

--- Just takes a list of item names and counts that you get from the inventory.get_contents(). Updates the passed in contents object.
---@param contents table<string, uint> # A table of item names to counts, as returned by LuaInventory.get_contents().
---@param targetInventory LuaInventory
---@param dropUnmovedOnGround? boolean # If TRUE then ALL items not moved are dropped on the ground. If FALSE then unmoved items are left in the source inventory. If not provided then defaults to FALSE.
---@param ratioToMove? double # Ratio of the item count to try and move. Float number from 0 to 1. If not provided it defaults to 1. Number of items moved is rounded up.
---@return boolean? everythingMoved? # If all items were moved successfully or not. Nil if no items to move.
InventoryUtils.TryInsertInventoryContents = function(contents, targetInventory, dropUnmovedOnGround, ratioToMove)
    -- Set default values.
    if dropUnmovedOnGround == nil then
        dropUnmovedOnGround = false
    end
    if ratioToMove == nil then
        ratioToMove = 1.0
    end

    -- Clamp ratio to between 0 and 1.
    ratioToMove = math_min(math_max(ratioToMove, 0), 1)

    -- Handle simple returns that don't require item moving.
    if TableUtils.IsTableEmpty(contents) then
        return nil
    end
    if ratioToMove == 0 then
        return false
    end

    local sourceOwner
    local itemAllMoved = true

    --Do the actual item moving.
    for name, count in pairs(contents) do
        local toMove = math_ceil(count * ratioToMove) --[[@as uint # This can't have a multiplier above 1.]]
        local moved = targetInventory.insert({ name = name, count = toMove })
        local remaining = count - moved
        if moved > 0 then
            contents[name] = remaining
        end
        if remaining > 0 then
            itemAllMoved = false
            if dropUnmovedOnGround then
                sourceOwner = sourceOwner or targetInventory.entity_owner or targetInventory.player_owner
                if sourceOwner ~= nil then
                    sourceOwner.surface.spill_item_stack(sourceOwner.position, { name = name, count = remaining }, true, sourceOwner.force, false)
                else
                    LoggingUtils.LogPrintWarning("Can't spill items on the ground as no source inventory to use position from. InventoryUtils.TryTakeGridsItems().", false)
                end
                contents[name] = 0
            end
        end
    end
    return itemAllMoved
end

--- Takes an array of SimpleItemStack and inserts them in to an inventory. Updates each SimpleItemStack passed in with the new count.
---@param simpleItemStacks SimpleItemStack[]
---@param targetInventory LuaInventory
---@param dropUnmovedOnGround? boolean # If TRUE then ALL items not moved are dropped on the ground. If FALSE then unmoved items are left in the source inventory. If not provided then defaults to FALSE.
---@param ratioToMove? double # Ratio of the item count to try and move. Float number from 0 to 1. If not provided it defaults to 1. Number of items moved is rounded up.
---@return boolean? everythingMoved? # If all items were moved successfully or not. Nil if no items to move.
---@deprecated This doesn't handle durability or tags. Also the health needs to be dropped on floor and ammo may need to be dropped on floor if non are inserted.
InventoryUtils.TryInsertSimpleItems = function(simpleItemStacks, targetInventory, dropUnmovedOnGround, ratioToMove)
    -- Set default values.
    if dropUnmovedOnGround == nil then
        dropUnmovedOnGround = false
    end
    if ratioToMove == nil then
        ratioToMove = 1.0
    end

    -- Clamp ratio to between 0 and 1.
    ratioToMove = math_min(math_max(ratioToMove, 0), 1)

    -- Handle simple returns that don't require item moving.
    if simpleItemStacks == nil or #simpleItemStacks == 0 then
        return nil
    end
    if ratioToMove == 0 then
        return false
    end

    local sourceOwner
    local itemAllMoved = true

    --Do the actual item moving.
    for index, simpleItemStack in pairs(simpleItemStacks) do
        -- CODE NOTE: ItemStacks are grouped by Factorio in to full health or damaged (health averaged across all items in itemStack).
        -- CODE NOTE: ItemStacks have a single durability and ammo stat which effectively is for the first item in the itemStack, with the other items in the itemStack all being full.
        -- CODE NOTE: when the itemStack's count is reduced the itemStacks durability and ammo fields are reset to full. As the first item is considered to be the partially used items.
        local toMove = math_ceil(simpleItemStack.count * ratioToMove) --[[@as uint]]
        -- This can't have a multiplier above 1.
        local moved = targetInventory.insert({ name = simpleItemStack.name, count = toMove, health = simpleItemStack.health, ammo = simpleItemStack.ammo })
        local remaining = simpleItemStack.count - moved
        if moved > 0 then
            simpleItemStacks[index].count = remaining
        end
        if remaining > 0 then
            itemAllMoved = false
            if dropUnmovedOnGround then
                sourceOwner = sourceOwner or targetInventory.entity_owner or targetInventory.player_owner
                if sourceOwner ~= nil then
                    sourceOwner.surface.spill_item_stack(sourceOwner.position, { name = simpleItemStack.name, count = remaining }, true, sourceOwner.force, false)
                else
                    LoggingUtils.LogPrintWarning("Can't spill items on the ground as no source inventory to use position from. InventoryUtils.TryTakeGridsItems().", false)
                end
                simpleItemStacks[index].count = 0
            end
        end
    end
    return itemAllMoved
end

--- Get the inventory of the builder (player, bot, or god controller).
---@param builder EntityActioner
InventoryUtils.GetBuilderInventory = function(builder)
    if builder.is_player() then
        return builder.get_main_inventory()
    elseif builder.type ~= nil and builder.type == "construction-robot" then
        return builder.get_inventory(defines.inventory.robot_cargo)
    else
        return builder
    end
end

return InventoryUtils
