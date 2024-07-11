local font_3x5_glyphs = " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_" ..
	"`abcdefghijklmnopqrstuvwxyz{|}~™АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя"
local font_8x11_glyphs = " 0123456789:;.,ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz?!/\\^@$%<=>()*-+[]_&"

font_3x5 = love.graphics.newImageFont(
	"res/fonts/3x5-ext.png",
	font_3x5_glyphs,
	-1
)

font_3x5_2 = love.graphics.newImageFont(
	"res/fonts/3x5_double-ext.png",
	font_3x5_glyphs,
	-2
)

font_3x5_3 = love.graphics.newImageFont(
	"res/fonts/3x5_medium-ext.png",
	font_3x5_glyphs,
	-3
)

font_3x5_4 = love.graphics.newImageFont(
	"res/fonts/3x5_large-ext.png",
	font_3x5_glyphs,
	-4
)

-- this would be font_8x11 with the other one as 8x11_2
-- but that would break compatibility :(
font_8x11_small = love.graphics.newImageFont(
	"res/fonts/8x11.png",
	font_8x11_glyphs,
	1
)

font_8x11 = love.graphics.newImageFont(
	"res/fonts/8x11_medium.png",
	font_8x11_glyphs,
	1
)
