local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

if RunService:IsServer() then
	modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);
	modCrates = shared.require(game.ReplicatedStorage.Library.Crates);
end

return function(event: EventPacket, ...)
	local player: Player? = event.Player;
    local interactable: InteractableInstance, values: anydict = ...;
    
    local variantId = interactable.Variant;
    --==
    
    if variantId == "MallKeypad" and player then
		local codeEntered = values and values.InputCode or nil;

        if codeEntered ~= "240" then 
			shared.Notify(player, "[Keypad] Code rejected.", "Negative");
            return;
        end;
        shared.Notify(player, "[Keypad] Code accepted.", "Positive");
        
        if #modReplicationManager.getReplicated(player, "Mall's Gift") > 0 then
            Debugger:Warn(`Mall's Gift already exists.`);
            return;
        end

        local content = {};
        if modEvents:GetEvent(player, "mallGift") == nil then
            content = modCrates.GenerateRewards("mallGift");
            modEvents:NewEvent(player, {Id="mallGift"});
        end
        
        local spawnPoint = CFrame.new(702.059998, 10.0209656, -693.022827, -1, 0, 0, 0, 1, 0, 0, 0, -1);

        local spawnAtt = interactable.Part:FindFirstChild("RewardSpawn");
        if spawnAtt then
            spawnPoint = spawnAtt.WorldCFrame;
        end

        modCrates.spawn(
            "mallGift", 
            spawnPoint, 
            {player}, 
            content, 
            true
        );

        shared.Notify(player, "You found a Mall's Gift from the safe.", "Reward");
    end
end;