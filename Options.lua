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
local getValue, setValue
local getColor, setColor
local getNumber, setNumber, validateNumber
local getParentId, setParentId, getParentValues, parentValuesSorting

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
    local node = AceDBOptions:GetOptionsTable(Database.db, true)
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
            enabled = {
                name = "Enabled",
                order = 10,
                width = 0.5,
                type = "toggle",
                handler = self,
                arg = node,
                get = getValue,
                set = setValue,
            },
            remove = {
                name = "Remove Command",
                order = 11,
                type = "execute",
                confirm = true,
                confirmText = ("Remove '|cffff0000%s|r' command?\nThis will remove all children."):format(command.name),
                handler = self,
                arg = node,
                func = "OnRemoveCommand",
            },
            br20 = AceConfigDialog:Break(20),
            name = {
                name = "Name",
                order = 21,
                width = 1.0,
                type = "input",
                handler = self,
                arg = node,
                get = getValue,
                set = setValue,
            },
            color = {
                name = "Color",
                desc = "Color of the text in the context menu.",
                order = 22,
                width = 0.5,
                type = "color",
                hasAlpha = false,
                handler = self,
                arg = node,
                get = getColor,
                set = setColor,
            },
            br30 = AceConfigDialog:Break(30),
            order = {
                name = "Order",
                desc = "Order of the command in the context menu.",
                order = 31,
                width = 0.5,
                type = "input",
                handler = self,
                arg = node,
                get = getNumber,
                set = setNumber,
                validate = validateNumber,
            },
            br50 = AceConfigDialog:Break(50),
            parentId = {
                name = "Parent",
                order = 51,
                width = 1.5,
                type = "select",
                style = "dropdown",
                handler = self,
                arg = node,
                get = getParentId,
                set = setParentId,
                values = getParentValues,
                sorting = parentValuesSorting,
            },
            br100 = AceConfigDialog:Break(100),
            value = {
                name = "Command",
                order = 101,
                width = "full",
                type = "input",
                multiline = 5,
                handler = self,
                arg = node,
                get = getValue,
                set = setValue,
            },
            test = {
                name = "Test Command",
                desc = "Execute the command. For testing purposes.",
                order = 102,
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

function getValue(info)
    local commandId = info[#info - 1]
    local property = info[#info]
    return Database.db.profile.commands[commandId][property]
end

function setValue(info, value, ...)
    local commandId = info[#info - 1]
    local property = info[#info]
    Database.db.profile.commands[commandId][property] = value
    Database:FireDataChanged("SetProperty", property)
end

function getColor(info)
    local commandId = info[#info - 1]
    local property = info[#info]
    local color = Database.db.profile.commands[commandId][property]
    return unpack(color ~= nil and color or {})
end

function setColor(info, value, ...)
    local commandId = info[#info - 1]
    local property = info[#info]
    Database.db.profile.commands[commandId][property] = { value, ... }
    Database:FireDataChanged("SetProperty", property)
end

function getNumber(info)
    local commandId = info[#info - 1]
    local property = info[#info]
    local value = Database.db.profile.commands[commandId][property]
    return value and tostring(value) or "0"
end

function setNumber(info, value, ...)
    local commandId = info[#info - 1]
    local property = info[#info]
    Database.db.profile.commands[commandId][property] = tonumber(value)
    Database:FireDataChanged("SetProperty", property)
end

function validateNumber(info, value)
    return tonumber(value) or "Not a number!"
end

function getParentId(info)
    return getValue(info) or nilCommandId
end

function setParentId(info, value, ...)
    local commandId = info[#info - 1]
    setValue(info, value ~= nilCommandId and value or nil, ...)
    selectCommand(commandId)
end

local function traverseParents(node, excludeCommandId, result, func)
    if node.command.id == excludeCommandId then
        return
    end
    func(node, result)
    for _, childNode in pairs(node.children) do
        traverseParents(childNode, excludeCommandId, result, func)
    end
end

local function traverseParentsValues(node, result)
    result[node.command.id] = ("   "):rep(#node.path) .. node.command.name
end

function getParentValues(info)
    local commandId = info[#info - 1]

    local values = { [nilCommandId] = "|cff999999<No Parent>" }
    for _, node in pairs(Database.commandTree.rootNodes) do
        traverseParents(node, commandId, values, traverseParentsValues)
    end

    return values
end

local function traverseParentsSorting(node, result)
    table.insert(result, node.command.id)
end

function parentValuesSorting(info)
    local commandId = info[#info - 1]

    local sorting = { nilCommandId }
    for _, node in pairs(Database.commandTree.rootNodes) do
        traverseParents(node, commandId, sorting, traverseParentsSorting)
    end

    return sorting
end
