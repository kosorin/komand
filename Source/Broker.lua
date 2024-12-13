local pairs, ipairs, unpack, tonumber, tostring = pairs, ipairs, unpack, tonumber, tostring
local table, string, math = table, string, math

local LibDataBroker = LibStub("LibDataBroker-1.1")
local LibDBIcon = LibStub("LibDBIcon-1.0")

---@type string, Komand
local KOMAND, K = ...

---@class Komand.Module.Broker : Komand.Module
---@field object LibDataBroker.DataObject
K.Broker = {}

K.Broker.object = LibDataBroker:NewDataObject(K.addon.name, {
    type = "launcher",
    icon = "Interface\\Icons\\inv_misc_map_01",
    OnTooltipShow = function(tooltip)
        tooltip:SetText(K.addon.name)
    end,
    OnClick = function(frame, button)
        if button == "LeftButton" then
            K.Menu:Show()
        end
    end,
})

function K.Broker:Initialize()
    LibDBIcon:Register(K.addon.name, self.object, K.Database.db.profile.minimap)
end
