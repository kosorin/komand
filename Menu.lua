local _, Core = ...

--> Locals
local App = Core.App
local Console = Core.Console
local Command = Core.Command
local Database = Core.Database
local Options = Core.Options
local Menu = Core.Menu
local Utils = Core.Utils

-------------------------------------------------------------------------------
-- Menu
-------------------------------------------------------------------------------

--> Forward declarations

local createMenuFrame

--> Functions

function Menu:Show(commandName)
    local command = Utils.FindByName(Database.db.profile.commands, commandName)
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

--> Local functions

local function executeCommand(_, commandValue)
    Command.Execute(commandValue)
end

local function createMenuButton(node, isMain)
    local info = {}

    local command = node.command

    info.notCheckable = true
    info.isTitle = false
    info.hasArrow = not isMain and getn(node.children) > 0

    info.value = command.id
    info.text = command.name

    info.colorCode = Utils.ToColorCode(command.color)

    info.tooltipTitle = command.name
    info.tooltipText = command.value

    info.func = executeCommand
    info.arg1 = command.value

    return info
end

function createMenuFrame()
    local frame = CreateFrame("Frame", nil, nil, "UIDropDownMenuTemplate")
    frame.displayMode = "MENU"
    frame.initialize = function(_, level)
        if not level then
            return
        end

        local nodes
        local node = UIDROPDOWNMENU_MENU_VALUE and Database.commandTree.nodes[UIDROPDOWNMENU_MENU_VALUE]
        if node then
            nodes = node.children
        else
            nodes = Database.commandTree.rootNodes
        end

        -- TODO: Maybe add settings for this
        if level == 1 and node then
            UIDropDownMenu_AddButton(createMenuButton(node, true), level)
        end

        for _, node in pairs(nodes) do
            if node.command.enabled then
                UIDropDownMenu_AddButton(createMenuButton(node, false), level)
            end
        end
    end
    return frame
end
