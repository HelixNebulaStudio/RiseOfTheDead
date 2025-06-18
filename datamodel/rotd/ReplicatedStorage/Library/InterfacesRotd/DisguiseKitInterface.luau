local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modGlobalVars = shared.require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modDisguiseMechanics = shared.require(game.ReplicatedStorage.Library.DisguiseMechanics);

local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);


local interfacePackage = {
    Type = "Character";
};
--==


function interfacePackage.newInstance(interface: InterfaceInstance)
	local remoteDisguiseKitRemote = modRemotesManager:Get("DisguiseKitRemote");
    local modData = shared.require(localPlayer:WaitForChild("DataModule"));

    local templateButton = script:WaitForChild("templateButton");
        
	local windowFrame = script:WaitForChild("DisguiseKit"):Clone();
	windowFrame.Parent = interface.ScreenGui;
	
	local scrollingFrame = windowFrame:WaitForChild("ScrollingFrame");
	local killsLabel = windowFrame:WaitForChild("killsLabel");

	local activeStorageItem: StorageItem;
	local window: InterfaceWindow = interface:NewWindow("DisguiseKit", windowFrame);
	window.CompactFullscreen = true;
    window.CloseWithInteract = true;
    window.DisableInteractables = true;
	window:SetClosePosition(UDim2.new(0.5, 0, -1.5, 0), UDim2.new(0.5, 0, 0.5, 0));

    --MARK: OnToggle
	window.OnToggle:Connect(function(visible, storageItem)
        if storageItem then
            activeStorageItem = storageItem;
        end
		if visible then
			interface:HideAll{[window.Name]=true;};
			spawn(function()
				remoteDisguiseKitRemote:InvokeServer(storageItem.ID, "open");
			end)
            window:Update();
		end
	end)
	windowFrame:WaitForChild("TitleFrame"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
		window:Close();
	end)
		
    --MARK: OnUpdate
    window.OnUpdate:Connect(function() 
		if activeStorageItem == nil then
            window:Close();
			return;
		end;
		
		local playerKills = modData.GameSave and modData.GameSave.Stats and modData.GameSave.Stats.Kills;
		local initKills = activeStorageItem:GetValues("InitKills");
		local unlockedDisguises = activeStorageItem:GetValues("Disguises") or {};
		
        Debugger:StudioLog(`Unlocked Disguise`, tostring(activeStorageItem), activeStorageItem);

		killsLabel.Text = `Kills: {(initKills and math.clamp(playerKills-initKills, 0, 5000) or 0)}/5000`;
		
		for _, obj in pairs(scrollingFrame:GetChildren()) do
			local disguiseLib = modDisguiseMechanics.Library:Find(obj.Name);
			if not obj:IsA("ImageButton") or disguiseLib == nil then continue end;
            local label = obj:WaitForChild("buttonText");
            
            if disguiseLib.Price == nil or unlockedDisguises[disguiseLib.Id] then
                label.Text = disguiseLib.Name;
                obj.ImageColor3 = Color3.fromRGB(100, 100, 100);
                
            else
                label.Text = "Locked - "..disguiseLib.Name.." ("..disguiseLib.Price.." Kills or Gold)";
                obj.ImageColor3 = Color3.fromRGB(50, 50, 50);
                
            end
		end
    end)
	
	for order, disguiseLib in pairs(modDisguiseMechanics.Library:GetIndexList()) do
		local id = disguiseLib.Id;
		
		local new = templateButton:Clone();
		new.Parent = scrollingFrame;
		new.Name = id;
		new.LayoutOrder= order;
		local text = new:WaitForChild("buttonText");
		text.Text = disguiseLib.Name;
		
		new.MouseButton1Click:Connect(function()
			if activeStorageItem == nil then return end;
			local unlockedDisguises = activeStorageItem.Values.Disguises or {};
			
			if disguiseLib.Price == nil or unlockedDisguises[disguiseLib.Id] then
				remoteDisguiseKitRemote:InvokeServer(activeStorageItem.ID, "disguise", disguiseLib.Id);
				return;
            end


            local playerGold = modData.PlayerGold or 0;
            local currency = "Kills";
            
            local function purchase()
                local desc = `Are you sure you want to unlock ({disguiseLib.Name}) for `..
                            `{(currency == "Gold" and "<b><font color='rgb(170, 120, 0)'>" or "")}{disguiseLib.Price} {currency}?`..
                            (currency == "Gold" and "</font></b>" or "");

                modClientGuis.promptDialogBox({
                    Title=`Unlock Disguise`;
                    Desc=desc;
                    Buttons={
                        {
                            Text=(currency == "Gold" and `Unlock with {disguiseLib.Price}` 
                                                      or `Unlock with {disguiseLib.Price}`);
                            Style=(currency == "Gold" and "Gold" or "Kill");
                            OnPrimaryClick=function(dialogWindow)
                                local statusLabel = dialogWindow.Binds.StatusLabel;
                                statusLabel.Text = "Unlocking<...>";

                                local r = remoteDisguiseKitRemote:InvokeServer(
                                    activeStorageItem.ID, 
                                    `purchase{currency}`, 
                                    disguiseLib.Id
                                );
                                if r == 1 then
                                    statusLabel.Text = "Disguise unlocked";

                                elseif r == 2 then
                                    statusLabel.Text = "Already purchased";

                                elseif r == 3 then
                                    statusLabel.Text = "Not enough "..currency;

                                end

                                task.wait(1);
                                window:Update();
                            end;
                        };
                        {
                            Text="Cancel";
                            Style="Cancel";
                        };
                    }
                });
            end
            
            if playerGold >= disguiseLib.Price then
                modClientGuis.promptDialogBox({
                    Title=`Unlock Disguise`;
                    Desc=`Do you want to unlock ({disguiseLib.Name}) with Kills or <b><font color='rgb(170, 120, 0)'>Gold</font></b>?`;
                    Buttons={
                        {
                            Text=`{disguiseLib.Price}`;
                            Style="Kill";
                            OnPrimaryClick=function(dialogWindow)
                                currency = "Kills";
                                purchase();

                                return true;
                            end;
                        };
                        {
                            Text=`{disguiseLib.Price}`;
                            Style="Gold";
                            OnPrimaryClick=function(dialogWindow)
                                currency = "Gold";
                                purchase();

                                return true;
                            end;
                        };
                        {
                            Text="Cancel";
                            Style="Cancel";
                        };
                    }
                });
                
            else
                purchase();
            end

		end)
	end

end

return interfacePackage;

