---@type string, Komand
local KOMAND, K = ...

---@class Komand.Menu
---@field frame W.Frame
K.Menu = {}

---@param _ unknown
---@param command Komand.DB.Command
local function executeCommand(_, command)
    K.Menu:Hide()
    K.Command.Execute(command)
end

---@param node Komand.CommandNode
---@param isHeader boolean
---@return W.DropDownMenuButtonInfo
local function createButton(node, isHeader)
    local info = {}

    local command = node.command
    info.func = executeCommand
    info.arg1 = command
    info.value = command.id

    info.notCheckable = true
    info.isTitle = false
    info.hasArrow = not isHeader and getn(node.children) > 0
    info.colorCode = K.Utils.ColorCode(command.color)
    info.text = command.name
    info.tooltipTitle = command.name
    info.tooltipText = command.value

    return info
end

---@param _ unknown
---@param level integer
local function initializeMenu(_, level)
    if not level then
        return
    end

    local tree = K.Database.commandTree

    local parentNode = UIDROPDOWNMENU_MENU_VALUE and tree.nodes[UIDROPDOWNMENU_MENU_VALUE]
    if level == 1 and parentNode then
        UIDropDownMenu_AddButton(createButton(parentNode, true), level)
    end

    local nodes = parentNode and parentNode.children or tree.rootNodes
    for _, node in pairs(nodes) do
        if node.command.enabled then
            UIDropDownMenu_AddButton(createButton(node, false), level)
        end
    end
end

---@return W.Frame
local function createFrame()
    local frame = CreateFrame("Frame", K.Addon.name .. "Menu", UIParent, "UIDropDownMenuTemplate")
    frame.displayMode = "MENU"
    frame.initialize = initializeMenu
    return frame
end

function K.Menu:Initialize()
    K.Database.db.RegisterCallback(self, "DataChanged", "OnDataChanged")
end

---@param query string?
function K.Menu:Show(query)
    local command = K.Database:FindCommand(query)
    local commandId = command and command.id or nil

    if not self.frame then
        self.frame = createFrame()
    end

    ToggleDropDownMenu(1, commandId, self.frame, "cursor", 0, 0)
end

function K.Menu:Hide()
    if UIDROPDOWNMENU_OPEN_MENU == self.frame then
        CloseDropDownMenus()
    end
end

---@param ... any
function K.Menu:OnDataChanged(...)
    self:Hide()
end
