local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
repeat task.wait() until shared.MasterScriptInit == true;

--== Variables;
local modItemDrops = require(game.ServerScriptService.ServerLibrary.ItemDrops);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);

local prefabItems = game.ReplicatedStorage.Prefabs.Items;
local random = Random.new();
--== Script;

task.spawn(function()
	local lootSpawn = workspace:FindFirstChild("LootSpawns");
	local spawns = lootSpawn and lootSpawn:GetChildren() or nil;
	--==
	
	if spawns then
		while true do
			local pickedSpawn = spawns[random:NextInteger(1, #spawns)];
			if pickedSpawn:IsA("Attachment") then
				local resourceTable = modRewardsLibrary:Find("loot"..pickedSpawn.Name);
				if resourceTable then
					local cframe = pickedSpawn.CFrame;
					local itemDrop = modItemDrops.ChooseDrop(resourceTable);
					if itemDrop then
						modItemDrops.Spawn(itemDrop, cframe);
					end
				end
			end
			wait(random:NextNumber(60, 300));
		end
	end
end)


--task.spawn(function()
--	local mysteryChestPrefab = script:WaitForChild("MysteryChest");
--	local mysteryChestBase = workspace:FindFirstChild("MysteryChestSpawns");
--	local mysteryChestSpawns = mysteryChestBase and mysteryChestBase:GetChildren() or nil;
--	--==
	
--	local roll = math.random(1, 100)/100;
	
--	if modBranchConfigs.IsWorld("BioXResearch") then
--		roll = 1;
--	end
	
--	if roll >= 0.65 and mysteryChestSpawns then
--		local new = mysteryChestPrefab:Clone();
--		new.Parent = workspace.Interactables;
		
--		local pSpawn = mysteryChestSpawns[math.random(1, #mysteryChestSpawns)];
--		new:SetPrimaryPartCFrame(pSpawn.WorldCFrame);
--	end
--end)