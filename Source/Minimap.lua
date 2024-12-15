local pairs, ipairs, unpack, tonumber, tostring = pairs, ipairs, unpack, tonumber, tostring
local table, string, math = table, string, math

local LibDBIcon = LibStub("LibDBIcon-1.0")

---@type string, Komand
local KOMAND, K = ...

---@class Komand.Module.Minimap : Komand.Module
---@field private items table<ID, Komand.DataBroker.Item>
K.Minimap = {}

local defaultIcon = "Interface\\Icons\\inv_misc_map_01"
local dataBrokerGroup = "minimap"

---@type LibDBIcon.button.DB
local emptyIconButton = {
    hide = true,
    lock = true,
    minimapPos = 0,
}

function K.Minimap:Initialize()
    self.items = {}

    ---@diagnostic disable-next-line: missing-fields
    K.DataBroker:AddGroup(dataBrokerGroup, {
        type = "launcher",
    })

    for _, object in pairs(K.Button.collection) do
        self:Add(object)
    end

    K.Button.RegisterCallback(self, "OnCollectionChanged", "OnCollectionChanged")
end

---@private
---@param object Komand.Button.Object
function K.Minimap:Add(object)
    local button = object.button
    local item, isNew = K.DataBroker:Rent(dataBrokerGroup)

    item.object.icon = button.icon or defaultIcon

    function item.object.OnTooltipShow(tooltip)
        tooltip:SetText(K.addon.name)
        tooltip:AddLine(button.name)
    end

    function item.object.OnClick(_, mouseButton)
        K.Button:Execute(button, mouseButton)
    end

    if isNew then
        LibDBIcon:Register(item.name, item.object, button --[[@as LibDBIcon.button.DB]])
    else
        LibDBIcon:Refresh(item.name, button --[[@as LibDBIcon.button.DB]])
    end

    self.items[button.id] = item
end

---@private
---@param object Komand.Button.Object
function K.Minimap:Remove(object)
    local button = object.button
    local item = self.items[button.id]

    self.items[button.id] = nil

    LibDBIcon:Hide(item.name)
    LibDBIcon:Refresh(item.name, emptyIconButton)

    item.object.OnTooltipShow = nil
    item.object.OnClick = nil

    K.DataBroker:Return(item)
end

---@private
---@param object Komand.Button.Object
function K.Minimap:Refresh(object)
    local button = object.button
    local item = self.items[button.id]

    LibDBIcon:Refresh(item.name, button --[[@as LibDBIcon.button.DB]])
end

---@private
---@param _ Komand.Module.Button
---@param action string
---@param object Komand.Button.Object
function K.Minimap:OnCollectionChanged(_, action, object)
    if object.button.type ~= "minimap" then
        return
    end

    if action == "add" then
        self:Add(object)
    elseif action == "remove" then
        self:Remove(object)
    elseif action == "property" then
        self:Refresh(object)
    end
end
