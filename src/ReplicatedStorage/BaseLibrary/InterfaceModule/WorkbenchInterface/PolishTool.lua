local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Workbench = {};
local Interface = {};

local TweenService = game:GetService("TweenService");
local player = game.Players.LocalPlayer;

local modData = require(player:WaitForChild("DataModule"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modWorkbenchLibrary = require(game.ReplicatedStorage.Library.WorkbenchLibrary);
local modItemLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modItemSkinWear = require(game.ReplicatedStorage.Library.ItemSkinWear);

--== Remotes;
local remotePolishTool = modRemotesManager:Get("PolishTool");

local polishFrameTemplate = script:WaitForChild("PolishFrame");


function Workbench.new(itemId, library, storageItem)
	local itemLib = modItemLibrary:Find(itemId);
	local listMenu = Interface.List.create();
	listMenu.ContentList.ScrollingEnabled = false;
	listMenu.Menu.Name = "polishTool";
	listMenu:SetEnableScrollBar(false);
	listMenu:SetEnableSearchBar(false);

	local ItemValues = storageItem.Values;
	
	local newFrame = polishFrameTemplate:Clone();
	local titleLabel = newFrame:WaitForChild("titleTag");
	titleLabel.Text = "Polish "..itemLib.Name;

	local buttonFrame = newFrame:WaitForChild("ButtonFrame");
	local startButton = buttonFrame:WaitForChild("StartButton");
	
	local descLabel = buttonFrame:WaitForChild("descTag");
	local rangeStr = modWorkbenchLibrary.PolishRangeBase.Min*100 .."-".. modWorkbenchLibrary.PolishRangeBase.Max*100;
	descLabel.Text = "Polishing a tool will give you a chance to improve the condition of the tool.\n\nThe amount of improvement may vary from "..rangeStr.."%."
	
	local outcomeList = buttonFrame:WaitForChild("OutcomeFrame"):WaitForChild("List");
	local perksLabel = outcomeList:WaitForChild("Item1");
	local lmpLabel = outcomeList:WaitForChild("Item2");
	local hourLabel = outcomeList:WaitForChild("Item3");

	local playerStats = modData.GameSave and modData.GameSave.Stats;
	
	local polishCost = modWorkbenchLibrary.PolishCost;
	if Interface.IsPremium then
		polishCost = modWorkbenchLibrary.PolishPremiumCost;
	end
	
	perksLabel.Text = "• Perks: ".. (playerStats.Perks or 0) .."/".. polishCost;
	perksLabel.TextColor3 = (playerStats.Perks or 0) >= polishCost and Color3.fromRGB(147, 255, 135) or Color3.fromRGB(255, 108, 103);
	
	local lmpCountOnChar = modData.CountItemIdFromCharacter("liquidmetalpolish");
	local lmpCountAll = modData.CountItemIdFromStorages("liquidmetalpolish");
	
	lmpLabel.Text = "• Liquid Metal Polish: ".. (lmpCountOnChar or 0) .."/1".. "(In Storage: ".. lmpCountAll .. ")";
	lmpLabel.TextColor3 = (lmpCountOnChar or 0) >= 1 and Color3.fromRGB(147, 255, 135) or Color3.fromRGB(255, 108, 103);
	
	local upgradeLib = modWorkbenchLibrary.ItemUpgrades[itemId];
	local hoursCost = upgradeLib and upgradeLib.Tier or 1
	hourLabel.Text = "• Time Cost: ".. (hoursCost > 1 and hoursCost .." Hours" or hoursCost .." Hour");
	hourLabel.TextColor3 = Color3.fromRGB(147, 255, 135);
	
	
	local actionButtonDebounce = false;
	startButton.MouseButton1Click:Connect(function()
		if actionButtonDebounce then return end;
		actionButtonDebounce = true;
		
		Interface:PlayButtonClick();
		startButton.Text = "Starting to polish...";
		
		local serverReply = remotePolishTool:InvokeServer(Interface.Object, 1, storageItem.ID);
		if serverReply == modWorkbenchLibrary.PolishToolReplies.Success then
			Interface.ClearSelection();
		else
			startButton.Text = modWorkbenchLibrary.PolishToolReplies[serverReply] or ("Error Code: "..serverReply);
		end
		wait(1);
		startButton.Text = "Polish";
		actionButtonDebounce = false;
	end)
	
	
	local wearLib = modItemSkinWear.GetWearLib(itemId);
	local toolFloat = modItemSkinWear.LoadFloat(itemId, ItemValues.SkinWearId).Float;
	
	if toolFloat < modWorkbenchLibrary.PolishLimit or toolFloat < wearLib.Wear.Min+modWorkbenchLibrary.PolishLimit then
		actionButtonDebounce = true;
		startButton.Text = "Polish limit reached";
	end

	listMenu:Add(newFrame);
	return listMenu;
end

function Workbench.init(interface)
	Interface = interface;
	return Workbench;
end

return Workbench;
