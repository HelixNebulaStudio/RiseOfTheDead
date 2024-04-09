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
	local listMenu = Interface.List.create();
	listMenu.Menu.Name = "deconstructMod";
	listMenu.ContentList.ScrollingEnabled = false;
	listMenu:SetEnableScrollBar(false);
	listMenu:SetEnableSearchBar(false);
	
	local upgrades = library.Upgrades;
	local perks = 0;
	
	
	local newDeconFrame = deconFrameTemplate:Clone();
	local titleLabel = newDeconFrame:WaitForChild("titleTag");
	titleLabel.Text = "Deconstruct "..library.Name;
	
	local buttonFrame = newDeconFrame:WaitForChild("ButtonFrame");
	local outcomeList = buttonFrame:WaitForChild("OutcomeFrame"):WaitForChild("List");
	local outcomeItem = outcomeList:WaitForChild("Item");
	local outcomeLayout = outcomeList:WaitForChild("UIListLayout");
	local deconstructButton = buttonFrame:WaitForChild("DeconstructButton");
	
	function listMenu:Refresh()
		perks = modWorkbenchLibrary.CalculatePerksSpent(storageItem, library, Interface.IsPremium);
		outcomeItem.Text = ("• $p Perks"):gsub("$p", perks);
		outcomeItem.TextColor3 = perks > 0 and Color3.fromRGB(147, 255, 135) or Color3.fromRGB(255, 108, 103);
		
	end
	listMenu:Refresh();
	
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
	
	if perks <= 0 then
		listMenu:NewLabel("This mod is not worth deconstructing.");
	end
	
	return listMenu;
end

function Workbench.init(interface)
	Interface = interface;
	return Workbench;
end

return Workbench;