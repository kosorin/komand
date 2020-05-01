local KOMAND, Core = ...

local Menu = {}
Core.Menu = Menu

function Menu:BuildMenu(group, isRoot)
    local menu = {}

    if isRoot then
        table.insert(menu, {
            text = group.name or KOMAND,
            notCheckable = true,
            isTitle = true,
        })
    end

    local items = Core.db.profile.items or {}
    items = Core.Utils.Where(items, function(_, item)
        return item.groupId == group.id
    end)
    items = Core.Utils.Sort(items, Core.ItemComparer)

    for _, item in ipairs(items) do
        table.insert(menu, {
            text = item.name,
            colorCode = ("|cff%02x%02x%02x"):format(unpack(Core.Utils.Select(item.color, function(_, x)
                return x * 255
            end), 1, 3)),
            func = function()
                Core.Execute(item.command)
            end,
            notCheckable = true,
            tooltipTitle = item.name,
            tooltipText = item.command,
        })
    end

    return menu
end

function Menu:Show(groupName)
    local menu

    local group = Core.Utils.FindByName(Core.db.profile.groups, groupName)
    if group then
        menu = self:BuildMenu(group, true)
    else
        menu = {
            {
                text = "Menu",
                notCheckable = true,
                isTitle = true,
            },
        }
        for _, group in pairs(Core.Utils.Sort(Core.db.profile.groups, Core.GroupComparer)) do
            local subMenu = {
                text = group.name,
                notCheckable = true,
                menuList = self:BuildMenu(group, false),
            }
            subMenu.hasArrow = getn(subMenu.menuList) > 0
            table.insert(menu, subMenu)
        end
    end

    if menu then
        if not self.frame then
            self.frame = CreateFrame("Frame", nil, nil, "UIDropDownMenuTemplate")
        end
        EasyMenu(menu, self.frame, "cursor", 0, 0, "MENU");
    end
end
