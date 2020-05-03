local KOMAND, Core = ...

local AceAddon = LibStub("AceAddon-3.0")

local Addon = AceAddon:NewAddon(KOMAND)
Core.Addon = Addon

function Addon:OnInitialize()
    Core.Database:Initialize()
    Core.Options:Initialize()
end

function Addon:OnEnable()
end

function Addon:OnDisable()
end
