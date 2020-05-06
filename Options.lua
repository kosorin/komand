local _, Core = ...

--> Libraries
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")

function AceConfigDialog:Break(order)
    return {
        name = "",
        order = order,
        width = "full",
        type = "description",
    }
end

function AceConfigDialog:Header(name, order)
    return {
        name = "\n\n|cffffcc00" .. name,
        order = order,
        width = "full",
        type = "description",
    }
end

--> Locals
local App = Core.App
local Console = Core.Console
local Command = Core.Command
local Database = Core.Database
local Options = Core.Options
local Menu = Core.Menu
local Utils = Core.Utils

-------------------------------------------------------------------------------
-- Options
-------------------------------------------------------------------------------

--> Forward declarations

local selectCommand
local getCommand, setCommand
local getCommand_parentId, setCommand_parentId, valuesCommand_parentId, sortingCommand_parentId

--> Local variables

local commandOrderOffset = 100
local nilCommandId = ""

--> Functions

function Options:Initialize()
    self:Build()

    AceConfig:RegisterOptionsTable(Core.name, function() return self:Build() end, Core.slash)
    AceConfigDialog:SetDefaultSize(Core.name, 615, 550)
    
    self.frames = {
        commands = AceConfigDialog:AddToBlizOptions(Core.name, nil, nil, "commands"),
        general = AceConfigDialog:AddToBlizOptions(Core.name, self.options.args.general.name, Core.name, "general"),
        profiles = AceConfigDialog:AddToBlizOptions(Core.name, self.options.args.profiles.name, Core.name, "profiles"),
    }
end

function Options:Open(frame, ...)
    if InterfaceOptionsFrame:IsShown() then
        InterfaceOptionsFrame:Hide()
    else
        InterfaceOptionsFrame:Show()
        InterfaceOptionsFrame_OpenToCategory(frame or self.frames.commands)

        if frame == self.frames.commands then
            local commandName = ...
            local command = Utils.FindByName(Database.db.profile.commands, commandName)
            selectCommand(command and command.id)
        end
    end
end

function Options:Close()
    AceConfigDialog:Close(Core.name)
end

function Options:Build()
    if self.options == nil then
        Database:FireDataChanged("BuildOptions")
        self:BuildOptions()
    end
    self:UpdateOptions()
    return self.options
end

function Options:BuildOptions()
    self.options = {
        type = "group",
        childGroups = "tab",
        args = {},
    }

    -- Command line
    self.options.args.show = {
        name = "Show",
        order = 0,
        guiHidden = true,
        type = "input",
        set = function(info, value)
            Menu:Show(value)
        end
    }
    self.options.args.options = {
        name = "Options",
        order = 1,
        guiHidden = true,
        type = "input",
        set = function(info, value)
            self:Open(self.frames.commands, value)
        end
    }

    -- GUI
    self.options.args.commands = self:BuildCommandsOptions(100)
    self.options.args.general = self:BuildGeneralOptions(200)
    self.options.args.profiles = self:BuildProfilesOptions(300)
end

function Options:BuildCommandsOptions(order)
    return {
        name = "Commands",
        order = order,
        cmdHidden = true,
        type = "group",
        args = {
            add = {
                name = "Add Command",
                order = 0,
                type = "execute",
                handler = self,
                func = "OnAddCommand",
            },
            -- order {commandOrderOffset}+ is reserved for command tree
        },
    }
end

function Options:BuildGeneralOptions(order)
    return {
        name = "General",
        order = order,
        cmdHidden = true,
        type = "group",
        args = {},
    }
end

function Options:BuildProfilesOptions(order)
    local node =  AceDBOptions:GetOptionsTable(Database.db, true)
    node.order = order
    return node
end

function Options:UpdateOptions()
    for key, arg in pairs(self.options.args.commands.args) do
        if arg.order >= commandOrderOffset then
            self.options.args.commands.args[key] = nil
        end
    end

    for order, node in pairs(Database.commandTree.rootNodes) do
        self.options.args.commands.args[node.command.id] = self:BuildCommand(node, commandOrderOffset + order)
    end
end

function Options:BuildCommand(node, order)
    local command = node.command

    local arg = {
        name = command.name,
        order = order,
        type = "group",
        childGroups = "tree",
        args = {
            selector = {
                name = "You can't see this",
                order = 0,
                handler = self,
                arg = node,
                hidden = "OnCommandNodeChanged",
                type = "input",
            },
            name = {
                name = "Name",
                order = 10,
                width = "normal",
                type = "input",
                handler = self,
                arg = node,
                get = getCommand,
                set = setCommand,
            },
            remove = {
                name = "Remove Command",
                order = 15,
                width = "normal",
                type = "execute",
                confirm = true,
                confirmText = ("Remove '|cffff0000%s|r' command?\nThis will remove all children."):format(command.name),
                handler = self,
                arg = node,
                func = "OnRemoveCommand",
            },
            settings = AceConfigDialog:Header("Settings", 20),
            pinned = {
                name = "Pinned",
                order = 25,
                width = 0.75,
                type = "toggle",
                handler = self,
                arg = node,
                get = getCommand,
                set = setCommand,
            },
            color = {
                name = "Color",
                order = 26,
                width = 0.75,
                type = "color",
                hasAlpha = false,
                handler = self,
                arg = node,
                get = getCommand,
                set = setCommand,
            },
            br50 = AceConfigDialog:Break(50),
            parentId = {
                name = "Parent",
                order = 52,
                width = "double",
                type = "select",
                style = "dropdown",
                handler = self,
                arg = node,
                get = getCommand_parentId,
                set = setCommand_parentId,
                values = valuesCommand_parentId,
                sorting = sortingCommand_parentId,
            },
            br100 = AceConfigDialog:Break(100),
            value = {
                name = "Command",
                order = 101,
                width = 1.5,
                type = "input",
                handler = self,
                arg = node,
                get = getCommand,
                set = setCommand,
            },
            execute = {
                name = "Execute",
                order = 102,
                width = 0.5,
                type = "execute",
                handler = self,
                arg = node,
                func = "OnExecuteCommand",
            },
            br1000 = AceConfigDialog:Break(1000),
        }
    }

    for order, childNode in pairs(node.children) do
        arg.args[childNode.command.id] = self:BuildCommand(childNode, order)
    end

    return arg
end

function Options:OnAddCommand(info)
    local command = Database:AddCommand(self.lastCommandId)
    selectCommand(command.id)
end

function Options:OnRemoveCommand(info)
    local commandId = info.arg.command.id
    local command = Database:RemoveCommand(commandId)
    selectCommand(command.parentId)
end

function Options:OnExecuteCommand(info)
    local commandId = info.arg.command.id
    local command = Database.db.profile.commands[commandId]
    Command.Execute(command.value)
end

function Options:OnCommandNodeChanged(info)
    local command = info.arg.command

    self.lastCommandId = command.id
    
    return true
end

--> Local functions

function selectCommand(commandId)
    local node = commandId and Database.commandTree.nodes[commandId]
    AceConfigDialog:SelectGroup(Core.name, "commands", unpack(node and node.path or {}))
end

function getCommand(info)
    local commandId = info[#info - 1]
    local property = info[#info]
    if info.type == "color" then
        local color = Database.db.profile.commands[commandId][property]
        return unpack(color ~= nil and color or {})
    else
        return Database.db.profile.commands[commandId][property]
    end
end

function setCommand(info, value, ...)
    local commandId = info[#info - 1]
    local property = info[#info]
    if info.type == "color" then
        Database.db.profile.commands[commandId][property] = {value, ...}
    else
        Database.db.profile.commands[commandId][property] = value
    end
    Database:FireDataChanged("SetProperty", property)
end

function getCommand_parentId(info)
    return getCommand(info) or nilCommandId
end

function setCommand_parentId(info, value, ...)
    local commandId = info[#info - 1]
    setCommand(info, value ~= nilCommandId and value or nil, ...)
    selectCommand(commandId)
end

local function traverseComandTree_parentId(node, excludeCommandId, result, func)
    if node.command.id == excludeCommandId then
        return
    end
    func(node, result)
    for _, childNode in pairs(node.children) do
        traverseComandTree_parentId(childNode, excludeCommandId, result, func)
    end
end

local function traverseComandTree_parentId_values(node, result)
    result[node.command.id] = ("   "):rep(#node.path) .. node.command.name
end

function valuesCommand_parentId(info)
    local commandId = info[#info - 1]

    local values = {[nilCommandId] = "|cff999999<No Parent>"}
    for _, node in pairs(Database.commandTree.rootNodes) do
        traverseComandTree_parentId(node, commandId, values, traverseComandTree_parentId_values)
    end

    return values
end

local function traverseComandTree_parentId_sorting(node, result)
    table.insert(result, node.command.id)
end

function sortingCommand_parentId(info)
    local commandId = info[#info - 1]
    
    local sorting = {nilCommandId}
    for _, node in pairs(Database.commandTree.rootNodes) do
        traverseComandTree_parentId(node, commandId, sorting, traverseComandTree_parentId_sorting)
    end

    return sorting
end
