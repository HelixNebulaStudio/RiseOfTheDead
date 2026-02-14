local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local HumanModule = script.Parent.Human;
--== Modules
local modNpcComponent = shared.require(game.ServerScriptService.ServerLibrary.Entity.NpcClass);
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

-- Note; Function called for each NPC before parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Prefab = npc;
		SpawnCFrame = spawnPoint;
		Immortal = 1;
		
		SafehouseId = "Community";
		Enemies = {};
	};
	
	self.BanditMessages = {
		"OMG! Ruuun!";
	}
	
	self.GoneMessages = {
		"That's right, and stay out! Lousy bandits..";
	}
	
	self.NpcChat = {
		Nate = {
			{"I am so cold."; "That's because you didn't bring a jacket."};
			{"Nate, your shoes are untied."; "Very funny Kelly.."};
			{"Why does it smell like updog here."; "What's updog.."};
		};
		Dallas = {
			{"Hey, great haul on the last scavenge Dallas."; "Oh thanks! Hope it will last, bandits are on high alert and I won't be able to head out as much."};
			{"Yo Dallas, what's up with the basement? It's a mess.."; "Ahhh, yeah.. Umm.. You know.. I'll talk to you later.."};
			{"Hey, I need you to get something from this location, my brother may have left a message there."; "Sure, will do ma'am."};
		};
		Zep = {
			{"Heeya Zep. Working hard or hardly working?"; "A bit of both hehe.."};
			{"Zep, have you heard? The bandits are on high alert, rumors are that they captured something.."; "Yeah, I've heard. They are already ruling Wrighton Dale, what else do they want?"};
			{"Somebody blew up the north Wrighton Dale bridge, can you believe it."; "Oh gosh, that's scary.. Is someone trying to cut us off from the airport?"};
		};
	}
	
	self.RoamOutside = {
		Vector3.new(1176.833, 61.165, -107.701);
		Vector3.new(1144.475, 58.515, 26.789);
		Vector3.new(1258.646, 58.515, 28.088);
	}
	
	self.RoamSafehome = {
		Vector3.new(1185.371, 75.939, 75.79);
		Vector3.new(1197.814, 61.399, 42.456);
		Vector3.new(1142.507, 61.399, 56.37);
	}
	
	self.BedLocation = Vector3.new(1203.145, 75.939, 73.817);
	self.SnoozeTexts = {"ZzZzZzZzZ.."};
	self.BedSeat = workspace.Environment:FindFirstChild("KellySleepingSeat", true);
	self.SafehouseDoorEnter = "Safehouse2EntranceFront";
	self.SafehouseDoorExit = "Safehouse2ExitFront"
	
	--== Initialize;
	function self.Initialize()
		if modBranchConfigurations.IsWorld("TheResidentials") then
			repeat until not self.Update();
		else
			coroutine.yield();
		end
	end
	
	function self.Update()
		if self.IsDead then return false; end;
		
		self.BehaviorTree:RunTree("CommunityNpcTree", true);
		
		--Debugger:Log("State:", self.BehaviorTree.State, " Status:", self.BehaviorTree.Status);
		task.wait(0.5);
		return true;
	end
	
	--== Components;
	self:AddComponent("AvatarFace");
	self:AddComponent("Follow");
	self:AddComponent("Movement");
	self:AddComponent("Wield");
	self:AddComponent("IsInVision");
	self:AddComponent("BehaviorTree");
	self:AddComponent("ObjectScan");
	self:AddComponent(HumanModule.Chat);
	self:AddComponent(HumanModule.Actions);
	
	
return self end
