local pairs, ipairs, unpack, tonumber, tostring = pairs, ipairs, unpack, tonumber, tostring
local table, string, math = table, string, math

-- https://www.wowhead.com/classic/icons

---@type string, Komand
local KOMAND, K = ...

---@class Komand.Module.Icon : Komand.Module
---@field optionsSelectValues table<string, string>
K.Icon = {
    optionsSelectValues = {},
}

do
    local directory = "Interface\\Icons\\"
    local size = 16
    for _, name in ipairs {
        "INV_Misc_QuestionMark",
        "Ability_Warrior_Charge",
        "Spell_Nature_HealingTouch",
        "INV_Sword_04",
        "INV_Shield_05",
        "inv_scroll_05",
        "inv_misc_map_01",
        "inv_misc_gear_01",
        "Inv_scroll_03",
    } do
        local path = directory .. name
        K.Icon.optionsSelectValues[path] = ("|T%s:%i|t %s"):format(path, size, name)
    end
end
