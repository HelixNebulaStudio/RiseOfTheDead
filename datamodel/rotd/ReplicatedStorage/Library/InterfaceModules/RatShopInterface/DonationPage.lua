local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local PageInterface = {};
PageInterface.__index = PageInterface;

local MarketplaceService = game:GetService("MarketplaceService");

local templateDonateOption = script:WaitForChild("donateGoldButton");
local templatesupportMessage = script:WaitForChild("supportMessage");

local localplayer = game.Players.LocalPlayer;
local modData = shared.require(localplayer:WaitForChild("DataModule"));

local localplayer = game.Players.LocalPlayer;

local modShopLibrary = shared.require(game.ReplicatedStorage.Library.RatShopLibrary);
local modGoldShopLibrary = shared.require(game.ReplicatedStorage.Library.GoldShopLibrary);
local modFormatNumber = shared.require(game.ReplicatedStorage.Library.FormatNumber);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modLeaderboardService = shared.require(game.ReplicatedStorage.Library.LeaderboardService);

local modLeaderboardInterface = shared.require(game.ReplicatedStorage.Library.UI.LeaderboardInterface);

local remoteGoldDonate = modRemotesManager:Get("GoldDonate");
--==
local donateOptions = {
	modGoldShopLibrary.Products:Find("250gold");
	modGoldShopLibrary.Products:Find("500gold");
	modGoldShopLibrary.Products:Find("1000gold");
	modGoldShopLibrary.Products:Find("5000gold");
	modGoldShopLibrary.Products:Find("10000gold");
	
	{Product={Gold=25000;};};
	{Product={Gold=50000;};};
}

function PageInterface:Load(interface)
	local keyTable = {
		StatName="Gold";
		AllTimeTableKey="AllTimeGoldDonor";
		YearlyTableKey="YearlyGoldDonor";
		SeasonlyTableKey="SeasonlyGoldDonor";
		MonthlyTableKey="MonthlyGoldDonor";
		WeeklyTableKey="WeeklyGoldDonor";
		DailyTableKey="DailyGoldDonor";
	};
	
	modLeaderboardService.ClientSyncRequest();
	local newLeaderboard = modLeaderboardInterface.new(keyTable);
	newLeaderboard.Frame.Parent = interface.PageFrame;
	
	local leaderboardFrame = newLeaderboard.Frame;
	local purchaseFrame = leaderboardFrame:WaitForChild("Frame"):WaitForChild("purchase");
	purchaseFrame.Visible = true;
	local purchaseCell = purchaseFrame:WaitForChild("purchaseCell");
	
	local frameSizeConstraint = purchaseFrame:WaitForChild("UISizeConstraint");
	local maxSize = math.ceil(leaderboardFrame.AbsoluteSize.X*0.3);
	
	if purchaseCell.AbsoluteSize.X >= maxSize then
		frameSizeConstraint.MinSize = Vector2.new(maxSize, 0);
		frameSizeConstraint.MaxSize = Vector2.new(maxSize, math.huge);
	end
	
	local function promptDonate(optionInfo)
		local opTitle = modFormatNumber.Beautify(optionInfo.Product.Gold) .." Gold";
		
		local promptWindow = interface:PromptQuestion("Donate ".. modFormatNumber.Beautify(optionInfo.Product.Gold),
			("Are you sure you want to donate "..opTitle.." to this project?"), 
			"Donate", "Cancel", optionInfo.Icon);
		local YesClickedSignal, NoClickedSignal;

		YesClickedSignal = promptWindow.Frame.Yes.MouseButton1Click:Connect(function()
			interface:PlayButtonClick();

			promptWindow.Frame.Yes.buttonText.Text = "Donating";

			local serverReply = remoteGoldDonate:InvokeServer(optionInfo.Id);
			if serverReply == modShopLibrary.PurchaseReplies.Success then
				promptWindow.Frame.Yes.buttonText.Text = "Donated!";
				wait(0.5);
				interface:OpenWindow("RatShopWindow");
			else
				warn("Sell Item>> Error Code:"..serverReply);
				promptWindow.Frame.Yes.buttonText.Text = (modShopLibrary.PurchaseReplies[serverReply] or ("Error Code: "..serverReply));
			end

			promptWindow:Close();
			interface:OpenWindow("RatShopWindow");
			YesClickedSignal:Disconnect();
			NoClickedSignal:Disconnect();
		end);
		NoClickedSignal = promptWindow.Frame.No.MouseButton1Click:Connect(function()
			interface:PlayButtonClick();
			promptWindow:Close();
			interface:OpenWindow("RatShopWindow");
			YesClickedSignal:Disconnect();
			NoClickedSignal:Disconnect();
		end);
	end
	
	local purchaseDebounce = false;
	
	local suppMsg = templatesupportMessage:Clone();
	suppMsg.Parent = purchaseCell;
	
	for a=1, #donateOptions do
		local optionInfo = donateOptions[a];
		local opTitle = modFormatNumber.Beautify(optionInfo.Product.Gold) .." Gold";
		
		local new = templateDonateOption:Clone();
		new.Parent = purchaseCell;
		local goldLabel = new:WaitForChild("goldLabel");
		goldLabel.Text = opTitle;
		
		new.MouseButton1Click:Connect(function()
			if purchaseDebounce then return end;
			purchaseDebounce = true;

			local playerGold = modData.Profile and modData.Profile.Trader and modData.Profile.Trader.Gold or 0;
			if playerGold >= optionInfo.Product.Gold then
				promptDonate(optionInfo);
				
			else
				if optionInfo.Product.Id then
					MarketplaceService:PromptProductPurchase(localplayer, optionInfo.Product.Id);
					
				else
					interface:PromptWarning("Insufficient Gold!");
					
				end
				
			end
			purchaseDebounce = false;
		end)
	end
end

return PageInterface;