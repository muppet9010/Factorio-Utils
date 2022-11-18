---@meta

---@class LuaSurface
local LuaSurface = {
    ---Get the tile at a given position.
    ---
    ---**Note:** The input position params can also be a single tile position.
    ---
    ---[View documentation](https://lua-api.factorio.com/latest/LuaSurface.html#LuaSurface.get_tile)
    ---@param x int
    ---@param y int
    ---@return LuaTile
    ---@overload fun(position: TilePosition): LuaTile
    get_tile = function(x, y) end,
}

---@class LuaEntity
LuaEntity = {
	--- Is optional parameter. Logged: https://forums.factorio.com/viewtopic.php?f=28&t=97880&p=577348#p577348
	---@param driver LuaEntity|PlayerIdentification|nil@The new driver or `nil` to eject the current driver if any.
	set_driver = function (driver) end
	
	--- Is optional parameter. Logged: https://forums.factorio.com/viewtopic.php?f=28&t=97880&p=577348#p577348
	---@param passenger LuaEntity|PlayerIdentification|nil@The new Passenger or `nil` to eject the current driver if any.
	set_passenger = function (passenger) end
}

---@class Prototype.Entity
---@field flags string[] # This is just an array of strngs in data stage. The Factorio API files by Nexula has it wrong.
---@field icons? IconData[]
---@field icon_size? int16

---@class IconData
---@field icon string
---@field icon_size? int16 # Mandatory for each IconData unless provided at the LuaEntity class level.
---@field scale? double
---@field icon_mipmaps? uint8
---@fie;d shift Vector
---@field tint Color

---@class RotatedAnimation
---@field layers Animation[]
---@field hr_version RotatedAnimation

---@class Animation
---@field width uint
---@field frame_count uint


-- Just add the minimal attributes I need.
---@class MinableProperties
---@field result string

-- Just add the minimal attributes I need.
---@class ModifierPrototype
---@field type string
---@field recipe string

-- Just add the minimal attributes I need.
---@class Animation
---@field draw_as_glow? boolean
---@field layers? Animation[]
---@field hr_version Animation
---@field filename? string
---@field stripes? Stripe[]

-- Just add the minimal attributes I need.
---@class Sprite
---@field hr_version? Sprite

-- Just add the minimal attributes I need.
---@alias AnimationVariations Animation|Animation[]

-- Just add the minimal attributes I need.
---@class Stripe
---@field filename? string

-- Just add the minimal attributes I need.
---@class DamagePrototype
---@field type string




---@class RealOrientation:float
---@operator unm:RealOrientation
---@operator mod:RealOrientation
---@operator add:RealOrientation
---@operator div:RealOrientation
---@operator sub:RealOrientation
---@operator mul:RealOrientation

---@class defines.direction
---@operator unm:defines.direction
---@operator mod:defines.direction
---@operator add:defines.direction
---@operator div:defines.direction
---@operator sub:defines.direction
---@operator mul:defines.direction

---@class defines.direction.north
---@operator unm:defines.direction
---@operator mod:defines.direction
---@operator add:defines.direction
---@operator div:defines.direction
---@operator sub:defines.direction
---@operator mul:defines.direction

---@class defines.direction.northeast
---@operator unm:defines.direction
---@operator mod:defines.direction
---@operator add:defines.direction
---@operator div:defines.direction
---@operator sub:defines.direction
---@operator mul:defines.direction

---@class defines.direction.east
---@operator unm:defines.direction
---@operator mod:defines.direction
---@operator add:defines.direction
---@operator div:defines.direction
---@operator sub:defines.direction
---@operator mul:defines.direction

---@class defines.direction.southeast
---@operator unm:defines.direction
---@operator mod:defines.direction
---@operator add:defines.direction
---@operator div:defines.direction
---@operator sub:defines.direction
---@operator mul:defines.direction

---@class defines.direction.south
---@operator unm:defines.direction
---@operator mod:defines.direction
---@operator add:defines.direction
---@operator div:defines.direction
---@operator sub:defines.direction
---@operator mul:defines.direction

---@class defines.direction.southwest
---@operator unm:defines.direction
---@operator mod:defines.direction
---@operator add:defines.direction
---@operator div:defines.direction
---@operator sub:defines.direction
---@operator mul:defines.direction

---@class defines.direction.west
---@operator unm:defines.direction
---@operator mod:defines.direction
---@operator add:defines.direction
---@operator div:defines.direction
---@operator sub:defines.direction
---@operator mul:defines.direction

---@class defines.direction.northwest
---@operator unm:defines.direction
---@operator mod:defines.direction
---@operator add:defines.direction
---@operator div:defines.direction
---@operator sub:defines.direction
---@operator mul:defines.direction
