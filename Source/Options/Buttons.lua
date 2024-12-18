local pairs, ipairs, unpack, tonumber, tostring = pairs, ipairs, unpack, tonumber, tostring
local table, string, math = table, string, math

local AceConfigDialog = LibStub("AceConfigDialog-3.0")

---@type string, Komand
local KOMAND, K = ...

---@class Komand.OptionsTab.Buttons : Komand.OptionsTab
local Tab = {
    key = "buttons",
    title = "Buttons",
}

---@class Komand.OptionsTab.Buttons.ActionTab
---@field key mouseButton
---@field title string

---@type Komand.OptionsTab.Buttons.ActionTab[]
local actionTabs = {}
for _, mouseButtonInfo in ipairs(K.Utils.mouseButtons) do
    table.insert(actionTabs, {
        key = mouseButtonInfo.mouseButton,
        title = mouseButtonInfo.label,
    })
end

---@param info AceConfig.Handler.Info
---@return any
local function onGetValue(info)
    local buttonId = info[#info - 1]
    local property = info[#info]
    return K.Button:Get(buttonId)[property]
end

---@param info AceConfig.Handler.Info
---@param value any
local function onSetValue(info, value)
    local buttonId = info[#info - 1]
    local property = info[#info]
    K.Button:Get(buttonId)[property] = value
    K.Button:Refresh(buttonId)
end

---@param info AceConfig.Handler.Info
---@return any
local function onGetActionValue(info)
    local buttonId = info[#info - 2]
    local actionKey = info[#info - 1]
    local property = info[#info]
    return K.Button:Get(buttonId).actions[actionKey][property]
end

---@param info AceConfig.Handler.Info
---@param value any
local function onSetActionValue(info, value)
    local buttonId = info[#info - 2]
    local actionKey = info[#info - 1]
    local property = info[#info]
    K.Button:Get(buttonId).actions[actionKey][property] = value
    K.Button:Refresh(buttonId)
end

---@param info AceConfig.Handler.Info
---@return string
local function onGetActionType(info)
    return onGetActionValue(info) or K.Options.notSetSelectKey
end

---@param info AceConfig.Handler.Info
---@param value string
local function onSetActionType(info, value)
    local buttonId = info[#info - 2]
    local actionKey = info[#info - 1]
    local property = info[#info]
    K.Button:Get(buttonId).actions[actionKey][property] = value ~= K.Options.notSetSelectKey and value or nil
    K.Button:Refresh(buttonId)
end

---@param info AceConfig.Handler.Info
---@return table<Komand.Button.Action.Type, string>
local function onGetActionTypeValues(info)
    local values = {
        [K.Options.notSetSelectKey] = K.Utils.ColorCode { .6, .6, .6 } .. "<Not Set>",
    }

    for _, actionInfo in ipairs(K.Button.actions) do
        values[actionInfo.type] = actionInfo.label
    end

    return values
end

---@param info AceConfig.Handler.Info
---@return string
local function onGetActionCommandId(info)
    return onGetActionValue(info) or K.Options.notSetSelectKey
end

---@param info AceConfig.Handler.Info
---@param value string
local function onSetActionCommandId(info, value)
    local buttonId = info[#info - 2]
    local actionKey = info[#info - 1]
    local property = info[#info]
    K.Button:Get(buttonId).actions[actionKey][property] = value ~= K.Options.notSetSelectKey and value or nil
    K.Button:Refresh(buttonId)
end

---@param info AceConfig.Handler.Info
---@return table<ID, string>
local function onGetActionCommandValues(info)
    local values = {
        [K.Options.notSetSelectKey] = K.Utils.ColorCode { .6, .6, .6 } .. "<No Command>",
    }

    for _, rootNode in pairs(K.Command.tree.rootNodes) do
        rootNode:Traverse(function(node)
            values[node.command.id] = ("   "):rep(#node.path - 1) .. node:GetText(true)
        end)
    end

    return values
end

---@param info AceConfig.Handler.Info
---@return ID[]
local function onGetActionCommandSorting(info)
    local sorting = {
        K.Options.notSetSelectKey,
    }

    for _, rootNode in pairs(K.Command.tree.rootNodes) do
        rootNode:Traverse(function(node)
            table.insert(sorting, node.command.id)
        end)
    end

    return sorting
end

---@param info AceConfig.Handler.Info
local function onAddButton(info)
    local button = K.Button:Add()
    Tab:SelectButtonGroup(button.id)
end

---@param info AceConfig.Handler.Info
local function onRemoveButton(info)
    local buttonId = info[#info - 1]
    local button = K.Button:Get(buttonId)
    K.Button:Remove(button.id)
end

---@param info AceConfig.Handler.Info
---@return true
local function onButtonGroupSelectionChanged(info)
    local buttonId = info[#info - 1]
    K.Options.lastSelectedGroupKey = buttonId
    return true
end

---@param buttonId ID?
function Tab:SelectButtonGroup(buttonId)
    local object = buttonId and K.Button.collection[buttonId]
    local objectId = object and object.button.id
    if objectId then
        AceConfigDialog:SelectGroup(K.addon.name, self.key, objectId)
    else
        AceConfigDialog:SelectGroup(K.addon.name, self.key)
    end
end

---@private
---@param object Komand.Button.Object
---@param actionTab Komand.OptionsTab.Buttons.ActionTab
---@return AceConfig.OptionsTable.Ex
function Tab:BuildButtonActionOptionsTable(object, actionTab)
    ---@type AceConfig.OptionsTable.Ex
    return {
        _key = actionTab.key,
        name = actionTab.title,
        type = "group",
        get = onGetActionValue,
        set = onSetActionValue,
        args = K.Options.Build {
            {
                _key = "type",
                name = "Type",
                width = "normal",
                type = "select",
                style = "dropdown",
                get = onGetActionType,
                set = onSetActionType,
                values = onGetActionTypeValues,
            },
            {
                _key = "commandId",
                name = "Command",
                width = 1.5,
                type = "select",
                style = "dropdown",
                get = onGetActionCommandId,
                set = onSetActionCommandId,
                values = onGetActionCommandValues,
                sorting = onGetActionCommandSorting,
            },
        },
    }
end

---@private
---@param object Komand.Button.Object
---@return AceConfig.OptionsTable
function Tab:BuildButtonOptionsTable(object)
    local button = object.button

    ---@type AceConfig.OptionsTable.Ex[]
    local controlOptionsTables = {
        {
            name = "HIDDEN", ---@todo delete?
            type = "input",
            hidden = onButtonGroupSelectionChanged,
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
            _key = "lock",
            name = "Lock",
            width = 0.5,
            type = "toggle",
        },
        {
            name = "Remove Button",
            type = "execute",
            confirm = true,
            confirmText = ("Remove '%s' button?")
                :format(K.Utils.Colorize({ 1, 0, 0 }, button.name)),
            func = onRemoveButton,
        },
        K.Options.LineBreak(),
        {
            _key = "name",
            name = "Name",
            width = 1.0,
            type = "input",
        },
        K.Options.LineBreak(),
        {
            _key = "icon",
            name = "Icon",
            width = 1.5,
            type = "select",
            values = K.Icon.optionsSelectValues,
        },
    }

    for _, actionOptionsTable in ipairs(actionTabs) do
        table.insert(controlOptionsTables, self:BuildButtonActionOptionsTable(object, actionOptionsTable))
    end

    ---@type AceConfig.OptionsTable
    local buttonOptionsTable = {
        name = button.name,
        type = "group",
        childGroups = "tab",
        get = onGetValue,
        set = onSetValue,
        args = K.Options.Build(controlOptionsTables),
    }

    return buttonOptionsTable
end

---@return AceConfig.OptionsTable.Ex
function Tab:BuildOptionsTable()
    ---@type AceConfig.OptionsTable.Ex
    return {
        _key = self.key,
        name = "Buttons",
        type = "group",
        cmdHidden = true,
        args = K.Options.Build {
            {
                name = "Add Button",
                type = "execute",
                func = onAddButton,
            },
        },
    }
end

---@param containerOptionsTable AceConfig.OptionsTable
function Tab:UpdateOptionsTable(containerOptionsTable)
    local optionsTables = containerOptionsTable.args --[[@as table<string, AceConfig.OptionsTable>]]

    for key, _ in pairs(optionsTables) do
        if K.Utils.StartsWith(key, K.Button.idPrefix) then
            optionsTables[key] = nil
        end
    end

    for order, object in ipairs(K.Button:GetSortedCollection()) do
        local buttonOptionsTable = self:BuildButtonOptionsTable(object)
        buttonOptionsTable.order = order
        optionsTables[object.button.id] = buttonOptionsTable
    end
end

K.Options.Tabs.Buttons = Tab
