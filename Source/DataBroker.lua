local pairs, ipairs, unpack, tonumber, tostring = pairs, ipairs, unpack, tonumber, tostring
local table, string, math = table, string, math

local LibDataBroker = LibStub("LibDataBroker-1.1")

---@type string, Komand
local KOMAND, K = ...

---@class Komand.DataBroker.Item
---@field group string
---@field index integer
---@field name string
---@field object LibDataBroker.DataObject

---@class Komand.Module.DataBroker : Komand.Module
---@field private pool { next: integer, [integer]: Komand.DataBroker.Item }
---@field private groups table<string, LibDataBroker.DataObject>
K.DataBroker = {}

function K.DataBroker:Initialize()
    self.pool = { next = 1 }
    self.groups = {}
end

---@param name string
---@param default LibDataBroker.DataObject
function K.DataBroker:AddGroup(name, default)
    self.groups[name] = default
end

---@param group string
---@return Komand.DataBroker.Item
---@return boolean isNew
function K.DataBroker:Rent(group)
    for i = #self.pool, 1, -1 do
        local item = self.pool[i]
        if item.group == group then
            table.remove(self.pool, i)
            return item, false
        end
    end

    local index = self.pool.next
    local name = ("%s_%s_%i"):format(K.addon.name, group, index)

    local data = {}
    for k, v in pairs(self.groups[group]) do
        data[k] = v
    end
    local object = LibDataBroker:NewDataObject(name, data)

    self.pool.next = index + 1

    ---@type Komand.DataBroker.Item
    local item = {
        group = group,
        index = index,
        name = name,
        object = object,
    }

    return item, true
end

---@param item Komand.DataBroker.Item
function K.DataBroker:Return(item)
    table.insert(self.pool, item)
end
