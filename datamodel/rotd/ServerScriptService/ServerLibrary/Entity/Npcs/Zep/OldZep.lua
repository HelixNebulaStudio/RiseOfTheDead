local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local HumanModule = script.Parent.Human;
--== Modules
local modNpcComponent = shared.require(game.ServerScriptService.ServerLibrary.Entity.NpcClass);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

-- Note; Function called for each NPC before parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Prefab = npc;
		SpawnPoint = spawnPoint;
		Immortal = 1;
		
		SafehouseId = "Community";
		Enemies = {};
	};
	
	self.BanditMessages = {
		"Oh gosh..";
	}
	
	self.GoneMessages = {
		"Phew..";
	}
	
	self.NpcChat = {
		Nate = {
			{"Oh umm, Nate, one of the walls have a hole in it, I think we might need to patch that up.."; "Oh I see, I'll work on it when I am free."};
			{"Nate, how are we doing with connecting the clean water supply from the Cafe?"; "I'm afraid it's taking longer than expected. It's done when it's done. *shrug*"}
		};
		Dallas = {
			{"Hi Dallas, are you heading out today?"; "Probably not, the bandits have been roam a lot more lately, seems a bit too dangerous at the moment."};
			{"Hey, you look cute in that shirt."; "Gee thanks! You look great too!"};
		};
	}
	
	self.RoamOutside = {
		Vector3.new(1254.305, 58.015, 29.317);
		Vector3.new(1222.932, 58.015, -10.334);
		Vector3.new(1223.466, 58.015, -54.492);
	}
	
	self.RoamSafehome = {
		Vector3.new(1153.887, 60.599, 47.587);
		Vector3.new(1171.936, 73.634, 78.462);
	}
	
	self.BedLocation = Vector3.new(1191.269, 75.939, 49.141);
	self.SnoozeTexts = {"ZzZzZzZzZ.."};
	self.BedSeat = workspace.Environment:FindFirstChild("ZepSleepingSeat", true);
	self.SafehouseDoorEnter = "Safehouse2EntranceFront";
	self.SafehouseDoorExit = "Safehouse2ExitFront"
	
	--== Initialize;
	function self.Initialize()
		if modBranchConfigs.IsWorld("TheResidentials") then
			repeat until not self.Update();
		else
			coroutine.yield();
		end
	end
	
	function self.Update()
		if self.IsDead then return false; end;
		
		self.BehaviorTree:RunTree("CommunityNpcTree", true);
		
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
	
	--== Connections;
	
return self end
