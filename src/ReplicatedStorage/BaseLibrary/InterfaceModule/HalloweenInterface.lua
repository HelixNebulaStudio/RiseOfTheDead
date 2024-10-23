local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface = {};

local localplayer = game.Players.LocalPlayer;
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modConfigurations = require(game.ReplicatedStorage.Library:WaitForChild("Configurations"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modDropRateCalculator = require(game.ReplicatedStorage.Library.DropRateCalculator);
local modLeaderboardService = require(game.ReplicatedStorage.Library.LeaderboardService);
local modFormatNumber = require(game.ReplicatedStorage.Library.FormatNumber);
local modItem = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);

local modItemInterface = require(game.ReplicatedStorage.Library.UI.ItemInterface);

local remoteHalloween = modRemotesManager:Get("Halloween");
	
local shopOptionTemplate = script:WaitForChild("ShopOption");
local candyOptionTemplate = script:WaitForChild("CandyOption");

--== Script;
function Interface.init(modInterface)
	if not modConfigurations.SpecialEvent.Halloween then return; end
	setmetatable(Interface, modInterface);
	
	local modData = require(localplayer:WaitForChild("DataModule") :: ModuleScript);
	local modLeaderboardInterface = require(game.ReplicatedStorage.Library.UI.LeaderboardInterface);
	
	local interfaceScreenGui = localplayer.PlayerGui:WaitForChild("MainInterface");

	local mainFrame = script:WaitForChild("Halloween"):Clone();
	mainFrame.Parent = interfaceScreenGui;

	local travelButton = mainFrame:WaitForChild("travelButton");

	local rewardLib = modRewardsLibrary:Find("slaughterfestcandyrecipes24");

	if modBranchConfigs.WorldName == "Slaughterfest" then

	end

	local window = Interface.NewWindow("HalloweenWindow", mainFrame);
	window.CompactFullscreen = true;
	if modConfigurations.CompactInterface then
		window:SetOpenClosePosition(UDim2.new(0.5, 0, 0, 0), UDim2.new(0.5, 0, -1.5, 0));
	else
		window:SetOpenClosePosition(UDim2.new(0.5, 0, 0, game:GetService("GuiService").TopbarInset.Height+10), UDim2.new(0.5, 0, -1.5, 0));
	end

	mainFrame:WaitForChild("TitleFrame"):WaitForChild("touchCloseButton"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
		Interface:CloseWindow("HalloweenWindow");
	end)

	window.OnWindowToggle:Connect(function(visible)
		if visible then
			if modConfigurations.CompactInterface then
				mainFrame.Size = UDim2.new(1, 0, 1, 0);
			else
				mainFrame.Size = UDim2.new(0.7, 0, 0.8, -game:GetService("GuiService").TopbarInset.Height-10);
			end
			if modBranchConfigs.WorldName == "Slaughterfest" then
				travelButton.Visible = false;
				
			else
				travelButton.Visible = true;
				
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
		
		Interface:PromptDialogBox({
			Title=`Join Slaughterfest`;
			Desc=`Are you sure you want to travel to <b>Slaughterfest</b>?`;
			Icon=`rbxassetid://11262940674`;
			Buttons={
				{
					Text="Travel";
					Style="Confirm";
					OnPrimaryClick=function(promptDialogFrame, textButton)
						promptDialogFrame.statusLabel.Text = "Travelling...";
						local rPacket = remoteHalloween:InvokeServer({Action="Join";});
						modInterface:ToggleGameBlinds(false, 3);
					end;
				};
				{
					Text="Cancel";
					Style="Cancel";
				};
			}
		});
	end))
	
	window:AddCloseButton(mainFrame);
	
	local candyShopFrame = mainFrame:WaitForChild("CandyShop");
	local shopChoicesFrame = candyShopFrame:WaitForChild("RewardChoices");

	local rerollButton: TextButton = candyShopFrame:WaitForChild("rerollButton");
	local rerollDebounce = tick();

	local restockTimer = 18000;
	local function updateRerollText()
		local slaughterfestData = modData:GetFlag("Slaughterfest");

		local shopReroll = slaughterfestData.ShopReroll;
		local shopLastRestock = slaughterfestData.ShopLastRestock;

		if tick()-rerollDebounce < 1 then
			rerollButton.Text = "Rerolling Recipes";
			rerollButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80);
			rerollButton.AutoButtonColor = false;
			
		else
			rerollButton.BackgroundColor3 = Color3.fromRGB(50, 80, 106);
			rerollButton.AutoButtonColor = true;

			local timeLapse = workspace:GetServerTimeNow() - shopLastRestock;
			local nextRestock = math.clamp(restockTimer-timeLapse, 0, restockTimer);
			if shopReroll < 10 then
				rerollButton.Text = `Reroll Recipes ({shopReroll}/10)    +1 reroll in {modSyncTime.ToString(nextRestock)}`;
			else
				rerollButton.Text = `Reroll Recipes ({shopReroll}/10)`;
			end
			if nextRestock <= 0 then
				modData:GetFlag("Slaughterfest", true);
			end
		end
	end

	rerollButton.MouseButton1Click:Connect(function()
		if tick()-rerollDebounce <= 1.1 then return end;

		local slaughterfestData = modData:GetFlag("Slaughterfest", true);
		if slaughterfestData.ShopReroll <= 0 then return; end

		Interface:PlayButtonClick();
		rerollDebounce = tick();

		local rPacket = remoteHalloween:InvokeServer({Action="Reroll";});
		if rPacket == nil then return end;

		updateRerollText();
		Interface.Update();
	end)
	Interface.Garbage:Tag(modSyncTime.GetClock():GetPropertyChangedSignal("Value"):Connect(function()
		if not mainFrame.Visible then return end;
		updateRerollText();
		task.wait(0.5);
		updateRerollText();
	end));

	function Interface.Update()
		local slaughterfestData = modData:GetFlag("Slaughterfest", true);
		local rollSeed = slaughterfestData.RollSeed;
		local claimedReward = slaughterfestData.Claimed or {};

		if rewardLib then
			local shopRewardInfoList = {};

			for a=1, 10 do
				local rewardsData = modDropRateCalculator.RollDrop(rewardLib, rollSeed/a);
				local rewardInfo = rewardsData[1];
				if rewardInfo == nil then continue end;

				local exist = false;
				for b=1, #shopRewardInfoList do
					if shopRewardInfoList[b].ItemId == rewardInfo.ItemId then
						exist = true;
						break;
					end
				end

				if not exist then
					table.insert(shopRewardInfoList, rewardInfo);
				end

				if #shopRewardInfoList >= 3 then
					break;
				end
			end
			
			local candyIcons = {
				["zombiejello"]="rbxassetid://99854271826378";
				["eyeballgummies"]="rbxassetid://72634660358826";
				["spookmallow"]="rbxassetid://93144909042467";
				["cherrybloodbar"]="rbxassetid://87358672710754";
				["wickedtaffy"]="rbxassetid://125482145777312";
			};
			local candyTypes = {
				"zombiejello";
				"eyeballgummies";
				"spookmallow";
				"cherrybloodbar";
				"wickedtaffy";
			};
			local tierRecipeCost = {
				[1] = 6;
				[2] = 8;
				[3] = 12;
				[4] = 16;
				[5] = 20;
			}
			for _, obj in pairs(shopChoicesFrame:GetChildren()) do
				if not obj:IsA("GuiObject") then continue end;
				game.Debris:AddItem(obj, 0);
			end
			for a=1, #shopRewardInfoList do
				local rewardInfo = shopRewardInfoList[a];

				local itemLib = modItem:Find(rewardInfo.ItemId);

				local newOption = shopOptionTemplate:Clone();
				newOption.Name = rewardInfo.ItemId;

				local alreadyClaimed = claimedReward[rewardInfo.ItemId];

				local uiLayout: UIListLayout = newOption:WaitForChild("UIListLayout");
				
				local itemButtonObj = modItemInterface.newItemButton(rewardInfo.ItemId);
				local itemImgButton = itemButtonObj.ImageButton;
				itemImgButton.AnchorPoint = Vector2.new(0.5, 0.5);
				itemImgButton.Size = UDim2.new(0.8, 0, 0.8, 0);

				local uiAspect = Instance.new("UIAspectRatioConstraint");
				uiAspect.Parent = itemImgButton;

				itemImgButton.Parent = newOption;
				newOption.Parent = shopChoicesFrame;

				itemButtonObj:Update();
				
				if alreadyClaimed then
					itemImgButton.ImageColor3 = Color3.fromRGB(50, 50, 50);
					newOption.BackgroundColor3 = Color3.fromRGB(15, 30, 15);
					newOption.AutoButtonColor = false;
				end

				local candyCostFrame = newOption:WaitForChild("CandyCost"); 

				local rewardTier = rewardInfo.Tier;
				local recipeRandom = Random.new(rollSeed/a);

				local recipeItems = {};
				local recipeCost = tierRecipeCost[rewardTier];

				local candyOrder = {};

				for b=1, recipeCost do
					local pickCandyItemId = candyTypes[recipeRandom:NextInteger(1, #candyTypes)];
					recipeItems[pickCandyItemId] = (recipeItems[pickCandyItemId] or 0) + 1;

					if table.find(candyOrder, pickCandyItemId) == nil then
						table.insert(candyOrder, pickCandyItemId);
					end
				end

				for b=1, #candyOrder do
					local candyItemId = candyOrder[b];
					local amt = recipeItems[candyItemId];

					local validCount = modData.CountItemIdFromStorages(candyItemId);

					for c=1, amt do
						local newCandy: ImageLabel = candyOptionTemplate:Clone();
						newCandy.Image = candyIcons[candyItemId];
						newCandy.Parent = candyCostFrame;

						if alreadyClaimed then
							newCandy.ImageTransparency = 0.5;
							newCandy.BackgroundTransparency = 0.9;

						elseif validCount >= c then
							newCandy.ImageTransparency = 0;
							newCandy.BackgroundTransparency = 0.6;
						else
							newCandy.ImageTransparency = 0.5;
							newCandy.BackgroundTransparency = 0.9;
						end

						if modConfigurations.CompactInterface then
							if recipeCost > 20 then
								newCandy.Size = UDim2.new(0, 20, 0, 20);
							elseif recipeCost > 6 then
								newCandy.Size = UDim2.new(0, 25, 0, 25);
							end
						end
					end
				end
				
				if modConfigurations.CompactInterface then
					uiLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom;

					if recipeCost > 20 then
						itemImgButton.Size = UDim2.new(0.5, 0, 0.5, 0);
					elseif recipeCost > 10 then
						itemImgButton.Size = UDim2.new(0.65, 0, 0.65, 0);
					end
				end

				newOption.MouseButton1Click:Connect(function()
					if alreadyClaimed then return end;

					Interface:PromptDialogBox({
						Title=`Cook {itemLib.Name}`;
						Desc=`Are you sure you want to cook your candies in the cauldron for a {itemLib.Name}.`;
						Icon=itemLib.Icon;
						Buttons={
							{
								Text="Cook";
								Style="Confirm";
								OnPrimaryClick=function(promptDialogFrame, textButton)
									promptDialogFrame.statusLabel.Text = "Cooking...";
									local rPacket = remoteHalloween:InvokeServer({Action="Cook"; ItemId=rewardInfo.ItemId});
									if rPacket == nil then
										return;
									end
									slaughterfestData.Claimed[rewardInfo.ItemId]=true;

									Interface.Update();
								end;
							};
							{
								Text="Cancel";
								Style="Cancel";
							};
						}
					});
				end)
			end

		end
	end
	
	return Interface;
end;

--Interface.Garbage is only initialized after .init();
return Interface;