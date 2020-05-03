local KOMAND, Core = ...
_G.Komand = Core

local AceConsole = LibStub("AceConsole-3.0")

function Core.Execute(commandValue)
    Core.Menu:Hide()

    local editBox = DEFAULT_CHAT_FRAME.editBox
    editBox:SetText(commandValue)
    ChatEdit_SendText(editBox)
end

function Core.Print(...)
    AceConsole.Print(KOMAND, ...)
end

function Core.Debug(...)
    AceConsole.Print(KOMAND, "|cffa0a0a0", ...)
end
