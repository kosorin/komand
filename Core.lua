---@type string, Komand
local KOMAND, K = ...

---@class Komand
---@field slash string[]
---@field Console Komand.Console
---@field Utils Komand.Utils
---@field Addon Komand.Addon
---@field Database Komand.Database
---@field Broker Komand.Broker
---@field Command Komand.Command
---@field Options Komand.Options
---@field Menu Komand.Menu
_G.Komand = K

K.slash = { "komand", "kmd" }
