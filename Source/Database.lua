local pairs, ipairs, unpack, tonumber, tostring = pairs, ipairs, unpack, tonumber, tostring
local table, string, math = table, string, math

local AceDB = LibStub("AceDB-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local CallbackHandler = LibStub("CallbackHandler-1.0")

---@type string, Komand
local KOMAND, K = ...

---@class Komand.DB.Profile
---@field commands table<ID, Komand.Command>
---@field buttons table<ID, Komand.Button>

---@class Komand.DB.Schema : AceDB.Schema
---@field profile Komand.DB.Profile

---@class Komand.DB : Komand.DB.Schema, AceDBObject-3.0

---@alias Komand.Module.Database.EventName "OnProfileChanged"

---@class Komand.Module.Database.CallbackHandlerRegistry : CallbackHandlerRegistry
---@field Fire fun(self: Komand.Module.Database.CallbackHandlerRegistry, eventName: Komand.Module.Database.EventName, ...)

---@class Komand.Module.Database : Komand.Module
---@field RegisterCallback fun(target: table, eventName: Komand.Module.Database.EventName, method: string|function)
---@field UnregisterCallback fun(target: table, eventName: Komand.Module.Database.EventName)
---@field UnregisterAllCallbacks fun(target: table)
---@field db Komand.DB
---@field private defaults Komand.DB.Schema
---@field private callbacks Komand.Module.Database.CallbackHandlerRegistry
K.Database = {}

K.Database.defaults = {
    profile = {
        commands = {
            ["**"] = {
                id = nil, ---@diagnostic disable-line: assign-type-mismatch
                parentId = nil,
                hide = false,
                type = "macro",
                name = "",
                color = { 1, 1, 1 },
                order = 0,
                script = "",
            } --[[@as Komand.Command]],
        },
        buttons = {
            ["**"] = {
                id = nil, ---@diagnostic disable-line: assign-type-mismatch
                type = "minimap",
                name = "",
                icon = nil,
                hide = false,
                lock = false,
                actions = {
                    ["**"] = {
                        type = nil, ---@diagnostic disable-line: assign-type-mismatch
                        commandId = nil, ---@diagnostic disable-line: assign-type-mismatch
                    } --[[@as Komand.Button.Action]],
                },
            } --[[@as Komand.Button]],
        },
    },
}

do
    local idLength = 5
    local idAlphabet = "abcdefghijklmnopqrstuvwxyz0123456789"
    local idAlphabetLength = string.len(idAlphabet)

    ---@param prefix string
    ---@param items { [ID]: { id: ID? } }?
    ---@return ID
    function K.Database:GenerateId(prefix, items)
        local id
        local bytes = {}
        repeat
            for i = 1, idLength do
                bytes[i] = string.byte(idAlphabet, math.random(idAlphabetLength))
            end
            id = prefix .. string.char(unpack(bytes))
        until items == nil or items[id] == nil or items[id].id == nil
        return id
    end
end

function K.Database:Initialize()
    self.callbacks = CallbackHandler:New(self) --[[@as Komand.Module.Database.CallbackHandlerRegistry]]

    self.db = AceDB:New(K.addon.name .. "DB", self.defaults, true) --[[@as Komand.DB]]
    self.db.RegisterCallback(self, "OnNewProfile", "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
end

---@private
function K.Database:OnProfileChanged()
    self.callbacks:Fire("OnProfileChanged")
    AceConfigRegistry:NotifyChange(K.addon.name)
end
