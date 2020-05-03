local KOMAND, Core = ...

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")

function AceConfigDialog:Break(order)
    return {
        name = "",
        order = order,
        width = "full",
        type = "description",
    }
end
function AceConfigDialog:Header(name, order)
    return {
        name = "\n\n|cffffcc00" .. name,
        order = order,
        width = "full",
        type = "description",
    }
end

local Options = {}
Core.Options = Options

local NIL_PARENT_ITEM_ID = ""
local NIL_PARENT_SELECT_ID = 1

function Options:Open()
    AceConfigDialog:Open(KOMAND)
    AceConfigDialog:SelectGroup(KOMAND, "menu")
end

function Options:OnAddGroup()
    local group = Core.Database:AddGroup()
    AceConfigDialog:SelectGroup(KOMAND, "menu", group.id)
end

function Options:OnRemoveGroup(groupId)
    Core.Database:RemoveGroup(groupId)
    AceConfigDialog:SelectGroup(KOMAND, "menu")
end

function Options:OnAddItem(groupId)
    local item = Core.Database:AddItem(groupId)
    AceConfigDialog:SelectGroup(KOMAND, "menu", groupId, item.id)
end

function Options:OnRemoveItem(itemId)
    local item = Core.Database.db.profile.items[itemId]
    Core.Database:RemoveItem(itemId)
    AceConfigDialog:SelectGroup(KOMAND, "menu", item.groupId)
end

function Options:OnExecuteItem(itemId)
    local item = Core.Database.db.profile.items[itemId]
    Core.Execute(item.command)
end


function Options:CreateRoot()

    self.root = {
        type = "group",
        childGroups = "tree",
        args = {},
    }

    -- Command line
    self.root.args.show = {
        name = "Show",
        order = 0,
        guiHidden = true,
        type = "input",
        set = function(info, value)
            Core.Menu:Show(value)
        end
    }
    self.root.args.options = {
        name = "Options",
        order = 1,
        guiHidden = true,
        type = "execute",
        func = function(info)
            self:Open()
        end
    }

    -- GUI
    self.root.args.general = self:CreateGeneral(100)
    self.root.args.menu = self:CreateMenu(101)
    self.root.args.profiles = self:CreateProfiles(101)
end

function Options:CreateGeneral(order)
    return {
        name = "General",
        order = order,
        cmdHidden = true,
        type = "group",
        args = {}
    }
end

function Options:CreateMenu(order)
    return {
        name = "Menu",
        order = order,
        cmdHidden = true,
        type = "group",
        args = {
            groups = {
                name = "Groups",
                order = 10,
                type = "group",
                inline = true,
                args = {
                    new = {
                        name = "Create Group",
                        order = 0,
                        width = "double",
                        type = "execute",
                        func = function(info)
                            self:OnAddGroup()
                        end,
                    },
                },
            },
        }
    }
end

function Options:CreateProfiles(order)
    local node =  AceDBOptions:GetOptionsTable(Core.Database.db, true)
    node.order = order
    return node
end

function Options:CreateGroup(group, order)
    return {
        name = group.name,
        order = order,
        type = "group",
        childGroups = "tree",
        args = {
            group = {
                name = "Group",
                order = 10,
                type = "group",
                inline = true,
                args = {
                    name = {
                        name = "Name",
                        order = 10,
                        width = "normal",
                        type = "input",
                        get = function(info) return group.name end,
                        set = function(info, value) group.name = value end,
                    },
                    delete = {
                        name = "Delete Group",
                        order = 11,
                        width = "normal",
                        type= "execute",
                        confirm = true,
                        confirmText = ("Delete '%s' group?"):format(group.name),
                        func = function(info)
                            self:OnRemoveGroup(group.id)
                        end,
                    },
                },
            },
            items = {
                name = "Items",
                order = 20,
                type = "group",
                inline = true,
                args = {
                    new = {
                        name = "Create Item",
                        order = 10,
                        width = "double",
                        type= "execute",
                        func = function(info)
                            self:OnAddItem(group.id)
                        end,
                    },
                }
            },
        }
    }
end

local function getItemValue(info)
    local itemId = info[#info - 2]
    if info.type == "color" then
        local color = Core.Database.db.profile.items[itemId][info[#info]]
        return unpack(color ~= nil and color or {})
    else
        return Core.Database.db.profile.items[itemId][info[#info]]
    end
end

local function setItemValue(info, value, ...)
    local itemId = info[#info - 2]
    if info.type == "color" then
        Core.Database.db.profile.items[itemId][info[#info]] = {value, ...}
    else
        Core.Database.db.profile.items[itemId][info[#info]] = value
    end
end

local function getItemValueParent(info)
    local itemId = getItemValue(info) or NIL_PARENT_ITEM_ID
    return Options.parentData.fromDatabase[itemId] or NIL_PARENT_SELECT_ID
end

local function setItemValueParent(info, value, ...)
    local parentId = Options.parentData.toDatabase[value]
    setItemValue(info, parentId ~= NIL_PARENT_ITEM_ID and parentId or nil)
end

function Options:CreateItem(item, order)
    return {
        name = item.name,
        desc = item.command,
        order = order,
        type = "group",
        childGroups = "tree",
        args = {
            item = {
                name = "Item",
                order = 1,
                type = "group",
                inline = true,
                args = {
                    name = {
                        name = "Name",
                        order = 10,
                        width = "normal",
                        type = "input",
                        get = getItemValue,
                        set = setItemValue,
                    },
                    delete = {
                        name = "Delete Item",
                        order = 11,
                        width = "normal",
                        type= "execute",
                        confirm = true,
                        confirmText = ("Delete '%s' item?"):format(item.name),
                        func = function(info)
                            self:OnRemoveItem(item.id)
                        end,
                    },
                    settings = AceConfigDialog:Header("Settings", 20),
                    pinned = {
                        name = "Pinned",
                        order = 25,
                        type = "toggle",
                        get = getItemValue,
                        set = setItemValue,
                    },
                    color = {
                        name = "Color",
                        order = 26,
                        type = "color",
                        hasAlpha = false,
                        get = getItemValue,
                        set = setItemValue,
                    },
                    br50 = AceConfigDialog:Break(50),
                    parentId = {
                        name = "Parent",
                        order = 52,
                        width = "double",
                        type = "select",
                        style = "dropdown",
                        values = self.parentData.values,
                        get = getItemValueParent,
                        set = setItemValueParent,
                    },
                    br100 = AceConfigDialog:Break(100),
                    command = {
                        name = "Command",
                        order = 101,
                        width = 1.5,
                        type = "input",
                        get = getItemValue,
                        set = setItemValue,
                    },
                    execute = {
                        name = "Execute",
                        order = 102,
                        width = 0.5,
                        type= "execute",
                        func = function(info)
                            self:OnExecuteItem(item.id)
                        end,
                    },
                    br1000 = AceConfigDialog:Break(1000),
                },
            },
        }
    }
end

function Options:ClearMenu()
    local args = self.root.args.menu.args
    for key, _ in pairs(args) do
        if key:match("^" .. Core.Utils.idPrefix) then
            args[key] = nil
        end
    end
end

function Options:UpdateParentData()
    local selectItems = Core.Database.db.profile.items
    selectItems = Core.Utils.Sort(selectItems, Core.ItemNameComparer)
    selectItems = Core.Utils.Select(selectItems, function(_, item) return {
        key = item.id,
        value = item.name,
    } end)
    table.insert(selectItems, 1, {
        key = NIL_PARENT_ITEM_ID,
        value = "|cff909090<No Parent>",
    })

    self.parentData = {
        values = {},
        fromDatabase = {},
        toDatabase = {},
    }

    for i, selectItem in pairs(selectItems) do
        self.parentData.values[i] = selectItem.value
        self.parentData.fromDatabase[selectItem.key] = i
        self.parentData.toDatabase[i] = selectItem.key
    end
end

function Options:Update()
    self:UpdateParentData()
    self:ClearMenu()
    for order, group in pairs(Core.Utils.Sort(Core.Database.db.profile.groups, Core.GroupComparer)) do
        self.root.args.menu.args[group.id] = self:CreateGroup(group, order)
    end
    for order, item in pairs(Core.Utils.Sort(Core.Database.db.profile.items, Core.ItemComparer)) do
        self.root.args.menu.args[item.groupId].args[item.id] = self:CreateItem(item, order)
    end
end

function Options:Build()
    Core.Database:FireDataChanged()
    
    if self.root == nil then
        self:CreateRoot()
    end
    self:Update()

    return self.root
end

function Options:Initialize()
    self:Build()
    AceConfig:RegisterOptionsTable(KOMAND, function() return self:Build() end, {"k", "kmd", "komand"})
    AceConfigDialog:SetDefaultSize(KOMAND, 600, 600)
end
