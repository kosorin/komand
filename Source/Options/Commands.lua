local pairs, ipairs, unpack, tonumber, tostring = pairs, ipairs, unpack, tonumber, tostring
local table, string, math = table, string, math

local AceConfigDialog = LibStub("AceConfigDialog-3.0")

---@type string, Komand
local KOMAND, K = ...

---@class Komand.OptionsTab.Commands : Komand.OptionsTab
local Tab = {
    key = "commands",
    title = "Commands",
}

---@type table<Komand.Command.Type, string>
local typeValues = {
    ["macro"] = "Macro",
    ["lua"] = "Lua script",
    ["separator"] = "Separator",
}

---@param info AceConfig.Handler.Info
---@return any
local function onGetValue(info)
    local commandId = info[#info - 1]
    local property = info[#info]
    return K.Command:Get(commandId)[property]
end

---@param info AceConfig.Handler.Info
---@param value any
local function onSetValue(info, value)
    local commandId = info[#info - 1]
    local property = info[#info]
    K.Command:Get(commandId)[property] = value
    K.Command:RebuildTree()
end

---@param info AceConfig.Handler.Info
---@return number r,number g, number b, number a
local function onGetColor(info)
    local commandId = info[#info - 1]
    local property = info[#info]
    local color = K.Command:Get(commandId)[property]
    return unpack(color ~= nil and color or {})
end

---@param info AceConfig.Handler.Info
---@param r number
---@param g number
---@param b number
---@param a number
local function onSetColor(info, r, g, b, a)
    local commandId = info[#info - 1]
    local property = info[#info]
    K.Command:Get(commandId)[property] = { r, g, b, a }
    K.Command:RebuildTree()
end

---@param info AceConfig.Handler.Info
---@return string
local function onGetNumber(info)
    local commandId = info[#info - 1]
    local property = info[#info]
    local value = K.Command:Get(commandId)[property]
    return value and tostring(value) or "0"
end

---@param info AceConfig.Handler.Info
---@param value string
local function onSetNumber(info, value)
    local commandId = info[#info - 1]
    local property = info[#info]
    K.Command:Get(commandId)[property] = tonumber(value)
    K.Command:RebuildTree()
end

---@param info AceConfig.Handler.Info
---@param value string
---@return number|string
local function onValidateNumber(info, value)
    return tonumber(value) or "Not a number!"
end

---@param info AceConfig.Handler.Info
---@return string
local function onGetType(info)
    return onGetValue(info) or K.Options.notSetSelectKey
end

---@param info AceConfig.Handler.Info
---@param value string
local function onSetType(info, value)
    local commandId = info[#info - 1]
    local property = info[#info]
    K.Command:Get(commandId)[property] = value ~= K.Options.notSetSelectKey and value or nil
    K.Command:RebuildTree()
end

---@param info AceConfig.Handler.Info
---@return string
local function onGetParentId(info)
    return onGetValue(info) or K.Options.notSetSelectKey
end

---@param info AceConfig.Handler.Info
---@param value string
local function onSetParentId(info, value)
    local commandId = info[#info - 1]
    local property = info[#info]
    K.Command:Get(commandId)[property] = value ~= K.Options.notSetSelectKey and value or nil
    K.Command:RebuildTree()
    Tab:SelectCommandGroup(commandId)
end

---@param info AceConfig.Handler.Info
---@return table<ID, string>
local function onGetParentValues(info)
    local commandId = info[#info - 1]

    local values = {
        [K.Options.notSetSelectKey] = K.Utils.ColorCode { .6, .6, .6 } .. "<Root>",
    }

    for _, rootNode in pairs(K.Command.tree.rootNodes) do
        rootNode:Traverse(function(node)
            values[node.command.id] = ("   "):rep(#node.path) .. node:GetText(true)
        end, commandId)
    end

    return values
end

---@param info AceConfig.Handler.Info
---@return ID[]
local function onGetParentSorting(info)
    local commandId = info[#info - 1]

    local sorting = {
        K.Options.notSetSelectKey,
    }

    for _, rootNode in pairs(K.Command.tree.rootNodes) do
        rootNode:Traverse(function(node)
            table.insert(sorting, node.command.id)
        end, commandId)
    end

    return sorting
end

---@param info AceConfig.Handler.Info
local function onAddCommand(info)
    local command = K.Command:Add(K.Options.lastSelectedGroupKey)
    Tab:SelectCommandGroup(command.id)
end

---@param info AceConfig.Handler.Info
local function onRemoveCommand(info)
    local commandId = info[#info - 1]
    local command = K.Command:Get(commandId)
    K.Command:Remove(command.id)
    Tab:SelectCommandGroup(command.parentId)
end

---@param info AceConfig.Handler.Info
local function onExecuteCommand(info)
    local commandId = info[#info - 1]
    local command = K.Command:Get(commandId)
    K.Command:Execute(command)
end

---@param info AceConfig.Handler.Info
---@return true
local function onIsSeparatorCommand(info)
    local commandId = info[#info - 1]
    local command = K.Command:Get(commandId)
    return command.type == "separator"
end

---@param info AceConfig.Handler.Info
---@return true
local function onCommandGroupSelectionChanged(info)
    local commandId = info[#info - 1]
    K.Options.lastSelectedGroupKey = commandId
    return true
end

---@param commandId ID?
function Tab:SelectCommandGroup(commandId)
    local node = commandId and K.Command.tree.nodes[commandId]
    local path = node and node.path or {}
    AceConfigDialog:SelectGroup(K.addon.name, self.key, unpack(path))
end

---@private
---@param node Komand.Command.Node
---@return AceConfig.OptionsTable.Ex
function Tab:BuildCommandOptionsTable(node)
    local command = node.command

    ---@type AceConfig.OptionsTable.Ex[]
    local controlOptionsTables = {
        {
            name = "HIDDEN", ---@todo delete?
            type = "input",
            hidden = onCommandGroupSelectionChanged,
            disabled = true,
            get = false, ---@diagnostic disable-line: assign-type-mismatch
            set = false, ---@diagnostic disable-line: assign-type-mismatch
        },
        {
            _key = "hide",
            name = "Hide",
            width = 0.5,
            type = "toggle",
        },
        {
            name = "Remove Command",
            type = "execute",
            confirm = true,
            confirmText = ("Remove '%s' command?\nThis will remove ALL children!")
                :format(K.Utils.Colorize({ 1, 0, 0 }, node:GetText())),
            func = onRemoveCommand,
        },
        K.Options.LineBreak(),
        {
            _key = "type",
            name = "Type",
            width = 0.75,
            type = "select",
            style = "dropdown",
            get = onGetType,
            set = onSetType,
            values = typeValues,
        },
        K.Options.Space(),
        {
            _key = "order",
            name = "Order",
            desc = "Order of the command in the context menu.",
            width = 0.5,
            type = "input",
            get = onGetNumber,
            set = onSetNumber,
            validate = onValidateNumber,
        },
        K.Options.LineBreak(),
        {
            _key = "parentId",
            name = "Parent",
            width = 1.5,
            type = "select",
            style = "dropdown",
            get = onGetParentId,
            set = onSetParentId,
            values = onGetParentValues,
            sorting = onGetParentSorting,
        },
        K.Options.LineBreak(),
        {
            _key = "name",
            name = "Name",
            width = 1.0,
            hidden = onIsSeparatorCommand,
            type = "input",
        },
        K.Options.Space(),
        {
            _key = "color",
            name = "Color",
            desc = "Color of the text in the context menu.",
            width = 0.5,
            hidden = onIsSeparatorCommand,
            type = "color",
            hasAlpha = false,
            get = onGetColor,
            set = onSetColor,
        },
        K.Options.LineBreak(),
        {
            _key = "script",
            name = "Script",
            width = "full",
            hidden = onIsSeparatorCommand,
            type = "input",
            multiline = 5,
        },
        {
            name = "Test Command",
            desc = "Execute the command. For testing purposes.",
            hidden = onIsSeparatorCommand,
            type = "execute",
            func = onExecuteCommand,
        },
    }

    for _, childNode in pairs(node.children) do
        table.insert(controlOptionsTables, self:BuildCommandOptionsTable(childNode))
    end

    ---@type AceConfig.OptionsTable.Ex
    local commandOptionsTable = {
        _key = command.id,
        name = node:GetText(),
        type = "group",
        get = onGetValue,
        set = onSetValue,
        args = K.Options.Build(controlOptionsTables),
    }

    return commandOptionsTable
end

---@return AceConfig.OptionsTable.Ex
function Tab:BuildOptionsTable()
    ---@type AceConfig.OptionsTable.Ex
    return {
        _key = self.key,
        name = "Commands",
        type = "group",
        cmdHidden = true,
        args = K.Options.Build {
            {
                name = "Add Command",
                type = "execute",
                func = onAddCommand,
            },
        },
    }
end

---@param containerOptionsTable AceConfig.OptionsTable
function Tab:UpdateOptionsTable(containerOptionsTable)
    local optionsTables = containerOptionsTable.args --[[@as table<string, AceConfig.OptionsTable>]]

    for key, _ in pairs(optionsTables) do
        if K.Utils.StartsWith(key, K.Command.idPrefix) then
            optionsTables[key] = nil
        end
    end

    for order, rootNode in ipairs(K.Command.tree.rootNodes) do
        local commandOptionsTable = self:BuildCommandOptionsTable(rootNode)
        commandOptionsTable.order = order

        K.Options.ClearKey(commandOptionsTable)

        optionsTables[rootNode.command.id] = commandOptionsTable
    end
end

K.Options.Tabs.Commands = Tab
