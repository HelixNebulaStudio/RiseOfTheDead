local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModProperties = require(game.ReplicatedStorage.Library.ItemModsLibrary.ItemModProperties);

local itemModifier = modItemModProperties.new(script);

if RunService:IsServer() then
	function itemModifier:OnBulletHit(packet)
        local toolModule = self.WeaponModule;
		local player = packet.Player;
        local hitInfo = packet.HitInfo;

        Debugger:StudioLog("KnockoutTrigger OnBulletHit", self.Disabled, player, hitInfo, toolModule ~= nil);

	end

end


return itemModifier;