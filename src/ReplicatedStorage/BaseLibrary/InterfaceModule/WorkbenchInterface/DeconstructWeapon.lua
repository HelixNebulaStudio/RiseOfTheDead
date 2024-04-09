local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Workbench = {};
local Interface = {};

local TweenService = game:GetService("TweenService");
local player = game.Players.LocalPlayer;

local modData = require(player:WaitForChild("DataModule"));
local modModsLibrary = require(game.ReplicatedStorage.Library:WaitForChild("ModsLibrary"));
local modWorkbenchLibrary = require(game.ReplicatedStorage.Library:WaitForChild("WorkbenchLibrary"));
local modBranchConfigs = require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("BranchConfigurations"));
local modItemLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modBlueprintLibrary = require(game.ReplicatedStorage.Library.BlueprintLibrary);
local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));

--== Remotes;
local remoteDeconstruct = modRemotesManager:Get("DeconstructItem");

local deconFrameTemplate = script:WaitForChild("DeconstructFrame");

function Workbench.new(itemId, library, storageItem)
	local itemLib = modItemLibrary:Find(itemId);
	local listMenu = Interface.List.create();
	listMenu.ContentList.ScrollingEnabled = false;
	listMenu.Menu.Name = "deconstructWeapon";
	listMenu:SetEnableScrollBar(false);
	listMenu:SetEnableSearchBar(false);
	
	local newDeconFrame = deconFrameTemplate:Clone();
	local titleLabel = newDeconFrame:WaitForChild("titleTag");
	titleLabel.Text = "Deconstruct "..itemLib.Name;
	
	local buttonFrame = newDeconFrame:WaitForChild("ButtonFrame");
	local outcomeList = buttonFrame:WaitForChild("OutcomeFrame"):WaitForChild("List");
	local deconstructButton = buttonFrame:WaitForChild("DeconstructButton");
	
	local rewardLabels = outcomeList:GetChildren();
	for a=#rewardLabels, 1, -1 do if not rewardLabels[a]:IsA("TextLabel") then table.remove(rewardLabels, a) end; end;
	
	local levels = storageItem.Values and storageItem.Values.L or 0;
	local rTier = math.floor(levels/5);
	
	for a=1, #rewardLabels do
		rewardLabels[a].TextColor3 = rTier > rewardLabels[a].LayoutOrder and Color3.fromRGB(147, 255, 135) or Color3.fromRGB(255, 108, 103);
	end
	
	deconstructButton.Visible = levels >= 5;
	local actionButtonDebounce = false;
	deconstructButton.MouseButton1Click:Connect(function()
		if actionButtonDebounce then return end;
		actionButtonDebounce = true;
		Interface:PlayButtonClick();
		deconstructButton.Text = "Starting to deconstruct...";
		local serverReply = remoteDeconstruct:InvokeServer(Interface.Object, 1, storageItem.ID);
		if serverReply == modWorkbenchLibrary.DeconstructModReplies.Success then
			Interface.ClearSelection();
		else
			deconstructButton.Text = modWorkbenchLibrary.DeconstructModReplies[serverReply] or ("Error Code: "..serverReply);
		end
		wait(1);
		deconstructButton.Text = "Deconstruct";
		actionButtonDebounce = false;
	end)
	
	listMenu:Add(newDeconFrame);
	return listMenu;
end

function Workbench.init(interface)
	Interface = interface;
	return Workbench;
end

return Workbench;
