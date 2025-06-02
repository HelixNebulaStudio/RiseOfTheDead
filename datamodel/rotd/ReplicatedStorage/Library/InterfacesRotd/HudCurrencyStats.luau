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
    interface:BindConfigKey("DisableGeneralStats", {window});

    if modConfigurations.CompactInterface then
        statsFrame.Size = UDim2.new(0.5, 0, 0, 25);
        window:SetClosePosition(UDim2.new(0.5, 0, 1, 45), UDim2.new(0.5, 0, 1, -45));

        statsFrame.moneylabel.AnchorPoint = Vector2.new(0, 1);
        statsFrame.moneylabel.Position = UDim2.new(0.5, 160, 1, 0);
        statsFrame.moneylabel.TextYAlignment = Enum.TextYAlignment.Bottom;
        statsFrame.perkslabel.AnchorPoint = Vector2.new(1, 1);
        statsFrame.perkslabel.Position = UDim2.new(0.5, -160, 1, 0);
        statsFrame.perkslabel.TextYAlignment = Enum.TextYAlignment.Bottom;
    end
    window:Open();

    local previousStats = {};
    interface:BindEvent("UpdateStats", function()
        local modData = shared.require(localPlayer:WaitForChild("DataModule"));

        local statsData = modData.GameSave and modData.GameSave.Stats;
        if statsData then
            statsFrame.Visible = not modConfigurations.DisableGeneralStats;
            for key, value in pairs(statsData) do
                local label = (key == "Money" and statsFrame.moneylabel) or (key == "Perks" and statsFrame.perkslabel) or nil;
                if label then
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

                            delay(duration+0.02, function() label.TextColor3=Color3.fromRGB(255, 255, 255); end);
                        elseif value < previousStats[key].Value then
                            label.TextColor3=Color3.fromRGB(147, 49, 49);

                            TweenService:Create(label, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                                TextColor3=Color3.fromRGB(255, 255, 255);
                            }):Play();

                            delay(duration+0.02, function() label.TextColor3=Color3.fromRGB(255, 255, 255); end);
                        end
                        TweenService:Create(previousStats[key], TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                            Value=value;
                        }):Play();
                        delay(duration+0.02, function() 
                            previousStats[key].Value = value;
                        end)
                    end
                end
                -- if key == "Level" and properties then
                --     progressionLabel.Text = "Mastery Level: ".. tostring(value or 0);
                --     if modInterface.modMasteryInterface then
                --         modInterface.modMasteryInterface.Update();
                --     end
                -- end
            end
        else
            statsFrame.Visible = false;
        end
    end)
end

return interfacePackage;