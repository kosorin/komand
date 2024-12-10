local unpack = unpack ---@diagnostic disable-line: deprecated

local AceDB = LibStub("AceDB-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

---@type string, Komand
local KOMAND, K = ...

---@alias Komand.CommandType "command" | "separator"

---@class Komand.CommandNode
---@field command Komand.DB.Command
---@field path Komand.DB.Id[]
---@field children Komand.CommandNode[]

---@class Komand.CommandTree
---@field rootNodes Komand.CommandNode[]
---@field nodes table<Komand.DB.Id, Komand.CommandNode>

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

---@class Komand.DB.Minimap
---@field hide boolean

---@class Komand.DB.Profile
---@field commands table<Komand.DB.Id, Komand.DB.Command>
---@field minimap Komand.DB.Minimap

---@class Komand.DB
---@field profile Komand.DB.Profile
---@field [any] unknown

---@class Komand.Database
---@field db Komand.DB
---@field commandTree Komand.CommandTree
K.Database = {}

---@param commands table<Komand.DB.Id, Komand.DB.Command>
---@return Komand.CommandTree
local function buildCommandTree(commands)
    ---@type Komand.DB.Command[]
    local sortedCommands = {}
    for _, command in pairs(commands) do
        table.insert(sortedCommands, command)
    end
    table.sort(sortedCommands, K.Command.Comparer)

    ---@type Komand.CommandTree
    local tree = {
        rootNodes = {},
        nodes = {},
    }

    for _, command in ipairs(sortedCommands) do
        tree.nodes[command.id] = {
            command = command,
            path = {},
            children = {},
        }
    end

    for _, command in ipairs(sortedCommands) do
        local node = tree.nodes[command.id]
        local parentNode = tree.nodes[command.parentId]

        local nodeContainer = parentNode and parentNode.children or tree.rootNodes
        table.insert(nodeContainer, node)

        local path = { unpack(parentNode and parentNode.path or {}) }
        table.insert(path, node.command.id)
        node.path = path
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
    ---@type Komand.DB
    local defaults = {
        profile = {
            commands = {
                ["**"] = {
                    id = nil, ---@diagnostic disable-line: assign-type-mismatch
                    parentId = nil,
                    enabled = true,
                    type = "command",
                    name = "",
                    color = K.Utils.Color(255, 255, 255),
                    order = 0,
                    value = "",
                },
            },
            minimap = {
                hide = false,
            },
        },
    }

    self.db = AceDB:New(K.Addon.name .. "DB", defaults, true)
    self.db.RegisterCallback(self, "OnNewProfile", "OnNewProfile")
    self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileCopied")
    self.db.RegisterCallback(self, "OnProfileReset", "OnProfileReset")
    self.db.RegisterCallback(self, "DataChanged", "OnDataChanged")
end

---@param parentId Komand.DB.Id
---@return Komand.DB.Command
function K.Database:AddCommand(parentId)
    local command = addCommand(self.db.profile.commands, parentId)
    self:FireDataChanged("AddCommand")
    return command
end

---@param id Komand.DB.Id
---@return Komand.DB.Command
function K.Database:RemoveCommand(id)
    local command = removeCommand(self.db.profile.commands, id)
    self:FireDataChanged("RemoveCommand")
    return command
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

---@param ... any
function K.Database:FireDataChanged(...)
    self.db.callbacks:Fire("DataChanged", ...)
end

function K.Database:OnNewProfile(_, _, profileName)
    self:FireDataChanged("NewProfile", profileName)
    AceConfigRegistry:NotifyChange(K.Addon.name)
end

function K.Database:OnProfileChanged(_, _, profileName)
    self:FireDataChanged("ProfileChanged", profileName)
    AceConfigRegistry:NotifyChange(K.Addon.name)
end

function K.Database:OnProfileCopied(_, _, profileName)
    self:FireDataChanged("ProfileCopied", profileName)
    AceConfigRegistry:NotifyChange(K.Addon.name)
end

function K.Database:OnProfileReset()
    self:FireDataChanged("ProfileReset")
    AceConfigRegistry:NotifyChange(K.Addon.name)
end

---@param ... any
function K.Database:OnDataChanged(...)
    self.commandTree = buildCommandTree(self.db.profile.commands)
end
