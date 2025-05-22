local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Workbench = {};
local Interface = {} :: any;

local modWorkbenchLibrary = shared.require(game.ReplicatedStorage.Library:WaitForChild("WorkbenchLibrary"));
local modRemotesManager = shared.require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));

--== Remotes;
local remoteDeconstruct = modRemotesManager:Get("DeconstructItem");

local deconFrameTemplate = script:WaitForChild("DeconstructFrame");

function Workbench.new(itemId, library, storageItem)
	local listMenu = Interface.List.create();
	listMenu.Menu.Name = "deconstructMod";
	listMenu.ContentList.ScrollingEnabled = false;
	listMenu:SetEnableScrollBar(false);
	listMenu:SetEnableSearchBar(false);
	
	local perks = 0;
	
	
	local newDeconFrame = deconFrameTemplate:Clone();
	local titleLabel = newDeconFrame:WaitForChild("titleTag");
	titleLabel.Text = "Deconstruct "..library.Name;
	
	local buttonFrame = newDeconFrame:WaitForChild("ButtonFrame");
	local outcomeList = buttonFrame:WaitForChild("OutcomeFrame"):WaitForChild("List");
	local outcomeItem = outcomeList:WaitForChild("Item");
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