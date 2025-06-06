local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local localPlayer = game.Players.LocalPlayer;

local modWorkbenchLibrary = shared.require(game.ReplicatedStorage.Library:WaitForChild("WorkbenchLibrary"));
local modItemLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));

local WorkbenchClass = {};
--==

function WorkbenchClass.init(interface: InterfaceInstance, workbenchWindow: InterfaceWindow)
	local modData = shared.require(localPlayer:WaitForChild("DataModule"));

	local binds = workbenchWindow.Binds;

	local remoteDeconstruct = modRemotesManager:Get("DeconstructItem");
	local deconFrameTemplate = script:WaitForChild("DeconstructFrame");

	function WorkbenchClass.new(itemId, library, storageItem)
		local itemLib = modItemLibrary:Find(itemId);
		local listMenu = binds.List.create();
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
			interface:PlayButtonClick();
			deconstructButton.Text = "Starting to deconstruct...";
			local serverReply = remoteDeconstruct:InvokeServer(binds.InteractPart, 1, storageItem.ID);
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
		return listMenu;
	end

	return WorkbenchClass;
end

return WorkbenchClass;