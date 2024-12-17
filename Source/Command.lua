local loadstring, pcall = loadstring, pcall
local pairs, ipairs, unpack, tonumber, tostring = pairs, ipairs, unpack, tonumber, tostring
local table, string, math = table, string, math

local CallbackHandler = LibStub("CallbackHandler-1.0")

---@type string, Komand
local KOMAND, K = ...

---@class Komand.Command.Node
---@field command Komand.Command
---@field parent Komand.Command.Node?
---@field children Komand.Command.Node[]
---@field path ID[]
local nodePrototype = {}

---@param useColor boolean?
---@return string
function nodePrototype:GetText(useColor)
    local text = self.command.type == "separator"
        and "-------"
        or self.command.name

    if useColor then
        text = K.Utils.ColorCode(self.command.color) .. text
    end

    return text
end

---@class Komand.Command.Tree
---@field rootNodes Komand.Command.Node[]
---@field nodes table<ID, Komand.Command.Node>

---@alias Komand.Command.Type "macro"|"lua"|"separator"

---@class Komand.Command
---@field id ID
---@field parentId ID?
---@field type Komand.Command.Type
---@field hide boolean
---@field name string
---@field color color
---@field order integer
---@field script string

---@alias Komand.Module.Command.EventName "OnTreeChanged"

---@class Komand.Module.Command.CallbackHandlerRegistry : CallbackHandlerRegistry
---@field Fire fun(self: Komand.Module.Command.CallbackHandlerRegistry, eventName: Komand.Module.Command.EventName, ...)

---@class Komand.Module.Command : Komand.Module
---@field tree Komand.Command.Tree
---@field private callbacks Komand.Module.Command.CallbackHandlerRegistry
---@field RegisterCallback fun(target: table, eventName: Komand.Module.Command.EventName, method: string|function)
---@field UnregisterCallback fun(target: table, eventName: Komand.Module.Command.EventName)
---@field UnregisterAllCallbacks fun(target: table)
K.Command = {}

---@param commands table<ID, Komand.Command>
---@return Komand.Command.Tree
local function buildTree(commands)
    ---@type Komand.Command.Tree
    local tree = {
        rootNodes = {},
        nodes = {},
    }

    ---@type Komand.Command.Node[]
    local sortedNodes = {}

    -- Create nodes
    for _, command in pairs(commands) do
        ---@type Komand.Command.Node
        local node = setmetatable({
            command = command,
            path = {},
            parent = nil,
            children = {},
        }, { __index = nodePrototype })
        tree.nodes[command.id] = node
        table.insert(sortedNodes, node)
    end

    table.sort(sortedNodes, function(a, b)
        local aa, bb

        aa = a.command.order or 0
        bb = b.command.order or 0
        if aa ~= bb then
            return aa < bb
        end

        aa = a.command.type == "separator"
        bb = b.command.type == "separator"
        if aa ~= bb then
            return aa
        end

        aa = a.command.name:upper()
        bb = b.command.name:upper()
        if aa ~= bb then
            return aa < bb
        end

        return aa < bb
    end)

    -- Set parent and children
    for _, node in ipairs(sortedNodes) do
        ---@type Komand.Command.Node?
        local parentNode = tree.nodes[node.command.parentId]

        node.parent = parentNode

        if parentNode then
            table.insert(parentNode.children, node)
        else
            table.insert(tree.rootNodes, node)
        end
    end

    -- Build paths
    ---@type Komand.Command.Node[]
    local nodes = { unpack(tree.rootNodes) }
    local i = 1
    while i <= #nodes do
        local node = nodes[i]

        if node.parent then
            for _, p in ipairs(node.parent.path) do
                table.insert(node.path, p)
            end
        end
        table.insert(node.path, node.command.id)

        for _, childNode in ipairs(node.children) do
            table.insert(nodes, childNode)
        end

        i = i + 1
    end

    return tree
end

function K.Command:Initialize()
    self.callbacks = CallbackHandler:New(self) --[[@as Komand.Module.Command.CallbackHandlerRegistry]]

    self:RebuildTree()
end

---@param command Komand.Command
---@return boolean
---@return string?
function K.Command:Execute(command)
    if not command then
        return false, "Missing command."
    end

    if command.type == "macro" then
        local editBox = DEFAULT_CHAT_FRAME.editBox
        editBox:SetText(command.script)
        ChatEdit_SendText(editBox)
    elseif command.type == "lua" then
        local chunkName = ("%s: %s"):format(K.addon.name, command.name)
        local func, error = loadstring(command.script, chunkName);
        if not func then
            return false, error
        end
        local success, error = pcall(func);
        if not success then
            return false, error
        end
    else
        return false, ("Unknown command type: %s"):format(command.type)
    end

    return true, nil
end

---@param id ID
---@return Komand.Command
function K.Command:Get(id)
    return K.Database.db.profile.commands[id]
end

do
    ---@param query string
    ---@return string
    local function normalize(query)
        return query:gsub("%s+", ""):upper()
    end

    ---@param query string?
    ---@return Komand.Command?
    function K.Command:Find(query)
        if not query or query:match("^%s*$") then
            return nil
        end

        query = normalize(query)

        for _, command in pairs(K.Database.db.profile.commands) do
            if normalize(command.name) == query then
                return command
            end
        end

        return nil
    end
end

do
    ---@param commands table<ID, Komand.Command>
    ---@param parentId ID
    ---@return Komand.Command
    local function addDB(commands, parentId)
        local id = K.Database:GenerateId("cmd", commands)
        local command = commands[id]
        command.id = id
        command.parentId = parentId
        command.name = "*New Command"
        return command
    end

    ---@param parentId ID
    ---@return Komand.Command
    function K.Command:Add(parentId)
        local command = addDB(K.Database.db.profile.commands, parentId)
        self:RebuildTree()
        return command
    end
end

do
    ---@param commands table<ID, Komand.Command>
    ---@param id ID
    ---@return Komand.Command
    local function removeDB(commands, id)
        local command = commands[id]
        for _, childCommand in pairs(commands) do
            if childCommand.parentId == id then
                removeDB(commands, childCommand.id)
            end
        end
        commands[id] = nil
        return command
    end

    ---@param id ID
    ---@return Komand.Command
    function K.Command:Remove(id)
        local command = removeDB(K.Database.db.profile.commands, id)
        self:RebuildTree()
        return command
    end
end

function K.Command:RebuildTree()
    self.tree = buildTree(K.Database.db.profile.commands)
    self.callbacks:Fire("OnTreeChanged")
end
