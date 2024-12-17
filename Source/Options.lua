local pairs, ipairs, unpack, tonumber, tostring = pairs, ipairs, unpack, tonumber, tostring
local table, string, math = table, string, math

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")

---@type string, Komand
local KOMAND, K = ...

---@class AceConfig.HandlerInfo
---@field arg any
---@field options AceConfig.OptionsTable
---@field option AceConfig.OptionsTable
---@field [integer] string

---@class Komand.Module.Options : Komand.Module
---@field private options AceConfig.OptionsTable
---@field private tabFrames table
---@field private lastSelectedId ID?
K.Options = {}

local tabKeys = {
    commands = "commands",
    buttons = "buttons",
    profiles = "profiles",
}

---@param args AceConfig.OptionsTable[]
---@return table<string, AceConfig.OptionsTable>
local function build(args)
    local result = {}

    local unspecifiedKey = 1

    for order, value in ipairs(args) do
        local key = value.key

        if not key then
            key = "__key" .. tostring(unspecifiedKey)
            unspecifiedKey = unspecifiedKey + 1
        end

        value.key = nil ---@diagnostic disable-line: inject-field
        value.order = order

        result[key] = value
    end

    return result
end

---@param width number?
---@return AceConfig.OptionsTable
local function space(width)
    return {
        name = "",
        width = width or 0.1,
        type = "description",
    }
end

---@return AceConfig.OptionsTable
local function lineBreak()
    return {
        name = "",
        width = "full",
        type = "description",
    }
end

---@type ID
local notSetSelectKey = ""

---@param node Komand.Command.Node
---@param excludeCommandId ID?
---@param callback fun(node: Komand.Command.Node)
local function traverseParents(node, excludeCommandId, callback)
    if excludeCommandId and excludeCommandId == node.command.id then
        return
    end

    callback(node)

    for _, childNode in pairs(node.children) do
        traverseParents(childNode, excludeCommandId, callback)
    end
end

do
    ---@param commandId ID?
    local function selectCommandGroup(commandId)
        local node = commandId and K.Command.tree.nodes[commandId]
        local path = node and node.path or {}
        AceConfigDialog:SelectGroup(K.addon.name, tabKeys.commands, unpack(path))
    end

    ---@param info AceConfig.HandlerInfo
    ---@return any
    local function getValue(info)
        local commandId = info[#info - 1]
        local property = info[#info]
        return K.Command:Get(commandId)[property]
    end

    ---@param info AceConfig.HandlerInfo
    ---@param value any
    local function setValue(info, value)
        local commandId = info[#info - 1]
        local property = info[#info]
        K.Command:Get(commandId)[property] = value
        K.Command:RebuildTree()
    end

    ---@param info AceConfig.HandlerInfo
    ---@return number r,number g, number b, number a
    local function getColor(info)
        local commandId = info[#info - 1]
        local property = info[#info]
        local color = K.Command:Get(commandId)[property]
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
        K.Command:Get(commandId)[property] = { r, g, b, a }
        K.Command:RebuildTree()
    end

    ---@param info AceConfig.HandlerInfo
    ---@return string
    local function getNumber(info)
        local commandId = info[#info - 1]
        local property = info[#info]
        local value = K.Command:Get(commandId)[property]
        return value and tostring(value) or "0"
    end

    ---@param info AceConfig.HandlerInfo
    ---@param value string
    local function setNumber(info, value)
        local commandId = info[#info - 1]
        local property = info[#info]
        K.Command:Get(commandId)[property] = tonumber(value)
        K.Command:RebuildTree()
    end

    ---@param info AceConfig.HandlerInfo
    ---@param value string
    ---@return number|string
    local function validateNumber(info, value)
        return tonumber(value) or "Not a number!"
    end

    ---@param info AceConfig.HandlerInfo
    ---@return string
    local function getType(info)
        return getValue(info) or notSetSelectKey
    end

    ---@param info AceConfig.HandlerInfo
    ---@param value string
    local function setType(info, value)
        local commandId = info[#info - 1]
        local property = info[#info]
        K.Command:Get(commandId)[property] = value ~= notSetSelectKey and value or nil
        K.Command:RebuildTree()
    end

    ---@param info AceConfig.HandlerInfo
    ---@return table<Komand.Command.Type, string>
    local function getTypeValues(info)
        return {
            ["macro"] = "Macro",
            ["lua"] = "Lua script",
            ["separator"] = "Separator",
        }
    end

    ---@param info AceConfig.HandlerInfo
    ---@return string
    local function getParentId(info)
        return getValue(info) or notSetSelectKey
    end

    ---@param info AceConfig.HandlerInfo
    ---@param value string
    local function setParentId(info, value)
        local commandId = info[#info - 1]
        local property = info[#info]
        K.Command:Get(commandId)[property] = value ~= notSetSelectKey and value or nil
        K.Command:RebuildTree()
        selectCommandGroup(commandId)
    end

    ---@param info AceConfig.HandlerInfo
    ---@return table<ID, string>
    local function getParentValues(info)
        local commandId = info[#info - 1]

        local values = {
            [notSetSelectKey] = K.Utils.ColorCode { .6, .6, .6 } .. "<Root>",
        }

        for _, rootNode in pairs(K.Command.tree.rootNodes) do
            traverseParents(rootNode, commandId, function(node)
                values[node.command.id] = ("   "):rep(#node.path) .. node:GetText(true)
            end)
        end

        return values
    end

    ---@param info AceConfig.HandlerInfo
    ---@return ID[]
    local function getParentSorting(info)
        local commandId = info[#info - 1]

        local sorting = { notSetSelectKey }

        for _, rootNode in pairs(K.Command.tree.rootNodes) do
            traverseParents(rootNode, commandId, function(node)
                table.insert(sorting, node.command.id)
            end)
        end

        return sorting
    end

    ---@private
    ---@param info AceConfig.HandlerInfo
    local function addCommand(info)
        local command = K.Command:Add(K.Options.lastSelectedId)
        selectCommandGroup(command.id)
    end

    ---@private
    ---@param info AceConfig.HandlerInfo
    local function removeCommand(info)
        local commandId = info[#info - 1]
        local command = K.Command:Get(commandId)
        K.Command:Remove(command.id)
        selectCommandGroup(command.parentId)
    end

    ---@private
    ---@param info AceConfig.HandlerInfo
    local function executeCommand(info)
        local commandId = info[#info - 1]
        local command = K.Command:Get(commandId)
        K.Command:Execute(command)
    end

    ---@private
    ---@param info AceConfig.HandlerInfo
    ---@return true
    local function commandGroupChanged(info)
        local commandId = info[#info - 1]
        local command = K.Command:Get(commandId)
        K.Options.lastSelectedId = command.id
        return true
    end

    ---@private
    ---@param info AceConfig.HandlerInfo
    ---@return true
    local function commandIsSeparator(info)
        local commandId = info[#info - 1]
        local command = K.Command:Get(commandId)
        return command.type == "separator"
    end

    ---@param node Komand.Command.Node
    ---@return AceConfig.OptionsTable
    local function buildCommandOptionsTable(node)
        local command = node.command

        local argsSource = {
            {
                key = "selector",
                name = "HIDDEN",
                handler = K.Options,
                hidden = commandGroupChanged,
                type = "input",
            },
            {
                key = "hide",
                name = "Hide",
                width = 0.5,
                type = "toggle",
                handler = K.Options,
                get = getValue,
                set = setValue,
            },
            {
                key = "remove",
                name = "Remove Command",
                type = "execute",
                confirm = true,
                confirmText = ("Remove '%s' command?\nThis will remove all children.")
                    :format(K.Utils.Colorize({ 1, 0, 0 }, node:GetText())),
                handler = K.Options,
                func = removeCommand,
            },
            lineBreak(),
            {
                key = "type",
                name = "Type",
                width = 0.75,
                type = "select",
                style = "dropdown",
                handler = K.Options,
                get = getType,
                set = setType,
                values = getTypeValues,
            },
            space(),
            {
                key = "order",
                name = "Order",
                desc = "Order of the command in the context menu.",
                width = 0.5,
                type = "input",
                handler = K.Options,
                get = getNumber,
                set = setNumber,
                validate = validateNumber,
            },
            lineBreak(),
            {
                key = "parentId",
                name = "Parent",
                width = 1.5,
                type = "select",
                style = "dropdown",
                handler = K.Options,
                get = getParentId,
                set = setParentId,
                values = getParentValues,
                sorting = getParentSorting,
            },
            lineBreak(),
            {
                key = "name",
                name = "Name",
                width = 1.0,
                hidden = commandIsSeparator,
                type = "input",
                handler = K.Options,
                get = getValue,
                set = setValue,
            },
            space(),
            {
                key = "color",
                name = "Color",
                desc = "Color of the text in the context menu.",
                width = 0.5,
                hidden = commandIsSeparator,
                type = "color",
                hasAlpha = false,
                handler = K.Options,
                get = getColor,
                set = setColor,
            },
            lineBreak(),
            {
                key = "script",
                name = "Script",
                width = "full",
                hidden = commandIsSeparator,
                type = "input",
                multiline = 5,
                handler = K.Options,
                get = getValue,
                set = setValue,
            },
            {
                key = "test",
                name = "Test Command",
                desc = "Execute the command. For testing purposes.",
                hidden = commandIsSeparator,
                type = "execute",
                handler = K.Options,
                func = executeCommand,
            },
        }

        for _, childNode in pairs(node.children) do
            table.insert(argsSource, buildCommandOptionsTable(childNode))
        end

        ---@type AceConfig.OptionsTable
        local optionsTable = {
            key = node.command.id,
            name = node:GetText(),
            type = "group",
            args = build(argsSource),
        }

        return optionsTable
    end

    ---@private
    ---@return AceConfig.OptionsTable
    function K.Options:BuildCommandsOptionsTable()
        ---@type AceConfig.OptionsTable
        return {
            key = tabKeys.commands,
            name = "Commands",
            cmdHidden = true,
            type = "group",
            args = build {
                {
                    key = "add",
                    name = "Add Command",
                    type = "execute",
                    handler = K.Options,
                    func = addCommand,
                },
            },
        }
    end

    ---@private
    ---@param args table<string, AceConfig.OptionsTable>
    function K.Options:RebuildCommandsOptionsTable(args)
        for key, optionsTable in pairs(args) do
            if optionsTable.type == "group" then
                args[key] = nil
            end
        end

        local argsSource = {}
        for _, rootNode in ipairs(K.Command.tree.rootNodes) do
            table.insert(argsSource, buildCommandOptionsTable(rootNode))
        end

        for key, childArgs in pairs(build(argsSource)) do
            args[key] = childArgs
        end
    end
end

do
    ---@alias Komand.Options.ButtonActionTab { key: mouseButton, title: string }
    ---@type Komand.Options.ButtonActionTab[]
    local buttonActionTabs = {}
    for _, mouseButtonInfo in ipairs(K.Utils.mouseButtons) do
        table.insert(buttonActionTabs, { key = mouseButtonInfo.mouseButton, title = mouseButtonInfo.label, })
    end

    ---@param buttonId ID?
    local function selectButtonGroup(buttonId)
        local object = buttonId and K.Button.collection[buttonId]
        local objectId = object and object.button.id
        if objectId then
            AceConfigDialog:SelectGroup(K.addon.name, tabKeys.buttons, objectId)
        else
            AceConfigDialog:SelectGroup(K.addon.name, tabKeys.buttons)
        end
    end

    ---@param info AceConfig.HandlerInfo
    ---@return any
    local function getValue(info)
        local buttonId = info[#info - 1]
        local property = info[#info]
        return K.Button:Get(buttonId)[property]
    end

    ---@param info AceConfig.HandlerInfo
    ---@param value any
    local function setValue(info, value)
        local buttonId = info[#info - 1]
        local property = info[#info]
        K.Button:Get(buttonId)[property] = value
        K.Button:Refresh(buttonId)
    end

    ---@param info AceConfig.HandlerInfo
    ---@return any
    local function getActionValue(info)
        local buttonId = info[#info - 2]
        local actionKey = info[#info - 1]
        local property = info[#info]
        return K.Button:Get(buttonId).actions[actionKey][property]
    end

    ---@param info AceConfig.HandlerInfo
    ---@param value any
    local function setActionValue(info, value)
        local buttonId = info[#info - 2]
        local actionKey = info[#info - 1]
        local property = info[#info]
        K.Button:Get(buttonId).actions[actionKey][property] = value
        K.Button:Refresh(buttonId)
    end

    ---@param info AceConfig.HandlerInfo
    ---@return string
    local function getActionType(info)
        return getActionValue(info) or notSetSelectKey
    end

    ---@param info AceConfig.HandlerInfo
    ---@param value string
    local function setActionType(info, value)
        local buttonId = info[#info - 2]
        local actionKey = info[#info - 1]
        local property = info[#info]
        K.Button:Get(buttonId).actions[actionKey][property] = value ~= notSetSelectKey and value or nil
        K.Button:Refresh(buttonId)
    end

    ---@param info AceConfig.HandlerInfo
    ---@return table<Komand.Button.Action.Type, string>
    local function getActionTypeValues(info)
        local values = {
            [notSetSelectKey] = K.Utils.ColorCode { .6, .6, .6 } .. "<Not Set>",
        }

        for _, actionInfo in ipairs(K.Button.actions) do
            values[actionInfo.type] = actionInfo.label
        end

        return values
    end

    ---@param info AceConfig.HandlerInfo
    ---@return string
    local function getActionCommandId(info)
        return getActionValue(info) or notSetSelectKey
    end

    ---@param info AceConfig.HandlerInfo
    ---@param value string
    local function setActionCommandId(info, value)
        local buttonId = info[#info - 2]
        local actionKey = info[#info - 1]
        local property = info[#info]
        K.Button:Get(buttonId).actions[actionKey][property] = value ~= notSetSelectKey and value or nil
        K.Button:Refresh(buttonId)
    end

    ---@param info AceConfig.HandlerInfo
    ---@return table<ID, string>
    local function getCommandValues(info)
        local values = { [notSetSelectKey] = K.Utils.ColorCode { .6, .6, .6 } .. "<No Command>" }

        for _, rootNode in pairs(K.Command.tree.rootNodes) do
            traverseParents(rootNode, nil, function(node)
                values[node.command.id] = ("   "):rep(#node.path - 1) .. node:GetText(true)
            end)
        end

        return values
    end

    ---@param info AceConfig.HandlerInfo
    ---@return ID[]
    local function getCommandSorting(info)
        local sorting = { notSetSelectKey }

        for _, rootNode in pairs(K.Command.tree.rootNodes) do
            traverseParents(rootNode, nil, function(node)
                table.insert(sorting, node.command.id)
            end)
        end

        return sorting
    end

    ---@private
    ---@param info AceConfig.HandlerInfo
    local function addButton(info)
        local button = K.Button:Add()
        selectButtonGroup(button.id)
    end

    ---@private
    ---@param info AceConfig.HandlerInfo
    local function removeButton(info)
        local buttonId = info[#info - 1]
        local button = K.Button:Get(buttonId)
        K.Button:Remove(button.id)
    end

    ---@private
    ---@param info AceConfig.HandlerInfo
    ---@return true
    local function buttonGroupChanged(info)
        local buttonId = info[#info - 1]
        local button = K.Button:Get(buttonId)
        K.Options.lastSelectedId = button.id
        return true
    end

    ---@param object Komand.Button.Object
    ---@param tab Komand.Options.ButtonActionTab
    ---@return AceConfig.OptionsTable?
    local function buildButtonActionOptionsTable(object, tab)
        ---@type AceConfig.OptionsTable
        return {
            key = tab.key,
            name = tab.title,
            type = "group",
            args = build {
                {
                    key = "type",
                    name = "Type",
                    width = "normal",
                    type = "select",
                    style = "dropdown",
                    handler = K.Options,
                    get = getActionType,
                    set = setActionType,
                    values = getActionTypeValues,
                },
                {
                    key = "commandId",
                    name = "Command",
                    width = 1.5,
                    type = "select",
                    style = "dropdown",
                    handler = K.Options,
                    get = getActionCommandId,
                    set = setActionCommandId,
                    values = getCommandValues,
                    sorting = getCommandSorting,
                },
            },
        }
    end

    ---@param object Komand.Button.Object
    ---@return AceConfig.OptionsTable
    local function buildButtonOptionsTable(object)
        local button = object.button

        local argsSource = {
            {
                key = "selector",
                name = "HIDDEN",
                handler = K.Options,
                hidden = buttonGroupChanged,
                type = "input",
            },
            {
                key = "hide",
                name = "Hide",
                width = 0.5,
                type = "toggle",
                handler = K.Options,
                get = getValue,
                set = setValue,
            },
            {
                key = "lock",
                name = "Lock",
                width = 0.5,
                type = "toggle",
                handler = K.Options,
                get = getValue,
                set = setValue,
            },
            {
                key = "remove",
                name = "Remove Button",
                type = "execute",
                confirm = true,
                confirmText = ("Remove '%s' button?")
                    :format(K.Utils.Colorize({ 1, 0, 0 }, button.name)),
                handler = K.Options,
                func = removeButton,
            },
            lineBreak(),
            {
                key = "name",
                name = "Name",
                width = 1.0,
                type = "input",
                handler = K.Options,
                get = getValue,
                set = setValue,
            },
            lineBreak(),
            {
                key = "icon",
                name = "Icon",
                width = 1.5,
                type = "select",
                get = getValue,
                set = setValue,
                values = K.Icon.optionsSelectValues,
            },
        }

        for _, tab in ipairs(buttonActionTabs) do
            table.insert(argsSource, buildButtonActionOptionsTable(object, tab))
        end

        ---@type AceConfig.OptionsTable
        local optionsTable = {
            key = button.id,
            name = button.name,
            type = "group",
            childGroups = "tab",
            args = build(argsSource),
        }

        return optionsTable
    end

    ---@private
    ---@return AceConfig.OptionsTable
    function K.Options:BuildButtonsOptionsTable()
        ---@type AceConfig.OptionsTable
        return {
            key = tabKeys.buttons,
            name = "Buttons",
            cmdHidden = true,
            type = "group",
            args = build {
                {
                    key = "add",
                    name = "Add Button",
                    type = "execute",
                    handler = K.Options,
                    func = addButton,
                },
            },
        }
    end

    ---@private
    ---@param args table<string, AceConfig.OptionsTable>
    function K.Options:RebuildButtonsOptionsTable(args)
        for key, optionsTable in pairs(args) do
            if optionsTable.type == "group" then
                args[key] = nil
            end
        end

        ---@type Komand.Button.Object[]
        local sortedCollection = {}

        for _, object in pairs(K.Button.collection) do
            table.insert(sortedCollection, object)
        end

        table.sort(sortedCollection, function(a, b)
            local aa, bb

            aa = a.button.name:upper()
            bb = b.button.name:upper()
            if aa ~= bb then
                return aa < bb
            end

            return aa < bb
        end)

        local argsSource = {}
        for _, object in ipairs(sortedCollection) do
            table.insert(argsSource, buildButtonOptionsTable(object))
        end

        for key, childArgs in pairs(build(argsSource)) do
            args[key] = childArgs
        end
    end
end

---@private
---@return AceConfig.OptionsTable
function K.Options:BuildProfilesOptionsTable()
    local options = AceDBOptions:GetOptionsTable(K.Database.db, true)
    options.key = tabKeys.profiles ---@diagnostic disable-line: inject-field
    return options
end

---@private
---@return AceConfig.OptionsTable
function K.Options:BuildOptionsTable()
    ---@type AceConfig.OptionsTable
    return {
        name = K.addon.name,
        type = "group",
        childGroups = "tab",
        args = build {
            {
                key = "show",
                name = "Show",
                desc = "Shows the menu.",
                guiHidden = true,
                type = "input",
                set = function(info, value)
                    K.Menu:Show(K.Command:Find(value))
                end,
            },
            {
                key = "options",
                name = "Options",
                desc = "Shows the options.",
                guiHidden = true,
                type = "input",
                set = function(info, value)
                    AceConfigDialog:Open(K.addon.name)
                end,
            },
            self:BuildCommandsOptionsTable(),
            self:BuildButtonsOptionsTable(),
            self:BuildProfilesOptionsTable(),
        },
    }
end

function K.Options:Initialize()
    self.options = self:BuildOptionsTable()

    AceConfig:RegisterOptionsTable(K.addon.name, function()
        self:RebuildCommandsOptionsTable(self.options.args[tabKeys.commands].args or {})
        self:RebuildButtonsOptionsTable(self.options.args[tabKeys.buttons].args or {})
        return self.options
    end, K.slash)

    AceConfigDialog:SetDefaultSize(K.addon.name, 800, 600)

    self.tabFrames = {
        [tabKeys.commands] = AceConfigDialog:AddToBlizOptions(
            K.addon.name, K.addon.name, nil, tabKeys.commands),
        [tabKeys.buttons] = AceConfigDialog:AddToBlizOptions(
            K.addon.name, self.options.args.buttons.name --[[@as string]], K.addon.name, tabKeys.buttons),
        [tabKeys.profiles] = AceConfigDialog:AddToBlizOptions(
            K.addon.name, self.options.args.profiles.name --[[@as string]], K.addon.name, tabKeys.profiles),
    }
end
