local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface = {
	OpenWindow = nil;
	CloseWindow = nil;
	LoadPage = nil;
	PlayButtonClick = nil;
	PromptWarning = nil;
};

local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");
local MarketplaceService = game:GetService("MarketplaceService");

local localplayer = game.Players.LocalPlayer;
local modData = require(localplayer:WaitForChild("DataModule") :: ModuleScript);

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modFormatNumber = require(game.ReplicatedStorage.Library.FormatNumber);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modGoldShopLibrary = require(game.ReplicatedStorage.Library.GoldShopLibrary);
local modKeyBindsHandler = require(game.ReplicatedStorage.Library.KeyBindsHandler);

local modItemInterface = require(game.ReplicatedStorage.Library.UI.ItemInterface);

local modShowcases = require(script:WaitForChild("Showcases"));

local remoteGoldShopPurchase = modRemotesManager:Get("GoldShopPurchase");
local remoteLimitedService = modRemotesManager:Get("LimitedService");
	
local GoldMenuFrame = script.Parent.Parent:WaitForChild("GoldMenuFrame");
local GoldStatFrame = script.Parent.Parent:WaitForChild("GoldStats");
local goldLabel = GoldStatFrame:WaitForChild("goldLabel");
local goldButton = GoldStatFrame:WaitForChild("GoldMenu");
local exclaimIcon = goldButton:WaitForChild("exclaimImage");

local mainMenu = GoldMenuFrame:WaitForChild("Main");
local listFrame = mainMenu:WaitForChild("List");
local listLayout = listFrame:WaitForChild("UIListLayout");
local backButton = GoldMenuFrame:WaitForChild("backButton");
local downIndicator = GoldMenuFrame:WaitForChild("downIndicator");
local upIndicator = GoldMenuFrame:WaitForChild("upIndicator");

local lScrollFrame = mainMenu:WaitForChild("LScroll");
local rScrollFrame = mainMenu:WaitForChild("RScroll");

local templateProduct = script:WaitForChild("templateProduct");
local templatePage = script:WaitForChild("templatePage");
local templatePageButton = script:WaitForChild("templatePageButton")
local searchOption = script:WaitForChild("searchOption");

local frontPage = "FrontPage";
local pageHistory = {};

local goldLerpTag = Instance.new("NumberValue"); goldLerpTag.Parent = script;
goldLerpTag:GetPropertyChangedSignal("Value"):Connect(function()
	local goldText = modFormatNumber.Beautify(math.floor(goldLerpTag.Value));
	goldLabel.Text = goldText;
end)

Interface.LimitedList = {};
local nameCaches = {};
--== Script;
local function updateGoldStats(value)
	if goldLerpTag then
		local duration = 2;
		if value > goldLerpTag.Value then
			goldLabel.TextColor3=Color3.fromRGB(149, 221, 115);
			
			TweenService:Create(goldLabel, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
				TextColor3=Color3.fromRGB(255, 255, 255);
			}):Play();
			
			delay(duration+0.02, function() goldLabel.TextColor3=Color3.fromRGB(255, 255, 255); end);
		elseif value < goldLerpTag.Value then
			goldLabel.TextColor3=Color3.fromRGB(147, 49, 49);
			
			TweenService:Create(goldLabel, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				TextColor3=Color3.fromRGB(255, 255, 255);
			}):Play();
			
			delay(duration+0.02, function() goldLabel.TextColor3=Color3.fromRGB(255, 255, 255); end);
		end
		TweenService:Create(goldLerpTag, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Value=value;
		}):Play();
		delay(duration+0.02, function() 
			goldLerpTag.Value = value;
		end)
	end
	
	local hasFreeLoot = false;
	if hasFreeLoot then
		exclaimIcon.Visible = true;
		if exclaimIcon:GetAttribute("Blink") == nil then
			exclaimIcon:SetAttribute("Blink", true);

			local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true, 0);
			TweenService:Create(exclaimIcon, tweenInfo, {ImageTransparency=0.6}):Play();
		end
	else
		exclaimIcon.Visible = false;
	end
end

if modConfigurations.CompactInterface then
	GoldMenuFrame.Position = UDim2.new(0.5, 0, 0.5, 0);
	GoldMenuFrame.Size = UDim2.new(1, 0, 1, 0);
	GoldMenuFrame:WaitForChild("UICorner"):Destroy();
	
	GoldMenuFrame:WaitForChild("touchCloseButton").Visible = true;
	GoldMenuFrame:WaitForChild("touchCloseButton"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
		Interface:CloseWindow("GoldMenu");
	end)
end
function Interface.init(modInterface)
	setmetatable(Interface, modInterface);

	local window = Interface.NewWindow("GoldMenu", GoldMenuFrame);
	window.CompactFullscreen = true;
	if modConfigurations.CompactInterface then
		window:SetOpenClosePosition(UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, -1.5, 0));
	else
		window:SetOpenClosePosition(UDim2.new(0.5, 0, 0.5, -35), UDim2.new(0.5, 0, -1.5, 0));
	end
	local initGoldLib = false;
	window.OnWindowToggle:Connect(function(visible, productpageId)
		if visible then
			if initGoldLib == false then
				initGoldLib = true;

				for pageId, pageInfo in pairs(modGoldShopLibrary.Pages) do
					for a=1, #pageInfo do
						local pageDetails = pageInfo[a];
						local pageType = pageDetails.Type;
						if pageType == "Product" then
							local productLib = modGoldShopLibrary.Products:Find(pageDetails.Id);
							productLib.ParentId = pageId;

							if productLib.Product == nil then continue end;
							if productLib.Product.CreatorId then
								task.spawn(function() 
									if nameCaches[productLib.Product.CreatorId] == nil then
										pcall(function()
											productLib.Product.CreatorUsername = game.Players:GetNameFromUserIdAsync(productLib.Product.CreatorId);
										end)
										nameCaches[productLib.Product.CreatorId] = productLib.Product.CreatorUsername;
									else
										productLib.Product.CreatorUsername = nameCaches[productLib.Product.CreatorId];
									end
								end)
							end
						end
					end
				end
			end
			
			Interface:HideAll{[window.Name]=true;};
			Interface.Update();
			
			if productpageId then
				local lib = modGoldShopLibrary.Products:Find(productpageId);
				if lib then
					Interface:LoadProduct(productpageId);
				else
					Interface:LoadPage(productpageId);
				end
			else
				Interface:LoadPage(frontPage);
			end
		end
	end)
	Interface:ConnectQuickButton(goldButton);
	window:AddCloseButton(GoldMenuFrame);
	modKeyBindsHandler:SetDefaultKey("KeyWindowGoldMenu", Enum.KeyCode.K);
	window:SetConfigKey("DisableGoldMenu");
	
	window.OnRefreshFunc = function(visible)
		GoldStatFrame.Visible = goldButton.Visible;
	end
	
	Interface.Garbage:Tag(modData.OnGoldUpdate:Connect(updateGoldStats));
	
	return Interface;
end;

function Interface:Back(clear)
	if #pageHistory > 1 and clear ~= true then
		local pageId = pageHistory[#pageHistory-1];
		
		if pageId == frontPage then
			pageHistory = {};
		else
			table.remove(pageHistory, #pageHistory);
			table.remove(pageHistory, #pageHistory);
		end
		Interface:LoadPage(pageId);
	else
		pageHistory = {};
		Interface:LoadPage(frontPage);
	end
end

local function fetchProductStock()
	Interface.LimitedList = remoteLimitedService:InvokeServer("fetch");
end

function Interface:LoadProduct(productId)
	local lib = modGoldShopLibrary.Products:Find(productId);
	if lib == nil then
		Debugger:Warn("Product",productId,"unavailable.");
		Interface:LoadPage(frontPage);
		return;
	end
	
	for _, obj in pairs(listFrame:GetChildren()) do
		if obj:IsA("GuiObject") then
			obj:Destroy();
		end
	end

	lScrollFrame.Visible = false;
	rScrollFrame.Visible = false;
	listFrame.Visible = true;

	if pageHistory[#pageHistory] ~= productId then
		table.insert(pageHistory, productId);
	end
	local new = templateProduct:Clone();
	new.Size = UDim2.new(1, 0, 0, listFrame.AbsoluteSize.Y-10);

	local infoFrame = new:WaitForChild("infoFrame");
	local descFrame = infoFrame:WaitForChild("descFrame");
	
	local labelFrame = descFrame:WaitForChild("labelFrame");
	local descLabel = labelFrame:WaitForChild("descLabel");
	local showcaseFrame = labelFrame:WaitForChild("showcaseFrame");
	
	local titleImage = descFrame:WaitForChild("titleImage");
	local titleLabel = titleImage:WaitForChild("titleLabel");
	
	local iconButton = new:WaitForChild("iconButton");
	local iconLabel = iconButton:WaitForChild("iconLabel");
	
	local limitedImage = new:WaitForChild("limitedImage");
	local limitedLabel = limitedImage:WaitForChild("limitedLabel");
	
	local purchaseButton = new:WaitForChild("purchaseButton");
	local buttonText = purchaseButton:WaitForChild("buttonText");
	
	local purchaseText = "Loading Product";
	
	local productLib = lib.Product;
	local function refreshPurchaseButton()
		local marketInfo;
		pcall(function()
			local infoType = productLib.Type == "GamePass" and Enum.InfoType.GamePass or Enum.InfoType.Product;
			if productLib.ProductInfoType then
				infoType = productLib.ProductInfoType;
			end
			marketInfo = MarketplaceService:GetProductInfo(productLib.Id, infoType);
		end)
		if marketInfo then 
			if marketInfo.PriceInRobux then
				buttonText.Text = marketInfo.PriceInRobux.." Robux";
			else
				buttonText.Text = "Not On Sale";
			end
			purchaseText = buttonText.Text;

			if productLib.Type == "ThirdParty" then
				local userOwnGamePass;
				pcall(function()
					userOwnGamePass = MarketplaceService:UserOwnsGamePassAsync(localplayer.UserId, productLib.Id);
				end)
				if userOwnGamePass == true then
					buttonText.Text = "Claim Item";
					purchaseText = buttonText.Text;
				end
			end

		else
			buttonText.Text = "Could not load info";

		end
	end
	
	if productLib then
		if productLib.Type == "GamePass" or productLib.Type == "Product" or productLib.Type == "ThirdParty" then
			spawn(refreshPurchaseButton);
			
		elseif productLib.Type == "Gold" then
			if lib.NotForSale == true then
				purchaseText = "Not On Sale";
				
			else
				purchaseText = modFormatNumber.Beautify(productLib.Price).." Gold";
			end
			
		elseif productLib.Type == "Battlepass" then
			purchaseText = modFormatNumber.Beautify(productLib.Price).." Gold";
			
		end
		
		
		if productLib.ShowcaseType then
			local modShowcasing = modShowcases.new(productLib.ShowcaseType, Interface, showcaseFrame, productLib);
		end
	end
	buttonText.Text = purchaseText;
	
	if lib.TitleImage then
		titleImage.Image = lib.TitleImage;
		titleLabel.Text = "";
		
	elseif lib.TitleText then
		titleImage.Image = "nil";
		titleLabel.Text = lib.TitleText;
		
		if lib.Amount then
			titleLabel.Text = titleLabel.Text.." x"..lib.Amount;
		end
		
	end
	
	if lib.LimitedId then
		local stockLeft = Interface.LimitedList[lib.LimitedId] or 0;
		limitedImage.Visible = true;
		descFrame.limitedInfo.Visible = true;
		if stockLeft <= 0 then
			limitedLabel.Text = "Out of stock!"
		else
			limitedLabel.Text = "Limited! ".. (stockLeft > 99 and "?" or stockLeft) .." Left!";
		end
		iconButton.Size = UDim2.new(0.3, 0, 1, -150);
		
	else
		limitedImage.Visible = false;
		descFrame.limitedInfo.Visible = false;
		iconButton.Size = UDim2.new(0.3, 0, 1, -120);
		
	end
	
	if lib.Desc then
		descLabel.Text = lib.Desc;
	else
		descLabel.Text = "No available description.";
	end
	
	if productLib and productLib.ItemId then
		local itemButtonObj = modItemInterface.newItemButton(productLib.ItemId);
		itemButtonObj.ImageButton.Position = iconLabel.Position;
		itemButtonObj.ImageButton.Size = iconLabel.Size;
		itemButtonObj.ImageButton.Parent = iconButton;
		itemButtonObj:Update();
		
		local itemLib = modItemsLibrary:Find(productLib.ItemId);
		--iconLabel.Image = itemLib.Icon
		iconLabel.Visible = false;
		
		descLabel.Text = itemLib.Description.."\n"..(productLib.Desc or "");
		titleImage.Image = "nil";
		titleLabel.Text = lib.TitleText or itemLib.Name;
		if lib.Amount then
			titleLabel.Text = titleLabel.Text.." x"..lib.Amount;
		end
		
		
	elseif lib.Icon then
		iconLabel.Image = lib.Icon;
		
	else
		iconLabel.Image = "";
		
	end
	
	local debounce = false;
	purchaseButton.MouseButton1Click:Connect(function()
		if debounce then return end
		debounce = true;

		Interface:PlayButtonClick();
		if modBranchConfigs.CurrentBranch.Name == "Live" or RunService:IsStudio() or not productLib.Disabled or modGlobalVars.IsCreator(localplayer) or localplayer.UserId == productLib.CreatorId then
			if productLib.Type == "GamePass" then
				MarketplaceService:PromptGamePassPurchase(localplayer, productLib.Id);
				
			elseif productLib.Type == "Product" then
				
				if productLib.Gold and productLib.Gold > 0 and (modData.PlayerGold or 0) + productLib.Gold > 1000000 then
					Interface:PromptWarning("Can not purchase, you will exceed 1 million gold limit.");
					return;
				end
				
				MarketplaceService:PromptProductPurchase(localplayer, productLib.Id);
				
			elseif productLib.Type == "ThirdParty" then
				local result = remoteGoldShopPurchase:InvokeServer(lib.Id);
				
				if result == 0 then
					MarketplaceService:PromptGamePassPurchase(localplayer, productLib.Id);
					buttonText.Text = "Item can be claimed here after purchased.";
					wait(5);
					task.spawn(function()
						for a=1, 60 do
							task.wait(1);
							spawn(refreshPurchaseButton);
							local result = remoteGoldShopPurchase:InvokeServer(lib.Id);
							if result == 1 or result == 4 then
								buttonText.Text = "Thank you for claiming your item!";
								Interface:OpenWindow("Inventory");
								break;
							end
							if GoldMenuFrame.Visible == false then break; end;
						end
					end)
					buttonText.Text = purchaseText;

				elseif result == 1 then
					buttonText.Text = "Thank you for claiming your item!";
					Interface:OpenWindow("Inventory");
					wait(2);
					buttonText.Text = purchaseText;

				elseif result == 4 then
					buttonText.Text = "Already own item!";
					wait(2);
					buttonText.Text = purchaseText;
					
				elseif result == 3 then
					buttonText.Text = "Inventory full!";
					wait(1);
					buttonText.Text = purchaseText;

				else
					buttonText.Text = "An error occured, see chat logs.";
					wait(1);
					buttonText.Text = purchaseText;
					
				end
				
			elseif productLib.Type == "Gold" then
				if lib.NotForSale == true then
					return;
				end
				
				buttonText.Text = "Purchasing...";
				
				local result = remoteGoldShopPurchase:InvokeServer(lib.Id);
				if result == 0 then
					buttonText.Text = "Purchased!";

					if productLib and productLib.ItemId then
						Interface:OpenWindow("Inventory");
					end
					if lib.LimitedId then
						task.spawn(function()
							fetchProductStock();
							Interface:LoadProduct(productId);
						end);
					else
						wait(1);
						buttonText.Text = purchaseText;
					end
					
				elseif result == 1 then
					buttonText.Text = "Not enough Gold!";
					wait(1);
					Interface:LoadPage("GoldPage");
					return;
					
				elseif result == 2 then
					buttonText.Text = "Woah there..";
					wait(1);
					buttonText.Text = purchaseText;
					
				elseif result == 3 then
					buttonText.Text = "Inventory full!";
					wait(1);
					buttonText.Text = purchaseText;
					
				elseif result == 4 then
					buttonText.Text = "Internal error..";
					wait(1);
					buttonText.Text = purchaseText;

				elseif result == 5 then
					buttonText.Text = "Out of stock..";
					wait(3);
					buttonText.Text = purchaseText;
					
				end
				
			elseif productLib.Type == "Battlepass" then

				buttonText.Text = "Purchasing...";

				local result = remoteGoldShopPurchase:InvokeServer(lib.Id);
				if result == 0 then
					buttonText.Text = "Purchased!";

					Interface:OpenWindow("Missions");

				elseif result == 1 then
					buttonText.Text = "Not enough Gold!";
					wait(1);
					Interface:LoadPage("GoldPage");
					return;

				elseif result == 2 then
					buttonText.Text = "Purchase failed!";
					
				end
				
			end
		else
			Interface:PromptWarning("This feature is currently disabled.");
		end
		
		debounce = false;
	end)
	
	new.Parent = listFrame;
	backButton.Visible = #pageHistory > 0;
end


function Interface:LoadPage(pageId)
	local pageInfo = modGoldShopLibrary.Pages[pageId];

	if pageInfo == nil then
		if modGoldShopLibrary.Pages[frontPage] == nil then Debugger:Warn("No front page."); return end;
		Interface:LoadPage(frontPage)
		return;

	end;
	
	local tagsCount = {};
	
	if pageId == "FrontPage" then
		lScrollFrame.Visible = false;
		rScrollFrame.Visible = true;
		listFrame.Visible = false;
		rScrollFrame.Size = UDim2.new(1, 0, 0.9, 0);
		rScrollFrame.UIGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center;
		rScrollFrame.UIGridLayout.CellSize = UDim2.new(0.333, 0, 0.5, 0);
		rScrollFrame.UIPadding.PaddingBottom = UDim.new(0, 0);
	else
		lScrollFrame.Visible = true;
		rScrollFrame.Visible = true;
		listFrame.Visible = false;
		rScrollFrame.Size = UDim2.new(0.8, 0, 0.9, 0);
		rScrollFrame.UIGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left;
		rScrollFrame.UIPadding.PaddingBottom = UDim.new(0, 5);
		
		local margin = math.fmod(rScrollFrame.AbsoluteSize.X, 200)/math.floor(rScrollFrame.AbsoluteSize.X/200);
		rScrollFrame.UIGridLayout.CellSize = UDim2.new(0, 200+margin, 0, 200);
	end
	
	for _, obj in pairs(rScrollFrame:GetChildren()) do
		if obj:IsA("GuiObject") then
			obj:Destroy();
		end
	end
	
	if pageHistory[#pageHistory] ~= pageId then
		table.insert(pageHistory, pageId);
	end
	for a=1, #pageInfo do
		local pageDetails = pageInfo[a];
		local pageType = pageDetails.Type;
		
		local new = templatePageButton:Clone();
		new.LayoutOrder = a;

		local lib;
		if pageType == "Product" then
			lib = modGoldShopLibrary.Products:Find(pageDetails.Id);

			if lib.Product and lib.Product.Type == "GamePass" then
				spawn(function()
					local own = false;
					pcall(function() 
						own = MarketplaceService:UserOwnsGamePassAsync(localplayer.UserId, lib.Product.Id);
					end)
					if own then
						new.LayoutOrder = new.LayoutOrder+100;
					end
				end)
			end

		elseif pageType == "Page" then
			lib = pageDetails;

		end
		
		new.LayoutOrder = pageDetails.Order or new.LayoutOrder;

		local titleImage = new:WaitForChild("titleImage");
		local titleLabel = titleImage:WaitForChild("titleLabel");
		
		local exclaimImage = new:WaitForChild("exclaimImage");
		if pageId == "FrontPage" then
			exclaimImage.Position = UDim2.new(0.1, 0, 0, 0);
		end
		local limitedLabel = new:WaitForChild("limitedLabel");

		local iconButton = new:WaitForChild("iconButton");
		local iconLabel = iconButton:WaitForChild("iconLabel");
		
		local bkFrame = new:WaitForChild("BackgroundFrame");
		
		local productInfo = lib.Product;

		if lib.LoadLimited then
			if modBranchConfigs.CurrentBranch.Name == "Dev" and not RunService:IsStudio() then
				continue;
			end
			task.spawn(fetchProductStock);
		end

		if lib.TitleImage then
			titleImage.Image = lib.TitleImage;
			titleLabel.Text = "";

		elseif lib.TitleText then
			titleImage.Image = "nil";
			titleLabel.Text = lib.TitleText;
			if lib.Amount then
				titleLabel.Text = titleLabel.Text.." x"..lib.Amount;
			end

		end
		
		if lib.LimitedId then
			local stockLeft = Interface.LimitedList[lib.LimitedId] or 0;
			if stockLeft <= 0 then
				limitedLabel.Text = "X"
				limitedLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50);
				exclaimImage.Visible = false;
			else
				limitedLabel.Text = (stockLeft > 99 and "?" or stockLeft);
				limitedLabel.BackgroundColor3 = Color3.fromRGB(255, 162, 0);
				exclaimImage.Visible = true;
			end
			limitedLabel.Visible = true;

		else
			exclaimImage.Visible = false;
			limitedLabel.Visible = false;
		end
		
		if pageDetails.New or lib.New or pageId == "NewItems" then
			exclaimImage.Visible = true;
		end

		local debounce = tick();
		local function onClickFunction()
			if tick()-debounce < 0.2 then return end
			debounce = tick();
			
			Interface:PlayButtonClick();
			if pageType == "Product" then
				Interface:LoadProduct(pageDetails.Id)

			elseif pageType == "Page" then
				Interface:LoadPage(lib.Id);

			end

			debounce = tick()-0.2;
		end
		
		iconButton.MouseButton1Click:Connect(onClickFunction);
		
		if productInfo and productInfo.ItemId then
			
			local itemButtonObj = modItemInterface.newItemButton(productInfo.ItemId);
			itemButtonObj.ImageButton.Position = iconLabel.Position;
			itemButtonObj.ImageButton.Size = iconLabel.Size;
			itemButtonObj.ImageButton.Parent = iconButton;
			itemButtonObj.ImageButton.MouseButton1Click:Connect(onClickFunction);
			itemButtonObj:Update();

			local itemLib = modItemsLibrary:Find(productInfo.ItemId);
			iconLabel.Image = itemLib.Icon;
			
			local tags = modItemsLibrary:GetTags(productInfo.ItemId);
			for b=1, #tags do
				local tag = tags[b];
				if tag == itemLib.Id or tag == itemLib.Name then continue end;
				tagsCount[tag] = (tagsCount[tag] or 0) + 1;
			end
			
			iconLabel.Visible = false;

			titleImage.Image = "nil";
			titleLabel.Text = lib.TitleText or itemLib.Name;
			if lib.Amount then
				titleLabel.Text = titleLabel.Text.." x"..lib.Amount;
			end

		elseif lib.Icon then
			iconLabel.Image = lib.Icon;
		else
			iconLabel.Image = "";
		end

		if productInfo and productInfo.CreatorUsername then
			local name = (productInfo.CreatorUsername):gsub("^%l", string.upper);
			tagsCount[name] = 1;
		end
		
		new.MouseButton1Click:Connect(onClickFunction)
		
		local highlighted = false;
		new.MouseMoved:Connect(function()
			if not highlighted then
				TweenService:Create(bkFrame, TweenInfo.new(0.5), {BackgroundColor3=Color3.fromRGB(60, 60, 60)}):Play();
				TweenService:Create(iconButton, TweenInfo.new(0.5), {Size=UDim2.new(1, 0, 1.2, -35)}):Play();
				highlighted = true;
			end
		end)
		new.MouseLeave:Connect(function()
			if highlighted then
				highlighted = false;
				TweenService:Create(bkFrame, TweenInfo.new(0.5), {BackgroundColor3=Color3.fromRGB(30, 30, 30)}):Play();
				TweenService:Create(iconButton, TweenInfo.new(0.5), {Size=UDim2.new(1, 0, 1, -35)}):Play();
			end
		end)
		
		if exclaimImage.Visible then
			local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true, 0);
			TweenService:Create(exclaimImage, tweenInfo, {ImageTransparency=0.6}):Play();
		end
		
		new.Parent = rScrollFrame;
	end
	backButton.Visible = #pageHistory > 0 and pageId ~= frontPage;
	
	if lScrollFrame.Visible then
		lScrollFrame.SearchBox.Text = "";
		
		for _, obj in pairs(lScrollFrame:GetChildren()) do
			if obj.Name == "searchOption" then
				obj:Destroy();
			end
		end
		
		local debounce = tick();
		for tag, count in pairs(tagsCount) do
			if count <= 0 then continue end;
			
			local newSearch = searchOption:Clone();
			
			newSearch.Text = tag;
			newSearch.Parent = lScrollFrame;
			newSearch.LayoutOrder = 30 + count; -- because some labels are using < 10
			
			newSearch.MouseButton1Click:Connect(function()
				if tick()-debounce < 0.1 then return end;
				debounce=tick();
				lScrollFrame.SearchBox.Text = tag;
			end)
		end

		
		local newSearch = searchOption:Clone();
		newSearch.Text = "All";
		newSearch.Parent = lScrollFrame;
		newSearch.LayoutOrder = 10;

		newSearch.MouseButton1Click:Connect(function()
			if tick()-debounce < 0.1 then return end;
			debounce=tick();
			lScrollFrame.SearchBox.Text = "All";
		end)
		
		local newSearch = searchOption:Clone();
		newSearch.Text = "New";
		newSearch.Parent = lScrollFrame;
		newSearch.LayoutOrder = 11;

		newSearch.MouseButton1Click:Connect(function()
			if tick()-debounce < 0.1 then return end;
			debounce=tick();
			lScrollFrame.SearchBox.Text = "New";
		end)
	end
end

function Interface.RefreshSearch()
	local newText = lScrollFrame.SearchBox.Text;

	local latestPage = pageHistory[#pageHistory];
	
	if #newText <= 0 then 
		Interface:LoadPage(latestPage);
		return 
	end;
	
	
	local latestPageInfo = modGoldShopLibrary.Pages[latestPage];
	
	local depthProductIds = {};
	
	local pagesDone = {};
	local function concatProductsInPages(pageInfo)
		if pageInfo.Type == "Page" then
			local subPageInfo = modGoldShopLibrary.Pages[pageInfo.Id];
			if subPageInfo == nil then return end;
			
			for a=1, #subPageInfo do
				concatProductsInPages(subPageInfo[a]);
			end
			
		elseif pageInfo.Type == "Product" then
			if table.find(depthProductIds, pageInfo.Id) == nil then
				table.insert(depthProductIds, pageInfo.Id);
			end
			
		end
	end
	for a=1, #latestPageInfo do
		concatProductsInPages(latestPageInfo[a]);
	end
	
	for _, obj in pairs(rScrollFrame:GetChildren()) do
		if obj:IsA("GuiObject") then
			obj:Destroy();
		end
	end
	
	for a=1, #depthProductIds do
		local productId = depthProductIds[a];
		local lib = modGoldShopLibrary.Products:Find(productId);
		local productInfo = lib.Product;
		
		local itemLib = productInfo.ItemId and modItemsLibrary:Find(productInfo.ItemId);
		local itemTags = itemLib and modItemsLibrary:GetTags(productInfo.ItemId) or {};

		if lib.LoadLimited then
			if modBranchConfigs.CurrentBranch.Name == "Dev" and not RunService:IsStudio() then
				continue;
			end
			task.spawn(fetchProductStock);
		end
		
		local new = rScrollFrame:FindFirstChild(productId) or templatePageButton:Clone();
		new.Visible = false;
		new.Name = productId;
		new.LayoutOrder = a;
		
		local matchSearch = false;
		if string.lower(newText) == "all" then
			matchSearch = true;
			
		elseif productInfo.New and string.lower(newText) == "new" then
			matchSearch = true;
			
		elseif productInfo.CreatorUsername and string.match( string.lower(productInfo.CreatorUsername), string.lower(newText) ) then
			matchSearch = true;
			
		elseif string.match(productId, string.lower(newText)) then
			matchSearch = true;
			
		elseif lib.TitleText and string.match( string.lower(lib.TitleText), string.lower(newText) ) then
			matchSearch = true;
			
		elseif tonumber(newText) and tonumber(newText) > productInfo.Price then
			matchSearch = true;
			
		elseif itemLib and (string.match(string.lower(itemLib.Name), string.lower(newText)) or string.match(string.lower(itemLib.Description), string.lower(newText))) then
			matchSearch = true;
			
		elseif productInfo.ParentId and string.match( string.lower(productInfo.ParentId), string.lower(newText) ) then
			matchSearch = true;
			
		else
			for b=1, #itemTags do
				if string.match(string.lower(itemTags[b]), string.lower(newText)) then
					matchSearch = true;
					break;
				end
			end
			
		end
		
		new.Visible = matchSearch;
		
		if lib.Product and lib.Product.Type == "GamePass" then
			spawn(function()
				local own = false;
				pcall(function() 
					own = MarketplaceService:UserOwnsGamePassAsync(localplayer.UserId, lib.Product.Id);
				end)
				if own then
					new.iconButton.ImageColor3 = Color3.fromRGB(50, 50, 50);
				end
			end)
		end
		

		local titleImage = new:WaitForChild("titleImage");
		local titleLabel = titleImage:WaitForChild("titleLabel");

		local exclaimImage = new:WaitForChild("exclaimImage");
		local limitedLabel = new:WaitForChild("limitedLabel");

		local iconButton = new:WaitForChild("iconButton");
		local iconLabel = iconButton:WaitForChild("iconLabel");

		local bkFrame = new:WaitForChild("BackgroundFrame");

		if lib.TitleImage then
			titleImage.Image = lib.TitleImage;
			titleLabel.Text = "";

		elseif lib.TitleText then
			titleImage.Image = "nil";
			titleLabel.Text = lib.TitleText;
			if lib.Amount then
				titleLabel.Text = titleLabel.Text.." x"..lib.Amount;
			end

		end

		if lib.LimitedId then
			local stockLeft = Interface.LimitedList[lib.LimitedId] or 0;
			if stockLeft <= 0 then
				limitedLabel.Text = "X"
				limitedLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50);
				exclaimImage.Visible = false;
			else
				limitedLabel.Text = (stockLeft > 99 and "?" or stockLeft);
				limitedLabel.BackgroundColor3 = Color3.fromRGB(255, 162, 0);
				exclaimImage.Visible = true;
			end
			limitedLabel.Visible = true;

		else
			exclaimImage.Visible = false;
			limitedLabel.Visible = false;
		end

		if productInfo.New then
			exclaimImage.Visible = true;
		end
		
		local debounce = tick();
		local function onClickFunction()
			if tick()-debounce < 0.1 then return end 
			debounce = tick();

			Interface:PlayButtonClick();
			Interface:LoadProduct(productId);

			debounce = tick()-0.1;
		end

		iconButton.MouseButton1Click:Connect(onClickFunction);

		if productInfo.ItemId then
			
			local itemButtonObj = modItemInterface.newItemButton(productInfo.ItemId);
			itemButtonObj.ImageButton.Position = iconLabel.Position;
			itemButtonObj.ImageButton.Size = iconLabel.Size;
			itemButtonObj.ImageButton.Parent = iconButton;
			itemButtonObj.ImageButton.MouseButton1Click:Connect(onClickFunction);
			itemButtonObj:Update();

			local itemLib = modItemsLibrary:Find(productInfo.ItemId);
			iconLabel.Image = itemLib.Icon;

			iconLabel.Visible = false;

			titleImage.Image = "nil";
			titleLabel.Text = lib.TitleText or itemLib.Name;
			if lib.Amount then
				titleLabel.Text = titleLabel.Text.." x"..lib.Amount;
			end

		elseif lib.Icon then
			iconLabel.Image = lib.Icon;
		else
			iconLabel.Image = "";
		end

		new.MouseButton1Click:Connect(onClickFunction)

		local highlighted = false;
		new.MouseMoved:Connect(function()
			if not highlighted then
				TweenService:Create(bkFrame, TweenInfo.new(0.5), {BackgroundColor3=Color3.fromRGB(60, 60, 60)}):Play();
				TweenService:Create(iconButton, TweenInfo.new(0.5), {Size=UDim2.new(1, 0, 1.2, -35)}):Play();
				highlighted = true;
			end
		end)
		new.MouseLeave:Connect(function()
			if highlighted then
				highlighted = false;
				TweenService:Create(bkFrame, TweenInfo.new(0.5), {BackgroundColor3=Color3.fromRGB(30, 30, 30)}):Play();
				TweenService:Create(iconButton, TweenInfo.new(0.5), {Size=UDim2.new(1, 0, 1, -35)}):Play();
			end
		end)

		if exclaimImage.Visible then
			local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true, 0);
			TweenService:Create(exclaimImage, tweenInfo, {ImageTransparency=0.6}):Play();
		end

		new.Parent = rScrollFrame;
	end
	
end


function Interface.Update()

end

local function updateScrollIndicator()
	downIndicator.Visible = rScrollFrame.CanvasPosition.Y < (rScrollFrame.CanvasSize.Y.Offset - rScrollFrame.AbsoluteWindowSize.Y)-1;
	upIndicator.Visible = rScrollFrame.CanvasPosition.Y > 0;
end

backButton.MouseButton1Click:Connect(function()
	Interface:PlayButtonClick();
	Interface:Back();
	updateScrollIndicator();
end)
backButton.MouseMoved:Connect(function()
	backButton.ImageColor3 = modBranchConfigs.CurrentBranch.Color;
end)
backButton.MouseLeave:Connect(function()
	backButton.ImageColor3 = Color3.fromRGB(255,255,255);
end)

lScrollFrame:WaitForChild("SearchBox"):WaitForChild("ClearButton").MouseButton1Click:Connect(function()
	lScrollFrame.SearchBox.Text = "";
end)

rScrollFrame.UIGridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	local showScrollBars = modData.Settings and modData.Settings.ShowScrollbars == 1 or false;
	rScrollFrame.ScrollBarThickness = showScrollBars and 5 or 0;
	updateScrollIndicator();
end)

rScrollFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
	updateScrollIndicator();
end)

lScrollFrame:WaitForChild("SearchBox"):GetPropertyChangedSignal("Text"):Connect(function()
	Interface.RefreshSearch();
end)

return Interface;