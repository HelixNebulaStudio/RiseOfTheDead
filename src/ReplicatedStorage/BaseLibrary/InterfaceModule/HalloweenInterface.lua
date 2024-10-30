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
local modNpcProfileLibrary = require(game.ReplicatedStorage.BaseLibrary.NpcProfileLibrary);

local modItemInterface = require(game.ReplicatedStorage.Library.UI.ItemInterface);

local remoteHalloween = modRemotesManager:Get("Halloween");
	
local shopOptionTemplate = script:WaitForChild("ShopOption");
local candyOptionTemplate = script:WaitForChild("CandyOption");
local offerListingTemplate = script:WaitForChild("OfferListing");
local npcListingTemplate = script:WaitForChild("NpcListing");
local pageButtonTemplate = script:WaitForChild("PageButton");

local sfGuideImgs = {
	"rbxassetid://14993666654";
	"rbxassetid://14993668054";
	"rbxassetid://14993669673";
}
--== Script;
function Interface.init(modInterface)
	if not modConfigurations.SpecialEvent.Halloween then return; end
	setmetatable(Interface, modInterface);
	
	local modData = require(localplayer:WaitForChild("DataModule") :: ModuleScript);
	local modLeaderboardInterface = require(game.ReplicatedStorage.Library.UI.LeaderboardInterface);
	
	local interfaceScreenGui = localplayer.PlayerGui:WaitForChild("MainInterface");

	local mainFrame = script:WaitForChild("Halloween"):Clone();
	mainFrame.Parent = interfaceScreenGui;

	local treatFrame = mainFrame:WaitForChild("TreatFrame");
	local treatNpcScrollFrame = treatFrame:WaitForChild("Content"):WaitForChild("ScrollList");
	local treatGuideImgLabel: ImageLabel = treatFrame:WaitForChild("Content"):WaitForChild("GuideImgLabel");
	local travelButton = treatFrame:WaitForChild("travelButton");

	local cauldronRewardLib = modRewardsLibrary:Find("slaughterfestcauldron");
	local festRewardLib = modRewardsLibrary:Find("slaughterfestcandyrecipes24");

	if modBranchConfigs.WorldName == "Slaughterfest" then

	end

	local setPage = "Uncover";
	local uncoverPageIndex = 1;

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

	local uncoverButton = candyShopFrame:WaitForChild("newButton");
	local antiqueButton = candyShopFrame:WaitForChild("oldButton");
	local pageButtonsFrame = candyShopFrame:WaitForChild("PageButtons");
	local antiqueCookOptionsFrame = candyShopFrame:WaitForChild("AntiqueCookOptions");
	local uncoverCookOptionsFrame = candyShopFrame:WaitForChild("UncoverCookOptions");
	local rerollButton: TextButton = candyShopFrame:WaitForChild("rerollButton");


	local function updatePage()
		if setPage == "Uncover" then
			uncoverButton.BackgroundColor3 = Color3.fromRGB(28, 106, 5);
			uncoverButton.BackgroundTransparency = 0;
			antiqueButton.BackgroundColor3 = Color3.fromRGB(35, 70, 36);
			antiqueButton.BackgroundTransparency = 0.4;
			pageButtonsFrame.Visible = true;
			rerollButton.Visible = false;
			antiqueCookOptionsFrame.Visible = false;
			uncoverCookOptionsFrame.Visible = true;

		elseif setPage == "Antique" then
			antiqueButton.BackgroundColor3 = Color3.fromRGB(28, 106, 5);
			antiqueButton.BackgroundTransparency = 0;
			uncoverButton.BackgroundColor3 = Color3.fromRGB(35, 70, 36);
			uncoverButton.BackgroundTransparency = 0.4;
			pageButtonsFrame.Visible = false;
			rerollButton.Visible = true;
			antiqueCookOptionsFrame.Visible = true;
			uncoverCookOptionsFrame.Visible = false;

		end
	end

	uncoverButton.MouseButton1Click:Connect(function()
		setPage = "Uncover";
		Interface:PlayButtonClick();
		updatePage();
	end)
	antiqueButton.MouseButton1Click:Connect(function()
		setPage = "Antique";
		Interface:PlayButtonClick();
		updatePage();
	end)

	local rerollDebounce = tick();

	local restockTimer = 18000;
	local function updateRerollText()
		local slaughterfestData = modData:GetFlag("Slaughterfest");
		if slaughterfestData == nil then return end;

		local shopReroll = slaughterfestData.ShopReroll;
		local shopLastRestock = slaughterfestData.ShopLastRestock;

		if tick()-rerollDebounce < 1 then
			rerollButton.Text = "Rerolling Recipes";
			rerollButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80);
			rerollButton.AutoButtonColor = false;
			
		else
			rerollButton.BackgroundColor3 = Color3.fromRGB(28, 106, 5);
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

	local imgLabelTick = tick();
	Interface.Garbage:Tag(modSyncTime.GetClock():GetPropertyChangedSignal("Value"):Connect(function()
		if not mainFrame.Visible then return end;
		updateRerollText();
		task.wait(0.5);
		updateRerollText();

		if tick()-imgLabelTick > 2 then
			imgLabelTick = tick();	
			local imgIndex = treatGuideImgLabel:GetAttribute("ImgIndex");
			treatGuideImgLabel.Image = sfGuideImgs[imgIndex];
			imgIndex = imgIndex + 1;
			if imgIndex > #sfGuideImgs then
				imgIndex = 1;
			end
			treatGuideImgLabel:SetAttribute("ImgIndex", imgIndex);
		end

		local timeLeft = modSyncTime.TimeOfEndOfDay()-modSyncTime.GetTime();
		mainFrame:WaitForChild("TitleFrame"):WaitForChild("GuideLabel").Text = `Tricks & Treats & Recipes Refresh: {modSyncTime.ToString(timeLeft)}`;
	end));

	local npcTradesFrame = mainFrame:WaitForChild("NpcTrades");

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

	function Interface.Update()
		local slaughterfestData = modData:GetFlag("Slaughterfest", true);
		local rollSeed = slaughterfestData.RollSeed;
		local claimedReward = slaughterfestData.Claimed or {};

		-- MARK: Fest Rewards;
		if festRewardLib then
			local rewardsList = festRewardLib.Rewards;
			local cookCostSeed = modSyncTime.TimeOfEndOfDay();

			local tierRecipeCost = {
				[1] = 10;
				[2] = 15;
				[3] = 20;
			};

			local loadPageDebounce = tick();
			local function loadFestPage()
				for _, obj in pairs(uncoverCookOptionsFrame:GetChildren()) do
					if not obj:IsA("GuiObject") then continue end;
					obj.Visible = false;
					game.Debris:AddItem(obj, 0);
				end

				local rewardStartIndex = 1+(uncoverPageIndex-1)*3;
				local rewardEndIndex = rewardStartIndex+2;

				for a=rewardStartIndex, rewardEndIndex do
					local rewardInfo = rewardsList[a];
					if rewardInfo == nil then continue end;
					local itemId = rewardInfo.ItemId;
	
					local newOption = shopOptionTemplate:Clone();
					newOption.Name = rewardInfo.ItemId;
					
					local uiLayout: UIListLayout = newOption:WaitForChild("UIListLayout");
	
					local itemButtonObj = modItemInterface.newItemButton(rewardInfo.ItemId);
					local itemImgButton = itemButtonObj.ImageButton;
					itemImgButton.AnchorPoint = Vector2.new(0.5, 0.5);
					itemImgButton.Size = UDim2.new(0.8, 0, 0.8, 0);
	
					local uiAspect = Instance.new("UIAspectRatioConstraint");
					uiAspect.Parent = itemImgButton;
	
					itemImgButton.Parent = newOption;
					newOption.Parent = uncoverCookOptionsFrame;
	
					itemImgButton.ZIndex = 1;
					itemButtonObj:Update();
	
					local candyCostFrame = newOption:WaitForChild("CandyCost"); 
	
					local cookCostAmount = tierRecipeCost[rewardInfo.Tier];
					local costRandom = Random.new(cookCostSeed+(a*100));
	
					local candyCost = {};
					local candyOrder = {};
					for b=1, cookCostAmount do
						local pickCandyId = candyTypes[costRandom:NextInteger(1, #candyTypes)];
	
						if table.find(candyOrder, pickCandyId) == nil then
							table.insert(candyOrder, pickCandyId);
						end
						candyCost[pickCandyId] = (candyCost[pickCandyId] or 0) +1;
					end
	
					for b=1, #candyOrder do
						local candyItemId = candyOrder[b];
						local amt = candyCost[candyItemId];
	
						local validCount = modData.CountItemIdFromStorages(candyItemId);
	
						for c=1, amt do
							local newCandy: ImageLabel = candyOptionTemplate:Clone();
							newCandy.Image = candyIcons[candyItemId];
							newCandy.Parent = candyCostFrame;
	
							if validCount >= c then
								newCandy.ImageTransparency = 0;
								newCandy.BackgroundTransparency = 0.4;
							else
								newCandy.ImageTransparency = 0.5;
								newCandy.BackgroundTransparency = 0.9;
							end
	
							if modConfigurations.CompactInterface then
								if cookCostAmount > 20 then
									newCandy.Size = UDim2.new(0, 20, 0, 20);
								elseif cookCostAmount > 6 then
									newCandy.Size = UDim2.new(0, 25, 0, 25);
								end
							end
						end
					end
					
					if modConfigurations.CompactInterface then
						uiLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom;
	
						if cookCostAmount > 20 then
							itemImgButton.Size = UDim2.new(0.5, 0, 0.5, 0);
						elseif cookCostAmount > 10 then
							itemImgButton.Size = UDim2.new(0.65, 0, 0.65, 0);
						end
					end
	
					local itemLib = modItem:Find(itemId);
					local optionClickFunc = function()
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
										local rPacket = remoteHalloween:InvokeServer({Action="CookNew"; ItemId=rewardInfo.ItemId});
										if rPacket == nil then
											return;
										end
	
										Interface.Update();
									end;
								};
								{
									Text="Cancel";
									Style="Cancel";
								};
							}
						});
					end

					newOption.MouseButton1Click:Connect(optionClickFunc)
					itemImgButton.MouseButton1Click:Connect(optionClickFunc);
				end

				for _, textButton in pairs(pageButtonsFrame:GetChildren()) do
					if not textButton:IsA("GuiObject") then continue end;
					local buttonIndex = textButton.LayoutOrder;

					if buttonIndex == uncoverPageIndex then
						textButton.BackgroundColor3 = Color3.fromRGB(28, 106, 5);
						textButton.BackgroundTransparency = 0;
					else
						textButton.BackgroundColor3 = Color3.fromRGB(35, 70, 36);
						textButton.BackgroundTransparency = 0.4;
					end
				end
			end

			local maxPageCount = math.ceil(#rewardsList/3);
			for _, obj in pairs(pageButtonsFrame:GetChildren()) do
				if not obj:IsA("GuiObject") then continue end;
				game.Debris:AddItem(obj, 0);
			end
			for a=1, maxPageCount do
				local pageButton = pageButtonTemplate:Clone();
				pageButton.Text = a;
				pageButton.LayoutOrder = a;
				pageButton.Parent = pageButtonsFrame;

				pageButton.MouseButton1Click:Connect(function()
					if tick()-loadPageDebounce <= 0.5 then return end;
					loadPageDebounce = tick();

					Interface:PlayButtonClick();
					uncoverPageIndex = a;
					loadFestPage();
				end)
			end

			loadFestPage();
		end

		-- MARK: Cauldron Rewards
		if cauldronRewardLib then
			local shopRewardInfoList = {};

			for a=1, 10 do
				local rewardsData = modDropRateCalculator.RollDrop(cauldronRewardLib, rollSeed/a);
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
			
			local tierRecipeCost = {
				[1] = 6;
				[2] = 8;
				[3] = 12;
				[4] = 16;
				[5] = 20;
			}
			for _, obj in pairs(antiqueCookOptionsFrame:GetChildren()) do
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
				newOption.Parent = antiqueCookOptionsFrame;

				itemImgButton.ZIndex = 1;
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
							newCandy.BackgroundTransparency = 0.4;
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

				local optionClickFunc = function()
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
				end

				newOption.MouseButton1Click:Connect(optionClickFunc);
				itemImgButton.MouseButton1Click:Connect(optionClickFunc);

			end
		end

		-- MARK: Exchange & Treats
		local npcSeed = modSyncTime.TimeOfEndOfDay();
		local npcRandom = Random.new(npcSeed);

		local survivorsList = modNpcProfileLibrary:ListByMatchFunc(function(libItem)
			if libItem.Class == "Survivor" and libItem.Id ~= "Stan" and libItem.Id ~= "Robert" then
				return true;
			end
			return false;
		end);
		local tradeNpcList = {};

		local treatNpcList = {};

		for a=1, 5 do
			local npcInfo = table.remove(survivorsList, npcRandom:NextInteger(1, #survivorsList));
			table.insert(tradeNpcList, npcInfo);
		end
		for a=1, 3 do
			local npcInfo = table.remove(survivorsList, npcRandom:NextInteger(1, #survivorsList));
			table.insert(treatNpcList, npcInfo);
		end

		local offersScrollFrame = npcTradesFrame:WaitForChild("OffersList");
		for _, obj in pairs(offersScrollFrame:GetChildren()) do
			if not obj:IsA("GuiObject") then continue end;
			game.Debris:AddItem(obj, 0);
		end
		for a=1, #tradeNpcList do
			local npcInfo = tradeNpcList[a];
			local worldName = modBranchConfigs.GetWorldDisplayName(npcInfo.World) or "Unknown";

			local newListing = offerListingTemplate:Clone();
			newListing.Name = npcInfo.Id;

			local nameLabel = newListing:WaitForChild("NameLabel");
			nameLabel.Text = `<b>{npcInfo.Id}</b>\n{worldName}`;

			local avatarLabel = newListing:WaitForChild("AvatarLabel");
			avatarLabel.Image = npcInfo.Avatar or "rbxassetid://15641359355";

			local candyRandom = Random.new(npcSeed+a);
			local biasRng = candyRandom:NextNumber();

			local candyWantAmt = candyRandom:NextInteger(3, 4);
			local candyForAmt = candyRandom:NextInteger(2, 4);

			if candyWantAmt > candyForAmt and biasRng > 0.4 then -- 60% chance to equal;
				candyWantAmt = candyWantAmt -1;
			end
			if candyForAmt > candyWantAmt and biasRng > 0.1 then -- 10% chance to better;
				candyWantAmt, candyForAmt = candyForAmt, candyWantAmt;
			end

			local candyWantList = {};
			local candyWantOrder = {};
			for b=1, candyWantAmt do
				local pickCandyItemId;
				if #candyWantOrder >= 3 then
					pickCandyItemId = candyWantOrder[candyRandom:NextInteger(1, #candyWantOrder)];
				else
					pickCandyItemId = candyTypes[candyRandom:NextInteger(1, #candyTypes)];
				end
				candyWantList[pickCandyItemId] = (candyWantList[pickCandyItemId] or 0) + 1;

				if table.find(candyWantOrder, pickCandyItemId) == nil then
					table.insert(candyWantOrder, pickCandyItemId);
				end
			end

			local candyForList = {};
			local candyForOrder = {};
			for b=1, #candyTypes do
				if table.find(candyWantOrder, candyTypes[b]) then continue end;
				table.insert(candyForOrder, candyTypes[b]);
			end
			for b=1, candyForAmt do
				local pickCandyItemId;
				if b <= #candyForOrder then
					pickCandyItemId = candyForOrder[b];
				else
					pickCandyItemId = candyForOrder[candyRandom:NextInteger(1, #candyForOrder)];
				end
				
				candyForList[pickCandyItemId] = (candyForList[pickCandyItemId] or 0) + 1;
			end
			for b=#candyForOrder, 1, -1 do
				if candyForList[candyForOrder[b]] == nil then
					table.remove(candyForOrder, b);
				end
			end 

			local candyWantFrame = newListing:WaitForChild("CandyWant");
			for b=1, #candyWantOrder do
				local candyItemId = candyWantOrder[b];
				local candyAmt = candyWantList[candyItemId];

				local validCount = modData.CountItemIdFromStorages(candyItemId);

				for c=1, candyAmt do
					local newCandy: ImageLabel = candyOptionTemplate:Clone();
					newCandy.Image = candyIcons[candyItemId];
					newCandy.Parent = candyWantFrame;

					if validCount >= c then
						newCandy.ImageTransparency = 0;
						newCandy.BackgroundTransparency = 0.6;
					else
						newCandy.ImageTransparency = 0.5;
						newCandy.BackgroundTransparency = 0.9;
					end
				end
			end

			local candyForFrame = newListing:WaitForChild("CandyFor");
			for b=1, #candyForOrder do
				local candyItemId = candyForOrder[b];
				local candyAmt = candyForList[candyItemId];

				for c=1, candyAmt do
					local newCandy: ImageLabel = candyOptionTemplate:Clone();
					newCandy.Image = candyIcons[candyItemId];
					newCandy.Parent = candyForFrame;

					newCandy.ImageTransparency = 0;
					newCandy.BackgroundTransparency = 0.6;
				end
			end

			newListing.Parent = offersScrollFrame;
		end

		for _, obj in pairs(treatNpcScrollFrame:GetChildren()) do
			if not obj:IsA("GuiObject") then continue end;
			game.Debris:AddItem(obj, 0);
		end
		local npcSeed = modSyncTime.TimeOfEndOfDay();
		for a=1, #treatNpcList do
			local npcInfo = treatNpcList[a];
			local npcName = npcInfo.Id;
	
			local npcProfileLib = modNpcProfileLibrary:Find(npcName);
			local descRandom = Random.new(npcSeed+a);

			local newListing = npcListingTemplate:Clone();
			local textLabel = newListing:WaitForChild("TextLabel");
			newListing.Parent = treatNpcScrollFrame;

			local avatarLabel = newListing:WaitForChild("AvatarLabel");
			if slaughterfestData.ClaimedTreats and slaughterfestData.ClaimedTreats[npcName] then
				avatarLabel.Image = npcProfileLib.Avatar;
			end

			local DescTypes = {
				{Str=`$Gender with $Hair`; Keys={"Gender"; "Hair"}; Gender={["M"]="Guy"; ["F"]="Gal"};};
				{Str=`Some $Role $Gender`; Keys={"Gender"; "Role"}; Gender={["M"]="Gentleman"; ["F"]="Lady"};};
				{Str=`$Gender wearing $Clothing`; Keys={"Gender"; "Clothing"}; Gender={["M"]="Man"; ["F"]="Woman"};};
				{Str=`Someone with $Hair wearing $Clothing`; Keys={"Hair"; "Clothing"}};
				{Str=`Some guy with $Hair and $Beard`; Keys={"Hair"; "Beard"}};
				{Str=`Person with the $Scar Scar`; Keys={"Scar";}};
			};
			for b=#DescTypes, 1, -1 do
				local missingKey = false;
				for c=1, #DescTypes[b].Keys do
					if npcProfileLib.Descriptors[DescTypes[b].Keys[c]] == nil then
						missingKey = true;
					end
				end
				if missingKey then
					table.remove(DescTypes, b);
				end
			end
			if #DescTypes <= 0 then continue end;

			local pickDesc = DescTypes[descRandom:NextInteger(1, #DescTypes)];
			
			for b=1, #pickDesc.Keys do
				local key = pickDesc.Keys[b];
				local val = npcProfileLib.Descriptors[key];
				if key == "Gender" then
					if pickDesc[key] then
						pickDesc.Str = string.gsub(pickDesc.Str, `${key}`, pickDesc[key][val]);
					else
						pickDesc.Str = string.gsub(pickDesc.Str, `${key}`, val);
					end
				else
					if typeof(val) == "table" then
						pickDesc.Str = string.gsub(pickDesc.Str, `${key}`, val[descRandom:NextInteger(1, #val)]);
					else
						pickDesc.Str = string.gsub(pickDesc.Str, `${key}`, val);
					end
				end
			end

			textLabel.Text = pickDesc.Str;
		end

	end
	
	return Interface;
end;

--Interface.Garbage is only initialized after .init();
return Interface;