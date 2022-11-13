--[[
    Functionality related to player's weapons. Includes options to force a specific weapon to be given and/or equipped. Returns details so the previous weapon/options can be returned if desired.

    Usage: Call any public functions (not starting with "_") as required.
]]
local PlayerWeapon = {} ---@class Utility_PlayerWeapon

----------------------------------------------------------------------------------
--                          PUBLIC FUNCTIONS
----------------------------------------------------------------------------------

---@class UtilityPlayerWeapon_RemovedWeaponToEnsureWeapon
---@field gunInventoryIndex uint # The index in the gun and ammo inventory where the weapon was removed.
---@field weaponItemName? string # Nil if no weapon was in the slot.
---@field weaponFilterName? string # Nil if no weapon filter was set on the slot.
---@field ammoItemName? string # Nil if no ammo was in the slot.
---@field ammoFilterName? string # Nil if no ammo filter was set on the slot.
---@field beforeSelectedWeaponGunIndex uint # The weapon slot that the player had selected before the weapon was removed.

--- Ensure the player has the specified weapon, clearing any weapon filters if needed. Includes options to ensure compatibility with a specific ammo type, otherwise will ensure the ammo slot setup allows the gun to be placed even if the ammo filter is incompatible.
---@param player LuaPlayer # Requires the player to be in a position to receive the weapon, has character and in character controller.
---@param weaponName string
---@param forceWeaponToWeaponInventorySlot boolean # If the weapon should be forced to be equipped, otherwise it may end up in their inventory.
---@param selectWeapon boolean
---@param ammoTypePlanned? string # The name of the ammo planned to be put in this weapon. Handles removing the ammo from the weapon slot and any filters if needed. Doesn't actually give any ammo.
---@return boolean? weaponGiven # If the weapon item had to be given to the player, compared to them already having it and it possibly just being moved between their inventories. Returns nil for invalid situations, i.e. called on a player with no gun inventory.
---@return UtilityPlayerWeapon_RemovedWeaponToEnsureWeapon? removedWeaponDetails # Details on the weapon that was removed to add the new weapon. Is nil if no active weapon was set/found, i.e. weapon was found/put in to the players main inventory and not as an equipped weapon.
PlayerWeapon.EnsureHasWeapon = function(player, weaponName, forceWeaponToWeaponInventorySlot, selectWeapon, ammoTypePlanned)
    ---@type UtilityPlayerWeapon_RemovedWeaponToEnsureWeapon
    local removedWeaponDetails = {
        beforeSelectedWeaponGunIndex = player.character.selected_gun_index
    }

    -- See if the gun is already equipped by the player in their active gun inventory, or find which of their weapon slots is best to assign too.
    ---@type boolean, uint?, uint?, uint?
    local weaponGiven, weaponFoundIndex, freeGunIndex, freeButFilteredGunIndex = false, nil, nil, nil
    local gunInventory = player.get_inventory(defines.inventory.character_guns)
    if gunInventory == nil then
        return nil, nil
    end
    for gunInventoryIndex = 1, #gunInventory do ---@type uint
        local gunItemStack = gunInventory[gunInventoryIndex]
        if gunItemStack.valid_for_read then
            -- Weapon in this slot.
            if gunItemStack.name == weaponName then
                -- Player already has this gun equipped.
                weaponFoundIndex = gunInventoryIndex
                break
            end
        else
            -- No weapon in slot.
            local filteredName = gunInventory.get_filter(gunInventoryIndex)
            if filteredName == nil or filteredName == weaponName then
                -- Non filtered weapon slot or filtered to the weapon we want to assign.
                freeGunIndex = gunInventoryIndex
            else
                -- Filtered weapon slot to a different weapon.
                freeButFilteredGunIndex = gunInventoryIndex
            end
        end
    end

    -- Handle if the player doesn't already have the gun equipped.
    local needsGunGiving = false
    local characterInventory ---@type LuaInventory? # Only populated if needsGunGiving is true.
    if weaponFoundIndex == nil then
        needsGunGiving = true
        characterInventory = player.get_main_inventory()
        if characterInventory == nil then
            -- Just return as player is in some bad state.
            return nil, nil
        end

        if freeGunIndex ~= nil then
            -- Player has a free slot, so we can just use it.
            weaponFoundIndex = freeGunIndex
        else
            -- Player doesn't have a free slot.
            if forceWeaponToWeaponInventorySlot then
                -- As forceWeaponToWeaponInventorySlot is true and as the player has full gun slots then a weapon (and ammo) slot is "cleared" so that our weapon can then be put there. We select the least inconvenient weapon slot to clear.

                -- Get the best gun slot to clear out and use.
                if freeButFilteredGunIndex ~= nil then
                    -- The player has a gun slot with no weapon, but it is filtered. So use this for our gun.
                    weaponFoundIndex = freeButFilteredGunIndex
                else
                    -- The player only has gun slots with other weapons in them, so select one randomly for our gun.
                    weaponFoundIndex = math.random(1, #gunInventory) --[[@as uint]]
                end

                -- Clear the gun slot ready for the weapon.
                local gunItemStack = gunInventory[weaponFoundIndex]
                if gunItemStack ~= nil and gunItemStack.valid_for_read then
                    local currentName, currentCount = gunItemStack.name, gunItemStack.count
                    local gunInsertedCount = player.insert({ name = currentName, count = currentCount })
                    if gunInsertedCount < currentCount then
                        player.surface.spill_item_stack(player.position, { name = currentName, count = currentCount - gunInsertedCount }, true, nil, false)
                    end
                    removedWeaponDetails.weaponItemName = currentName
                end
                removedWeaponDetails.weaponFilterName = gunInventory.get_filter(weaponFoundIndex)
                gunInventory.set_filter(weaponFoundIndex, nil)
                gunItemStack.clear()
            else
                -- As we won't force the weapon it should go in to the characters inventory if they don't already have one.
                -- As we can't select the weapon the function is done after this.
                if characterInventory.get_item_count(weaponName) == 0 then
                    -- Player doesn't have this weapon in their inventory, so give them one.
                    characterInventory.insert({ name = weaponName, count = 1 })
                    return true, nil
                else
                    -- Player has the weapon in their inventory already.
                    return false, nil
                end
            end
        end ---@cast weaponFoundIndex -nil # All logic paths either ensure its populated or return.
    end

    -- Get the ammo slot for the equipped gun.
    local ammoInventory = player.get_inventory(defines.inventory.character_ammo)
    if ammoInventory == nil then
        -- Just return as player is in some bad state.
        return nil, nil
    end
    local ammoItemStack = ammoInventory[weaponFoundIndex]

    -- Make sure the ammo slot is safe with our set weapon based on any planned ammo type. As otherwise we can't give the gun.
    if ammoTypePlanned ~= nil then
        -- As an expected ammo type is set ensure the ammo stack doesn't have a different ammo type currently in it or filter set.
        if ammoItemStack ~= nil and ammoItemStack.valid_for_read then
            -- Ammo in the slot so need to check its type.
            local currentAmmoName = ammoItemStack.name

            -- Clear the current ammo stack ready for the the planned ammo if not the same.
            if ammoTypePlanned ~= currentAmmoName then
                -- Move it to the players inventory, or the floor.
                local currentAmmoCount = ammoItemStack.count
                local ammoInsertedCount = player.insert({ name = currentAmmoName, count = currentAmmoCount, ammo = ammoItemStack.ammo })
                if ammoInsertedCount < currentAmmoCount then
                    player.surface.spill_item_stack(player.position, { name = currentAmmoName, count = currentAmmoCount - ammoInsertedCount }, true, nil, false)
                end
                removedWeaponDetails.ammoItemName = currentAmmoName
                ammoItemStack.clear()
            end
        end

        -- Clear any incompatible filter on the ammo slot.
        local currentAmmoFilterName = ammoInventory.get_filter(weaponFoundIndex)
        if currentAmmoFilterName ~= nil and currentAmmoFilterName ~= ammoTypePlanned then
            removedWeaponDetails.ammoFilterName = currentAmmoFilterName
            ammoInventory.set_filter(weaponFoundIndex, nil)
        end
    else
        -- No expected ammo type so we just need to remove any incompatible ammo, any filter can stay.
        if ammoItemStack ~= nil and ammoItemStack.valid_for_read then
            -- Ammo in the slot so need to check its compatible with the gun.

            -- Clear the current ammo stack ready for the the planned ammo if not compatible with the gun.
            local ammoType = ammoItemStack.prototype.get_ammo_type("player") ---@cast ammoType - nil
            local ammoIsCompatibleWithGun = PlayerWeapon.IsAmmoCompatibleWithWeapon(ammoType, game.item_prototypes[weaponName])
            if not ammoIsCompatibleWithGun then
                -- Move it to the players inventory, or the floor.
                local currentAmmoName, currentAmmoCount = ammoItemStack.name, ammoItemStack.count
                local ammoInsertedCount = player.insert({ name = currentAmmoName, count = currentAmmoCount, ammo = ammoItemStack.ammo })
                if ammoInsertedCount < currentAmmoCount then
                    player.surface.spill_item_stack(player.position, { name = currentAmmoName, count = currentAmmoCount - ammoInsertedCount }, true, nil, false)
                end
                removedWeaponDetails.ammoItemName = currentAmmoName
                ammoItemStack.clear()
            end
        end
    end

    -- Give the gun if needed. We had to handle ammo first for both when needing a gun giving and not.
    if needsGunGiving then
        ---@cast characterInventory -nil # Inventory was cached already if needsGunGiving was set to true.
        -- Remove 1 item of the weapon type from the players inventory if they had one, to simulate equipping the weapon. Otherwise we will flag this as giving the player a weapon.
        if characterInventory.get_item_count(weaponName) == 0 then
            -- No instance of the weapon in the player's inventory.
            weaponGiven = true
        else
            -- Weapon in players inventory, so remove 1.
            characterInventory.remove({ name = weaponName, count = 1 })
        end

        -- Put the weapon in the player's actual gun slot.
        gunInventory[weaponFoundIndex].set_stack({ name = weaponName, count = 1 })
    end

    -- Set the players active weapon if this is desired.
    if selectWeapon then
        player.character.selected_gun_index = weaponFoundIndex
    end

    -- Record the weapon index that was used in the end.
    removedWeaponDetails.gunInventoryIndex = weaponFoundIndex

    return weaponGiven, removedWeaponDetails
end

--- Sets the players weapon filter back to what was removed. Assumes that anything put in the weapon slot in the mean time is to be overridden.
--- If the player's character is currently alive then it also equips the weapon and ammo from their inventory (assuming they still have them).
---@param player LuaPlayer
---@param removedWeaponDetails UtilityPlayerWeapon_RemovedWeaponToEnsureWeapon
PlayerWeapon.ReturnRemovedWeapon = function(player, removedWeaponDetails)
    ---@type LuaInventory, LuaInventory, LuaInventory
    local playerGunInventory, playerAmmoInventory, playerCharacterInventory = nil, nil, nil
    if removedWeaponDetails.weaponFilterName ~= nil then
        playerGunInventory = playerGunInventory or player.get_inventory(defines.inventory.character_guns)
        playerGunInventory.set_filter(removedWeaponDetails.gunInventoryIndex, removedWeaponDetails.weaponFilterName)
    end
    if removedWeaponDetails.ammoFilterName ~= nil then
        playerAmmoInventory = playerAmmoInventory or player.get_inventory(defines.inventory.character_ammo)
        playerAmmoInventory.set_filter(removedWeaponDetails.gunInventoryIndex, removedWeaponDetails.ammoFilterName)
    end

    -- Return the player's weapon and/or ammo if one was removed and the player has an alive character.
    if player.character then
        -- If a weapon was removed from the slot, so assuming the player still has it in their inventory return it to the weapon slot.
        if removedWeaponDetails.weaponItemName ~= nil then
            playerCharacterInventory = playerCharacterInventory or player.get_main_inventory()
            playerGunInventory = playerGunInventory or player.get_inventory(defines.inventory.character_guns)
            if playerCharacterInventory.get_item_count(removedWeaponDetails.weaponItemName) >= 1 then
                playerCharacterInventory.remove({ name = removedWeaponDetails.weaponItemName, count = 1 })
                playerGunInventory[removedWeaponDetails.gunInventoryIndex].set_stack({ name = removedWeaponDetails.weaponItemName, count = 1 })
            end
        end

        -- If an ammo item was removed from the slot, so assuming the player still has it in their inventory return it to the ammo slot.
        if removedWeaponDetails.ammoItemName ~= nil then
            playerCharacterInventory = playerCharacterInventory or player.get_main_inventory()
            playerAmmoInventory = playerAmmoInventory or player.get_inventory(defines.inventory.character_ammo)
            local ammoItemStackToReturn = playerCharacterInventory.find_item_stack(removedWeaponDetails.ammoItemName)
            if ammoItemStackToReturn ~= nil then
                playerAmmoInventory[removedWeaponDetails.gunInventoryIndex].swap_stack(ammoItemStackToReturn)
            end
        end

        -- Restore the player's active weapon back to what it was before.
        player.character.selected_gun_index = removedWeaponDetails.beforeSelectedWeaponGunIndex
    end
end

--- Take the item from the player (weapon slot, inventory or dropped on ground).
---@param player LuaPlayer
---@param itemName string
---@param itemCount uint
---@return uint
PlayerWeapon.TakeItemFromPlayerOrGround = function(player, itemName, itemCount)
    local removed = 0 ---@type uint
    removed = removed + player.remove_item({ name = itemName, count = itemCount })
    if itemCount == 0 then
        return removed
    end

    local itemsOnGround = player.surface.find_entities_filtered { position = player.position, radius = 10, name = "item-on-ground" }
    for _, itemOnGround in pairs(itemsOnGround) do
        if itemOnGround.stack ~= nil and itemOnGround.stack.name == itemName then
            itemOnGround.destroy()
            removed = removed + 1
            itemCount = itemCount - 1
            if itemCount == 0 then
                break
            end
        end
    end
    return removed
end

--- Checks if an ammo type can be used with a weapon type.
---
--- When getting the AmmoType of the ammo LuaItemPrototype with get_ammo_type() he API will automatically return the 'default' source_type if there isn't one defined for the specific type we ask for. So generally you always want to be specific.
---@param ammoType AmmoType
---@param weaponItemPrototype LuaItemPrototype
---@return boolean compatible
PlayerWeapon.IsAmmoCompatibleWithWeapon = function(ammoType, weaponItemPrototype)
    local weapon_attackParameters = weaponItemPrototype.attack_parameters ---@cast weapon_attackParameters - nil # Is mandatory for `gun` type items. This will error if a non `gun` weaponItemPrototype is passed in, but that should be validated outside of this.

    -- If the weapon has an ammo_type specified then it doesn't take any external ammo type, but generates its own attack effect. So the ammo is never the right type for this weapon. It may still have a category specified, but this doesn't really matter.
    if weapon_attackParameters.ammo_type ~= nil then return false end

    -- There is a weapon list so check if the specific ammo category is in the weapon's category list.
    local currentAmmoType_category = ammoType.category
    local weapon_categories = weapon_attackParameters.ammo_categories ---@cast weapon_categories - nil # If there's no ammo_type on the weapon prototype it must have categories.
    for _, weapon_category in pairs(weapon_categories) do
        if currentAmmoType_category == weapon_category then return true end
    end

    return false
end

--- Gets the details for an ammo type fired from a specific weapon. This doesn't include any deviation values.
---
--- Includes: min and max range, cooldown between shots.
---@param ammoType AmmoType
---@param weaponItemPrototype LuaItemPrototype
---@return float minRange
---@return float maxRange
---@return float cooldown
PlayerWeapon.GetWeaponAmmoDetails = function(ammoType, weaponItemPrototype)
    local weapon_attackParameters = weaponItemPrototype.attack_parameters --[[@as AttackParameters # Is mandatory for `gun` type items. This will error if a non `gun` weaponItemPrototype is passed in, but that should be validated outside of this.]]

    local minRange = weapon_attackParameters.min_range

    local maxRange = weapon_attackParameters.range
    local ammoRangeModifier = ammoType.range_modifier
    if ammoRangeModifier ~= nil then
        maxRange = maxRange * ammoRangeModifier
    end

    local cooldown = weapon_attackParameters.cooldown
    local cooldownModifier = ammoType.cooldown_modifier
    if cooldownModifier ~= nil then
        cooldown = cooldown * cooldownModifier
    end

    return minRange, maxRange, cooldown
end

----------------------------------------------------------------------------------
--                          PRIVATE FUNCTIONS
----------------------------------------------------------------------------------

return PlayerWeapon
