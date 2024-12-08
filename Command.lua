---@type string, Komand
local KOMAND, K = ...

---@class Komand.Command
K.Command = {}

---@param a Komand.DB.Command
---@param b Komand.DB.Command
---@return boolean
function K.Command.Comparer(a, b)
    local aa, bb

    aa = a.order or 0
    bb = b.order or 0
    if aa ~= bb then
        return aa < bb
    end

    aa = a.name:upper()
    bb = b.name:upper()
    if aa ~= bb then
        return aa < bb
    end

    return aa < bb
end

---@param command Komand.DB.Command
function K.Command.Execute(command)
    local editBox = DEFAULT_CHAT_FRAME.editBox
    editBox:SetText(command.value)
    ChatEdit_SendText(editBox)
end
