local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local localPlayer = game.Players.LocalPlayer;

local modGlobalVars = shared.require(game.ReplicatedStorage.GlobalVariables);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);

local interfacePackage = {
    Type = "Character";
};
--==

function interfacePackage.newInstance(interface: InterfaceInstance)
    
	local statsFrame = script:WaitForChild("GeneralStats"):Clone();
    statsFrame.Parent = interface.ScreenGui;
    
	local window = interface:NewWindow("GeneralStats", statsFrame);
	window.IgnoreHideAll = true;
	window.ReleaseMouse = false;
    window.Layers = {"CharacterHud"; "CompactHidden"; "CurrencyStats"};
    interface:BindConfigKey("DisableGeneralStats", {window});

    function window.Binds.SetStyle(styleId)
        if modConfigurations.CompactInterface then
            if styleId == "Inventory" then
                window.ClosePoint = UDim2.new(0, 0, 0, -40);
                window.OpenPoint = UDim2.new(0, 0, 1, 0);
                statsFrame.Position = window.OpenPoint;
                statsFrame.AnchorPoint = Vector2.new(0, 1);
                statsFrame.Size = UDim2.new(0.5, 0, 0, 24);
                statsFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10);
                statsFrame.BackgroundTransparency = 0.1;

            else
                statsFrame.BackgroundTransparency = 1;
                statsFrame.AnchorPoint = Vector2.new(0.5, 0);
                statsFrame.Size = UDim2.new(0.5, 0, 0, 25);
                window.ClosePoint = UDim2.new(0.5, 0, 1, 70);
                window.OpenPoint = UDim2.new(0.5, 0, 1, -70);
                statsFrame.Position = window.OpenPoint;

            end

        else
            statsFrame.Parent = interface.ScreenGui;
            
            local ratShopWindow = interface:GetWindow("RatShopWindow");
            if styleId == "Shop" and ratShopWindow then
                local shopFrameContainer = ratShopWindow.Frame:WaitForChild("StatsFrame");

                statsFrame.Parent = shopFrameContainer;
                statsFrame.Position = UDim2.new(0.5, 0, 1, 0);
                statsFrame.Size = UDim2.new(1, 0, 0, 24);
                statsFrame.BackgroundTransparency = 0.95;

            else
                window.ClosePoint = UDim2.new(0.5, 0, 1, 18);
                window.OpenPoint = UDim2.new(0.5, 0, 1, -18);
                statsFrame.Position = window.OpenPoint;

                statsFrame.AnchorPoint = Vector2.new(0.5, 1);
                statsFrame.Size = UDim2.new(0, 600, 0, 24);
                statsFrame.BackgroundTransparency = 1;

            end
        end
    end
    window.Binds.SetStyle();
    window:Open();

    interface.OnWindowToggle:Connect(function(w: InterfaceWindow, v: boolean)
        if modConfigurations.CompactInterface then
            local openedWindows = interface:ListWindows(function(win: InterfaceWindow)
                return win.Visible == true;
            end)

            local invOpen = false;
            for a=1, #openedWindows do
                local win: InterfaceWindow = openedWindows[a];
                if win.Name == "Inventory" or win.Name == "Workbench" then
                    invOpen = true;
                end
            end

            if invOpen == true then
                window.Binds.SetStyle("Inventory");
            else
                window.Binds.SetStyle();
            end

        else
            if w.Name == "RatShopWindow" then
                if w.Visible then
                    window.Binds.SetStyle("Shop");
                else
                    window.Binds.SetStyle();
                end
            end

        end
    end)

    local previousStats = {};
    --MARK: OnUpdate
    window.OnUpdate:Connect(function()
        local modData = shared.require(localPlayer:WaitForChild("DataModule"));

        local statsData = modData.GameSave and modData.GameSave.Stats;
        if statsData == nil then return; end
        
        for key, value in pairs(statsData) do
            local label = (key == "Money" and statsFrame.moneylabel) or (key == "Perks" and statsFrame.perkslabel) or nil;
            if label == nil then continue; end;
            
            if previousStats[key] == nil then 
                previousStats[key] = Instance.new("NumberValue", label);
                previousStats[key]:GetPropertyChangedSignal("Value"):Connect(function()
                    if label.Name == "moneylabel" then
                        local money = previousStats[key].Value;
                        if money >= modGlobalVars.MaxMoney then
                            label.Text = "Money Maxed: "..math.floor(money);
                        else
                            label.Text = "Money: "..math.floor(money);
                        end

                    elseif label.Name == "perkslabel" then
                        local perks = math.floor(previousStats[key].Value);

                        if perks >= modGlobalVars.MaxPerks then
                            label.Text = perks.." :Perks Maxed";
                        else
                            label.Text = perks > 1 and perks.." :Perks" or perks.." :Perk";
                        end
                    end
                end)
            end;
            if previousStats[key] then
                local duration = 2;
                if value > previousStats[key].Value then
                    label.TextColor3=Color3.fromRGB(149, 221, 115);

                    TweenService:Create(label, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
                        TextColor3=Color3.fromRGB(255, 255, 255);
                    }):Play();

                    task.delay(duration+0.02, function() label.TextColor3=Color3.fromRGB(255, 255, 255); end);
                elseif value < previousStats[key].Value then
                    label.TextColor3=Color3.fromRGB(147, 49, 49);

                    TweenService:Create(label, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                        TextColor3=Color3.fromRGB(255, 255, 255);
                    }):Play();

                    task.delay(duration+0.02, function() label.TextColor3=Color3.fromRGB(255, 255, 255); end);
                end
                TweenService:Create(previousStats[key], TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                    Value=value;
                }):Play();
                task.delay(duration+0.02, function() 
                    previousStats[key].Value = value;
                end)
            end
            
        end
    end)

    interface:BindEvent("UpdateStats", function()
        window:Update();
    end)
    window:Update();
end

return interfacePackage;