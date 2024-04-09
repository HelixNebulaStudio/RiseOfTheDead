--	// FileName: ChatSettings.lua
--	// Written by: Xsitsu
--	// Description: Settings module for configuring different aspects of the chat window.

local PlayersService = game:GetService("Players");

local clientChatModules = script.Parent
local ChatConstants = require(clientChatModules:WaitForChild("ChatConstants"));

local module = {}

-- Updated

---[[ Chat Behaviour Settings ]]
module.WindowDraggable = false
module.WindowResizable = false;
module.ShowChannelsBar = false
module.GamepadNavigationEnabled = false
module.ShowUserOwnFilteredMessage = true	--Show a user the filtered version of their message rather than the original.
-- Make the chat work when the top bar is off
module.ChatOnWithTopBarOff = true
module.ScreenGuiDisplayOrder = 4 -- The DisplayOrder value for the ScreenGui containing the chat.

module.ShowFriendJoinNotification = false -- Show a notification in the chat when a players friend joins the game.

--- Replace with true/false to force the chat type. Otherwise this will default to the setting on the website.
module.BubbleChatEnabled = true
module.ClassicChatEnabled = true

---[[ Chat Text Size Settings ]]
module.ChatWindowTextSize = 15
module.ChatChannelsTabTextSize = 16
module.ChatBarTextSize = 12
module.ChatWindowTextSizePhone = 12
module.ChatChannelsTabTextSizePhone = 16
module.ChatBarTextSizePhone = 12

---[[ Font Settings ]]
module.DefaultFont = Enum.Font.Arial
module.ChatBarFont = Enum.Font.Arial

----[[ Color Settings ]]
module.BackGroundColor = Color3.new(0, 0, 0)
module.DefaultMessageColor = Color3.new(1, 1, 1)
module.DefaultNameColor = Color3.new(1, 1, 1)
module.ChatBarBackGroundColor = Color3.new(0, 0, 0)
module.ChatBarBoxColor = Color3.new(0, 0, 0)
module.ChatBarTextColor = Color3.new(1, 1, 1)
module.ChannelsTabUnselectedColor = Color3.new(0, 0, 0)
module.ChannelsTabSelectedColor = Color3.new(30/255, 30/255, 30/255)
module.DefaultChannelNameColor = Color3.fromRGB(35, 76, 142)
module.WhisperChannelNameColor = Color3.fromRGB(102, 14, 102)
module.ErrorMessageTextColor = Color3.fromRGB(245, 50, 50)

---[[ Window Settings ]]
module.MinimumWindowSize = UDim2.new(0.26, 0, 0.23, 0)
module.MaximumWindowSize = UDim2.new(0.26, 0, 0.25, 0) -- if you change this to be greater than full screen size, weird things start to happen with size/position bounds checking.
module.DefaultWindowPosition = UDim2.new(0, 0, 1, 0);
local extraOffset = 24--(7 * 2) + (5 * 2) -- Extra chatbar vertical offset
module.DefaultWindowSizePhone = UDim2.new(0.26, 0, 0.23, extraOffset)
module.DefaultWindowSizeTablet = UDim2.new(0.26, 0, 0.23, extraOffset)
module.DefaultWindowSizeDesktop = UDim2.new(0.26, 0, 0.23, extraOffset)

---[[ Fade Out and In Settings ]]
module.ChatWindowBackgroundFadeOutTime = 0.2; --Chat background will fade out after this many seconds.
module.ChatWindowTextFadeOutTime = 12				--Chat text will fade out after this many seconds.
module.ChatDefaultFadeDuration = 2
module.ChatShouldFadeInFromNewInformation = false;
module.ChatAnimationFPS = 30.0;

---[[ Channel Settings ]]
module.GeneralChannelName = "All" --"Server" -- You can set to nil to turn off echoing to a general channel.
module.EchoMessagesInGeneralChannel = true -- Should messages to channels other than general be echoed into the general channel.
--Setting this to false should be used with ShowChannelsBar
module.ChannelsBarFullTabSize = 4 -- number of tabs in bar before it starts to scroll
module.MaxChannelNameLength = 12
--// Although this feature is pretty much ready, it needs some UI design still.
module.RightClickToLeaveChannelEnabled = false
module.MessageHistoryLengthPerChannel = 50
-- Show the help text for joining and leaving channels. This is not useful unless custom channels have been added.
-- So it is turned off by default.
module.ShowJoinAndLeaveHelpText = false

---[[ Message Settings ]]
module.MaximumMessageLength = 200
module.DisallowedWhiteSpace = {"\n", "\r", "\t", "\v", "\f"}
module.ClickOnPlayerNameToWhisper = true
module.ClickOnChannelNameToSetMainChannel = true
module.BubbleChatMessageTypes = {ChatConstants.MessageTypeDefault, ChatConstants.MessageTypeWhisper}

---[[ Misc Settings ]]
module.WhisperCommandAutoCompletePlayerNames = true

local ChangedEvent = Instance.new("BindableEvent")

local proxyTable = setmetatable({},
{
	__index = function(tbl, index)
		return module[index]
	end,
	__newindex = function(tbl, index, value)
		module[index] = value
		--ChangedEvent:Fire(index, value)
	end,
})

rawset(proxyTable, "SettingsChanged", ChangedEvent.Event)

return proxyTable
