local pairs, ipairs, unpack, tonumber, tostring = pairs, ipairs, unpack, tonumber, tostring
local table, string, math = table, string, math

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

---@type string, Komand
local KOMAND, K = ...

---@class AceConfig.OptionsTable.Ex : AceConfig.OptionsTable
---@field _key string?

---@class AceConfig.Handler.Info
---@field arg any
---@field options AceConfig.OptionsTable
---@field option AceConfig.OptionsTable
---@field [integer] string

---@class Komand.OptionsTab
---@field key string
---@field name string
---@field frame table

---@class Komand.OptionsTabs
---@field Commands Komand.OptionsTab.Commands
---@field Buttons Komand.OptionsTab.Buttons
---@field Profiles Komand.OptionsTab.Profiles

---@class Komand.Module.Options : Komand.Module
---@field Tabs Komand.OptionsTabs
---@field notSetSelectKey ID
---@field lastSelectedGroupKey ID?
---@field private options AceConfig.OptionsTable
K.Options = {
    Tabs = {}, ---@diagnostic disable-line: missing-fields
    notSetSelectKey = "",
}

do
    local keyAutoIncrement = 1

    ---@param optionsTables AceConfig.OptionsTable.Ex[]
    ---@return table<string, AceConfig.OptionsTable>
    function K.Options.Build(optionsTables)
        ---@type table<string, AceConfig.OptionsTable>
        local result = {}

        for order, optionsTable in ipairs(optionsTables) do
            local key = optionsTable._key

            if not key then
                key = "_key" .. tostring(keyAutoIncrement)
                keyAutoIncrement = keyAutoIncrement + 1
            end

            assert(not result[key])

            optionsTable._key = nil
            optionsTable.order = order

            result[key] = optionsTable
        end

        return result
    end
end

---@param width (number|AceConfig.OptionsTable.Width)?
---@return AceConfig.OptionsTable.Ex
function K.Options.Space(width)
    ---@type AceConfig.OptionsTable.Ex
    return {
        name = "",
        width = width or 0.1,
        type = "description",
    }
end

---@return AceConfig.OptionsTable.Ex
function K.Options.LineBreak()
    ---@type AceConfig.OptionsTable.Ex
    return {
        name = "",
        width = "full",
        type = "description",
    }
end

---@private
---@return AceConfig.OptionsTable
function K.Options:BuildOptionsTable()
    ---@type AceConfig.OptionsTable
    return {
        name = K.addon.name,
        type = "group",
        childGroups = "tab",
        args = K.Options.Build {
            {
                _key = "show",
                name = "Show",
                desc = "Shows the menu.",
                guiHidden = true,
                type = "input",
                set = function(info, value)
                    K.Menu:Show(K.Command:Find(value))
                end,
            },
            {
                _key = "options",
                name = "Options",
                desc = "Shows the options.",
                guiHidden = true,
                type = "input",
                set = function(info, value)
                    AceConfigDialog:Open(K.addon.name)
                end,
            },
            self.Tabs.Commands:BuildOptionsTable(),
            self.Tabs.Buttons:BuildOptionsTable(),
            self.Tabs.Profiles:BuildOptionsTable(),
        },
    }
end

function K.Options:Initialize()
    self.options = self:BuildOptionsTable()

    AceConfig:RegisterOptionsTable(K.addon.name, function()
        self.Tabs.Commands:UpdateOptionsTable(self.options.args[self.Tabs.Commands.key])
        self.Tabs.Buttons:UpdateOptionsTable(self.options.args[self.Tabs.Buttons.key])
        return self.options
    end, K.slash)

    AceConfigDialog:SetDefaultSize(K.addon.name, 800, 600)

    self.Tabs.Commands.frame = AceConfigDialog:AddToBlizOptions(
        K.addon.name, K.addon.name, nil, self.Tabs.Commands.key)

    self.Tabs.Buttons.frame = AceConfigDialog:AddToBlizOptions(
        K.addon.name, self.Tabs.Buttons.title, K.addon.name, self.Tabs.Buttons.key)

    self.Tabs.Profiles.frame = AceConfigDialog:AddToBlizOptions(
        K.addon.name, self.Tabs.Profiles.title, K.addon.name, self.Tabs.Profiles.key)
end
