local KOMAND, Core = ...
_G.Komand = Core

local AceDB = LibStub("AceDB-3.0")

local Database = {}
Core.Database = Database

function Database:Initialize()
    self.db = AceDB:New(KOMAND .. "DB", {
        profile = {
            groups = {
                ["**"] = {
                    id = nil,
                    name = "*New Group",
                },
            },
            items = {
                ["**"] = {
                    id = nil,
                    parentId = nil,
                    groupId = nil,
                    name = "*New Item",
                    color = {1, 1, 1, 1},
                    pinned = false,
                    command = "",
                },
            },
        },
    }, true)
    self.db.RegisterCallback(self, "DataChanged", "OnDataChanged")
end

function Database:AddGroup()
    local id = Core.Utils.GenerateId(self.db.profile.groups)
    local group = self.db.profile.groups[id]
    group.id = id
    return group
end

function Database:RemoveGroup(id)
    for _, item in pairs(self.db.profile.items) do
        if (item.groupId == id) then
            self.db.profile.items[item.id] = nil
        end
    end
    self.db.profile.groups[id] = nil
end

function Database:AddItem(groupId)
    local id = Core.Utils.GenerateId(self.db.profile.items)
    local item = self.db.profile.items[id]
    item.id = id
    item.groupId = groupId
    return item
end

function Database:RemoveItem(id)
    self.db.profile.items[id] = nil
end

function Database:FireDataChanged(...)
	self.db.callbacks:Fire("DataChanged", ...)
end

local function generateMenu()
    local root = {
        text = "Menu",
        children = {},
        item = nil,
    }

    local nodes = Core.Utils.Select(Database.db.profile.items, function(_, item) return {
        text = item.name,
        children = {},
        item = item,
    } end)
    nodes = Core.Utils.Sort(nodes, function(a, b)
        return Core.ItemComparer(a.item, b.item)
    end)

    local keyedNodes = {}
    for _, node in pairs(nodes) do
        keyedNodes[node.item.id] = node
    end

    for _, node in pairs(nodes) do
        local parent = node.item.parentId and keyedNodes[node.item.parentId] or root
        table.insert(parent.children, node)
    end

    return {
        root = root,
        nodes = keyedNodes,
    }
end

function Database:OnDataChanged()
    Core.Menu:Hide()
    self.menu = generateMenu()
end
