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

---@param order integer
---@return AceConfig.OptionsTable
local function spaceDivider(order)
    return {
        name = "",
        order = order,
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
    local function getParentId(info)
        return getValue(info) or notSetSelectKey
    end

    ---@param info AceConfig.HandlerInfo
    ---@param value string
    local function setParentId(info, value)
        local commandId = info[#info - 1]
        local property = info[#info]
        K.Command:Get(commandId)[property] = value ~= notSetSelectKey and value or nil
        K.Command:RebuildTree(true)
        selectCommandGroup(commandId)
    end

    ---@param info AceConfig.HandlerInfo
    ---@return table<ID, string>
    local function getParentValues(info)
        local commandId = info[#info - 1]

        local values = {
            [notSetSelectKey] = K.Utils.ColorCode { .6, .6, .6 } .. "<No Parent>",
        }

        for _, rootNode in pairs(K.Command.tree.rootNodes) do
            traverseParents(rootNode, commandId, function(node)
                values[node.command.id] = ("   "):rep(#node.path)
                    .. K.Utils.ColorCode(node.command.color)
                    .. node.command.name
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

    ---@param node Komand.Command.Node
    ---@param order integer
    ---@return AceConfig.OptionsTable
    local function buildCommandOptionsTable(node, order)
        local command = node.command

        ---@type AceConfig.OptionsTable
        local optionsTable = {
            name = command.name,
            order = order,
            type = "group",
            args = {
                selector = {
                    name = "HIDDEN",
                    order = 0,
                    handler = K.Options,
                    hidden = commandGroupChanged,
                    type = "input",
                },
                hide = {
                    name = "Hide",
                    order = 10,
                    width = 0.5,
                    type = "toggle",
                    handler = K.Options,
                    get = getValue,
                    set = setValue,
                },
                remove = {
                    name = "Remove Command",
                    order = 15,
                    type = "execute",
                    confirm = true,
                    confirmText = ("Remove '|cffff0000%s|r' command?\nThis will remove all children.")
                        :format(command.name),
                    handler = K.Options,
                    func = removeCommand,
                },
                br20 = spaceDivider(20),
                name = {
                    name = "Name",
                    order = 21,
                    width = 1.0,
                    type = "input",
                    handler = K.Options,
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
                    get = getParentId,
                    set = setParentId,
                    values = getParentValues,
                    sorting = getParentSorting,
                },
                br100 = spaceDivider(100),
                script = {
                    name = "Script",
                    order = 101,
                    width = "full",
                    type = "input",
                    multiline = 5,
                    handler = K.Options,
                    get = getValue,
                    set = setValue,
                },
                test = {
                    name = "Test Command",
                    desc = "Execute the command. For testing purposes.",
                    order = 102,
                    type = "execute",
                    handler = K.Options,
                    func = executeCommand,
                },
            },
        }

        for order, childNode in pairs(node.children) do
            optionsTable.args[childNode.command.id] = buildCommandOptionsTable(childNode, order)
        end

        return optionsTable
    end

    ---@private
    ---@param order integer
    ---@return AceConfig.OptionsTable
    function K.Options:BuildCommandsOptionsTable(order)
        ---@type AceConfig.OptionsTable
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

        for order, rootNode in ipairs(K.Command.tree.rootNodes) do
            args[rootNode.command.id] = buildCommandOptionsTable(rootNode, order)
        end
    end
end

do
    ---@alias Komand.Options.ButtonActionTab { key: mouseButton, title: string }
    ---@type Komand.Options.ButtonActionTab[]
    local buttonActionTabs = {
        { key = "LeftButton",   title = "Left Button", },
        { key = "RightButton",  title = "Right Button", },
        { key = "MiddleButton", title = "Middle Button", },
    }

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
    end

    ---@param info AceConfig.HandlerInfo
    ---@return table<Komand.Button.Action.Type, string>
    local function getActionTypeValues(info)
        return {
            [""] = K.Utils.ColorCode { .6, .6, .6 } .. "<Not Set>",
            ["showMenu"] = "Show menu",
            ["executeCommand"] = "Execute command",
        }
    end

    ---@param info AceConfig.HandlerInfo
    ---@return table<ID, string>
    local function getCommandValues(info)
        local values = { [notSetSelectKey] = K.Utils.ColorCode { .6, .6, .6 } .. "<No Command>" }

        for _, rootNode in pairs(K.Command.tree.rootNodes) do
            traverseParents(rootNode, nil, function(node)
                values[node.command.id] = ("   "):rep(#node.path)
                    .. K.Utils.ColorCode(node.command.color)
                    .. node.command.name
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
        -- selectButtonGroup(nil)
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
    ---@param order integer
    ---@param tab Komand.Options.ButtonActionTab
    ---@return AceConfig.OptionsTable?
    local function buildButtonActionOptionsTable(object, order, tab)
        ---@type AceConfig.OptionsTable
        return {
            name = tab.title,
            order = order,
            type = "group",
            args = {
                type = {
                    name = "Type",
                    order = 1,
                    width = "normal",
                    type = "select",
                    style = "dropdown",
                    handler = K.Options,
                    get = getActionType,
                    set = setActionType,
                    values = getActionTypeValues,
                },
                commandId = {
                    name = "Command",
                    order = 2,
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
    ---@param order integer
    ---@return AceConfig.OptionsTable
    local function buildButtonOptionsTable(object, order)
        local button = object.button

        local buttonActionTabsOrderOffset = 100

        ---@type AceConfig.OptionsTable
        local optionsTable = {
            name = button.name,
            order = order,
            type = "group",
            childGroups = "tab",
            args = {
                selector = {
                    name = "HIDDEN",
                    order = 0,
                    handler = K.Options,
                    hidden = buttonGroupChanged,
                    type = "input",
                },
                hide = {
                    name = "Hide",
                    order = 10,
                    width = 0.5,
                    type = "toggle",
                    handler = K.Options,
                    get = getValue,
                    set = setValue,
                },
                lock = {
                    name = "Lock",
                    order = 11,
                    width = 0.5,
                    type = "toggle",
                    handler = K.Options,
                    get = getValue,
                    set = setValue,
                },
                remove = {
                    name = "Remove Button",
                    order = 15,
                    type = "execute",
                    confirm = true,
                    confirmText = ("Remove '|cffff0000%s|r' button?")
                        :format(button.name),
                    handler = K.Options,
                    func = removeButton,
                },
                br20 = spaceDivider(20),
                name = {
                    name = "Name",
                    order = 21,
                    width = 1.0,
                    type = "input",
                    handler = K.Options,
                    get = getValue,
                    set = setValue,
                },
                br100 = spaceDivider(buttonActionTabsOrderOffset),
            },
        }

        for i, tab in ipairs(buttonActionTabs) do
            local tabOrder = buttonActionTabsOrderOffset + i
            optionsTable.args[tab.key] = buildButtonActionOptionsTable(object, tabOrder, tab)
        end

        return optionsTable
    end

    ---@private
    ---@param order integer
    ---@return AceConfig.OptionsTable
    function K.Options:BuildButtonsOptionsTable(order)
        ---@type AceConfig.OptionsTable
        return {
            name = "Buttons",
            order = order,
            cmdHidden = true,
            type = "group",
            args = {
                add = {
                    name = "Add Button",
                    order = 0,
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

        for order, object in ipairs(sortedCollection) do
            args[object.button.id] = buildButtonOptionsTable(object, order)
        end
    end
end

---@private
---@param order integer
---@return AceConfig.OptionsTable
function K.Options:BuildProfilesOptionsTable(order)
    local options = AceDBOptions:GetOptionsTable(K.Database.db, true)
    options.order = order
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
        args = {
            show = {
                name = "Show",
                desc = "Shows the menu.",
                order = 0,
                guiHidden = true,
                type = "input",
                set = function(info, value)
                    K.Menu:Show(K.Command:Find(value))
                end,
            },
            options = {
                name = "Options",
                desc = "Shows the options.",
                order = 1,
                guiHidden = true,
                type = "input",
                set = function(info, value)
                    AceConfigDialog:Open(K.addon.name)
                end,
            },
            [tabKeys.commands] = self:BuildCommandsOptionsTable(100),
            [tabKeys.buttons] = self:BuildButtonsOptionsTable(200),
            [tabKeys.profiles] = self:BuildProfilesOptionsTable(300),
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
