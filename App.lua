local AceAddon = LibStub("AceAddon-3.0")

---@type string, Komand
local KOMAND, K = ...

---@class Komand.App
---@field name string
---@field [any] unknown
K.App = AceAddon:NewAddon(KOMAND)

function K.App:OnInitialize()
    -- keep order!
    K.Database:Initialize()
    K.Options:Initialize()
    K.Menu:Initialize()
end
