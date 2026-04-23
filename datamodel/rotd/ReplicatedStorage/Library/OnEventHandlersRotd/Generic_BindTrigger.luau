local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modUnlockPack = shared.require(game.ReplicatedStorage.Library.UsableItemsRotd.Generics.UnlockPack);

return function(event: EventPacket, ...)
	local triggerId: string, interactable: InteractableInstance = ...;
	if triggerId == nil then return end;
	
	local player: Player? = event.Player;
    if player == nil or interactable == nil then return end;

	task.spawn(function()
	    local profile = shared.modProfile:Get(player);
		local activeSave = profile:GetActiveSave();
		local inventory = activeSave.Inventory;

		if triggerId == "UnlockCamoPack" then
			if profile.SkinsPacks.Camo == nil then
				modUnlockPack.UnlockPack(player, "SkinsPacks", "Camo");
			end

		elseif triggerId == "UnlockHalloweenPack" then
			if profile.SkinsPacks.Halloween == nil then
				modUnlockPack.UnlockPack(player, "SkinsPacks", "Halloween");
			end
				
		elseif triggerId == "RandomDisguise30" then
			local model = interactable.Part and interactable.Part.Parent;

			local modDisguiseMechanics = shared.require(game.ReplicatedStorage.Library.DisguiseMechanics);
			
			local rollDisguiseId = {"ch1"; "cr1"; "cr2"; "pl1"; "ba1"; "cr3"; "snowman"; "tr1"; "pob1"; "sc1"; "man1"; "sca1"};
			modDisguiseMechanics:Disguise(player, rollDisguiseId[math.random(1,#rollDisguiseId)], 60);
			
			game.Debris:AddItem(model, 0);

		end
	end)
end;