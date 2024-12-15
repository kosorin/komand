local pairs, ipairs, unpack, tonumber, tostring = pairs, ipairs, unpack, tonumber, tostring
local table, string, math = table, string, math

---@type string, Komand
local KOMAND, K = ...

---@class Komand.Module.Menu : Komand.Module
---@field frame Frame
K.Menu = {}

---@param info unknown
local function cancelMenu(info)
    K.Menu:Hide()
end

---@param info unknown
---@param command Komand.Command
local function executeCommand(info, command)
    K.Menu:Hide()
    K.Command:Execute(command)
end

---@param node Komand.Command.Node
---@param level integer
local function addMenuItem(node, level)
    local command = node.command

    if command.type == "macro" or command.type == "lua" then
        local info = UIDropDownMenu_CreateInfo()

        info.func = executeCommand
        info.arg1 = command
        info.value = command.id

        info.notCheckable = true
        info.isTitle = false
        info.hasArrow = #node.children > 0
        info.colorCode = K.Utils.ColorCode(command.color)
        info.text = command.name
        info.tooltipTitle = command.name
        info.tooltipText = command.script

        UIDropDownMenu_AddButton(info, level)
    elseif command.type == "separator" then
        UIDropDownMenu_AddSeparator(level)
    end
end

---@param level integer
local function addMenuSpace(level)
    UIDropDownMenu_AddSpace(level)
end

---@param level integer
local function addMenuSeparator(level)
    UIDropDownMenu_AddSeparator(level)
end

---@param level integer
local function addMenuCancel(level)
    local info = UIDropDownMenu_CreateInfo()

    info.func = cancelMenu
    info.text = "Cancel"
    info.notCheckable = true

    UIDropDownMenu_AddButton(info, level)
end

---@param frame unknown
---@param level integer
local function initializeMenu(frame, level)
    if not level then
        return
    end

    local parentCommandId = UIDROPDOWNMENU_MENU_VALUE
    local parenttNode = parentCommandId and K.Command.tree.nodes[parentCommandId]
    local nodes = parenttNode and parenttNode.children or K.Command.tree.rootNodes

    for _, node in pairs(nodes) do
        if not node.command.hide then
            addMenuItem(node, level)
        end
    end

    if level == 1 then
        if #nodes > 0 then
            addMenuSeparator(level)
        end
        addMenuCancel(level)
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
