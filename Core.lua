local KOMAND, Core = ...
_G.Komand = Core

function Core.Execute(command)
    Core.Menu:Hide()

    local editBox = DEFAULT_CHAT_FRAME.editBox
    editBox:SetText(command)
    ChatEdit_SendText(editBox)
end

function Core.GroupComparer(a, b)
    local aa, bb

    aa = a.name:upper()
    bb = b.name:upper()
    if aa ~= bb then
        return aa < bb
    end

    return aa < bb
end

function Core.ItemComparer(a, b)
    local aa, bb

    bb = (a ~= nil and a.pinned and 1 or 0)
    aa = (b ~= nil and b.pinned and 1 or 0)
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

function Core.ItemNameComparer(a, b)
    local aa, bb

    aa = a.name:upper()
    bb = b.name:upper()
    if aa ~= bb then
        return aa < bb
    end

    return aa < bb
end
