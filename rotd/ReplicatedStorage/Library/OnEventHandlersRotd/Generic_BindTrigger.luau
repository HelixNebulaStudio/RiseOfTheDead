local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modUnlockPack = shared.require(game.ReplicatedStorage.Library.UsableItemsRotd.Generics.UnlockPack);
local modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);
local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

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

		elseif triggerId == "RandomDisguise30" then
			local model = interactable.Part and interactable.Part.Parent;

			local modDisguiseMechanics = shared.require(game.ReplicatedStorage.Library.DisguiseMechanics);
			
			local rollDisguiseId = {"ch1"; "cr1"; "cr2"; "pl1"; "ba1"; "cr3"; "snowman"; "tr1"; "pob1"; "sc1"; "man1"; "sca1"};
			modDisguiseMechanics:Disguise(player, rollDisguiseId[math.random(1,#rollDisguiseId)], 60);
			
			game.Debris:AddItem(model, 0);

		elseif triggerId == "warehouseSkateboard" then
			local warehouseSkateboardClaim = modEvents:GetEvent(player, "WarehouseSkateboard");
			if warehouseSkateboardClaim == nil then

				local missions = modMission.GetMissions(player.Name);
				local missionsCompleted = 0;
				
				for a = 1, #missions do
					local mission = missions[a];
					if mission.Type ~= 3 then continue end;
					missionsCompleted += 1;
				end

				if missionsCompleted < 10 then
					shared.Notify(player, "Not enough missions completed.", "Negative");
					return;
				end

				local hasSpace = inventory:SpaceCheck{{ItemId="skateboard"; Data={Quantity=1;}}};
				if not hasSpace then
					shared.Notify(player, "Not enough inventory space.", "Negative");
					return;
				end

				inventory:Add("skateboard", {Quantity=1;}, function()
					profile:GuiAction("specialpickup", {"skateboard";});
				end);
				modEvents:NewEvent(player, {Id="WarehouseSkateboard"});
				shared.Notify(player, "You picked up a Skateboard!", "Reward");
			end


		elseif triggerId == "warehouseXm1014" then
			local warehouseXm1014Claim = modEvents:GetEvent(player, "WarehouseXm1014");
			if warehouseXm1014Claim == nil then
				local hasSpace = inventory:SpaceCheck{{ItemId="xm1014"; Data={Quantity=1;}}};
				if not hasSpace then
					shared.Notify(player, "Not enough inventory space.", "Negative");
					return;
				end

				if activeSave:GetStat("ZombieKills") < 100 then
					shared.Notify(player, "You need at least 100 zombie kills.", "Negative");
					return;
				end

				inventory:Add("xm1014", {Quantity=1;}, function()
					profile:GuiAction("specialpickup", {"xm1014";});
				end);
				modEvents:NewEvent(player, {Id="WarehouseXm1014"});
				shared.Notify(player, "You picked up an XM1014!", "Reward");

				modEvents:SyncEvent(player, "WarehouseXm1014");
			end

		elseif triggerId == "warehouseMp5" then
			local warehouseMp5Claim = modEvents:GetEvent(player, "WarehouseMp5");
			if warehouseMp5Claim == nil then
				local hasSpace = inventory:SpaceCheck{{ItemId="mp5"; Data={Quantity=1;}}};
				if not hasSpace then
					shared.Notify(player, "Not enough inventory space.", "Negative");
					return;
				end

				if activeSave:GetStat("Level") < 20 then
					shared.Notify(player, "Reach Mastery Level 20 to claim.", "Negative");
					return;
				end

				inventory:Add("mp5", {Quantity=1;}, function()
					profile:GuiAction("specialpickup", {"mp5";});
				end);
				modEvents:NewEvent(player, {Id="WarehouseMp5"});
				shared.Notify(player, "You picked up an MP5!", "Reward");
						
				modEvents:SyncEvent(player, "WarehouseMp5");
			end

			
		end
	end)
end;