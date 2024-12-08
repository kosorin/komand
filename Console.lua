local AceConsole = LibStub("AceConsole-3.0")

---@type string, Komand
local KOMAND, K = ...

---@class Komand.Console
K.Console = {}

function K.Console.Print(...)
    AceConsole.Print(K.App.name, ...)
end

function K.Console.Debug(...)
    AceConsole.Print(K.App.name, K.Utils.ColorCode(K.Utils.Color(160, 160, 160)), ...)
end
