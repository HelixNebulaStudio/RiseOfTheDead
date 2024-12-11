local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modDropAppearance = require(game.ReplicatedStorage.Library.DropAppearance);

if RunService:IsServer() then
	
end

return function(handler, itemId, prefab)
	local Structure = {};
	Structure.WaistRotation = math.rad(0);
	Structure.PlaceOffset = CFrame.Angles(0, math.rad(-90), 0);
	
	Structure.Prefab = prefab or "crate";
	Structure.BuildDuration = 0.5;
	Structure.UseViewmodel = false;
	
	function Structure:CustomSpawn(cframe)
		local modCrates = require(game.ServerScriptService.ServerLibrary.Crates);
		
		local owner = self.Player;
		
		local rewards = modCrates.GenerateRewards(itemId, owner);
		if #rewards <= 0 then
			rewards = {{Quantity=1; ItemId="metal"}};
		end

		local prefab, interactable = modCrates.Spawn(itemId, cframe, {owner}, rewards);
		
		local dropAppearanceLib = modDropAppearance:Find(itemId);
		if dropAppearanceLib then
			modDropAppearance.ApplyAppearance(dropAppearanceLib, prefab);
		end
						
		modAudio.Play("StorageWoodPickup", prefab.PrimaryPart, nil, false);
		interactable:Sync(nil, {EmptyLabel="Owned by: "..owner.Name});
		Debugger.Expire(prefab, 120);
	end
	
	setmetatable(Structure, handler);
	return Structure;
end;