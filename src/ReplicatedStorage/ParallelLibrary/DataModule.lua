local localPlayer = game.Players.LocalPlayer;
local DefaultSettings;
--==
local Data = {};
Data.__index = Data;
Data.Script = localPlayer:WaitForChild("DataModule");

function Data:IsMobile()
	return game:GetService("UserInputService").TouchEnabled and game:GetService("UserInputService").KeyboardEnabled == false;
end

-- !outline: Data:IsSettingsLoaded()
function Data:IsSettingsLoaded()
	return self.Script:GetAttribute("SettingsLoaded") == true;
end

-- !outline: Data:GetSetting(key)
function Data:GetSetting(key)
	if DefaultSettings == nil then
		DefaultSettings = {
			["DisableDeathRagdoll"] = (Data:IsMobile() and 1 or 0);
			["MaxDeadbodies"] = (Data:IsMobile() and 0 or 16);
			["DisableParticle3D"] = (Data:IsMobile() and 1 or 0);
			["LimitParticles"] = (Data:IsMobile() and 1 or 0); -- limit particles;
			["DisableBulletTracers"] = (Data:IsMobile() and 1 or 0);
			["BloodParticle"] = (Data:IsMobile() and 1 or 0);
		};
	end

	local settingsValue = self.Script:GetAttribute("Settings"..key);
	if settingsValue == nil and DefaultSettings[key] then
		settingsValue = DefaultSettings[key];
	end
	return settingsValue;
end

function Data:SetSetting(key, value)
	if typeof(value) == "table" then
		return;
	end
	
	self.Script:SetAttribute("Settings"..key, value);
end

return Data;