local localPlayer = game.Players.LocalPlayer;
--==
local Data = {};
Data.__index = Data;
Data.Script = localPlayer:WaitForChild("DataModule");

function Data:IsMobile()
	return game:GetService("UserInputService").TouchEnabled and game:GetService("UserInputService").KeyboardEnabled == false;
end

local DefaultSettings = {
	["MaxDeadbodies"] = (Data:IsMobile() and 0 or 16);
	["DisableParticle3D"] = (Data:IsMobile() and true or nil);
	["NiceParticles"] = (Data:IsMobile() and true or nil); -- limit particles;
};

-- !outline: Data:IsSettingsLoaded()
function Data:IsSettingsLoaded()
	return self.Script:GetAttribute("SettingsLoaded") == true;
end

--DisableParticle3D
-- !outline: Data:GetSetting(key)
function Data:GetSetting(key)
	local settingsValue = self.Script:GetAttribute("Settings"..key);
	if settingsValue == nil and DefaultSettings[key] then
		settingsValue = DefaultSettings[key];
	end
	return settingsValue;
end

return Data;