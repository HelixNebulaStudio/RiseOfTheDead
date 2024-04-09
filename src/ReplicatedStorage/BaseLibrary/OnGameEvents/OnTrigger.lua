local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modAudio = require(game.ReplicatedStorage.Library.Audio);

return function(player, interactData, ...)
	local profile = shared.modProfile:Get(player);
	local activeSave = profile:GetActiveSave();
	local inventory = activeSave.Inventory;
	local triggerId = interactData.TriggerTag;
	
	if triggerId == "RandomDisguise30" then
		local model = interactData.Object and interactData.Object.Parent;

		local modDisguiseMechanics = require(game.ReplicatedStorage.Library.DisguiseMechanics);
		
		local rollDisguiseId = {"ch1"; "cr1"; "cr2"; "pl1"; "ba1"; "cr3"; "snowman"; "tr1"; "pob1"; "sc1"; "man1"; "sca1"};
		modDisguiseMechanics:Disguise(player, rollDisguiseId[math.random(1,#rollDisguiseId)], 60);
		
		game.Debris:AddItem(model, 0);
		
	end
end;
