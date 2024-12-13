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

    if command.type == "button" then
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
        info.tooltipText = command.value

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
    local tree = K.Command.tree
    local parentNode = commandId and tree.nodes[commandId]
    local nodes = parentNode and parentNode.children or tree.rootNodes

    if parentNode and level == 1 then
        if parentNode.command.enabled then
            return
        end
        addMenuItem(parentNode, true, level)
    end

    for _, node in pairs(nodes) do
        if node.command.enabled then
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

---@param query string?
function K.Menu:Show(query)
    local command = K.Command:Find(query)
    local commandId = command and command.id or nil

    if not self.frame then
        self.frame = createFrame()
    end

    ToggleDropDownMenu(1, commandId, self.frame, "cursor", 0, 0)
end

function K.Menu:Hide()
    local currentFrame = UIDROPDOWNMENU_OPEN_MENU
    if currentFrame == self.frame then
        CloseDropDownMenus()
    end
end

function K.Menu:OnTreeChanged()
    self:Hide()
end
