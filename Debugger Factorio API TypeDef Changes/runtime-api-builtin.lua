---@meta
---@diagnostic disable

--$Factorio 1.1.61
--$Overlay 5
--$Section builtin
-- This file is automatically generated. Edits will be overwritten.

---A double-precision floating-point number. This is the same data type as all Lua numbers use.
---
---[View documentation](https://lua-api.factorio.com/latest/Builtin-Types.html#double)
---@alias double number

---A floating-point number. This is a single-precision floating point number. Whilst Lua only uses double-precision numbers, when a function takes a float, the game engine will immediately convert the double-precision number to single-precision.
---
---[View documentation](https://lua-api.factorio.com/latest/Builtin-Types.html#float)
---@class float:number
---@operator add(float):float
---@operator sub(float):float
---@operator mul(float):float
---@operator div(float):float

---32-bit signed integer. Possible values are -2,147,483,648 to 2,147,483,647.
---
---[View documentation](https://lua-api.factorio.com/latest/Builtin-Types.html#int)
---@alias int integer
---@operator add(int):int
---@operator sub(int):int
---@operator mul(int):int

---8-bit signed integer. Possible values are -128 to 127.
---
---[View documentation](https://lua-api.factorio.com/latest/Builtin-Types.html#int8)
---@class int8:integer
---@operator add(int8):int8
---@operator sub(int8):int8
---@operator mul(int8):int8

---32-bit unsigned integer. Possible values are 0 to 4,294,967,295.
---
---[View documentation](https://lua-api.factorio.com/latest/Builtin-Types.html#uint)
---@class uint:integer
---@operator add(uint):uint
---@operator sub(uint):uint
---@operator mul(uint):uint

---16-bit unsigned integer. Possible values are 0 to 65535.
---
---[View documentation](https://lua-api.factorio.com/latest/Builtin-Types.html#uint16)
---@class uint16:uint
---@operator add(uint16):uint16
---@operator sub(uint16):uint16
---@operator mul(uint16):uint16

---64-bit unsigned integer. Possible values are 0 to 18,446,744,073,709,551,615.
---
---[View documentation](https://lua-api.factorio.com/latest/Builtin-Types.html#uint64)
---@class uint64:uint
---@operator add(uint64):uint64
---@operator sub(uint64):uint64
---@operator mul(uint64):uint64

---8-bit unsigned integer. Possible values are 0 to 255.
---
---[View documentation](https://lua-api.factorio.com/latest/Builtin-Types.html#uint8)
---@class uint8:uint
---@operator add(uint8):uint8
---@operator sub(uint8):uint8
---@operator mul(uint8):uint8

