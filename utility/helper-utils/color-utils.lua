--[[
    Utils related to colors, both Factorio Color class and our own Colors list.
]]
--

local ColorUtils = {} ---@class Utility_ColorUtils

--TASK: write a function that gets a random non already used color and returns it. Must store this data in globals and have it take a "colorPurposeName" so it can be run multiple times concurrently.
-- Railway tunnel mod did the below:
--[[
    if locomotives ~= nil then
        local color, colorId, secondaryColorsRemaining
        local primaryColorsRemaining = TableUtils.DeepCopy(TestFunctions.PrimaryLocomotiveColors)
        local currentColorRange, colorLoops = primaryColorsRemaining, 0
        for _, carriage in pairs(locomotives) do
            carriage.train.manual_mode = false

            -- Do preset colors to avoid 2 colors being very close to each other and don't repeat within the same train.

            -- If there's no current colors left then need to look for more.
            if #currentColorRange == 0 then
                if secondaryColorsRemaining == nil then
                    -- Secondary colors not initialised so get them and switch to them.
                    secondaryColorsRemaining = TableUtils.DeepCopy(TestFunctions.SecondaryLocomotiveColors)
                    currentColorRange = secondaryColorsRemaining
                else
                    -- Second colors have all been used up so repopulate the primary and clear the secondary in case later use needs them.
                    secondaryColorsRemaining = nil
                    primaryColorsRemaining = TableUtils.DeepCopy(TestFunctions.PrimaryLocomotiveColors)
                    currentColorRange = primaryColorsRemaining
                    colorLoops = colorLoops + 1
                end
            end

            -- Get a random color and apply it.
            colorId = math.random(1, #currentColorRange)
            color = currentColorRange[colorId]
            color[4] = 255 - colorLoops -- This ensures that the color is technically unique as on the full usage of all primary and secondary colors the alpha will be 1 lower for all colors in the new range usage.
            carriage.color = color

            -- Remove the color from the current range.
            table.remove(currentColorRange, colorId)
        end
    end
]]

return ColorUtils
