local pairs, ipairs, unpack, tonumber, tostring = pairs, ipairs, unpack, tonumber, tostring
local table, string, math = table, string, math

---@type string, Komand
local KOMAND, K = ...

---@alias mouseButton.Info { mouseButton: mouseButton, label: string }

---@class Komand.Module.Utils : Komand.Module
---@field mouseButtons { [integer]: mouseButton.Info, [mouseButton]: mouseButton.Info }
K.Utils = {}

K.Utils.mouseButtons = {
    { mouseButton = "LeftButton",   label = "Left Click" },
    { mouseButton = "RightButton",  label = "Right Click" },
    { mouseButton = "MiddleButton", label = "Middle Click" },
}
for _, info in ipairs(K.Utils.mouseButtons) do
    K.Utils.mouseButtons[info.mouseButton] = info
end

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

---@param color color
---@param text string
---@param reset boolean?
---@return string
function K.Utils.Colorize(color, text, reset)
    if not text or #text == 0 then
        return ""
    end

    local result = K.Utils.ColorCode(color) .. text

    if reset ~= false then
        result = result .. "|r"
    end

    return result
end
