local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface = {};

local localplayer = game.Players.LocalPlayer;
local modConfigurations = require(game.ReplicatedStorage.Library:WaitForChild("Configurations"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modLeaderboardService = require(game.ReplicatedStorage.Library.LeaderboardService);
local modFormatNumber = require(game.ReplicatedStorage.Library.FormatNumber);
local modItem = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);

local modItemInterface = require(game.ReplicatedStorage.Library.UI.ItemInterface);

local remoteHalloween = modRemotesManager:Get("Halloween");
	
--== Script;
function Interface.init(modInterface)
	if not modConfigurations.SpecialEvent.Halloween then return; end
	setmetatable(Interface, modInterface);
	
	local templateMarker = script:WaitForChild("pointMarker");
	
	local modData = require(localplayer:WaitForChild("DataModule"));
	local modLeaderboardInterface = require(game.ReplicatedStorage.Library.UI.LeaderboardInterface);
	
	--local rewardLib = modRewardsLibrary:Find("HalloweenCandyCauldron").Rewards
	--local MaxBarValue = rewardLib[#rewardLib].Value;

	local interfaceScreenGui = localplayer.PlayerGui:WaitForChild("MainInterface");

	local mainFrame = script:WaitForChild("Halloween"):Clone();
	mainFrame.Parent = interfaceScreenGui;

	local frame = mainFrame:WaitForChild("Frame");
	local playerDepositLabel = frame:WaitForChild("playerDepositLabel");
	local commDepositLabel = frame:WaitForChild("commDepositLabel");
	local candyCapacityFrame = frame:WaitForChild("CandyCapacity");
	local depositButton = mainFrame:WaitForChild("depositButton");
	local travelButton = mainFrame:WaitForChild("travelButton");

	local prevCandies = 0;
	local rewardButtons = {};

	if modBranchConfigs.WorldName == "Slaughterfest" then
		local slaughterfestHud = script:WaitForChild("SlaughterfestHud"):Clone();
		slaughterfestHud.Parent = interfaceScreenGui;

		local window = Interface.NewWindow("SlaughterfestHud", slaughterfestHud);
		window.IgnoreHideAll = true;
		window.ReleaseMouse = false;
		window:Open();
		
		local counterLabel = slaughterfestHud:WaitForChild("CandyBag"):WaitForChild("counterLabel");
		local cauldronTimerLabel = slaughterfestHud:WaitForChild("CandyBag"):WaitForChild("CauldronTimer");
		
		task.spawn(function()
			while true do
				if not slaughterfestHud:IsDescendantOf(interfaceScreenGui) then break; end;
				
				local timer = math.clamp((workspace:GetAttribute("NextCauldronSpawn") or 0)-modSyncTime.GetTime(), 0, 300);
				
				if timer < 240 then
					cauldronTimerLabel.Text = "Cauldron: ".. modSyncTime.ToString(timer)
					
				else
					cauldronTimerLabel.Text = "Cauldrons are available..";
					
				end
				
				local halloweenCauldronStorage = modData.Storages.HalloweenCauldron;
				if halloweenCauldronStorage then
					local count = 0;

					for id, storageItem in pairs(halloweenCauldronStorage.Container) do
						count = count + storageItem.Quantity;
					end

					counterLabel.Text = count.."/500";
				end
				
				task.wait(0.5)
			end
		end)
		
	end
	
	
	local window = Interface.NewWindow("HalloweenWindow", mainFrame);
	window:SetOpenClosePosition(UDim2.new(0.5, 0, 0.45, 0), UDim2.new(0.5, 0, -1.5, 0));
	
	window.OnWindowToggle:Connect(function(visible)
		if visible then
			if modBranchConfigs.WorldName == "Slaughterfest" then
				travelButton.Visible = false;
				depositButton.Visible = true;
				depositButton.Text = "Submit Candies";
			else
				travelButton.Visible = true;
				depositButton.Visible = false;
			end
			
			Interface.Update();
			Interface:ToggleInteraction(false);
			spawn(function()
				repeat until not window.Visible or Interface.Object == nil or not Interface.Object:IsDescendantOf(workspace) or Interface.modCharacter.Player:DistanceFromCharacter(Interface.Object.Position) >= 16 or not wait(0.5);
				Interface:ToggleWindow("HalloweenWindow", false);
			end)
			
			
		else
			task.delay(0.3, function()
				Interface:ToggleInteraction(true);
			end)
		end
	end)

	Interface.Garbage:Tag(travelButton.MouseButton1Click:Connect(function()
		Interface:PlayButtonClick();
		if modBranchConfigs.WorldName == "Slaughterfest" then return end;
		
		local promptWindow = Interface:PromptQuestion("Travel", 
			"Are you sure you want to travel to <b>Slaughterfest</b>?", 
			"Travel", "Cancel", "http://www.roblox.com/asset/?id=11262940674");
		local YesClickedSignal, NoClickedSignal;

		YesClickedSignal = promptWindow.Frame.Yes.MouseButton1Click:Connect(function()
			if debounce then return end;
			debounce = true;
			Interface:PlayButtonClick();
			promptWindow.Frame.Yes.buttonText.Text = "Travelling...";
			local rPacket = remoteHalloween:InvokeServer({Action="Join";});
			modInterface:ToggleGameBlinds(false, 3);
			
			wait(1.6);
			debounce = false;
			promptWindow:Close();
			YesClickedSignal:Disconnect();
			NoClickedSignal:Disconnect();
		end);
		NoClickedSignal = promptWindow.Frame.No.MouseButton1Click:Connect(function()
			if debounce then return end;
			Interface:PlayButtonClick();
			promptWindow:Close();
			YesClickedSignal:Disconnect();
			NoClickedSignal:Disconnect();
		end);
	end))
	
	Interface.Garbage:Tag(depositButton.MouseButton1Click:Connect(function()
		Interface:PlayButtonClick();
		if modBranchConfigs.WorldName ~= "Slaughterfest" then return end;
		
		Debugger:Log("Deposit Click");
		--Interface:OpenWindow("ExternalStorage", "Cauldron");
		
		depositButton.Text = "Submitting Candies";
		local rPacket = remoteHalloween:InvokeServer({Action="Submit";});
		if rPacket and rPacket.Success then
			depositButton.Text = "Submitted!";
			Interface.Update(rPacket);
			
		elseif rPacket and rPacket.FailMsg then
			depositButton.Text = rPacket.FailMsg;
			Interface.Update(rPacket);
		end
	end));
	
	--for a=1, #rewardLib do
	--	local reward = rewardLib[a];
		
	--	local newPointer = templateMarker:Clone();
	--	local itemLib = modItem:Find(reward.ItemId);
		
	--	local itemSlot = newPointer:WaitForChild("itemSlot");
	--	local label = newPointer:WaitForChild("label");
		
	--	label.Text = reward.Value
		
	--	local itemButtonObj = modItemInterface.newItemButton(reward.ItemId);
		
	--	itemButtonObj.ImageButton.Parent = itemSlot;
		
	--	Interface.Garbage:Tag(itemButtonObj.ImageButton.MouseButton1Click:Connect(function()
	--		Debugger:Log("Item Click");
			
	--		local rPacket = remoteHalloween:InvokeServer({Action="Claim"; ItemId=reward.ItemId;});
			
	--		if rPacket.ClaimSuccess then
	--			if rewardButtons[a] then
	--				rewardButtons[a]:Destroy();
	--				rewardButtons[a] = nil;
	--			end
	--		end
	--	end));
		
	--	itemButtonObj:Update();
		
	--	newPointer.Parent = candyCapacityFrame;
	--	newPointer.Position = UDim2.new(reward.Value/MaxBarValue, 0, 1, 0);
		
	--	rewardButtons[a] = itemButtonObj;
	--end
	
	window:AddCloseButton(mainFrame);
	
	function Interface.Update(rPacket)
		rPacket = rPacket or remoteHalloween:InvokeServer({Action="Request"});
		if rPacket == nil then return end;

		local candyData = rPacket.CandyData;
		local claimed = candyData.Claimed or {};

		--playerDepositLabel.Text = "Your Candy Contribution: "..(modFormatNumber.Beautify(candyData.Candy) or "0");
		--commDepositLabel.Text = modFormatNumber.Beautify(rPacket.CommunityContributions);

		--candyCapacityFrame.bar.Size = UDim2.new( math.clamp(candyData.Candy/MaxBarValue, 0, 1), 0, 1, 0);

		if rPacket.Storage then
			modData.SetStorage(rPacket.Storage);
		end

		--for a=1, #rewardLib do
		--	local reward = rewardLib[a];

		--	if candyData.Candy >= reward.Value then
		--		if claimed[reward.ItemId] == nil and rewardButtons[a] then
		--			local newGlow = rewardButtons[a].GlowEffect or modItemInterface.newGlowEffect();
		--			newGlow.Parent = rewardButtons[a].ImageButton;

		--		else
		--			if rewardButtons[a] then
		--				rewardButtons[a]:Destroy();
		--				rewardButtons[a] = nil;
		--			end
		--		end
		--	end
		--end

		prevCandies = candyData.Candy or 0;
	end
	
	return Interface;
end;

--Interface.Garbage is only initialized after .init();
return Interface;
