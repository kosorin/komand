local pairs, ipairs, unpack, tonumber, tostring = pairs, ipairs, unpack, tonumber, tostring
local table, string, math = table, string, math

---@type string, Komand
local KOMAND, K = ...

---@class Komand.Module.Utils : Komand.Module
K.Utils = {}

---@alias color { [1]: number?, [2]: number?, [3]: number?, [4]: number? } RGBA

---@param color color
---@return string
function K.Utils.ColorCode(color)
    local r = color and color[1] or 1
    local g = color and color[2] or 1
    local b = color and color[3] or 1
    local a = color and color[4] or 1

    r = r * 255
    g = g * 255
    b = b * 255
    a = a * 255

    return ("|c%02x%02x%02x%02x"):format(a, r, g, b)
end
