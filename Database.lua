local unpack = unpack ---@diagnostic disable-line: deprecated

local AceDB = LibStub("AceDB-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local CallbackHandler = LibStub("CallbackHandler-1.0")

---@type string, Komand
local KOMAND, K = ...

---@alias Komand.CommandType "command"|"separator"

---@class Komand.Node
---@field command Komand.DB.Command
---@field parent Komand.Node?
---@field children Komand.Node[]
---@field path Komand.DB.Id[]

---@class Komand.Tree
---@field rootNodes Komand.Node[]
---@field nodes table<Komand.DB.Id, Komand.Node>

---@alias Komand.DB.Id string

---@class Komand.DB.Command
---@field id Komand.DB.Id
---@field parentId Komand.DB.Id?
---@field type Komand.CommandType
---@field enabled boolean
---@field name string
---@field color color
---@field order integer
---@field value string

---@class Komand.DB.Minimap : LibDBIcon.button.DB

---@class Komand.DB.Profile
---@field commands table<Komand.DB.Id, Komand.DB.Command>
---@field minimap Komand.DB.Minimap

---@class Komand.DB.Schema : AceDB.Schema
---@field profile Komand.DB.Profile

---@class Komand.DB : Komand.DB.Schema, AceDBObject-3.0

---@alias Komand.Database.EventName "OnDataChanged"

---@class Komand.Database
---@field RegisterCallback fun(target: table, eventName: Komand.Database.EventName, method: string|function)
---@field UnregisterCallback fun(target: table, eventName: Komand.Database.EventName)
---@field UnregisterAllCallbacks fun(target: table)
---@field private commandTree Komand.Tree
---@field private db Komand.DB
---@field private callbacks CallbackHandlerRegistry
K.Database = {}

---@param commands table<Komand.DB.Id, Komand.DB.Command>
---@return Komand.Tree
local function buildCommandTree(commands)
    ---@type Komand.Tree
    local tree = {
        rootNodes = {},
        nodes = {},
    }

    ---@type Komand.Node[]
    local sortedNodes = {}

    -- Create nodes
    for _, command in pairs(commands) do
        local node = {
            command = command,
            path = {},
            parent = nil,
            children = {},
        }
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

        aa = a.command.name:upper()
        bb = b.command.name:upper()
        if aa ~= bb then
            return aa < bb
        end

        return aa < bb
    end)

    -- Set parent and children
    for _, node in ipairs(sortedNodes) do
        ---@type Komand.Node?
        local parentNode = tree.nodes[node.command.parentId]

        node.parent = parentNode

        if parentNode then
            table.insert(parentNode.children, node)
        else
            table.insert(tree.rootNodes, node)
        end
    end

    -- Build paths
    ---@type Komand.Node[]
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

local idAlphabet = "abcdefghijklmnopqrstuvwxyz0123456789"
local idAlphabetLength = string.len(idAlphabet)

---@param items { [Komand.DB.Id]: { id: Komand.DB.Id } }
---@return Komand.DB.Id
local function generateId(items)
    local id
    local bytes = {}
    repeat
        for i = 1, 5 do
            bytes[i] = string.byte(idAlphabet, math.random(idAlphabetLength))
        end
        id = "id-" .. string.char(unpack(bytes))
    until items == nil or items[id] == nil or items[id].id == nil
    return id
end

---@param commands table<Komand.DB.Id, Komand.DB.Command>
---@param parentId Komand.DB.Id
---@return Komand.DB.Command
local function addCommand(commands, parentId)
    local id = generateId(commands)
    local command = commands[id]
    command.id = id
    command.parentId = parentId
    command.name = "*New Command"
    return command
end

---@param commands table<Komand.DB.Id, Komand.DB.Command>
---@param id Komand.DB.Id
---@return Komand.DB.Command
local function removeCommand(commands, id)
    local command = commands[id]
    for _, childCommand in pairs(commands) do
        if childCommand.parentId == id then
            removeCommand(commands, childCommand.id)
        end
    end
    commands[id] = nil
    return command
end

function K.Database:Initialize()
    ---@type Komand.DB.Schema
    local defaults = {
        profile = {
            commands = {
                ["**"] = {
                    id = nil, ---@diagnostic disable-line: assign-type-mismatch
                    parentId = nil,
                    enabled = true,
                    type = "command",
                    name = "",
                    color = { 1, 1, 1 },
                    order = 0,
                    value = "",
                },
            },
            minimap = {
                hide = false,
                lock = false,
                minimapPos = 0,
            },
        },
    }

    self.callbacks = CallbackHandler:New(self)

    self.db = AceDB:New(K.Addon.name .. "DB", defaults, true) --[[@as Komand.DB]]
    self.db.RegisterCallback(self, "OnNewProfile", "OnNewProfile")
    self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileCopied")
    self.db.RegisterCallback(self, "OnProfileReset", "OnProfileReset")

    self:RebuildCommandTree(true)
end

---@param parentId Komand.DB.Id
---@return Komand.DB.Command
function K.Database:AddCommand(parentId)
    local command = addCommand(self.db.profile.commands, parentId)
    self:RebuildCommandTree(true)
    return command
end

---@param id Komand.DB.Id
---@return Komand.DB.Command
function K.Database:RemoveCommand(id)
    local command = removeCommand(self.db.profile.commands, id)
    self:RebuildCommandTree(true)
    return command
end

---@param id Komand.DB.Id
---@return Komand.DB.Command
function K.Database:GetCommand(id)
    return self.db.profile.commands[id]
end

---@param query string?
---@return Komand.DB.Command?
function K.Database:FindCommand(query)
    if not query or query:match("^%s*$") then
        return nil
    end

    ---@param s string
    ---@return string
    local function normalize(s)
        return s:gsub("%s+", ""):upper()
    end

    query = normalize(query)

    for _, command in pairs(self.db.profile.commands) do
        if normalize(command.name) == query then
            return command
        end
    end

    return nil
end

---@return Komand.Tree
function K.Database:GetCommandTree()
    if not self.commandTree then
        self.commandTree = buildCommandTree(self.db.profile.commands)
    end
    return self.commandTree
end

---@param full boolean?
function K.Database:RebuildCommandTree(full)
    if not self.commandTree or full then
        self.commandTree = buildCommandTree(self.db.profile.commands)
        self.callbacks:Fire("OnDataChanged", true)
    else
        self.callbacks:Fire("OnDataChanged", false)
    end
end

---@return Komand.DB.Minimap
function K.Database:GetMinimap()
    return self.db.profile.minimap
end

---@return AceConfig.OptionsTable
function K.Database:GetProfilesOptionsTable()
    return AceDBOptions:GetOptionsTable(self.db, true)
end

function K.Database:OnNewProfile()
    self:RebuildCommandTree(true)
    AceConfigRegistry:NotifyChange(K.Addon.name)
end

function K.Database:OnProfileChanged()
    self:RebuildCommandTree(true)
    AceConfigRegistry:NotifyChange(K.Addon.name)
end

function K.Database:OnProfileCopied()
    self:RebuildCommandTree(true)
    AceConfigRegistry:NotifyChange(K.Addon.name)
end

function K.Database:OnProfileReset()
    self:RebuildCommandTree(true)
    AceConfigRegistry:NotifyChange(K.Addon.name)
end
