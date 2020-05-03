local KOMAND, Core = ...

local Utils = {
    idPrefix = "ID-",
}
Core.Utils = Utils

function Utils.GenerateId(items)
    local random = math.random
    local template = Core.Utils.idPrefix .. "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    local function randomChar(c)
        local v = (c == "x") and random(0, 0xf) or random(8, 0xb)
        return ("%x"):format(v)
    end

    local id
    repeat
        id = template:gsub("[xy]", randomChar)
    until items == nil or items[id] == nil or items[id].id == nil

    return id
end

function Utils.Sort(items, comparer)
    local result = {}
    local copy = Utils.ToList(items)
    table.sort(copy, comparer)
    for _, item in ipairs(copy) do
        table.insert(result, item)
    end
    return result
end

function Utils.Find(items, predicate)
    for key, item in pairs(items or {}) do
        if predicate(key, item) then
            return item
        end
    end
    return nil
end

function Utils.FindByName(items, name)
    if (name or ""):match("^%s*$") then
        return nil
    end
    return Core.Utils.Find(items, function(_, item)
        local function normalize(name)
            return name:gsub("%s+", ""):upper()
        end
        local findName = normalize(name)
        local itemName = normalize(item.name)
        return itemName:match(findName)
    end)
end

function Utils.Where(items, filter, removeKeys)
    local result = {}
    for key, item in pairs(items or {}) do
        if filter(key, item) then
            if removeKeys then
                table.insert(result, item)
            else
                result[key] = item
            end
        end
    end
    return result
end

function Utils.Select(items, selector, removeKeys)
    local result = {}
    for key, item in pairs(items or {}) do
        local value = selector(key, item)
        if removeKeys then
            table.insert(result, value)
        else
            result[key] = value
        end
    end
    return result
end

function Utils.ToList(items)
    local result = {}
    for _, item in pairs(items) do
        table.insert(result, item)
    end
    return result
end

---@param color table RGB[A] (range 0..1)
function Utils.ToColorCode(color)
    local max = 255
    local values = Core.Utils.Select(color, function(_, x)
        return x * max
    end)
    return ("|c%02x%02x%02x%02x"):format(values[4] or max, unpack(values, 1, 3))
end
