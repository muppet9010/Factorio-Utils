-- Helper functions that apply across all vehicle types.

local VehicleUtils = {} ---@class Utility_VehicleUtils

--- Checks the vehicle for its current fuel and returns it's prototype. Checks fuel inventories if nothing is currently burning.
---@param vehicle LuaEntity
---@param vehicle_burner? LuaBurner # Optionally passed in, obtained otherwise.
---@return LuaItemPrototype? currentFuelPrototype # Will be nil if there's no current fuel in the vehicle or this vehicle doesn't have a burner.
VehicleUtils.GetVehicleCurrentFuelPrototype = function(vehicle, vehicle_burner)
    local vehicle_burner = vehicle_burner or vehicle.burner
    if vehicle_burner == nil then
        return nil
    end

    -- Check any currently burning fuel inventory first.
    local currentFuelItem = vehicle_burner.currently_burning
    if currentFuelItem ~= nil then
        return currentFuelItem
    end

    -- Check the fuel inventories as this will be burnt next.
    local burner_inventory = vehicle_burner.inventory
    local currentFuelStack
    for i = 1, #burner_inventory do
        currentFuelStack = burner_inventory[i] ---@type LuaItemStack
        if currentFuelStack ~= nil and currentFuelStack.valid_for_read then
            return currentFuelStack.prototype
        end
    end

    -- No fuel found.
    return nil
end

---@class VehicleUtils_BestFuelTrackingTable
---@field fuelName? string # Will be a blank value if no fuel recorded yet.
---@field fuelCount? uint # Will be a blank value if no fuel recorded yet.
---@field fuelValue? float # Will be a blank value if no fuel recorded yet.

--- Tracks the best fuel across multiple calls of the function. Used when wanting to identify the best fuel in a list.
---@param itemName string
---@param itemCount uint
---@param trackingTable? table # Reference to an existing table that the function will populate, or if nil a new table will be made and returned for subsequent loops.
---@return boolean? newBestFuel # Returns true when the fuel is a new best and false when its not. Returns nil if the item isn't a fuel type.
---@return VehicleUtils_BestFuelTrackingTable trackingTable
VehicleUtils.TrackBestFuelCount = function(itemName, itemCount, trackingTable)
    trackingTable = trackingTable or {}
    local itemPrototype = game.item_prototypes[itemName]
    local fuelValue = itemPrototype.fuel_value
    if fuelValue == nil then
        return nil, trackingTable
    end
    if trackingTable.fuelValue == nil or fuelValue > trackingTable.fuelValue then
        trackingTable.fuelName = itemName
        trackingTable.fuelCount = itemCount
        trackingTable.fuelValue = fuelValue
        return true, trackingTable
    end
    if trackingTable.fuelName == itemName and itemCount > trackingTable.fuelCount then
        trackingTable.fuelCount = itemCount
        return true, trackingTable
    end
    return false, trackingTable
end

return VehicleUtils
