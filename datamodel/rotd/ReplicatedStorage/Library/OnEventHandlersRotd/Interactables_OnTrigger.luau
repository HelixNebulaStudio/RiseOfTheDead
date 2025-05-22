local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modUnlockPack = shared.require(game.ReplicatedStorage.Library.UsableItemsRotd.Generics.UnlockPack);

return function(event: EventPacket, interactData, ...)
	local player: Player? = event.Player;
    if player == nil or interactData == nil then return end;

    local profile = shared.modProfile:Get(player);
	local activeSave = profile:GetActiveSave();
	local inventory = activeSave.Inventory;
	local triggerId = interactData.TriggerTag;
	
	if triggerId == "UnlockCamoPack" then
		if profile.SkinsPacks.Camo == nil then
			modUnlockPack.UnlockPack(player, "SkinsPacks", "Camo");
		end

	elseif triggerId == "UnlockHalloweenPack" then
		if profile.SkinsPacks.Halloween == nil then
			modUnlockPack.UnlockPack(player, "Halloween", "Camo");
		end
			
	elseif triggerId == "RandomDisguise30" then
		local model = interactData.Object and interactData.Object.Parent;

		local modDisguiseMechanics = shared.require(game.ReplicatedStorage.Library.DisguiseMechanics);
		
		local rollDisguiseId = {"ch1"; "cr1"; "cr2"; "pl1"; "ba1"; "cr3"; "snowman"; "tr1"; "pob1"; "sc1"; "man1"; "sca1"};
		modDisguiseMechanics:Disguise(player, rollDisguiseId[math.random(1,#rollDisguiseId)], 60);
		
		game.Debris:AddItem(model, 0);
	end
end;