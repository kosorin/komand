local pairs, ipairs, unpack, tonumber, tostring = pairs, ipairs, unpack, tonumber, tostring
local table, string, math = table, string, math

local AceAddon = LibStub("AceAddon-3.0")

---@type string, Komand
local KOMAND, K = ...

---@alias ID string

---@class Komand.Module

---@class Komand
---@field slash string[]
---@field addon AceAddon
---@field Utils Komand.Module.Utils
---@field Database Komand.Module.Database
---@field Broker Komand.Module.Broker
---@field Command Komand.Module.Command
---@field Options Komand.Module.Options
---@field Menu Komand.Module.Menu
_G[KOMAND] = K

K.slash = { "komand", "kmd" }

K.addon = AceAddon:NewAddon(KOMAND)

---@diagnostic disable-next-line: inject-field
function K.addon:OnInitialize()
    -- keep order!
    K.Database:Initialize()
    K.Command:Initialize()
    K.Broker:Initialize()
    K.Options:Initialize()
    K.Menu:Initialize()
end
