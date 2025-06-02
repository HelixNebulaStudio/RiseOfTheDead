local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local localPlayer = game.Players.LocalPlayer;

local modWorkbenchLibrary = shared.require(game.ReplicatedStorage.Library:WaitForChild("WorkbenchLibrary"));
local modRemotesManager = shared.require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));

local WorkbenchClass = {};
--==

function WorkbenchClass.init(interface: InterfaceInstance, workbenchWindow: InterfaceWindow)
	local modData = shared.require(localPlayer:WaitForChild("DataModule"));

	local binds = workbenchWindow.Binds;
		
	local remoteDeconstruct = modRemotesManager:Get("DeconstructItem");
	local deconFrameTemplate = script:WaitForChild("DeconstructFrame");

	function WorkbenchClass.new(itemId, library, storageItem)
		local listMenu = binds.List.create();
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
			perks = modWorkbenchLibrary.CalculatePerksSpent(storageItem, library, binds.IsPremium);
			outcomeItem.Text = ("• $p Perks"):gsub("$p", perks);
			outcomeItem.TextColor3 = perks > 0 and Color3.fromRGB(147, 255, 135) or Color3.fromRGB(255, 108, 103);
			
		end
		listMenu:Refresh();
		
		local actionButtonDebounce = false;
		deconstructButton.MouseButton1Click:Connect(function()
			if actionButtonDebounce then return end;
			actionButtonDebounce = true;
			interface:PlayButtonClick();
			deconstructButton.Text = "Starting to deconstruct...";
			local serverReply = remoteDeconstruct:InvokeServer(binds.InteractObject, 1, storageItem.ID);
			if serverReply == modWorkbenchLibrary.DeconstructModReplies.Success then
				binds.ClearSelection();
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


	return WorkbenchClass
end

return WorkbenchClass;