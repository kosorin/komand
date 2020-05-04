local KOMAND, Core = ...

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
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

local selectCommand

function Options:Open()
    AceConfigDialog:Open(KOMAND)
    selectCommand(Core.Database.rootCommandId)
end

function Options:Close()
    AceConfigDialog:Close(KOMAND)
end


function Options:BuildOptions()
    self.options = {
        type = "group",
        childGroups = "tab",
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
    self.options.args.commands = self:BuildGeneralCommands(200)
    self.options.args.profiles = self:BuildProfilesOptions(300)
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

function Options:BuildGeneralCommands(order)
    return {
        name = "Commands",
        order = order,
        cmdHidden = true,
        type = "group",
        args = {
            add = {
                name = "Add Command",
                order = 0,
                type = "execute",
                handler = self,
                func = "OnAddCommand",
            },
            -- order 100 reserved for command tree
        },
    }
end

function Options:BuildProfilesOptions(order)
    local node =  AceDBOptions:GetOptionsTable(Core.Database.db, true)
    node.order = order
    return node
end


function selectCommand(commandId)
    local node = commandId and Core.Database.commandTree.nodes[commandId] or Core.Database.commandTree.rootNode
    AceConfigDialog:SelectGroup(KOMAND, "commands", unpack(node.path))
end

local function getCommand(info)
    local commandId = info[#info - 2]
    local property = info[#info]
    if info.type == "color" then
        local color = Core.Database.db.profile.commands[commandId][property]
        return unpack(color ~= nil and color or {})
    else
        return Core.Database.db.profile.commands[commandId][property]
    end
end

local function setCommand(info, value, ...)
    local commandId = info[#info - 2]
    local property = info[#info]
    if info.type == "color" then
        Core.Database.db.profile.commands[commandId][property] = {value, ...}
    else
        Core.Database.db.profile.commands[commandId][property] = value
    end
    Core.Database:FireDataChanged("SetProperty", property)
end

local function disabledCommand_rootCommand(info)
    local commandId = info[#info - 2]
    return commandId == Core.Database.rootCommandId
end

local function getCommand_parentId(info)
    return getCommand(info)
end

local function setCommand_parentId(info, value, ...)
    local commandId = info[#info - 2]
    setCommand(info, value, ...)
    selectCommand(commandId)
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

local function valuesCommand_parentId(info)
    local commandId = info[#info - 2]

    local values = {}
    traverseComandTree_parentId(Core.Database.commandTree.rootNode, commandId, function(node)
        values[node.command.id] = ("   "):rep(#node.path - 1) .. node.command.name
    end)

    return values
end

local function sortingCommand_parentId(info)
    local commandId = info[#info - 2]
    
    local sorting = {}
    traverseComandTree_parentId(Core.Database.commandTree.rootNode, commandId, function(node)
        table.insert(sorting, node.command.id)
    end)

    return sorting
end

function Options:OnAddCommand(info)
    local command = Core.Database:AddCommand(self.lastCommandId)
    selectCommand(command.id)
end

function Options:OnRemoveCommand(info)
    local commandId = info.arg.command.id
    local command = Core.Database:RemoveCommand(commandId)
    selectCommand(command.parentId)
end

function Options:OnExecuteCommand(info)
    local commandId = info.arg.command.id
    local command = Core.Database.db.profile.commands[commandId]
    Core.Execute(command.value)
end

function Options:OnCommandNodeChanged(info)
    local command = info.arg.command

    self.lastCommandId = command.id
    
    return true
end

function Options:BuildCommand(node, order)
    local command = node.command

    local arg = {
        name = command.name,
        order = order,
        type = "group",
        childGroups = "tree",
        args = {
            selector = {
                name = "You can't see this",
                order = 0,
                handler = self,
                arg = node,
                hidden = "OnCommandNodeChanged",
                type = "input",
            },
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
                        handler = self,
                        arg = node,
                        get = getCommand,
                        set = setCommand,
                    },
                    remove = {
                        disabled = disabledCommand_rootCommand,
                        name = "Remove Command",
                        order = 15,
                        width = "normal",
                        type = "execute",
                        confirm = true,
                        confirmText = ("Remove '|cffff0000%s|r' command?\nThis will remove all children."):format(command.name),
                        handler = self,
                        arg = node,
                        func = "OnRemoveCommand",
                    },
                    settings = AceConfigDialog:Header("Settings", 20),
                    pinned = {
                        disabled = disabledCommand_rootCommand,
                        name = "Pinned",
                        order = 25,
                        width = 0.75,
                        type = "toggle",
                        handler = self,
                        arg = node,
                        get = getCommand,
                        set = setCommand,
                    },
                    color = {
                        name = "Color",
                        order = 26,
                        width = 0.75,
                        type = "color",
                        hasAlpha = false,
                        handler = self,
                        arg = node,
                        get = getCommand,
                        set = setCommand,
                    },
                    br50 = AceConfigDialog:Break(50),
                    parentId = {
                        disabled = disabledCommand_rootCommand,
                        name = "Parent",
                        order = 52,
                        width = "double",
                        type = "select",
                        style = "dropdown",
                        handler = self,
                        arg = node,
                        values = valuesCommand_parentId,
                        sorting = sortingCommand_parentId,
                        get = getCommand_parentId,
                        set = setCommand_parentId,
                    },
                    br100 = AceConfigDialog:Break(100),
                    value = {
                        name = "Command",
                        order = 101,
                        width = 1.5,
                        type = "input",
                        handler = self,
                        arg = node,
                        get = getCommand,
                        set = setCommand,
                    },
                    execute = {
                        name = "Execute",
                        order = 102,
                        width = 0.5,
                        type = "execute",
                        handler = self,
                        arg = node,
                        func = "OnExecuteCommand",
                    },
                    br1000 = AceConfigDialog:Break(1000),
                },
            },
        }
    }

    for order, childNode in pairs(node.children) do
        arg.args[childNode.command.id] = self:BuildCommand(childNode, order)
    end

    return arg
end

function Options:UpdateOptions()
    self.options.args.commands.args[Core.Database.rootCommandId] = self:BuildCommand(Core.Database.commandTree.rootNode, 100)
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
    AceConfigDialog:SetDefaultSize(KOMAND, 615, 550)
end
