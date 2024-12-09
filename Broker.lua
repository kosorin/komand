local LibDataBroker = LibStub("LibDataBroker-1.1")
local LibDBIcon = LibStub("LibDBIcon-1.0")

---@type string, Komand
local KOMAND, K = ...

---@class Komand.Broker
---@field object W.DataBrokerObject
K.Broker = {
    object = LibDataBroker:NewDataObject(K.App.name, {
        type = "launcher",
        text = K.App.name,
        icon = "Interface\\Icons\\inv_misc_map_01",
        OnTooltipShow = function(tooltip)
            tooltip:SetText(K.App.name)
        end,
        OnClick = function(self, button)
            if button == "LeftButton" then
                K.Menu:Show()
            end
        end,
    })
}

function K.Broker:Initialize()
    LibDBIcon:Register(K.App.name, self.object, K.Database.db.profile.minimap)
end
