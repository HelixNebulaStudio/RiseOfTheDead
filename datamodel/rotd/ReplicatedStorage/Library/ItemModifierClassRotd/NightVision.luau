local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modifierPackage = {
	Name = "NightVision";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.onRequire()
	if RunService:IsClient() then return end;
end

function modifierPackage.Instancing(modifier: ItemModifierInstance, isFirstTime: boolean)
	if RunService:IsClient() then return end;

	if modifier.WieldComp and modifier.WieldComp.CompOwner and modifier.WieldComp.CompOwner.ClassName ~= "PlayerClass" then
		return 
	end;

	modifier.OnEnabledChanged:Connect(function(prevVal: boolean)
		if not modifier.Enabled then return end;
		if modifier.WieldComp == nil then return end;

		local playerClass: PlayerClass? = modifier.WieldComp.CompOwner :: PlayerClass;
		if playerClass == nil or playerClass.ClassName ~= "PlayerClass" then return end;
		
		playerClass.StatusComp:Apply("NightVision", {
			Values = {
				ModifierId = modifier.Id;
			};
		});
	end)
end

return modifierPackage;