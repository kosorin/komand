local unpack = unpack ---@diagnostic disable-line: deprecated

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")

---@type string, Komand
local KOMAND, K = ...

---@class AceConfig.HandlerInfo
---@field arg any
---@field [integer] string

---@class Komand.Options
---@field private options AceConfig.OptionsTable
---@field private tabFrames table
K.Options = {}

local function spaceDivider(order)
    return {
        name = "",
        order = order,
        width = "full",
        type = "description",
    }
end

local tabKeys = {
    commands = "commands",
    general = "general",
    profiles = "profiles",
}

---@type Komand.DB.Id
local noParentId = ""

---@param commandId Komand.DB.Id?
local function selectCommandGroup(commandId)
    local node = commandId and K.Database:GetCommandTree().nodes[commandId]
    local path = node and node.path or {}
    AceConfigDialog:SelectGroup(K.Addon.name, tabKeys.commands, unpack(path))
end

---@param info AceConfig.HandlerInfo
---@return any
local function getValue(info)
    local commandId = info[#info - 1]
    local property = info[#info]
    return K.Database:GetCommand(commandId)[property]
end

---@param info AceConfig.HandlerInfo
---@param value any
local function setValue(info, value)
    local commandId = info[#info - 1]
    local property = info[#info]
    K.Database:GetCommand(commandId)[property] = value
    K.Database:RebuildCommandTree()
end

---@param info AceConfig.HandlerInfo
---@return number r,number g, number b, number a
local function getColor(info)
    local commandId = info[#info - 1]
    local property = info[#info]
    local color = K.Database:GetCommand(commandId)[property]
    ---@diagnostic disable-next-line: redundant-return-value
    return unpack(color ~= nil and color or {})
end

---@param info AceConfig.HandlerInfo
---@param r number
---@param g number
---@param b number
---@param a number
local function setColor(info, r, g, b, a)
    local commandId = info[#info - 1]
    local property = info[#info]
    K.Database:GetCommand(commandId)[property] = { r, g, b, a }
    K.Database:RebuildCommandTree()
end

---@param info AceConfig.HandlerInfo
---@return string
local function getNumber(info)
    local commandId = info[#info - 1]
    local property = info[#info]
    local value = K.Database:GetCommand(commandId)[property]
    return value and tostring(value) or "0"
end

---@param info AceConfig.HandlerInfo
---@param value string
local function setNumber(info, value)
    local commandId = info[#info - 1]
    local property = info[#info]
    K.Database:GetCommand(commandId)[property] = tonumber(value)
    K.Database:RebuildCommandTree()
end

---@param info AceConfig.HandlerInfo
---@param value string
---@return number|string
local function validateNumber(info, value)
    return tonumber(value) or "Not a number!"
end

---@param info AceConfig.HandlerInfo
---@return string
local function getParentId(info)
    return getValue(info) or noParentId
end

---@param info AceConfig.HandlerInfo
---@param value string
local function setParentId(info, value)
    local commandId = info[#info - 1]
    local property = info[#info]
    K.Database:GetCommand(commandId)[property] = value ~= noParentId and value or nil
    K.Database:RebuildCommandTree(true)
    selectCommandGroup(commandId)
end

---@param node Komand.Node
---@param excludeCommandId Komand.DB.Id
---@param callback fun(node: Komand.Node)
local function traverseParents(node, excludeCommandId, callback)
    if node.command.id == excludeCommandId then
        return
    end

    callback(node)

    for _, childNode in pairs(node.children) do
        traverseParents(childNode, excludeCommandId, callback)
    end
end

---@param info AceConfig.HandlerInfo
---@return table<Komand.DB.Id, string>
local function getParentValues(info)
    local commandId = info[#info - 1]

    local values = { [noParentId] = K.Utils.ColorCode { .6, .6, .6 } .. "<No Parent>" }

    for _, rootNode in pairs(K.Database:GetCommandTree().rootNodes) do
        traverseParents(rootNode, commandId, function(node)
            values[node.command.id] = ("   "):rep(#node.path) .. node.command.name
        end)
    end

    return values
end

---@param info AceConfig.HandlerInfo
---@return Komand.DB.Id[]
local function getParentSorting(info)
    local commandId = info[#info - 1]

    local sorting = { noParentId }

    for _, rootNode in pairs(K.Database:GetCommandTree().rootNodes) do
        traverseParents(rootNode, commandId, function(node)
            table.insert(sorting, node.command.id)
        end)
    end

    return sorting
end

---@param order integer
---@return AceConfig.OptionsTable
local function buildCommandsOptionsTable(order)
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
                handler = K.Options,
                func = "OnAddCommand",
            },
        },
    }
end

---@param node Komand.Node
---@param order integer
---@return AceConfig.OptionsTable
local function buildCommandOptionsTable(node, order)
    local command = node.command

    local arg = {
        name = command.name,
        order = order,
        type = "group",
        args = {
            selector = {
                name = "You can't see this",
                order = 0,
                handler = K.Options,
                arg = node,
                hidden = "OnCommandGroupChanged",
                type = "input",
            },
            enabled = {
                name = "Enabled",
                order = 10,
                width = 0.5,
                type = "toggle",
                handler = K.Options,
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
                handler = K.Options,
                arg = node,
                func = "OnRemoveCommand",
            },
            br20 = spaceDivider(20),
            name = {
                name = "Name",
                order = 21,
                width = 1.0,
                type = "input",
                handler = K.Options,
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
                handler = K.Options,
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
                handler = K.Options,
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
                handler = K.Options,
                arg = node,
                get = getParentId,
                set = setParentId,
                values = getParentValues,
                sorting = getParentSorting,
            },
            br100 = spaceDivider(100),
            value = {
                name = "Command",
                order = 101,
                width = "full",
                type = "input",
                multiline = 5,
                handler = K.Options,
                arg = node,
                get = getValue,
                set = setValue,
            },
            test = {
                name = "Test Command",
                desc = "Execute the command. For testing purposes.",
                order = 102,
                type = "execute",
                handler = K.Options,
                arg = node,
                func = "OnExecuteCommand",
            },
            br1000 = spaceDivider(1000),
        }
    }

    for order, childNode in pairs(node.children) do
        arg.args[childNode.command.id] = buildCommandOptionsTable(childNode, order)
    end

    return arg
end

---@param order integer
---@return AceConfig.OptionsTable
local function buildGeneralOptionsTable(order)
    return {
        name = "General",
        order = order,
        cmdHidden = true,
        type = "group",
        args = {},
    }
end

---@param order integer
---@return AceConfig.OptionsTable
local function buildProfilesOptionsTable(order)
    local options = K.Database:GetProfilesOptionsTable()
    options.order = order
    return options
end

---@return AceConfig.OptionsTable
local function buildOptionsTable()
    return {
        type = "group",
        childGroups = "tab",
        args = {
            show = {
                name = "Show",
                order = 0,
                guiHidden = true,
                type = "input",
                set = function(info, value)
                    K.Menu:Show(value)
                end
            },
            options = {
                name = "Options",
                order = 1,
                guiHidden = true,
                type = "input",
                set = function(info, value)
                    AceConfigDialog:Open(K.Addon.name)
                end
            },
            [tabKeys.commands] = buildCommandsOptionsTable(100),
            [tabKeys.general] = buildGeneralOptionsTable(200),
            [tabKeys.profiles] = buildProfilesOptionsTable(300),
        },
    }
end

function K.Options:Initialize()
    self.options = buildOptionsTable()

    AceConfig:RegisterOptionsTable(K.Addon.name, function()
        local args = self.options.args[tabKeys.commands].args or {}

        for key, arg in pairs(args) do
            if arg.type == "group" then
                args[key] = nil
            end
        end

        for order, rootNode in pairs(K.Database:GetCommandTree().rootNodes) do
            args[rootNode.command.id] = buildCommandOptionsTable(rootNode, order)
        end

        return self.options
    end, K.slash)

    AceConfigDialog:SetDefaultSize(K.Addon.name, 640, 640)

    self.tabFrames = {
        [tabKeys.commands] = AceConfigDialog:AddToBlizOptions(
            K.Addon.name, K.Addon.name, nil, tabKeys.commands),
        [tabKeys.general] = AceConfigDialog:AddToBlizOptions(
            K.Addon.name, self.options.args.general.name, K.Addon.name, tabKeys.general),
        [tabKeys.profiles] = AceConfigDialog:AddToBlizOptions(
            K.Addon.name, self.options.args.profiles.name, K.Addon.name, tabKeys.profiles),
    }
end

---@param info AceConfig.HandlerInfo
function K.Options:OnAddCommand(info)
    local command = K.Database:AddCommand(self.lastCommandId)
    selectCommandGroup(command.id)
end

---@param info AceConfig.HandlerInfo
function K.Options:OnRemoveCommand(info)
    local node = info.arg --[[@as Komand.Node]]
    local command = node.command
    K.Database:RemoveCommand(command.id)
    selectCommandGroup(command.parentId)
end

---@param info AceConfig.HandlerInfo
function K.Options:OnExecuteCommand(info)
    local node = info.arg --[[@as Komand.Node]]
    local command = node.command
    K.Command.Execute(command)
end

---@param info AceConfig.HandlerInfo
---@return true
function K.Options:OnCommandGroupChanged(info)
    local node = info.arg --[[@as Komand.Node]]
    local command = node.command
    self.lastCommandId = command.id
    return true
end
