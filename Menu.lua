local KOMAND, Core = ...

local Menu = {}
Core.Menu = Menu

local function executeCommand(_, commandValue)
    Core.Execute(commandValue)
end

local function createMenuButton(node, isMain)
    local info = {}
    
    local command = node.command

    info.notCheckable = true
    info.isTitle = false
    info.hasArrow = not isMain and getn(node.children) > 0

    info.value = command.id
    info.text = command.name
    
    info.colorCode = Core.Utils.ToColorCode(command.color)

    info.tooltipTitle = command.name
    info.tooltipText = command.value

    info.func = executeCommand
    info.arg1 = command.value

    return info
end

local function createMenuFrame()
    local frame = CreateFrame("Frame", nil, nil, "UIDropDownMenuTemplate")
    frame.displayMode = "MENU"
    frame.initialize = function(_, level)
        if not level then
            return
        end

        local node = UIDROPDOWNMENU_MENU_VALUE
            and Core.Database.commandTree.nodes[UIDROPDOWNMENU_MENU_VALUE]
            or Core.Database.commandTree.rootNode
        if not node then
            return
        end

        if level == 1 then
            UIDropDownMenu_AddButton(createMenuButton(node, true), level)
        end

        for _, childNode in pairs(node.children) do
            UIDropDownMenu_AddButton(createMenuButton(childNode, false), level)
        end
    end
    return frame
end

function Menu:Show(commandName)
    local command = Core.Utils.FindByName(Core.Database.db.profile.commands, commandName)
    local commandId = command and command.id or nil
    
    if not self.frame then
        self.frame = createMenuFrame()
    end
    ToggleDropDownMenu(1, commandId, self.frame, "cursor", 0, 0)
end

function Menu:Hide()
    if UIDROPDOWNMENU_OPEN_MENU == self.frame then
        CloseDropDownMenus()
    end
end
