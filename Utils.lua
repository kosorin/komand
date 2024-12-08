---@type string, Komand
local KOMAND, K = ...

---@class Komand.Utils
K.Utils = {}

---@alias color number[] RGBA

---@param r number
---@param g number
---@param b number
---@param a number?
---@return color
function K.Utils.Color(r, g, b, a)
    return { r / 255, g / 255, b / 255, (a or 255) / 255 }
end

---@param color color
---@return string
function K.Utils.ColorCode(color)
    local max = 255

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
