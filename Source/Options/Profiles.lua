local pairs, ipairs, unpack, tonumber, tostring = pairs, ipairs, unpack, tonumber, tostring
local table, string, math = table, string, math

local AceDBOptions = LibStub("AceDBOptions-3.0")

---@type string, Komand
local KOMAND, K = ...

---@class Komand.OptionsTab.Profiles : Komand.OptionsTab
local Tab = {
    key = "profiles",
    title = "Profiles",
}

---@return AceConfig.OptionsTable.Ex
function Tab:BuildOptionsTable()
    local options = AceDBOptions:GetOptionsTable(K.Database.db, true) --[[@as AceConfig.OptionsTable.Ex]]
    options._key = Tab.key
    return options
end

K.Options.Tabs.Profiles = Tab
