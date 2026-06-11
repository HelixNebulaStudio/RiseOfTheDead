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
		titleLabel.Text = `Deconstruct {library.Name}`;
		
		local buttonFrame = newDeconFrame:WaitForChild("ButtonFrame");
		local outcomeList = buttonFrame:WaitForChild("OutcomeFrame"):WaitForChild("List");
		local outcomeItem = outcomeList:WaitForChild("Item");
		local deconstructButton = buttonFrame:WaitForChild("DeconstructButton");
		
		function listMenu:Refresh()
			local isMaxed = false;
			perks, isMaxed = modWorkbenchLibrary.CalculatePerksSpent(storageItem, library, binds.IsPremium);
			
			local outcomeList = {};

			table.insert(outcomeList, `<font color="{perks > 0 and "#93ff87" or "#ff6c67"}">• {perks} Perks</font>`);
			table.insert(outcomeList, `<font color="{isMaxed and "#93ff87" or "#ff6c67"}">• 3 Tweak Points</font>`);

			outcomeItem.Text = table.concat(outcomeList, "\n");
			outcomeItem.TextColor3 = Color3.fromRGB(255, 255, 255);
			
		end
		listMenu:Refresh();
		
		local actionButtonDebounce = false;
		deconstructButton.MouseButton1Click:Connect(function()
			if actionButtonDebounce then return end;
			actionButtonDebounce = true;
			interface:PlayButtonClick();
			deconstructButton.Text = "Starting to deconstruct...";
			local serverReply = remoteDeconstruct:InvokeServer(binds.InteractPart, 1, storageItem.ID);
			if serverReply == modWorkbenchLibrary.DeconstructModReplies.Success then
				binds.ClearSelection();
			else
				deconstructButton.Text = modWorkbenchLibrary.DeconstructModReplies[serverReply] or ("Error Code: "..serverReply);
			end
			task.wait(1);
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