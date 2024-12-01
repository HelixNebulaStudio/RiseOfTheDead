local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemModProperties = require(game.ReplicatedStorage.Library.ItemModsLibrary.ItemModProperties);

local itemModifier = modItemModProperties.new(script);

if RunService:IsServer() then
	function itemModifier:OnBulletHit(packet)
        local toolModule = self.WeaponModule;
		local player = packet.Player;
        local targetPart = packet.TargetPart;

        Debugger:StudioLog("OnBulletHit", self.Disabled, player, targetPart, toolModule ~= nil);

	end

end


return itemModifier;