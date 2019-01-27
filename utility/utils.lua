local Utils = {}
--local Logging = require("scripts/logging")

function Utils.KillAllObjectsInArea(surface, positionedBoundingBox, killerEntity, collisionBoxOnlyEntities)
    local entitiesFound = surface.find_entities(positionedBoundingBox)
    for k, entity in pairs(entitiesFound) do
        if entity.valid then
            if entity.health ~= nil and entity.destructible and (
                (collisionBoxOnlyEntities and Utils.IsCollisionBoxPopulated(entity.prototype.collision_box))
                or (not collisionBoxOnlyEntities)
            ) then
                entity.die("neutral", killerEntity)
            end
        end
    end
end

function Utils.ApplyBoundingBoxToPosition(centrePos, boundingBox, direction)
	if direction == nil or direction == defines.direction.north then
		return {
			left_top = {
				x = centrePos.x + boundingBox.left_top.x,
				y = centrePos.y + boundingBox.left_top.y
			},
			right_bottom = {
				x = centrePos.x + boundingBox.right_bottom.x,
				y = centrePos.y + boundingBox.right_bottom.y
			}
		}
	else
		game.print("direction not handled yet")
		return {
			left_top = {
				x = centrePos.x + boundingBox.left_top.x,
				y = centrePos.y + boundingBox.left_top.y
			},
			right_bottom = {
				x = centrePos.x + boundingBox.right_bottom.x,
				y = centrePos.y + boundingBox.right_bottom.y
			}
		}
	end
end

function Utils.ApplyOffsetToPosition(position, offset)
    if offset == nil then return position end
    if offset.x ~= nil then
        position.x = position.x + offset.x
    elseif offset[1] ~= nil then
        position.x = position.x + offset[1]
    end
    if offset.y ~= nil then
        position.y = position.y + offset.y
    elseif offset[2] ~= nil then
        position.y = position.y + offset[2]
    end
    return position
end

function Utils.IsCollisionBoxPopulated(collisionBox)
    if collisionBox == nil then return false end
    if collisionBox.left_top.x ~= 0 and collisionBox.left_top.y ~= 0 and collisionBox.right_bottom.x ~= 0 and collisionBox.right_bottom.y ~= 0 then
        return true
    else
        return false
    end
end

function Utils.LogisticEquation(index, height, steepness)
    return height / (1 + math.exp(steepness * (index - 0)))
end

function Utils.ExponentialDecayEquation(index, multiplyer, scale)
    return multiplyer * math.exp(-index * scale)
end

function Utils.RoundNumberToDecimalPlaces(num, numDecimalPlaces)
    local result
	if numDecimalPlaces ~= nil and numDecimalPlaces > 0 then
		local mult = 10 ^ numDecimalPlaces
		result =  math.floor(num * mult + 0.5) / mult
	else
		result = math.floor(num + 0.5)
	end
	if result == "nan" then
		result = 0
	end
	return result
end


--This doesn't guarentee correct on some of the edge cases, but is as close as possible assuming that 1/256 is the variance for the same number (Bilka, Dev on Discord)
function Utils.FuzzyCompareDoubles(num1, logic, num2)
    local numDif = num1 - num2
    local variance = 1/256
    if logic == "=" then
        if numDif < variance and numDif > -variance then return true
        else return false end
    elseif logic == "!=" then
        if numDif < variance and numDif > -variance then return false
        else return true end
    elseif logic == ">" then
        if numDif > variance then return true
        else return false end
    elseif logic == ">=" then
        if numDif > -variance then return true
        else return false end
    elseif logic == "<" then
        if numDif < -variance then return true
        else return false end
    elseif logic == "<=" then
        if numDif < variance then return true
        else return false end
    end
end

function Utils.GetTableLength(table)
	local count = 0
	for _ in pairs(table) do
		 count = count + 1
	end
	return count
end

function Utils.GetTableNonNilLength(table)
	local count = 0
	for k,v in pairs(table) do
		if v ~= nil then
			count = count + 1
		end
	end
	return count
end

function Utils.GetMaxKey(table)
	local max_key = 0
	for k in pairs(table) do
		if k > max_key then
			max_key = k
		end
	end
	return max_key
end

function Utils.CalculateBoundingBoxFromPositionAndRange(position, range)
    return {
        left_top = {
            x = position.x - range,
            y = position.y - range,
        },
        right_bottom = {
            x = position.x + range,
            y = position.y + range,
        }
    }
end

function Utils.CalculateTilesUnderPositionedBoundingBox(positionedBoundingBox)
    local tiles = {}
    for x = positionedBoundingBox.left_top.x, positionedBoundingBox.right_bottom.x do
        for y = positionedBoundingBox.left_top.y, positionedBoundingBox.right_bottom.y do
            table.insert(tiles, {x = x, y = y})
        end
    end
    return tiles
end

function Utils.GetEntityReturnedToInventoryName(entity)
	if entity.prototype.mineable_properties  ~= nil and entity.prototype.mineable_properties.products ~= nil and #entity.prototype.mineable_properties.products > 0 then
		return entity.prototype.mineable_properties.products[1].name
	else
		return entity.name
	end
end

return Utils
