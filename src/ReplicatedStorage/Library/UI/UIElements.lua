local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local UIElements = {};
UIElements.__index = UIElements;
UIElements.ElementCounter = 0;
--==

local UserInputService = game:GetService("UserInputService");
local HttpService = game:GetService("HttpService");
local CollectionService = game:GetService("CollectionService");

local localPlayer = game.Players.LocalPlayer;
local modData = require(localPlayer:WaitForChild("DataModule"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local modRadialImage = require(game.ReplicatedStorage.Library.UI.RadialImage);
local templateRadialButton = script:WaitForChild("radialButton");

local radialConfig = '{"version":1,"size":128,"count":128,"columns":8,"rows":8,"images":["rbxassetid://4467212179","rbxassetid://4467212459"]}';
UIElements.Color = modBranchConfigs.BranchColor
--==
function UIElements:Destroy()
	if self.ImageButton then
		game.Debris:AddItem(self.ImageButton, 0);
		self.ImageButton = nil;
	end
	if self.RadialObject then
		game.Debris:AddItem(self.RadialObject.label, 0);
		self.RadialObject = nil;
	end
end

function UIElements.newRadialButton()
	UIElements.ElementCounter = UIElements.ElementCounter +1;
	
	local self = {
		ImageButton = templateRadialButton:Clone();
		Id = UIElements.ElementCounter;
	};
	
	local radialBar = self.ImageButton:WaitForChild("radialBar");
	self.RadialObject = modRadialImage.new(radialConfig, radialBar);
	
	setmetatable(self, UIElements);
	return self;
end

return UIElements