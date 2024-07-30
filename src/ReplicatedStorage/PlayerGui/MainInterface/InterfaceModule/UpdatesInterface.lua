local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface = {};

local SoundService = game:GetService("SoundService");
local RunService = game:GetService("RunService");
local TextService = game:GetService("TextService");

local localplayer = game.Players.LocalPlayer;
local modData = require(localplayer:WaitForChild("DataModule"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modMarkupFormatter = require(game.ReplicatedStorage.Library.MarkupFormatter);


local remoteApiRequest = modRemotesManager:Get("ApiRequest");
local remoteGeneralUIRemote = modRemotesManager:Get("GeneralUIRemote");

local updateFrame = script.Parent.Parent:WaitForChild("UpdatesMenu");
local titleLabel = updateFrame:WaitForChild("TitleFrame"):WaitForChild("Title");
local textLabel = updateFrame:WaitForChild("Frame"):WaitForChild("notes"):WaitForChild("textLabel");

if modConfigurations.CompactInterface then
	updateFrame:WaitForChild("touchCloseButton").Visible = true;
	updateFrame:WaitForChild("touchCloseButton"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
		Interface:CloseWindow("UpdateWindow");
	end)
end

local versionStr = modGlobalVars.GameVersion.."."..modGlobalVars.GameBuild;
--== Script;
function Interface.init(modInterface)
	setmetatable(Interface, modInterface);
	
	titleLabel.Text = "Revived "..versionStr.." Update";
	
	local window = Interface.NewWindow("UpdateWindow", updateFrame);
	window:SetOpenClosePosition(UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, -1.5, 0));
	window.CompactFullscreen = true;
	
	if modConfigurations.CompactInterface then
		updateFrame:WaitForChild("UISizeConstraint"):Destroy();
	end
	window:AddCloseButton(updateFrame);
	
	window.OnWindowToggle:Connect(function(visible)
		if visible then
			Interface:HideAll{[window.Name]=true;};
			Interface.Update();
		else
			remoteGeneralUIRemote:InvokeServer("closeupdatelog");
		end
	end)
	
	return Interface;
end;

function Interface.Update()
	local updateLogText = remoteApiRequest:InvokeServer("updatelog") or "";
	Debugger:StudioWarn("updateLogText", updateLogText)
	local success, message = pcall(function()
		textLabel.Text = modMarkupFormatter.Format(updateLogText);
	end)
	if not success then
		Debugger:Warn("Failed to fetch update log:", message);
	end
end

return Interface;