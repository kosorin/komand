local AceAddon = LibStub("AceAddon-3.0")

---@type string, Komand
local KOMAND, K = ...

---@class Komand.App : W.Library
---@field name string
K.App = AceAddon:NewAddon(KOMAND)

function K.App:OnInitialize()
    -- keep order!
    K.Database:Initialize()
    K.Broker:Initialize()
    K.Options:Initialize()
    K.Menu:Initialize()
end
