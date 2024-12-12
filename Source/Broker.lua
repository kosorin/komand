local LibDataBroker = LibStub("LibDataBroker-1.1")
local LibDBIcon = LibStub("LibDBIcon-1.0")

---@type string, Komand
local KOMAND, K = ...

---@class Komand.Broker
---@field object LibDataBroker.DataObject
K.Broker = {
    object = LibDataBroker:NewDataObject(K.Addon.name, {
        type = "launcher",
        icon = "Interface\\Icons\\inv_misc_map_01",
        OnTooltipShow = function(tooltip)
            tooltip:SetText(K.Addon.name)
        end,
        OnClick = function(frame, button)
            if button == "LeftButton" then
                K.Menu:Show()
            end
        end,
    })
}

function K.Broker:Initialize()
    LibDBIcon:Register(K.Addon.name, self.object, K.Database:GetMinimap())
end