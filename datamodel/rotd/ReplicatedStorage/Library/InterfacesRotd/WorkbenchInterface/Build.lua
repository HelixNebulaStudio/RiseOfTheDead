local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local localPlayer = game.Players.LocalPlayer;

local modWorkbenchLibrary = shared.require(game.ReplicatedStorage.Library:WaitForChild("WorkbenchLibrary"));
local modItemLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);

local WorkbenchClass = {};
--==

function WorkbenchClass.init(interface: InterfaceInstance, workbenchWindow: InterfaceWindow)
	local modData = shared.require(localPlayer:WaitForChild("DataModule"));

	local buildFrameTemplate = script:WaitForChild("BuildFrame");
	local remoteBlueprintHandler = modRemotesManager:Get("BlueprintHandler");

	local binds = workbenchWindow.Binds;
	function WorkbenchClass.new(itemId, library, storageItem)
		local listMenu = binds.List.create();
		listMenu:SetEnableScrollBar(false);
		listMenu:SetEnableSearchBar(false);
		
		local buildFrame = buildFrameTemplate:Clone();
		local buttonsMenu = buildFrame:WaitForChild("ButtonFrame");
		local buildButton = buttonsMenu:WaitForChild("BuildButton");
	
		local requirementsFrame = buttonsMenu:WaitForChild("RequirementsFrame");
		local requirementsListLayout = requirementsFrame:WaitForChild("UIListLayout");
		local itemListingTemplate = requirementsListLayout:WaitForChild("Item");
		local requireListFrame = requirementsFrame:WaitForChild("List");
		
		local createsFrame = buttonsMenu:WaitForChild("CreatesFrame");
		local createsListFrame = createsFrame:WaitForChild("List");
		
		local blueprintTagLabel = buildFrame:WaitForChild("blueprintTag");
		blueprintTagLabel.Text = library.Name;
		
		buildFrame.Visible = true;
		listMenu:Add(buildFrame, 0);
		
		local actionButtonDebounce = false;
		
		local function updateRequirements()
			for _, c in pairs(requireListFrame:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end; end;
			for _, c in pairs(createsListFrame:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end; end;
			
			local productItemLib = modItemLibrary:Find(library.Product);
			local productLabel = itemListingTemplate:Clone();
			productLabel.Text = "• "..productItemLib.Name..(library.Amount and " x "..library.Amount or "");
			productLabel.Parent = createsListFrame;
			productLabel.Visible = true;
			local labels = {};
			for a=1, #library.Requirements do
				local listingLabel = itemListingTemplate:Clone();
				local amount = library.Requirements[a].Amount or 1;
				if library.Requirements[a].Type == "Stat" then
					if library.Requirements[a].Name == "Money" then
						listingLabel.Text = ("• $$Amount"):gsub("$Amount", amount);
						
					elseif library.Requirements[a].Name == "Level" then
						listingLabel.Text = ("• Level $Amount"):gsub("$Amount", amount);
						
					elseif library.Requirements[a].Name == "Perks" then
						listingLabel.Text = ("• $Amount Perks"):gsub("$Amount", amount);
						
					end
				elseif library.Requirements[a].Type == "Item" then
					local itemLib = modItemLibrary:Find(library.Requirements[a].ItemId);
					listingLabel.Text = ("• $Requires/$Amount $Name"):gsub("$Requires", `{0}`):gsub("$Amount", amount):gsub("$Name", itemLib.Name);
				end
				listingLabel.Parent = requireListFrame;
				listingLabel.Visible = true;
				table.insert(labels, listingLabel);
			end
			spawn(function()
				local rPacket = remoteBlueprintHandler:InvokeServer("check", {ItemId=itemId;});
				
				if rPacket.Success then
					local fulfillment = rPacket.Fulfillment;
					for a=1, #library.Requirements do
						local requires = fulfillment[a].Requires or 0;
						local amount = library.Requirements[a].Amount or 1;
						local listingLabel = labels[a];
						if fulfillment[a].Fulfilled then
							listingLabel.TextColor3 = Color3.fromRGB(147, 255, 135);
						elseif not fulfillment[a].Fulfilled then
							listingLabel.TextColor3 = Color3.fromRGB(255, 108, 103);
						elseif library.Requirements[a].Ignore then
							listingLabel.TextColor3 = Color3.fromRGB(70, 70, 70);
						end
						if library.Requirements[a].Type == "Item" then
							local itemLib = modItemLibrary:Find(library.Requirements[a].ItemId);
							listingLabel.Text = ("• $Requires/$Amount $Name"):gsub("$Requires", amount-requires)
															:gsub("$Amount", amount):gsub("$Name", itemLib.Name);
						end
					end
				end
			end);
		end
		updateRequirements();
		
		buildButton.MouseButton1Click:Connect(function()
			if actionButtonDebounce then return end;
			actionButtonDebounce = true;
			interface:PlayButtonClick();
			buildButton.Text = "Starting to build...";

			local rPacket = remoteBlueprintHandler:InvokeServer("build", {
				WorkbenchPart = binds.InteractObject;
				StorageItemId = (storageItem and storageItem.ID);
				ItemId = itemId;
			});
			
			if rPacket and rPacket.Success then
				binds.ClearSelection();
				task.delay(0.2, function()
					if binds.ActivePage ~= "Processes" then
						binds.ClearSelection();
					end
				end)
				
			else
				local errCode = rPacket and rPacket.FailCode or 10;
				buildButton.Text = modWorkbenchLibrary.BlueprintReplies[errCode] or ("Error Code: "..errCode);
				
			end
			
			task.wait(1);
			buildButton.Text = "Build Blueprint";
			actionButtonDebounce = false;
		end)
		
		return listMenu;
	end

	return WorkbenchClass;
end

return WorkbenchClass;