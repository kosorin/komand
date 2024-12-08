local unpack = unpack ---@diagnostic disable-line: deprecated

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")

---@type string, Komand
local KOMAND, K = ...

---@class Komand.Options
---@field options table
---@field frames table
K.Options = {}

local function spaceDivider(order)
    return {
        name = "",
        order = order,
        width = "full",
        type = "description",
    }
end

local selectCommand
local getValue, setValue
local getColor, setColor
local getNumber, setNumber, validateNumber
local getParentId, setParentId, getParentValues, parentValuesSorting

local commandOrderOffset = 100
local nilCommandId = ""

--> Functions

function K.Options:Initialize()
    self:Build()

    AceConfig:RegisterOptionsTable(K.App.name, function() return self:Build() end, { "komand", "kmd" })

    AceConfigDialog:SetDefaultSize(K.App.name, 600, 600)

    self.frames = {
        commands = AceConfigDialog:AddToBlizOptions(K.App.name, nil, nil, "commands"),
        general = AceConfigDialog:AddToBlizOptions(K.App.name, self.options.args.general.name, K.App.name, "general"),
        profiles = AceConfigDialog:AddToBlizOptions(K.App.name, self.options.args.profiles.name, K.App.name, "profiles"),
    }
end

function K.Options:Build()
    if self.options == nil then
        K.Database:FireDataChanged("BuildOptions")
        self:BuildOptions()
    end
    self:UpdateOptions()
    return self.options
end

function K.Options:BuildOptions()
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
            K.Menu:Show(value)
        end
    }
    self.options.args.options = {
        name = "Options",
        order = 1,
        guiHidden = true,
        type = "input",
        set = function(info, value)
            AceConfigDialog:Open(K.App.name)
            --Settings.OpenToCategory(K.App.name)
        end
    }

    -- GUI
    self.options.args.commands = self:BuildCommandsOptions(100)
    self.options.args.general = self:BuildGeneralOptions(200)
    self.options.args.profiles = self:BuildProfilesOptions(300)
end

function K.Options:BuildCommandsOptions(order)
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

function K.Options:BuildGeneralOptions(order)
    return {
        name = "General",
        order = order,
        cmdHidden = true,
        type = "group",
        args = {},
    }
end

function K.Options:BuildProfilesOptions(order)
    local node = AceDBOptions:GetOptionsTable(K.Database.db, true)
    node.order = order
    return node
end

function K.Options:UpdateOptions()
    for key, arg in pairs(self.options.args.commands.args) do
        if arg.order >= commandOrderOffset then
            self.options.args.commands.args[key] = nil
        end
    end

    for order, node in pairs(K.Database.commandTree.rootNodes) do
        self.options.args.commands.args[node.command.id] = self:BuildCommand(node, commandOrderOffset + order)
    end
end

function K.Options:BuildCommand(node, order)
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
            br20 = spaceDivider(20),
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
            br30 = spaceDivider(30),
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
            br50 = spaceDivider(50),
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
            br100 = spaceDivider(100),
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
            br1000 = spaceDivider(1000),
        }
    }

    for order, childNode in pairs(node.children) do
        arg.args[childNode.command.id] = self:BuildCommand(childNode, order)
    end

    return arg
end

function K.Options:OnAddCommand(info)
    local command = K.Database:AddCommand(self.lastCommandId)
    selectCommand(command.id)
end

function K.Options:OnRemoveCommand(info)
    local commandId = info.arg.command.id
    local command = K.Database:RemoveCommand(commandId)
    selectCommand(command.parentId)
end

function K.Options:OnExecuteCommand(info)
    local commandId = info.arg.command.id
    local command = K.Database.db.profile.commands[commandId]
    K.Command.Execute(command)
end

function K.Options:OnCommandNodeChanged(info)
    local command = info.arg.command

    self.lastCommandId = command.id

    return true
end

function selectCommand(commandId)
    local node = commandId and K.Database.commandTree.nodes[commandId]
    AceConfigDialog:SelectGroup(K.App.name, "commands", unpack(node and node.path or {}))
end

function getValue(info)
    local commandId = info[#info - 1]
    local property = info[#info]
    return K.Database.db.profile.commands[commandId][property]
end

function setValue(info, value, ...)
    local commandId = info[#info - 1]
    local property = info[#info]
    K.Database.db.profile.commands[commandId][property] = value
    K.Database:FireDataChanged("SetProperty", property)
end

function getColor(info)
    local commandId = info[#info - 1]
    local property = info[#info]
    local color = K.Database.db.profile.commands[commandId][property]
    return unpack(color ~= nil and color or {})
end

function setColor(info, value, ...)
    local commandId = info[#info - 1]
    local property = info[#info]
    K.Database.db.profile.commands[commandId][property] = { value, ... }
    K.Database:FireDataChanged("SetProperty", property)
end

function getNumber(info)
    local commandId = info[#info - 1]
    local property = info[#info]
    local value = K.Database.db.profile.commands[commandId][property]
    return value and tostring(value) or "0"
end

function setNumber(info, value, ...)
    local commandId = info[#info - 1]
    local property = info[#info]
    K.Database.db.profile.commands[commandId][property] = tonumber(value)
    K.Database:FireDataChanged("SetProperty", property)
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
    for _, node in pairs(K.Database.commandTree.rootNodes) do
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
    for _, node in pairs(K.Database.commandTree.rootNodes) do
        traverseParents(node, commandId, sorting, traverseParentsSorting)
    end

    return sorting
end
