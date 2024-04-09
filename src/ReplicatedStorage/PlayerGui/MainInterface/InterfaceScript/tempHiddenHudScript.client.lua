local UserInputService = game:GetService("UserInputService");
--== 
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

local keyTag = script:WaitForChild("Key");
--== Script;
local function showHud()
	delay(0.1, function()
		game.Players.LocalPlayer:SetAttribute("DisableHud", nil);
		
		script.Parent.MainInterface.Enabled = true;
		modConfigurations.Set("DisableWeaponInterface", false);
		
		script:Destroy();
	end)
end

UserInputService.InputBegan:Connect(function(inputObject, gameProcessed)
	if not script.Parent.MainInterface.Enabled
	and not script.Parent.LobbyInterface.Enabled then
		if keyTag.Value == "MouseButton1"
			or keyTag.Value == "MouseButton2"
			or keyTag.Value == "MouseButton3" then
			if inputObject.UserInputType == Enum.UserInputType[keyTag.Value] then
				showHud();
			end
		else
			if inputObject.KeyCode == Enum.KeyCode[keyTag.Value] then
				showHud();
			end
		end
	end
end)