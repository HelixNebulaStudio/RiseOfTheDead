local localPlayer = game.Players.LocalPlayer;
--==
local Data = {};
Data.__index = Data;
Data.Script = localPlayer:WaitForChild("DataModule");

function Data:IsMobile()
	return game:GetService("UserInputService").TouchEnabled and game:GetService("UserInputService").KeyboardEnabled == false;
end

local DefaultSettings = {
	["DisableDeathRagdoll"] = (Data:IsMobile() and 1 or 0);
	["MaxDeadbodies"] = (Data:IsMobile() and 0 or 16);
	["DisableParticle3D"] = (Data:IsMobile() and 1 or 0);
	["LimitParticles"] = (Data:IsMobile() and 1 or 0); -- limit particles;
	["DisableBulletTracers"] = (Data:IsMobile() and 1 or 0);
	["BloodParticle"] = (Data:IsMobile() and 1 or 0);
};

-- !outline: Data:IsSettingsLoaded()
function Data:IsSettingsLoaded()
	return self.Script:GetAttribute("SettingsLoaded") == true;
end

-- !outline: Data:GetSetting(key)
function Data:GetSetting(key)
	local settingsValue = self.Script:GetAttribute("Settings"..key);
	if settingsValue == nil and DefaultSettings[key] then
		settingsValue = DefaultSettings[key];
	end
	return settingsValue;
end

return Data;