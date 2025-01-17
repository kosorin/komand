local pairs, ipairs, unpack, tonumber, tostring = pairs, ipairs, unpack, tonumber, tostring
local table, string, math = table, string, math

local CallbackHandler = LibStub("CallbackHandler-1.0")

---@type string, Komand
local KOMAND, K = ...

---@class Komand.Button.Object
---@field button Komand.Button

---@alias Komand.Button.Collection table<ID, Komand.Button.Object>

---@alias Komand.Button.Action.Type "showMenu"|"executeCommand"

---@class Komand.Button.Action
---@field type Komand.Button.Action.Type
---@field commandId ID

---@alias Komand.Button.Action.Info { type: Komand.Button.Action.Type, label: string, textFormat: string }

---@alias Komand.Button.Type "minimap"

---@class Komand.Button
---@field id ID
---@field type Komand.Button.Type
---@field name string
---@field icon string?
---@field hide boolean
---@field lock boolean
---@field actions { [mouseButton]: Komand.Button.Action? }

---@alias Komand.Module.Button.EventName "OnCollectionChanged"

---@class Komand.Module.Button.CallbackHandlerRegistry : CallbackHandlerRegistry
---@field Fire fun(self: Komand.Module.Button.CallbackHandlerRegistry, eventName: Komand.Module.Button.EventName, ...)

---@class Komand.Module.Button : Komand.Module
---@field actions { [integer]: Komand.Button.Action.Info, [Komand.Button.Action.Type]: Komand.Button.Action.Info }
---@field collection Komand.Button.Collection
---@field private callbacks Komand.Module.Button.CallbackHandlerRegistry
---@field RegisterCallback fun(target: table, eventName: Komand.Module.Button.EventName, method: string|function)
---@field UnregisterCallback fun(target: table, eventName: Komand.Module.Button.EventName)
---@field UnregisterAllCallbacks fun(target: table)
K.Button = {
    idPrefix = "btn-",
}

K.Button.actions = {
    { type = "showMenu",       label = "Show Menu",       textFormat = "Show %s" },
    { type = "executeCommand", label = "Execute Command", textFormat = "Execute %s" },
}
for _, info in ipairs(K.Button.actions) do
    K.Button.actions[info.type] = info
end

---@param collection Komand.Button.Collection
---@param button Komand.Button
---@return Komand.Button.Object
local function addObject(collection, button)
    ---@type Komand.Button.Object
    local object = {
        button = button,
    }

    collection[button.id] = object

    return object
end

---@param collection Komand.Button.Collection
---@param button Komand.Button
---@return Komand.Button.Object
local function removeObject(collection, button)
    local object = collection[button.id]

    collection[button.id] = nil

    return object
end

function K.Button:Initialize()
    self.callbacks = CallbackHandler:New(self) --[[@as Komand.Module.Button.CallbackHandlerRegistry]]

    self.collection = {}

    for _, button in pairs(K.Database.db.profile.buttons) do
        addObject(self.collection, button)
    end
end

---@return Komand.Button.Object[]
function K.Button:GetSortedCollection()
    ---@type Komand.Button.Object[]
    local result = {}

    for _, object in pairs(self.collection) do
        table.insert(result, object)
    end

    table.sort(result, function(a, b)
        local aa, bb

        aa = a.button.name:upper()
        bb = b.button.name:upper()
        if aa ~= bb then
            return aa < bb
        end

        return aa < bb
    end)

    return result
end

---@param button Komand.Button
---@param mouseButton mouseButton
function K.Button:Execute(button, mouseButton)
    local action = button.actions[mouseButton]

    if not action then
        return
    end

    local command = K.Command:Get(action.commandId)

    if not command then
        return
    end

    if action.type == "showMenu" then
        K.Menu:Show(command)
    elseif action.type == "executeCommand" then
        K.Command:Execute(command)
    end
end

---@param id ID
---@return Komand.Button
function K.Button:Get(id)
    return K.Database.db.profile.buttons[id]
end

do
    ---@param buttons table<ID, Komand.Button>
    ---@return Komand.Button
    local function addDB(buttons)
        local id = K.Database:GenerateId(K.Button.idPrefix, buttons)
        local button = buttons[id]
        button.id = id
        button.name = "*New Button"
        return button
    end

    ---@return Komand.Button
    function K.Button:Add()
        local button = addDB(K.Database.db.profile.buttons)
        local object = addObject(self.collection, button)
        self.callbacks:Fire("OnCollectionChanged", "add", object)
        return button
    end
end

do
    ---@param buttons table<ID, Komand.Button>
    ---@param id ID
    ---@return Komand.Button
    local function removeDB(buttons, id)
        local button = buttons[id]
        buttons[id] = nil
        return button
    end

    ---@param id ID
    ---@return Komand.Button
    function K.Button:Remove(id)
        local button = removeDB(K.Database.db.profile.buttons, id)
        local object = removeObject(self.collection, button)
        self.callbacks:Fire("OnCollectionChanged", "remove", object)
        return button
    end
end

---@param id ID
function K.Button:Refresh(id)
    local object = self.collection[id]
    self.callbacks:Fire("OnCollectionChanged", "property", object)
end
