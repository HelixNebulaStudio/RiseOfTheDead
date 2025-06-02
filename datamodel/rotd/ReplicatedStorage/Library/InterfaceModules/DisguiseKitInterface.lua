local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface = {};

local CollectionService = game:GetService("CollectionService");
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;
local modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
local modGlobalVars = shared.require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modPlayers = shared.require(game.ReplicatedStorage.Library.Players);
local modDisguiseMechanics = shared.require(game.ReplicatedStorage.Library.DisguiseMechanics);

local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

--== Script;
function Interface.init(modInterface)
	setmetatable(Interface, modInterface);
	
	local templateButton = script:WaitForChild("templateButton");
	local windowFrameTemplate = script:WaitForChild("DisguiseKit");

	local remoteDisguiseKitRemote = modRemotesManager:Get("DisguiseKitRemote");

	local windowFrame = windowFrameTemplate:Clone();
	windowFrame.Parent = modInterface.MainInterface;
	
	local scrollingFrame = windowFrame:WaitForChild("ScrollingFrame");
	local listLayout = scrollingFrame:WaitForChild("UIListLayout");
	local killsLabel = windowFrame:WaitForChild("killsLabel");

	local storageItem;
	local window = Interface.NewWindow("DisguiseKit", windowFrame);
	window.CompactFullscreen = true;
	window:SetOpenClosePosition(UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, -1.5, 0));
	window.OnWindowToggle:Connect(function(visible, storageItem)
		if visible then
			Interface:HideAll{[window.Name]=true;};
			spawn(function()
				remoteDisguiseKitRemote:InvokeServer(storageItem.ID, "open");
			end)
			Interface.Update(storageItem);
		end
	end)
	windowFrame:WaitForChild("TitleFrame"):WaitForChild("touchCloseButton"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
		Interface:CloseWindow("DisguiseKit");
	end)
		
	window:AddCloseButton(windowFrame);

	function Interface.Update(si)
		storageItem = modData.GetItemById(si.ID);
		if storageItem == nil then 
			Interface:CloseWindow("DisguiseKit");
			return;
		end;
		
		local playerKills = modData.GameSave and modData.GameSave.Stats and modData.GameSave.Stats.Kills;
		local initKills = storageItem.Values.InitKills;
		local unlockedDisguises = storageItem.Values.Disguises or {};
		
		killsLabel.Text = "Kills: "..(initKills and math.clamp(playerKills-initKills, 0, 5000) or 0);
		
		for _, obj in pairs(scrollingFrame:GetChildren()) do
			local disguiseLib = modDisguiseMechanics.Library:Find(obj.Name);
			if obj:IsA("ImageButton") and disguiseLib then
				local label = obj:WaitForChild("buttonText");
				
				if disguiseLib.Price == nil or unlockedDisguises[disguiseLib.Id] then
					label.Text = disguiseLib.Name;
					obj.ImageColor3 = Color3.fromRGB(100, 100, 100);
					
				else
					label.Text = "Locked - "..disguiseLib.Name.." ("..disguiseLib.Price.." Kills or Gold)";
					obj.ImageColor3 = Color3.fromRGB(50, 50, 50);
					
				end
			end
		end
		
	end
	
	for order, disguiseLib in pairs(modDisguiseMechanics.Library:GetIndexList()) do
		local id = disguiseLib.Id;
		
		local new = templateButton:Clone();
		new.Parent = scrollingFrame;
		new.Name = id;
		new.LayoutOrder= order;
		local text = new:WaitForChild("buttonText");
		text.Text = disguiseLib.Name;
		
		local debounce = false;
		new.MouseButton1Click:Connect(function()
			if storageItem == nil then return end;
			local unlockedDisguises = storageItem.Values.Disguises or {};
			
			if disguiseLib.Price == nil or unlockedDisguises[disguiseLib.Id] then
				remoteDisguiseKitRemote:InvokeServer(storageItem.ID, "disguise", disguiseLib.Id);
				
			else
				local playerGold = modData.PlayerGold or 0;
				local currency = "Kills";
				
				local function purchase()
					local promptWindow = modClientGuis.promptQuestion("Unlock Disguise", 
						"Are you sure you want to unlock ("..disguiseLib.Name..") for "..
							(currency == "Gold" and "<b><font color='rgb(170, 120, 0)'>" or "")..disguiseLib.Price.." "..currency.."?"..
							(currency == "Gold" and "</font></b>" or ""));
					local YesClickedSignal, NoClickedSignal;

					YesClickedSignal = promptWindow.Frame.Yes.MouseButton1Click:Connect(function()
						if debounce then return end;
						debounce = true;
						Interface:PlayButtonClick();
						local r = remoteDisguiseKitRemote:InvokeServer(storageItem.ID, "purchase"..currency, disguiseLib.Id);
						if r == 1 then
							promptWindow.Frame.Yes.buttonText.Text = "Disguise unlocked";

						elseif r == 2 then
							promptWindow.Frame.Yes.buttonText.Text = "Already purchased";

						elseif r == 3 then
							promptWindow.Frame.Yes.buttonText.Text = "Not enough "..currency;

						end
						wait(1.6);
						debounce = false;
						promptWindow:Close();
						Interface:OpenWindow("DisguiseKit", storageItem);
						YesClickedSignal:Disconnect();
						NoClickedSignal:Disconnect();
					end);
					NoClickedSignal = promptWindow.Frame.No.MouseButton1Click:Connect(function()
						if debounce then return end;
						Interface:PlayButtonClick();
						promptWindow:Close();
						Interface:OpenWindow("DisguiseKit", storageItem);
						YesClickedSignal:Disconnect();
						NoClickedSignal:Disconnect();
					end);
				end
				
				if playerGold >= disguiseLib.Price then
					local promptWindow = modClientGuis.promptQuestion(
						"Unlock Disguise", 
						"Do you want to unlock ("..disguiseLib.Name..") with Kills or <b><font color='rgb(170, 120, 0)'>Gold</font></b>?",
						"Kills",
						"Gold");
					local YesClickedSignal, NoClickedSignal;

					YesClickedSignal = promptWindow.Frame.Yes.MouseButton1Click:Connect(function()
						if debounce then return end;
						debounce = true;
						Interface:PlayButtonClick();
						currency = "Kills";
						YesClickedSignal:Disconnect();
						NoClickedSignal:Disconnect();
						purchase();
						wait(0.2);
						debounce = false;
					end);
					
					promptWindow.Frame.No.ImageColor3 = Color3.fromRGB(206, 120, 0);
					NoClickedSignal = promptWindow.Frame.No.MouseButton1Click:Connect(function()
						if debounce then return end;
						Interface:PlayButtonClick();
						promptWindow:Close();
						currency = "Gold";
						YesClickedSignal:Disconnect();
						NoClickedSignal:Disconnect();
						purchase();
						wait(0.2);
						debounce = false;
					end);
					
				else
					purchase();
				end
			end
		end)
	end

	--Interface.Garbage:Tag();
	
	return Interface;
end;

return Interface;