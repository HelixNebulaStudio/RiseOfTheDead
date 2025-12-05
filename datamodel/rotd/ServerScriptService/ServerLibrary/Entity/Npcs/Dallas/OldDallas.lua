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
		"This is bad..";
		"Can't believe this..";
		"Here to waste our time again..";
		"These bandits...";
	}
	
	self.GoneMessages = {
		"Finally..";
		"Good riddance..";
		"Gone for good.";
	}
	
	self.NpcChat = {
		Nate = {
			{"Yo Nate, today was a smooth day, wasn't it?"; "Yeah, it wasn't too bad."};
			{"Nate, don't you think the R.A.T.s are behind all this?"; "No clue, they are suspiciously prepared though.."};
			{"Nate, I think Kelly is exaggerating the pest issue. I checked it and it was nothing to be worried about."; "Is that so?"};
			{"Hey Nate, do you think the military will come back?."; "*sigh* Unlikely.. I think they don't care about any survivors left, they even stopped dropping air drops."};
			{"Nate, do you like chain saws?"; "*facepalm* Please stop asking me about chainsaws.."};
		};
		Zep = {
			{"Hey Zep, how are you doing?"; "I'm doing great, keeping myself distracted from all the crazy out there."};
			{"Nice beanie Zep, where did you get it."; "Aww thanks, I found it in one of the closet here."};
			{"Do you need any help with that Zep?"; "Nope, I'm good. Thanks for asking though."};
		};
		Kelly = {
			{"Hey Kelly, what's up?"; "Not much, just playing pranks on Nate.."};
			{"Yo Kelly, I found a few boxes of canned beans. Where can I store them?"; "Just put them here for now, I'll deal with them later."};
			{"Kelly, do you know how to use a gun?"; "Hell yes, I used to be a sharpshooter."};
			{"Hey, why are you always so sassy to Nate?"; "He was my schoolmate, he always act all serious but he actually enjoys my company haha."};
			{"Hey, do you know what does Zep like? I want to find a gift."; "OoOo what's going on here.. Haha, I've heard Zep likes plushies."};
		};
	}
	
	self.RoamOutside = {
		Vector3.new(1128.193, 57.684, -72.619);
		Vector3.new(1244.274, 56.784, 13.539);
		Vector3.new(1294.288, 57.884, 27.761);
		Vector3.new(1184.215, 57.884, 30.468);
		Vector3.new(1090.252, 57.684, -3.439);
		Vector3.new(1196.991, 58.849, -4.589);
	}
	
	self.RoamSafehome = {
		Vector3.new(1153.518, 61.315, -137.106);
		Vector3.new(1173.932, 75.815, -137.919);
		Vector3.new(1142.242, 75.855, -123.604);
	}
	
	self.BedLocation = Vector3.new(1145.478, 75.855, -137.025);
	self.SnoozeTexts = {"ZzZzZzZzZ.."};
	self.BedSeat = workspace.Environment:FindFirstChild("DallasSleepingSeat", true);
	self.SafehouseDoorEnter = "SafehouseEntranceFront";
	self.SafehouseDoorExit = "SafehouseExitFront"
	
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
