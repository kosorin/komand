local pairs, ipairs, unpack, tonumber, tostring = pairs, ipairs, unpack, tonumber, tostring
local table, string, math = table, string, math

---@type string, Komand
local KOMAND, K = ...

---@class Komand.Module.Menu : Komand.Module
---@field frame Frame
K.Menu = {}

---@param info unknown
---@param command Komand.Command
local function executeCommand(info, command)
    K.Menu:Hide()
    K.Command:Execute(command)
end

---@param node Komand.Command.Node
---@param isHeader boolean
---@param level integer
local function addMenuItem(node, isHeader, level)
    local command = node.command

    if command.type == "macro" or command.type == "lua" then
        local info = UIDropDownMenu_CreateInfo()

        info.func = executeCommand
        info.arg1 = command
        info.value = command.id

        info.notCheckable = true
        info.isTitle = false
        info.hasArrow = not isHeader and getn(node.children) > 0
        info.colorCode = K.Utils.ColorCode(command.color)
        info.text = command.name
        info.tooltipTitle = command.name
        info.tooltipText = command.script

        UIDropDownMenu_AddButton(info, level)
    elseif command.type == "separator" then
        UIDropDownMenu_AddSeparator(level)
    end
end

---@param frame unknown
---@param level integer
local function initializeMenu(frame, level)
    if not level then
        return
    end

    local commandId = UIDROPDOWNMENU_MENU_VALUE

    local currentNode = commandId and K.Command.tree.nodes[commandId]
    if currentNode and level == 1 then
        if currentNode.command.hide then
            return
        end
        addMenuItem(currentNode, true, level)
    end

    local nodes = currentNode and currentNode.children or K.Command.tree.rootNodes
    for _, node in pairs(nodes) do
        if not node.command.hide then
            addMenuItem(node, false, level)
        end
    end
end

---@return Frame
local function createFrame()
    local frame = CreateFrame("Frame", K.addon.name .. "Menu", UIParent, "UIDropDownMenuTemplate")

    UIDropDownMenu_Initialize(frame, initializeMenu, "MENU")

    return frame --[[@as Frame]]
end

function K.Menu:Initialize()
    K.Command.RegisterCallback(self, "OnTreeChanged", "OnTreeChanged")
end

---@param command Komand.Command?
function K.Menu:Show(command)
    if not self.frame then
        self.frame = createFrame()
    end

    ToggleDropDownMenu(1, command and command.id, self.frame, "cursor", 0, 0)
end

function K.Menu:Hide()
    if self.frame == UIDROPDOWNMENU_OPEN_MENU then
        CloseDropDownMenus()
    end
end

---@private
function K.Menu:OnTreeChanged()
    self:Hide()
end
