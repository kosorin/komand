local KOMAND, Core = ...

local Menu = {}
Core.Menu = Menu

local function executeCommand(_, command)
    Core.Execute(command)
end

local function createMenuButton(node, isTitle)
    local info = {}
    
    info.isTitle = isTitle
    info.notCheckable = true
    info.text = node.text
    info.hasArrow = not isTitle and getn(node.children) > 0
    
    local item = node.item
    if item then
        info.value = item.id
        
        info.isTitle = false
        info.colorCode = Core.Utils.ToColorCode(item.color)

        info.tooltipTitle = item.name
        info.tooltipText = item.command

        info.func = executeCommand
        info.arg1 = item.command
    end

    return info
end

local function createMenuFrame()
    local frame = CreateFrame("Frame", nil, nil, "UIDropDownMenuTemplate")
    frame.displayMode = "MENU"
    frame.initialize = function(_, level)
        if not level then
            return
        end

        local parentNode = UIDROPDOWNMENU_MENU_VALUE
            and Core.Database.menu.nodes[UIDROPDOWNMENU_MENU_VALUE]
            or Core.Database.menu.root
        if not parentNode then
            return
        end

        -- Title
        if level == 1 then
            UIDropDownMenu_AddButton(createMenuButton(parentNode, true), level)
        end

        -- Items
        for _, node in pairs(parentNode.children) do
            UIDropDownMenu_AddButton(createMenuButton(node, false), level)
        end
    end
    return frame
end

function Menu:Show(itemName)
    if not self.frame then
        self.frame = createMenuFrame()
    end

    local item = Core.Utils.FindByName(Core.Database.db.profile.items, itemName)
    local itemId = item and item.id or nil

    ToggleDropDownMenu(1, itemId, self.frame, "cursor", 0, 0)
end

function Menu:Hide()
    if UIDROPDOWNMENU_OPEN_MENU == self.frame then
        CloseDropDownMenus()
    end
end
