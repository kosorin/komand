local _, Core = ...

--> Libraries
local AceDB = LibStub("AceDB-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

--> Locals
local App = Core.App
local Console = Core.Console
local Command = Core.Command
local Database = Core.Database
local Options = Core.Options
local Menu = Core.Menu
local Utils = Core.Utils

-------------------------------------------------------------------------------
--> Database
-------------------------------------------------------------------------------

--> Forward declarations

local addCommand, removeCommand, buildCommandTree

--> Static variables

Database.idPrefix = "ID-"
Database.rootCommandId = Database.idPrefix .. "ROOT-COMMAND"

--> Static functions

function Database.CommandComparer(a, b)
    local aa, bb

    bb = (a ~= nil and a.pinned and 1 or 0)
    aa = (b ~= nil and b.pinned and 1 or 0)
    if aa ~= bb then
        return aa < bb
    end

    aa = a.name:upper()
    bb = b.name:upper()
    if aa ~= bb then
        return aa < bb
    end

    return aa < bb
end

function Database.GenerateId(items)
    local random = math.random
    local template = Database.idPrefix .. "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    local function randomChar(c)
        local v = (c == "x") and random(0, 0xf) or random(8, 0xb)
        return ("%x"):format(v)
    end

    local id
    repeat
        id = template:gsub("[xy]", randomChar)
    until items == nil or items[id] == nil or items[id].id == nil

    return id
end

--> Functions

function Database:Initialize()
    self.db = AceDB:New(Core.name .. "DB", {
        profile = {
            commands = {
                ["**"] = {
                    id = nil,
                    parentId = nil,
                    name = "*New Command",
                    color = {1, 1, 1, 1},
                    pinned = false,
                    value = "",
                },
                [self.rootCommandId] = {
                    id = self.rootCommandId,
                    name = Core.name,
                    color = {1, 0.8, 0, 1},
                    value = ("/%s options"):format(Core.slash[1]),
                },
            },
        },
    }, true)
    self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileCopied")
    self.db.RegisterCallback(self, "OnProfileReset", "OnProfileReset")
    self.db.RegisterCallback(self, "DataChanged", "OnDataChanged")
end

function Database:AddCommand(parentId)
    local command = addCommand(parentId)
    self:FireDataChanged("AddCommand")
    return command
end

function Database:RemoveCommand(id)
    local command = removeCommand(id)
    self:FireDataChanged("RemoveCommand")
    return command
end

function Database:OnProfileChanged(_, _, profileName)
    self:FireDataChanged("ProfileChanged", profileName)
    AceConfigRegistry:NotifyChange(Core.name)
end

function Database:OnProfileCopied(_, _, profileName)
    self:FireDataChanged("ProfileCopied", profileName)
    AceConfigRegistry:NotifyChange(Core.name)
end

function Database:OnProfileReset(_, _)
    self:FireDataChanged("ProfileReset")
    AceConfigRegistry:NotifyChange(Core.name)
end

function Database:OnDataChanged(...)
    Menu:Hide()
    self.commandTree = buildCommandTree()
end

function Database:FireDataChanged(...)
	self.db.callbacks:Fire("DataChanged", ...)
end

--> Local functions

function addCommand(parentId)
    local profile = Database.db.profile

    local id = Database.GenerateId(profile.commands)
    local command = profile.commands[id]
    command.id = id
    command.parentId = parentId or Database.rootCommandId
    return command
end

function removeCommand(id)
    local profile = Database.db.profile

    local removedCommand = profile.commands[id]
    for _, command in pairs(profile.commands) do
        if (command.parentId == id) then
            removeCommand(command.id, true)
        end
    end
    profile.commands[id] = nil
    return removedCommand
end

function buildCommandTree()
    local nodes = Utils.Select(Database.db.profile.commands, function(_, command) return {
        command = command,
        path = nil,
        children = {},
    } end)
    local sortedNodes = Utils.Sort(nodes, function(a, b)
        return Database.CommandComparer(a.command, b.command)
    end)

    local rootNode = nodes[Database.rootCommandId]

    for _, node in pairs(sortedNodes) do
        if node.command.id ~= Database.rootCommandId then
            local parentNode = node.command.parentId and nodes[node.command.parentId] or rootNode
            table.insert(parentNode.children, node)
        end
    end

    local function setCommandNodePath(node, parentPath)
        local path = {unpack(parentPath)}
        table.insert(path, node.command.id)

        node.path = path
        for _, childNode in pairs(node.children) do
            setCommandNodePath(childNode, path)
        end
    end
    setCommandNodePath(rootNode, {})

    return {
        rootNode = rootNode,
        nodes = nodes,
    }
end
