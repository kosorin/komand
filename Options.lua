local KOMAND, Core = ...

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")

function AceConfigDialog:Break(order)
    return {
        name = "",
        order = order,
        width = "full",
        type = "description",
    }
end

function AceConfigDialog:Header(name, order)
    return {
        name = "\n\n|cffffcc00" .. name,
        order = order,
        width = "full",
        type = "description",
    }
end

local Options = {}
Core.Options = Options

local function selectCommandNode(commandId)
    local node = commandId and Core.Database.commandTree.nodes[commandId] or Core.Database.commandTree.rootNode
    AceConfigDialog:SelectGroup(KOMAND, unpack(node.path))
end

function Options:Open()
    AceConfigDialog:Open(KOMAND)
    selectCommandNode(Core.Database.rootCommandId)
end

function Options:Close()
    AceConfigDialog:Close(KOMAND)
end

function Options:OnAddItem(node)
    local command = Core.Database:AddCommand(node.command.id)
    selectCommandNode(command.id)
end

function Options:OnRemoveItem(node)
    Core.Database:RemoveCommand(node.command.id)
    selectCommandNode(node.command.parentId)
end

function Options:OnExecuteItem(commandId)
    local command = Core.Database.db.profile.commands[commandId]
    Core.Execute(command.value)
end


function Options:BuildOptions()
    self.options = {
        type = "group",
        childGroups = "tree",
        args = {},
    }

    -- Command line
    self.options.args.show = {
        name = "Show",
        order = 0,
        guiHidden = true,
        type = "input",
        set = function(info, value)
            Core.Menu:Show(value)
        end
    }
    self.options.args.options = {
        name = "Options",
        order = 1,
        guiHidden = true,
        type = "execute",
        func = function(info)
            self:Open()
        end
    }

    -- GUI
    self.options.args.general = self:BuildGeneralOptions(100)
    self.options.args.profiles = self:BuildProfilesOptions(200)
end

function Options:BuildGeneralOptions(order)
    return {
        name = "General",
        order = order,
        cmdHidden = true,
        type = "group",
        args = {},
    }
end

function Options:BuildProfilesOptions(order)
    local node =  AceDBOptions:GetOptionsTable(Core.Database.db, true)
    node.order = order
    return node
end

local function argDisabled_command_rootCommand(info)
    local commandId = info[#info - 2]
    return commandId == Core.Database.rootCommandId
end

local function argGet_command(info)
    local commandId = info[#info - 2]
    local property = info[#info]
    if info.type == "color" then
        local color = Core.Database.db.profile.commands[commandId][property]
        return unpack(color ~= nil and color or {})
    else
        return Core.Database.db.profile.commands[commandId][property]
    end
end

local function argSet_command(info, value, ...)
    local commandId = info[#info - 2]
    local property = info[#info]
    if info.type == "color" then
        Core.Database.db.profile.commands[commandId][property] = {value, ...}
    else
        Core.Database.db.profile.commands[commandId][property] = value
    end
    Core.Database:FireDataChanged("SetProperty", property)
end

local function argGet_command_parentId(info)
    return argGet_command(info)
end

local function argSet_command_parentId(info, value, ...)
    local commandId = info[#info - 2]
    argSet_command(info, value, ...)
    selectCommandNode(commandId)
end

local function traverseComandTree_parentId(node, excludeCommandId, func)
    if node.command.id == excludeCommandId then
        return
    end
    func(node)
    for _, childNode in pairs(node.children) do
        traverseComandTree_parentId(childNode, excludeCommandId, func)
    end
end

local function argValues_command_parentId(info)
    local commandId = info[#info - 2]

    local values = {}
    traverseComandTree_parentId(Core.Database.commandTree.rootNode, commandId, function(node)
        values[node.command.id] = ("   "):rep(#node.path - 1) .. node.command.name
    end)

    return values
end

local function argSorting_command_parentId(info)
    local commandId = info[#info - 2]
    
    local sorting = {}
    traverseComandTree_parentId(Core.Database.commandTree.rootNode, commandId, function(node)
        table.insert(sorting, node.command.id)
    end)

    return sorting
end

function Options:BuildCommand(node, order)
    local command = node.command

    local arg = {
        name = command.name,
        order = order,
        cmdHidden = true,
        type = "group",
        childGroups = "tree",
        args = {
            command = {
                name = "Command",
                order = 10,
                type = "group",
                inline = true,
                args = {
                    name = {
                        name = "Name",
                        order = 10,
                        width = "normal",
                        type = "input",
                        get = argGet_command,
                        set = argSet_command,
                    },
                    remove = {
                        disabled = argDisabled_command_rootCommand,
                        name = "Remove Command",
                        order = 11,
                        width = "normal",
                        type = "execute",
                        confirm = true,
                        confirmText = ("Remove '|cffff0000%s|r' command?\nThis will remove all children."):format(command.name),
                        func = function(info)
                            self:OnRemoveItem(node)
                        end,
                    },
                    settings = AceConfigDialog:Header("Settings", 20),
                    pinned = {
                        disabled = argDisabled_command_rootCommand,
                        name = "Pinned",
                        order = 25,
                        width = 0.75,
                        type = "toggle",
                        get = argGet_command,
                        set = argSet_command,
                    },
                    color = {
                        name = "Color",
                        order = 26,
                        width = 0.75,
                        type = "color",
                        hasAlpha = false,
                        get = argGet_command,
                        set = argSet_command,
                    },
                    br50 = AceConfigDialog:Break(50),
                    parentId = {
                        disabled = argDisabled_command_rootCommand,
                        name = "Parent",
                        order = 52,
                        width = "double",
                        type = "select",
                        style = "dropdown",
                        values = argValues_command_parentId,
                        sorting = argSorting_command_parentId,
                        get = argGet_command_parentId,
                        set = argSet_command_parentId,
                    },
                    br100 = AceConfigDialog:Break(100),
                    value = {
                        name = "Command",
                        order = 101,
                        width = 1.5,
                        type = "input",
                        get = argGet_command,
                        set = argSet_command,
                    },
                    execute = {
                        name = "Execute",
                        order = 102,
                        width = 0.5,
                        type = "execute",
                        func = function(info)
                            self:OnExecuteItem(command.id)
                        end,
                    },
                    br1000 = AceConfigDialog:Break(1000),
                },
            },
            children = {
                name = "Commands",
                order = 20,
                type = "group",
                inline = true,
                args = {
                    add = {
                        name = "Add Command",
                        order = 10,
                        width = "double",
                        type = "execute",
                        func = function(info)
                            self:OnAddItem(node)
                        end,
                    },
                }
            },
        }
    }

    for order, childNode in pairs(node.children) do
        arg.args[childNode.command.id] = self:BuildCommand(childNode, order)
    end

    return arg
end

function Options:UpdateOptions()
    self.options.args[Core.Database.rootCommandId] = self:BuildCommand(Core.Database.commandTree.rootNode, 150)
end

function Options:Build()
    if self.options == nil then
        Core.Database:FireDataChanged("BuildOptions")
        self:BuildOptions()
    end
    self:UpdateOptions()
    return self.options
end

function Options:Initialize()
    self:Build()
    AceConfig:RegisterOptionsTable(KOMAND, function() return self:Build() end, {"k", "kmd", "komand"})
    AceConfigDialog:SetDefaultSize(KOMAND, 600, 600)
end
