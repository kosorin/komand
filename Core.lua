local KOMAND, Core = ...

--> Globals
_G.Komand = Core

--> Libraries
local AceAddon = LibStub("AceAddon-3.0")
local AceConsole = LibStub("AceConsole-3.0")

--> Modules
Core.App = AceAddon:NewAddon(KOMAND)
Core.Console = {}
Core.Command = {}
Core.Database = {}
Core.Options = {}
Core.Menu = {}
Core.Utils = {}

--> Locals
local App = Core.App
local Console = Core.Console
local Command = Core.Command
local Database = Core.Database
local Options = Core.Options
local Menu = Core.Menu
local Utils = Core.Utils

--> Initialize
Core.name = Core.App.name
Core.slash = {"komand", "kmd", "k"} -- keep order

-------------------------------------------------------------------------------
--> App
-------------------------------------------------------------------------------

--> Functions

function App:OnInitialize()
    Database:Initialize()
    Options:Initialize()
end

function App:OnEnable()
end

function App:OnDisable()
end

-------------------------------------------------------------------------------
--> Console
-------------------------------------------------------------------------------

--> Static functions

function Console.Print(...)
    AceConsole.Print(Core.name, ...)
end

function Console.Debug(...)
    AceConsole.Print(Core.name, "|cffa0a0a0", ...)
end

-------------------------------------------------------------------------------
--> Command
-------------------------------------------------------------------------------

--> Static functions

function Command.Execute(value)
    Menu:Hide()

    local editBox = DEFAULT_CHAT_FRAME.editBox
    editBox:SetText(value)
    ChatEdit_SendText(editBox)
end
