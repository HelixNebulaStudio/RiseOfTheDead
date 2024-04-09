local localPlayer = game.Players.LocalPlayer;
local dataModule = localPlayer:WaitForChild("DataModule");
--==
local Data = {};

-- !outline: Data:IsSettingsLoaded()
function Data:IsSettingsLoaded()
	return dataModule:GetAttribute("SettingsLoaded") == true;
end

-- !outline: Data:GetSetting(key)
function Data:GetSetting(key)
	return dataModule:GetAttribute("Settings"..key);
end



return Data;