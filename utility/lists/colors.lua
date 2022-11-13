-- A list of standard colors for use across mods.

-- CODE NOTE: Can't use generics on the class as then it can't spot usage of invalid ones.

local Colors = {} ---@class Utility_Colors
--https://www.rapidtables.com/web/color/html-color-codes.html
--Excel conversion string: =CONCATENATE("Colors.", B1.0, " = {",  SUBSTITUTE(SUBSTITUTE(D1.0, "(", ""),")",""), ",255} ---@type Color")
-- Custom colors can be added, but shouldn't be removed or changed.

--Custom Colors
Colors.lightRed = { 255.0, 100.0, 100.0, 255.0 } ---@type Color -- Good for red writing on GUI backgrounds.
Colors.midRed = { 255.0, 50.0, 50.0, 255.0 } ---@type Color -- Between red and lightRed, used for writing on the screen.
Colors.guiHeadingColor = { 255.0, 230.0, 192.0, 255.0 } ---@type Color

--Red
Colors.lightsalmon = { 255.0, 160.0, 122.0, 255.0 } ---@type Color
Colors.salmon = { 250.0, 128.0, 114.0, 255.0 } ---@type Color
Colors.darksalmon = { 233.0, 150.0, 122.0, 255.0 } ---@type Color
Colors.lightcoral = { 230.0, 128.0, 128.0, 255.0 } ---@type Color
Colors.indianred = { 205.0, 92.0, 92.0, 255.0 } ---@type Color
Colors.crimson = { 220.0, 20.0, 60.0, 255.0 } ---@type Color
Colors.firebrick = { 178.0, 34.0, 34.0, 255.0 } ---@type Color
Colors.red = { 255.0, 0.0, 0.0, 255.0 } ---@type Color
Colors.darkred = { 139.0, 0.0, 0.0, 255.0 } ---@type Color

--Orange
Colors.coral = { 255.0, 127.0, 80.0, 255.0 } ---@type Color
Colors.tomato = { 255.0, 99.0, 71.0, 255.0 } ---@type Color
Colors.orangered = { 255.0, 69.0, 0.0, 255.0 } ---@type Color
Colors.gold = { 255.0, 215.0, 0.0, 255.0 } ---@type Color
Colors.orange = { 255.0, 165.0, 0.0, 255.0 } ---@type Color
Colors.darkorange = { 255.0, 130.0, 0.0, 255.0 } ---@type Color

--Yellow
Colors.lightyellow = { 255.0, 255.0, 224.0, 255.0 } ---@type Color
Colors.lemonchiffon = { 255.0, 250.0, 205.0, 255.0 } ---@type Color
Colors.lightgoldenrodyellow = { 250.0, 250.0, 210.0, 255.0 } ---@type Color
Colors.papayawhip = { 255.0, 239.0, 213.0, 255.0 } ---@type Color
Colors.moccasin = { 255.0, 228.0, 181.0, 255.0 } ---@type Color
Colors.peachpuff = { 255.0, 218.0, 185.0, 255.0 } ---@type Color
Colors.palegoldenrod = { 238.0, 232.0, 170.0, 255.0 } ---@type Color
Colors.khaki = { 230.0, 230.0, 130.0, 255.0 } ---@type Color
Colors.darkkhaki = { 189.0, 183.0, 107.0, 255.0 } ---@type Color
Colors.yellow = { 255.0, 255.0, 0.0, 255.0 } ---@type Color

--Green
Colors.lawngreen = { 124.0, 252.0, 0.0, 255.0 } ---@type Color
Colors.chartreuse = { 127.0, 255.0, 0.0, 255.0 } ---@type Color
Colors.limegreen = { 50.0, 205.0, 50.0, 255.0 } ---@type Color
Colors.lime = { 0.0, 255.0, 0.0, 255.0 } ---@type Color
Colors.forestgreen = { 34.0, 139.0, 34.0, 255.0 } ---@type Color
Colors.green = { 0.0, 128.0, 0.0, 255.0 } ---@type Color
Colors.darkgreen = { 0.0, 100.0, 0.0, 255.0 } ---@type Color
Colors.greenyellow = { 173.0, 255.0, 47.0, 255.0 } ---@type Color
Colors.yellowgreen = { 154.0, 205.0, 50.0, 255.0 } ---@type Color
Colors.springgreen = { 0.0, 255.0, 127.0, 255.0 } ---@type Color
Colors.mediumspringgreen = { 0.0, 250.0, 154.0, 255.0 } ---@type Color
Colors.lightgreen = { 144.0, 238.0, 144.0, 255.0 } ---@type Color
Colors.palegreen = { 152.0, 251.0, 152.0, 255.0 } ---@type Color
Colors.darkseagreen = { 143.0, 188.0, 143.0, 255.0 } ---@type Color
Colors.mediumseagreen = { 60.0, 179.0, 113.0, 255.0 } ---@type Color
Colors.seagreen = { 46.0, 139.0, 87.0, 255.0 } ---@type Color
Colors.olive = { 128.0, 128.0, 0.0, 255.0 } ---@type Color
Colors.darkolivegreen = { 85.0, 107.0, 47.0, 255.0 } ---@type Color
Colors.olivedrab = { 107.0, 142.0, 35.0, 255.0 } ---@type Color

--Cyan
Colors.lightcyan = { 224.0, 255.0, 255.0, 255.0 } ---@type Color
Colors.cyan = { 0.0, 255.0, 255.0, 255.0 } ---@type Color
Colors.aqua = { 0.0, 255.0, 255.0, 255.0 } ---@type Color
Colors.aquamarine = { 127.0, 255.0, 212.0, 255.0 } ---@type Color
Colors.mediumaquamarine = { 102.0, 205.0, 170.0, 255.0 } ---@type Color
Colors.paleturquoise = { 175.0, 238.0, 238.0, 255.0 } ---@type Color
Colors.turquoise = { 64.0, 224.0, 208.0, 255.0 } ---@type Color
Colors.mediumturquoise = { 72.0, 209.0, 204.0, 255.0 } ---@type Color
Colors.darkturquoise = { 0.0, 206.0, 209.0, 255.0 } ---@type Color
Colors.lightseagreen = { 32.0, 178.0, 170.0, 255.0 } ---@type Color
Colors.cadetblue = { 95.0, 158.0, 160.0, 255.0 } ---@type Color
Colors.darkcyan = { 0.0, 139.0, 139.0, 255.0 } ---@type Color
Colors.teal = { 0.0, 128.0, 128.0, 255.0 } ---@type Color

--Blue
Colors.powderblue = { 176.0, 224.0, 230.0, 255.0 } ---@type Color
Colors.lightblue = { 173.0, 216.0, 230.0, 255.0 } ---@type Color
Colors.lightskyblue = { 135.0, 206.0, 250.0, 255.0 } ---@type Color
Colors.skyblue = { 135.0, 206.0, 235.0, 255.0 } ---@type Color
Colors.deepskyblue = { 0.0, 191.0, 255.0, 255.0 } ---@type Color
Colors.lightsteelblue = { 176.0, 196.0, 222.0, 255.0 } ---@type Color
Colors.dodgerblue = { 30.0, 144.0, 255.0, 255.0 } ---@type Color
Colors.cornflowerblue = { 100.0, 149.0, 237.0, 255.0 } ---@type Color
Colors.steelblue = { 70.0, 130.0, 180.0, 255.0 } ---@type Color
Colors.royalblue = { 65.0, 105.0, 225.0, 255.0 } ---@type Color
Colors.blue = { 0.0, 0.0, 255.0, 255.0 } ---@type Color
Colors.mediumblue = { 0.0, 0.0, 205.0, 255.0 } ---@type Color
Colors.darkblue = { 0.0, 0.0, 139.0, 255.0 } ---@type Color
Colors.navy = { 0.0, 0.0, 128.0, 255.0 } ---@type Color
Colors.midnightblue = { 25.0, 25.0, 112.0, 255.0 } ---@type Color
Colors.mediumslateblue = { 123.0, 104.0, 238.0, 255.0 } ---@type Color
Colors.slateblue = { 106.0, 90.0, 205.0, 255.0 } ---@type Color
Colors.darkslateblue = { 72.0, 61.0, 139.0, 255.0 } ---@type Color

--Purple
Colors.lavender = { 230.0, 230.0, 250.0, 255.0 } ---@type Color
Colors.thistle = { 216.0, 191.0, 216.0, 255.0 } ---@type Color
Colors.plum = { 221.0, 160.0, 221.0, 255.0 } ---@type Color
Colors.violet = { 238.0, 130.0, 238.0, 255.0 } ---@type Color
Colors.orchid = { 218.0, 112.0, 214.0, 255.0 } ---@type Color
Colors.fuchsia = { 255.0, 0.0, 255.0, 255.0 } ---@type Color
Colors.magenta = { 255.0, 0.0, 255.0, 255.0 } ---@type Color
Colors.mediumorchid = { 186.0, 85.0, 211.0, 255.0 } ---@type Color
Colors.mediumpurple = { 147.0, 112.0, 219.0, 255.0 } ---@type Color
Colors.blueviolet = { 138.0, 43.0, 226.0, 255.0 } ---@type Color
Colors.darkviolet = { 148.0, 0.0, 211.0, 255.0 } ---@type Color
Colors.darkorchid = { 153.0, 50.0, 204.0, 255.0 } ---@type Color
Colors.darkmagenta = { 139.0, 0.0, 139.0, 255.0 } ---@type Color
Colors.purple = { 128.0, 0.0, 128.0, 255.0 } ---@type Color
Colors.indigo = { 75.0, 0.0, 130.0, 255.0 } ---@type Color

--Pink
Colors.pink = { 255.0, 192.0, 203.0, 255.0 } ---@type Color
Colors.lightpink = { 255.0, 182.0, 193.0, 255.0 } ---@type Color
Colors.hotpink = { 255.0, 105.0, 180.0, 255.0 } ---@type Color
Colors.deeppink = { 255.0, 20.0, 147.0, 255.0 } ---@type Color
Colors.palevioletred = { 219.0, 112.0, 147.0, 255.0 } ---@type Color
Colors.mediumvioletred = { 199.0, 21.0, 133.0, 255.0 } ---@type Color

--White
Colors.white = { 255.0, 255.0, 255.0, 255.0 } ---@type Color
Colors.snow = { 255.0, 250.0, 250.0, 255.0 } ---@type Color
Colors.honeydew = { 230.0, 255.0, 230.0, 255.0 } ---@type Color
Colors.mintcream = { 245.0, 255.0, 250.0, 255.0 } ---@type Color
Colors.azure = { 230.0, 255.0, 255.0, 255.0 } ---@type Color
Colors.aliceblue = { 230.0, 248.0, 255.0, 255.0 } ---@type Color
Colors.ghostwhite = { 248.0, 248.0, 255.0, 255.0 } ---@type Color
Colors.whitesmoke = { 245.0, 245.0, 245.0, 255.0 } ---@type Color
Colors.seashell = { 255.0, 245.0, 238.0, 255.0 } ---@type Color
Colors.beige = { 245.0, 245.0, 220.0, 255.0 } ---@type Color
Colors.oldlace = { 253.0, 245.0, 230.0, 255.0 } ---@type Color
Colors.floralwhite = { 255.0, 250.0, 230.0, 255.0 } ---@type Color
Colors.ivory = { 255.0, 255.0, 230.0, 255.0 } ---@type Color
Colors.antiquewhite = { 250.0, 235.0, 215.0, 255.0 } ---@type Color
Colors.linen = { 250.0, 230.0, 230.0, 255.0 } ---@type Color
Colors.lavenderblush = { 255.0, 230.0, 245.0, 255.0 } ---@type Color
Colors.mistyrose = { 255.0, 228.0, 225.0, 255.0 } ---@type Color

--Grey
Colors.gainsboro = { 220.0, 220.0, 220.0, 255.0 } ---@type Color
Colors.lightgrey = { 211.0, 211.0, 211.0, 255.0 } ---@type Color
Colors.silver = { 192.0, 192.0, 192.0, 255.0 } ---@type Color
Colors.darkgrey = { 169.0, 169.0, 169.0, 255.0 } ---@type Color
Colors.grey = { 128.0, 128.0, 128.0, 255.0 } ---@type Color
Colors.dimgrey = { 105.0, 105.0, 105.0, 255.0 } ---@type Color
Colors.lightslategrey = { 119.0, 136.0, 153.0, 255.0 } ---@type Color
Colors.slategrey = { 112.0, 128.0, 144.0, 255.0 } ---@type Color
Colors.darkslategrey = { 47.0, 79.0, 79.0, 255.0 } ---@type Color
Colors.black = { 0.0, 0.0, 0.0, 255.0 } ---@type Color

--Brown
Colors.cornsilk = { 255.0, 248.0, 220.0, 255.0 } ---@type Color
Colors.blanchedalmond = { 255.0, 235.0, 205.0, 255.0 } ---@type Color
Colors.bisque = { 255.0, 228.0, 196.0, 255.0 } ---@type Color
Colors.navajowhite = { 255.0, 222.0, 173.0, 255.0 } ---@type Color
Colors.wheat = { 245.0, 222.0, 179.0, 255.0 } ---@type Color
Colors.burlywood = { 222.0, 184.0, 135.0, 255.0 } ---@type Color
Colors.tan = { 210.0, 180.0, 130.0, 255.0 } ---@type Color
Colors.rosybrown = { 188.0, 143.0, 143.0, 255.0 } ---@type Color
Colors.sandybrown = { 244.0, 164.0, 96.0, 255.0 } ---@type Color
Colors.goldenrod = { 218.0, 165.0, 32.0, 255.0 } ---@type Color
Colors.peru = { 205.0, 133.0, 63.0, 255.0 } ---@type Color
Colors.chocolate = { 210.0, 105.0, 30.0, 255.0 } ---@type Color
Colors.saddlebrown = { 139.0, 69.0, 19.0, 255.0 } ---@type Color
Colors.sienna = { 160.0, 82.0, 45.0, 255.0 } ---@type Color
Colors.brown = { 165.0, 42.0, 42.0, 255.0 } ---@type Color
Colors.maroon = { 128.0, 0.0, 0.0, 255.0 } ---@type Color

-- Named presets - Must be last so we can reference already added values.
Colors.errorMessage = Colors.midRed
Colors.warningMessage = Colors.orange

--- A primary list of unique colors.
Colors.PrimaryLocomotiveColors = {
    Colors.red,
    Colors.darkorange,
    Colors.yellow,
    Colors.lime,
    Colors.cyan,
    Colors.blue,
    Colors.darkviolet,
    Colors.black,
    Colors.lavender
}

--- A secondary list of less unique colors.
Colors.SecondaryLocomotiveColors = {
    Colors.grey,
    Colors.teal,
    Colors.lightblue,
    Colors.green,
    Colors.brown,
    Colors.wheat,
    Colors.deeppink,
    Colors.olive,
    Colors.pink,
    Colors.darkred,
    Colors.salmon,
    Colors.slateblue,
    Colors.orchid,
    Colors.goldenrod
}

return Colors
