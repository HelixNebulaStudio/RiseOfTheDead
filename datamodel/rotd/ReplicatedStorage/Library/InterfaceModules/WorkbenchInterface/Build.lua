local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Workbench = {};
local Interface = {} :: any;

local TweenService = game:GetService("TweenService");
local player = game.Players.LocalPlayer;

local modData = shared.require(player:WaitForChild("DataModule") :: ModuleScript);
local modWorkbenchLibrary = shared.require(game.ReplicatedStorage.Library:WaitForChild("WorkbenchLibrary"));
local modBranchConfigs = shared.require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("BranchConfigurations"));
local modItemLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);

local buildFrameTemplate = script:WaitForChild("BuildFrame");
local remoteBlueprintHandler = modRemotesManager:Get("BlueprintHandler");

function Workbench.new(itemId, library, storageItem)
	local listMenu = Interface.List.create();
	listMenu:SetEnableScrollBar(false);
	listMenu:SetEnableSearchBar(false);
	
	local buildFrame = buildFrameTemplate:Clone();
	local coreListLayout = buildFrame:WaitForChild("UIListLayout");
	local buttonsMenu = buildFrame:WaitForChild("ButtonFrame");
	local menuListLayout = buttonsMenu:WaitForChild("UIListLayout");
	local buildButton = buttonsMenu:WaitForChild("BuildButton");
	local cancelButton = buttonsMenu:WaitForChild("CancelButton");
	local skipButton = buttonsMenu:WaitForChild("SkipButton");
	local claimButton = buttonsMenu:WaitForChild("ClaimButton");
	local cancelingBar = cancelButton:WaitForChild("Bar");
	
	local requirementsFrame = buttonsMenu:WaitForChild("RequirementsFrame");
	local requirementsListLayout = requirementsFrame:WaitForChild("UIListLayout");
	local itemListingTemplate = requirementsListLayout:WaitForChild("Item");
	local requireListFrame = requirementsFrame:WaitForChild("List");
	local rlistListLayout = requireListFrame:WaitForChild("UIListLayout");
	
	local createsFrame = buttonsMenu:WaitForChild("CreatesFrame");
	local createsListLayout = createsFrame:WaitForChild("UIListLayout");
	local createsListFrame = createsFrame:WaitForChild("List");
	local clistListLayout = createsListFrame:WaitForChild("UIListLayout");
	
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
		Interface:PlayButtonClick();
		buildButton.Text = "Starting to build...";

		local rPacket = remoteBlueprintHandler:InvokeServer("build", {
			WorkbenchPart=Interface.Object;
			StorageItemId=(storageItem and storageItem.ID);
			ItemId=itemId;
		});
		
		if rPacket and rPacket.Success then
			Interface.ClearSelection();
			task.delay(0.2, function()
				if Interface.ActivePage ~= "Processes" then
					Interface.ClearSelection();
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

function Workbench.init(interface)
	Interface = interface;
	return Workbench;
end

return Workbench;