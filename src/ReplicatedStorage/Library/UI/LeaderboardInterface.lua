local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local LeaderboardInterface = {}
LeaderboardInterface.__index = LeaderboardInterface;

local RunService = game:GetService("RunService");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modLeaderboardService = require(game.ReplicatedStorage.Library.LeaderboardService);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modFormatNumber = require(game.ReplicatedStorage.Library.FormatNumber);

local templateLeaderboardFrame = script:WaitForChild("LeaderboardFrame");
local templateUserListing = script:WaitForChild("userListing");

local templateToggleButton = script:WaitForChild("leaderboardButton");

local localplayer = game.Players.LocalPlayer;

local modInterface;

local rankColors = {
	Color3.fromRGB(255, 220, 112);
	Color3.fromRGB(255, 255, 255);
	Color3.fromRGB(181, 99, 85);
	Color3.fromRGB(170, 170, 170);
};

local loadingKey = 0;
--== Script;
function LeaderboardInterface.SetModInterface(interface)
	modInterface = interface;
end

function LeaderboardInterface:AddToggleButton()
	local new = templateToggleButton:Clone();
	
	new.MouseButton1Click:Connect(function()
		modInterface:PlayButtonClick();
		self.Frame.Visible = not self.Frame.Visible;
		
		new.ImageColor3 = self.Frame.Visible and Color3.fromRGB(1, 162, 254) or Color3.fromRGB(255, 255, 255);
	end)
	
	new.Parent = self.Frame.Parent;
	self.ToggleButton = new;
	return new;
end

function LeaderboardInterface.new(keyTable, defaultAb)
	if modInterface == nil then return end;
	
	local self = {};
	
	local newLeaderboard = templateLeaderboardFrame:Clone();

	local hintLabel = newLeaderboard:WaitForChild("hintLabel");
	local boardCell = newLeaderboard:WaitForChild("Frame"):WaitForChild("board"):WaitForChild("boardCell");
	local optionFrame = newLeaderboard:WaitForChild("options");
	local tableLayout = optionFrame:WaitForChild("UITableLayout");
	local allTimeTopButton = optionFrame:WaitForChild("allTimeOption"):WaitForChild("allTimeTop");
	local yearlyTopButton = optionFrame:WaitForChild("yearlyOption"):WaitForChild("yearlyTop");
	local seasonlyTopButton = optionFrame:WaitForChild("seasonlyOption"):WaitForChild("seasonlyTop");
	local monthlyTopButton = optionFrame:WaitForChild("monthlyOption"):WaitForChild("monthlyTop");
	local weeklyTopButton = optionFrame:WaitForChild("weeklyOption"):WaitForChild("weeklyTop");
	local dailyTopButton = optionFrame:WaitForChild("dailyOption"):WaitForChild("dailyTop");
	
	local statName = keyTable.StatName;
	
	local activeBoard = defaultAb or "Daily";

	local function refresh()
		tableLayout.Padding = UDim2.new(0, 6, 0, 0);

		if activeBoard == "Daily" then
			local timeLeft = modSyncTime.TimeOfEndOfDay()-modSyncTime.GetTime();
			hintLabel.Text = "Daily board resets in "..modSyncTime.ToString(timeLeft);
			
		elseif activeBoard == "Weekly" then
			local timeLeft = modSyncTime.TimeOfEndOfWeek()-modSyncTime.GetTime();
			hintLabel.Text = "Weekly board resets in "..modSyncTime.ToString(timeLeft);
			
		elseif activeBoard == "Monthly" then
			local timeLeft = modSyncTime.TimeOfEndOfMonth()-modSyncTime.GetTime();
			hintLabel.Text = "Monthly board resets in "..modSyncTime.ToString(timeLeft);

		elseif activeBoard == "Seasonly" then
			local timeLeft = modSyncTime.TimeOfEndOfSeason()-modSyncTime.GetTime();
			hintLabel.Text = "Seasonly board resets in "..modSyncTime.ToString(timeLeft);

		elseif activeBoard == "Yearly" then
			local timeLeft = modSyncTime.TimeOfEndOfYear()-modSyncTime.GetTime();
			hintLabel.Text = "Yearly board resets in "..modSyncTime.ToString(timeLeft);
			
		else
			hintLabel.Text = "";
			
		end
	end
	
	local function loadLeaderboard(boardTable)
		boardCell.CanvasPosition = Vector2.new();
		
		local newLoadingKey = loadingKey;
		for _, obj in pairs(boardCell:GetChildren()) do
			if obj:IsA("GuiObject") then
				obj:Destroy();
			end
		end
		
		refresh();
		local header = templateUserListing:Clone();
		header.Parent = boardCell;
		header.LayoutOrder = 0;
		local valueTagHeader = header:WaitForChild("valueFrame"):WaitForChild("valueTag");
		valueTagHeader.Text = statName;
		
		local isDevBranch = (modBranchConfigs.CurrentBranch.Name == "Dev" and not RunService:IsStudio());
		
		for a=1, #boardTable do
			local info = boardTable[a];
			local name = info.Title;
			local avatar = info.Avatar or (info.Icon and "rbxassetid://"..info.Icon);
			local valueStat = info.Value;
			local rank = info.Rank or "";
			
			local new = templateUserListing:Clone();
			local nameTag = new:WaitForChild("nameFrame"):WaitForChild("nameTag");
			local avatarTag = nameTag:WaitForChild("avatarTag");
			local posTag = new:WaitForChild("posFrame"):WaitForChild("posTag");
			local valueTag = new:WaitForChild("valueFrame"):WaitForChild("valueTag");
			
			nameTag.Text = isDevBranch and "[Failed to Load]" or name:sub(1, 1):upper()..name:sub(2, #name);
			if avatar then
				avatarTag.Image = avatar;
				
				if info.Color then
					avatarTag.ImageColor3 = Color3.fromHex(info.Color);
				end
			end
			avatarTag.Visible = true;
			valueTag.Text = modFormatNumber.Beautify(math.floor(valueStat));
			posTag.Text = (modBranchConfigs.CurrentBranch.Name == "Dev" and "DB " or "")..a; --rank;
			
			local textColor = rankColors[a] or Color3.fromRGB(170, 170, 170);
			nameTag.TextColor3 = textColor;
			valueTag.TextColor3 = textColor;
			posTag.TextColor3 = textColor;
			
			local backgroundColor = name == localplayer.Name and Color3.fromRGB(20, 0, 0) or Color3.fromRGB(0, 0, 0);
			nameTag.Parent.BackgroundColor3 = backgroundColor;
			valueTag.Parent.BackgroundColor3 = backgroundColor;
			posTag.Parent.BackgroundColor3 = backgroundColor;
			
			new.Parent = boardCell;
			
			task.wait(1/30);
			if newLoadingKey ~= loadingKey then break; end;
		end
	end
	
	if keyTable.AllTimeTableKey then
		allTimeTopButton.Parent.Visible = true;
		allTimeTopButton.MouseButton1Click:Connect(function()
			loadingKey = loadingKey +1;
			modInterface:PlayButtonClick();
			activeBoard = "AllTime";
			loadLeaderboard(modLeaderboardService:GetTable(keyTable.AllTimeTableKey));
		end)
		activeBoard = "AllTime";
	else
		allTimeTopButton.Parent.Visible = false;
	end
	
	if keyTable.YearlyTableKey then
		yearlyTopButton.Parent.Visible = true;
		yearlyTopButton.MouseButton1Click:Connect(function()
			loadingKey = loadingKey +1;
			modInterface:PlayButtonClick();
			activeBoard = "Yearly";
			loadLeaderboard(modLeaderboardService:GetTable(keyTable.YearlyTableKey)); 
		end)
		activeBoard = "Yearly";
	else
		yearlyTopButton.Parent.Visible = false;
	end

	if keyTable.SeasonlyTableKey then
		seasonlyTopButton.Parent.Visible = true;
		seasonlyTopButton.MouseButton1Click:Connect(function()
			loadingKey = loadingKey +1;
			modInterface:PlayButtonClick();
			activeBoard = "Seasonly";
			loadLeaderboard(modLeaderboardService:GetTable(keyTable.SeasonlyTableKey)); 
		end)
		activeBoard = "Seasonly";
	else
		seasonlyTopButton.Parent.Visible = false;
	end

	if keyTable.MonthlyTableKey then
		monthlyTopButton.Parent.Visible = true;
		monthlyTopButton.MouseButton1Click:Connect(function()
			loadingKey = loadingKey +1;
			modInterface:PlayButtonClick();
			activeBoard = "Monthly";
			loadLeaderboard(modLeaderboardService:GetTable(keyTable.MonthlyTableKey)); 
		end)
		activeBoard = "Monthly";
	else
		monthlyTopButton.Parent.Visible = false;
	end

	if keyTable.WeeklyTableKey then
		weeklyTopButton.Parent.Visible = true;
		weeklyTopButton.MouseButton1Click:Connect(function()
			loadingKey = loadingKey +1;
			modInterface:PlayButtonClick();
			activeBoard = "Weekly";
			loadLeaderboard(modLeaderboardService:GetTable(keyTable.WeeklyTableKey)); 
		end)
		activeBoard = "Weekly";
	else
		weeklyTopButton.Parent.Visible = false;
	end

	if keyTable.DailyTableKey then
		dailyTopButton.Parent.Visible = true;
		dailyTopButton.MouseButton1Click:Connect(function()
			loadingKey = loadingKey +1;
			modInterface:PlayButtonClick();
			activeBoard = "Daily";
			loadLeaderboard(modLeaderboardService:GetTable(keyTable.DailyTableKey));
		end)
		activeBoard = "Daily";
	else
		dailyTopButton.Parent.Visible = false;
	end
	
	local clockHook = modSyncTime.GetClock():GetPropertyChangedSignal("Value"):Connect(refresh);
	newLeaderboard.AncestryChanged:Connect(function(c, p)
		if c == newLeaderboard and p == nil then
			if clockHook then clockHook:Disconnect(); end;
		end
	end)

	spawn(function()
		if keyTable.DailyTableKey then
			loadLeaderboard(modLeaderboardService:GetTable(keyTable.DailyTableKey));
			
		elseif keyTable.WeeklyTableKey then
			loadLeaderboard(modLeaderboardService:GetTable(keyTable.WeeklyTableKey));

		elseif keyTable.MonthlyTableKey then
			loadLeaderboard(modLeaderboardService:GetTable(keyTable.MonthlyTableKey));

		elseif keyTable.SeasonlyTableKey then
			loadLeaderboard(modLeaderboardService:GetTable(keyTable.SeasonlyTableKey));

		elseif keyTable.YearlyTableKey then
			loadLeaderboard(modLeaderboardService:GetTable(keyTable.YearlyTableKey));

		elseif keyTable.AllTimeTableKey then
			loadLeaderboard(modLeaderboardService:GetTable(keyTable.AllTimeTableKey));

		end
	end)
	
	function self:SetActiveBoard(aB)
		loadingKey = loadingKey +1;
		activeBoard = aB;
		self:Refresh();
	end
	
	function self:Refresh()
		if activeBoard == "AllTime" and keyTable.AllTimeTableKey then
			loadLeaderboard(modLeaderboardService:GetTable(keyTable.AllTimeTableKey));
			
		elseif activeBoard == "Yearly" and keyTable.YearlyTableKey then
			loadLeaderboard(modLeaderboardService:GetTable(keyTable.YearlyTableKey));
			
		elseif activeBoard == "Seasonly" and keyTable.SeasonlyTableKey then
			loadLeaderboard(modLeaderboardService:GetTable(keyTable.SeasonlyTableKey));
			
		elseif activeBoard == "Monthly" and keyTable.MonthlyTableKey then
			loadLeaderboard(modLeaderboardService:GetTable(keyTable.MonthlyTableKey));

		elseif activeBoard == "Weekly" and keyTable.WeeklyTableKey then
			loadLeaderboard(modLeaderboardService:GetTable(keyTable.WeeklyTableKey));
			
		elseif activeBoard == "Daily" and keyTable.DailyTableKey then
			loadLeaderboard(modLeaderboardService:GetTable(keyTable.DailyTableKey));
			
		end
	end
	
	self.Frame = newLeaderboard;
	
	setmetatable(self, LeaderboardInterface);
	return self;
end

return LeaderboardInterface;