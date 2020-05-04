local KOMAND, Core = ...

local AceDB = LibStub("AceDB-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

local Database = {
    rootCommandId = Core.Utils.idPrefix .. "ROOT-COMMAND"
}
Core.Database = Database

function Database:Initialize()
    self.db = AceDB:New(KOMAND .. "DB", {
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
                    name = "Menu",
                    color = {1, 0.8, 0, 1},
                    value = "/komand options",
                },
            },
        },
    }, true)
    self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileCopied")
    self.db.RegisterCallback(self, "OnProfileReset", "OnProfileReset")
    self.db.RegisterCallback(self, "DataChanged", "OnDataChanged")
end

local function removeCommand(id)
    for _, command in pairs(Database.db.profile.commands) do
        if (command.parentId == id) then
            removeCommand(command.id, true)
        end
    end
    Database.db.profile.commands[id] = nil
end

function Database:AddCommand(parentId)
    local id = Core.Utils.GenerateId(self.db.profile.commands)
    local command = self.db.profile.commands[id]
    command.id = id
    command.parentId = parentId

    self:FireDataChanged("AddCommand")

    return command
end

function Database:RemoveCommand(id)
    local command = Database.db.profile.commands[id]
    removeCommand(id)
    
    self:FireDataChanged("RemoveCommand")

    return command
end

local function buildCommandTree()
    local nodes = Core.Utils.Select(Database.db.profile.commands, function(_, command) return {
        command = command,
        path = nil,
        children = {},
    } end)
    local sortedNodes = Core.Utils.Sort(nodes, function(a, b)
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

function Database:OnProfileChanged(_, _, profileName)
    self:FireDataChanged("ProfileChanged", profileName)
    AceConfigRegistry:NotifyChange(KOMAND)
end

function Database:OnProfileCopied(_, _, profileName)
    self:FireDataChanged("ProfileCopied", profileName)
    AceConfigRegistry:NotifyChange(KOMAND)
end

function Database:OnProfileReset(_, _)
    self:FireDataChanged("ProfileReset")
    AceConfigRegistry:NotifyChange(KOMAND)
end

function Database:FireDataChanged(...)
	self.db.callbacks:Fire("DataChanged", ...)
end

function Database:OnDataChanged(...)
    Core.Menu:Hide()
    self.commandTree = buildCommandTree()
end

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
