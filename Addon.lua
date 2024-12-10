local AceAddon = LibStub("AceAddon-3.0")

---@type string, Komand
local KOMAND, K = ...

---@class Komand.Addon : W.Addon
---@field name string
K.Addon = AceAddon:NewAddon(KOMAND)

function K.Addon:OnInitialize()
    -- keep order!
    K.Database:Initialize()
    K.Broker:Initialize()
    K.Options:Initialize()
    K.Menu:Initialize()
end
