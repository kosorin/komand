---@meta

---@class W.Library
---@field [any] unknown

---@class W.DataBrokerObject
---@field [any] unknown

---@class W.Frame
---@field [any] unknown

---@param t table
---@return integer
function getn(t) end

---@param name string
---@return unknown
function LibStub(name) end

---@type W.Frame
UIParent = nil

---@type W.Frame
DEFAULT_CHAT_FRAME = nil

---@type W.Frame
UIDROPDOWNMENU_OPEN_MENU = nil

---@type any
UIDROPDOWNMENU_MENU_VALUE = nil

---@class W.DropDownMenuButtonInfo

---@param info W.DropDownMenuButtonInfo
---@param level integer
---@return unknown
function UIDropDownMenu_AddButton(info, level) end

---@param type string
---@param name string?
---@param parent W.Frame?
---@param template string?
---@param id integer?
---@return W.Frame
function CreateFrame(type, name, parent, template, id) end

---@param level integer
---@param value any
---@param frame W.Frame
---@param anchor string
---@param xOffset number
---@param yOffset number
function ToggleDropDownMenu(level, value, frame, anchor, xOffset, yOffset) end

---@param editBox unknown
function ChatEdit_SendText(editBox) end

function CloseDropDownMenus() end
