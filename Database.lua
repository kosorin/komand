local KOMAND, Core = ...
_G.Komand = Core

local AceDB = LibStub("AceDB-3.0")

local Database = {}
Core.Database = Database

function Database:Initialize()
    Core.db = AceDB:New(KOMAND .. "DB", {
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
    Core.db.RegisterCallback(Core.Addon, "OnProfileChanged", "OnProfileChanged")
    Core.db.RegisterCallback(Core.Addon, "OnProfileCopied", "OnProfileChanged")
    Core.db.RegisterCallback(Core.Addon, "OnProfileReset", "OnProfileChanged")
end

function Database:AddGroup()
    local id = Core.Utils.GenerateId(Core.db.profile.groups)
    local group = Core.db.profile.groups[id]
    group.id = id
    return group
end

function Database:RemoveGroup(id)
    for _, item in pairs(Core.db.profile.items) do
        if (item.groupId == id) then
            Core.db.profile.items[item.id] = nil
        end
    end
    Core.db.profile.groups[id] = nil
end

function Database:AddItem(groupId)
    local id = Core.Utils.GenerateId(Core.db.profile.items)
    local item = Core.db.profile.items[id]
    item.id = id
    item.groupId = groupId
    return item
end

function Database:RemoveItem(id)
    Core.db.profile.items[id] = nil
end
