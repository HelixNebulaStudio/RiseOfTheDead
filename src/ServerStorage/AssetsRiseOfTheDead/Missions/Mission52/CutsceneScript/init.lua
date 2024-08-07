local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

--== Variables;
local missionId = 52;

if RunService:IsServer() then
	modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
	modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	
	modOnGameEvents:ConnectEvent("OnTrigger", function(player, interactData)
		local triggerTag = interactData.TriggerTag;
		local triggerObj = interactData.Object;
		
		if triggerTag == "TheInvestigation_CutStrap" then
			triggerObj:Destroy();
			workspace.Environment:WaitForChild("StrapPart").Transparency = 1;
			modAudio.Play("HardSlice", workspace.Environment.StrapPart).PlaybackSpeed = 2;
			modMission:Progress(player, missionId, function(mission)
				mission.ProgressionPoint = 11;
			end)
		end
	end)
else
	modData = require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	local remotes = game.ReplicatedStorage:WaitForChild("Remotes");
	local remoteSetHeadIcon = remotes:WaitForChild("SetHeadIcon");
	local remoteCameraShakeAndZoom = remotes.CameraShakeAndZoom;
	
	if modBranchConfigs.IsWorld("TheResidentials") then
		-- MARK: TheResidentials
		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, missionId);
			if mission == nil then return end;
				
			local robertModule = modNpc.GetPlayerNpc(player, "Robert");
			if robertModule == nil then
				local npc = modNpc.Spawn("Robert", nil, function(npc, npcModule)
					npcModule.Owner = player;
					robertModule = npcModule;
					robertModule.EntityStatus.Disabled = true;
				end);
				modReplicationManager.ReplicateOut(player, npc);
			end
			
			robertModule.AvatarFace:Set("Confident");
			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable
					
				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint == 1 then
						robertModule.Actions:Teleport(CFrame.new(1076.85449, 57.5146675, -125.994919, 1, 0, 0, 0, 1, 0, 0, 0, 0.999996185));
						
					elseif mission.ProgressionPoint == 2 then
						robertModule.Move:SetMoveSpeed("set", "default", 8);
						robertModule.Move:MoveTo(Vector3.new(1127.26965, 57.664669, -60.4100342));
						
					elseif mission.ProgressionPoint == 3 then
						robertModule.Move:SetMoveSpeed("set", "default", 16);
						
						robertModule.Actions:FollowOwner(function()
							return mission.Type == 1 and mission.ProgressionPoint == 3;
						end);
						
					elseif mission.ProgressionPoint >= 15 then
						local robertModule = modNpc.GetPlayerNpc(player, "Robert");
						if robertModule then
							robertModule:TeleportHide();
						end
						
						local nateModule = modNpc.GetPlayerNpc(player, "Nate");
						if nateModule then
							modReplicationManager.UnreplicateFrom(player, nateModule.Prefab);
						end
						
						local josephModule = modNpc.GetPlayerNpc(player, "Joseph");
						if josephModule then
							modReplicationManager.UnreplicateFrom(player, josephModule.Prefab);
						end
						
					elseif mission.ProgressionPoint >= 4 then
						modMission:Progress(player, missionId, function(mission)
							mission.ProgressionPoint = 3;
						end)
						
					end
				elseif mission.Type == 3 then -- OnComplete
					robertModule:TeleportHide();
					
				end
			end
			mission.Changed:Connect(OnChanged);
			OnChanged(true);
		end)


	elseif modBranchConfigs.IsWorld("TheInvestigation") then
		-- MARK: TheInvestigation
		local waterBarrels = workspace.Environment:WaitForChild("CutsceneBarrels");
		local cutsceneWallDestroy = workspace.Environment:WaitForChild("cutsceneWallDestroy");

		local assetTheInvestigation = script:WaitForChild("TheInvestigationAssets");

		local robertLeftHand = assetTheInvestigation:WaitForChild("RobertLeftHand");
		local cutStrap = assetTheInvestigation:WaitForChild("cutStrap");
		local radioStationTravel = assetTheInvestigation:WaitForChild("Travel_TheMall");
		
		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, missionId);
			if mission == nil then return end;
				
	
			local robertModule = modNpc.GetPlayerNpc(player, "Robert");
			if robertModule == nil then
				local npc = modNpc.Spawn("Robert", CFrame.new(12.7279015, 162.617722, -63.8735542, 0, 0, -1, 0, 1, 0, 1, 0, 0), function(npc, npcModule)
					npcModule.Owner = player;
					npcModule.Prefab:SetAttribute("LookAtClient", false);
					robertModule = npcModule;
					robertModule.EntityStatus.Disabled = true;
				end);
				modReplicationManager.ReplicateOut(player, npc);
			end
			
			local nateModule = modNpc.GetPlayerNpc(player, "Nate");
			if nateModule == nil then
				local npc = modNpc.Spawn("Nate", CFrame.new(35.2480125, 162.593155, -34.3742752, -1, 0, 0, 0, 1, 0, 0, 0, -1), function(npc, npcModule)
					npcModule.Owner = player;
					npcModule.Prefab:SetAttribute("LookAtClient", false);
					nateModule = npcModule;
				end);
				modReplicationManager.ReplicateOut(player, npc);
				nateModule.RootPart.Anchored = false;
			end
			
			local dallasModule = modNpc.GetPlayerNpc(player, "Dallas");
			if dallasModule == nil then
				local npc = modNpc.Spawn("Dallas", CFrame.new(38.07024, 176.987366, -44.433876, -1, 0, 0, 0, 1, 0, 0, 0, -1), function(npc, npcModule)
					npcModule.Owner = player;
					npcModule.Prefab:SetAttribute("LookAtClient", false);
					dallasModule = npcModule;
				end);
				modReplicationManager.ReplicateOut(player, npc);
			end
			
			local josephModule = modNpc.GetPlayerNpc(player, "Joseph");
			if josephModule == nil then
				local npc = modNpc.Spawn("Joseph", CFrame.new(38.07024, 176.987366, -44.433876, -1, 0, 0, 0, 1, 0, 0, 0, -1), function(npc, npcModule)
					npcModule.Owner = player;
					npcModule.Prefab:SetAttribute("LookAtClient", false);
					josephModule = npcModule;
				end);
				modReplicationManager.ReplicateOut(player, npc);
			end
			
			local zarkModule = modNpc.GetPlayerNpc(player, "Zark");
			if zarkModule == nil then
				local npc = modNpc.Spawn("Zark", CFrame.new(38.07024, 176.987366, -44.433876, -1, 0, 0, 0, 1, 0, 0, 0, -1), function(npc, npcModule)
					npcModule.Owner = player;
					zarkModule = npcModule;
				end);
				modReplicationManager.ReplicateOut(player, npc);
			end
			
			local banditModule = modNpc.GetPlayerNpc(player, "Bandit");
			if banditModule == nil then
				local npc = modNpc.Spawn("Bandit", CFrame.new(38.07024, 176.987366, -44.433876, -1, 0, 0, 0, 1, 0, 0, 0, -1), function(npc, npcModule)
					npcModule.Owner = player;
					banditModule = npcModule;
				end, require(game.ServerScriptService.ServerLibrary.Entity.Npc.Human));
				modReplicationManager.ReplicateOut(player, npc);
			end
			
			robertModule.AvatarFace:Set("Skeptical");
			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable
					
				elseif mission.Type == 1 then -- OnActive
					if firstRun and mission.ProgressionPoint > 3 then
						modMission:Progress(player, missionId, function(mission)
							mission.ProgressionPoint = 3;
						end)
					end
					if mission.ProgressionPoint == 3 then
						CutsceneSequence:NextScene("enableInterfaces");
						modMission:Progress(player, missionId, function(mission)
							mission.ProgressionPoint = 4;
						end)
						robertModule.Interactable.Parent = script;
						
					elseif mission.ProgressionPoint == 4 then
						robertModule.Chat(robertModule.Owner, "What's going on here..");
						robertModule.Actions:FollowOwner(function()
							
							if (robertModule.RootPart.Position-Vector3.new(37.134, 164.003, -45.589)).Magnitude <= 16 then
								modMission:Progress(player, missionId, function(mission)
									mission.ProgressionPoint = 5;
								end)
							end
							return mission.Type == 1 and mission.ProgressionPoint == 4;
						end);
						nateModule.Interactable.Parent = script;
						dallasModule.Interactable.Parent = script;
						josephModule.Interactable.Parent = script;
						zarkModule.Interactable.Parent = script;
						
					elseif mission.ProgressionPoint == 5 then
						robertModule.SetAnimation("Punch", {assetTheInvestigation.Punch});
						robertModule.SetAnimation("RobertLoseHand", {assetTheInvestigation.RobertLoseHand});
						robertModule.SetAnimation("RobertInvestigate1", {assetTheInvestigation.RobertInvestigate1});
						josephModule.SetAnimation("JosephInvestigate1", {assetTheInvestigation.JosephInvestigate1});
						josephModule.SetAnimation("JosephDown", {assetTheInvestigation.JosephDown});
						josephModule.SetAnimation("JosephDown2", {assetTheInvestigation.JosephDown2});
						josephModule.SetAnimation("JosephNoArm", {script.JosephNoArm});
						zarkModule.SetAnimation("LookAround", {assetTheInvestigation.LookAround});
						zarkModule.SetAnimation("CrouchLookAnim", {assetTheInvestigation.CrouchLookAnim});
						
						remoteSetHeadIcon:FireClient(player, 1, "Joseph", "HideAll");
						dallasModule.Actions:Teleport(CFrame.new(12.7279015, 162.617722, -63.8735542, 0, 0, -1, 0, 1, 0, 1, 0, 0));
						dallasModule.Movement:Move(Vector3.new(27.336, 162.593, -48.273));
						josephModule.Actions:Teleport(CFrame.new(12.7279015, 162.617722, -63.8735542, 0, 0, -1, 0, 1, 0, 1, 0, 0));
						josephModule.Movement:SetWalkSpeed("default", 10);
						wait(0.2);
						robertModule.Move:MoveTo(Vector3.new(36.017, 162.593, -44.846));
						robertModule.Move.MoveToEnded:Wait(10);
						
						nateModule.Chat(nateModule.Owner, "Hold it right there buddy.");
						dallasModule.Wield.Equip("m4a4");
						nateModule.Wield.Equip("m4a4");
						nateModule.Movement:Face(robertModule.RootPart.Position);
						robertModule.AvatarFace:Set("Disbelief");
						nateModule.AvatarFace:Set("Angry");
						dallasModule.AvatarFace:Set("Suspicious");
						josephModule.AvatarFace:Set("Skeptical");
						robertModule.Move:Face(nateModule.RootPart);
						
						wait(0.45);
						robertModule.PlayAnimation("Surrender");
						robertModule.Chat(robertModule.Owner, "Huh?!");
						modMission:Progress(player, missionId, function(mission)
							mission.ProgressionPoint = 6;
						end)
						
					elseif mission.ProgressionPoint == 6 then
						josephModule.Movement:Move(Vector3.new(34.36, 162.593, -53.878)):Wait();
						josephModule.Movement:Face(robertModule.RootPart.Position);
						dallasModule.Movement:Face(robertModule.RootPart.Position);
						josephModule.PlayAnimation("CrossedArm");
						
						nateModule.Chat(nateModule.Owner, "WHO ARE YOU?!");
						wait(5);
						robertModule.Chat(robertModule.Owner, "What!? What's going on?!");
						wait(5);
						nateModule.Chat(nateModule.Owner, "You are an infector, aren't you!?");
						wait(5);
						robertModule.Chat(robertModule.Owner, "What? What make you think that!? I saved your life!");
						robertModule.AvatarFace:Set("Disgusted");
						wait(5);
						nateModule.Chat(nateModule.Owner, "YES, but you just wanted to know about this safehouse..");
						wait(5);
						robertModule.Chat(robertModule.Owner, "I SWEAR, I'M NOT AN INFECTOR!! HOW CAN I PROVE MYSELF?!");
						robertModule.AvatarFace:Set("Grumpy");
						wait(5);
						josephModule.Chat(josephModule.Owner, "Shoot him");
						wait(0.5);
						dallasModule.AvatarFace:Set("Surprise");
						nateModule.AvatarFace:Set("Disbelief");
						wait(0.5);
						robertModule.AvatarFace:Set("Scared");
						nateModule.Chat(nateModule.Owner, "Joseph, are you sure?!");
						wait(1);
						robertModule.Chat(robertModule.Owner, "WHAT?! NO!");
						wait(1);
						dallasModule.Chat(dallasModule.Owner, "Oof");
						wait(5);
						josephModule.Chat(josephModule.Owner, "Yes. Shoot him");
						
						local lastDamaged = tick();
						robertModule.Garbage:Tag(robertModule.Humanoid.HealthChanged:Connect(function()
							robertModule.Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn; lastDamaged = tick();
							delay(2, function()
								if tick()-lastDamaged > 2 and robertModule.Humanoid then
									robertModule.Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
								end;
							end);
							
							RunService.Heartbeat:Wait();
							local hurtSound = modAudio.Play("ZombieHurt", robertModule.RootPart);
							hurtSound.Volume = math.random(50, 60)/100;
							hurtSound.PlaybackSpeed = math.random(110, 120)/100;
						end));
						
						wait(1.2);
						
						nateModule.Wield.SetEnemyHumanoid(robertModule.Humanoid);
						nateModule.Movement:Face(robertModule.RootPart.Position);
						nateModule.Wield.PrimaryFireRequest();
						delay(0.6, function()
							nateModule.Wield.Controls.Mouse1Down = false;
						end)
						
						wait(0.3);
						josephModule.StopAnimation("CrossedArm");
						robertModule.StopAnimation("Surrender");
						
						robertModule.Chat(robertModule.Owner, "*Infector Ouch*");
						task.spawn(function()
							for a=1, 3 do
								local hurtSound = modAudio.Play("ZombieHurt", robertModule.Head);
								hurtSound.Volume = math.random(50, 60)/100;
								hurtSound.PlaybackSpeed = math.random(110, 120)/100;
								robertModule.PlayAnimation("Flinch", 0.05, nil, 2);
								task.wait(0.15);
								robertModule.StopAnimation("Flinch");
							end
						end)
						
						robertModule.AvatarFace:Set("Infector");
						nateModule.AvatarFace:Set("Scared");
						dallasModule.AvatarFace:Set("Scared");
						josephModule.AvatarFace:Set("Serious");
						wait(1);
						josephModule.Wield.Equip("pickaxe");
						wait(1);
						dallasModule.Chat(dallasModule.Owner, "Oh snap..");
						wait(1);
						josephModule.Chat(josephModule.Owner, "Hmmm..");
						wait(1);
						robertModule.Chat(robertModule.Owner, "Heh heh heh...");
						wait(1);
						nateModule.Chat(nateModule.Owner, "SHOOT!! SHOOOT!!!");
						modMission:Progress(player, missionId, function(mission)
							mission.ProgressionPoint = 7;
						end)
						
					elseif mission.ProgressionPoint == 7 then
						wait(1);
						local classPlayer = shared.modPlayers.Get(player);
						
						robertModule.Chat(robertModule.Owner, "Well, guess there will be a minor setback for my plans..");
						
						nateModule.Wield.SetEnemyHumanoid(robertModule.Humanoid);
						nateModule.Movement:Face(robertModule.RootPart.Position);
						nateModule.Wield.PrimaryFireRequest();
						
						dallasModule.Wield.SetEnemyHumanoid(robertModule.Humanoid);
						dallasModule.Movement:Face(robertModule.RootPart.Position);
						dallasModule.Wield.PrimaryFireRequest();
						
						wait(1.5);
						robertModule.Chat(robertModule.Owner, "I'm done with this..");
						wait(1.5);
						robertModule.Move:SetMoveSpeed("set", "default", 30);

						robertModule.Move:MoveTo(nateModule.RootPart.Position);
						task.wait(0.5);
						
						robertModule.PlayAnimation("Punch");
						modAudio.Play("Punch", robertModule.RootPart);
						wait(0.2);
						dallasModule.Wield.ReloadRequest();
						nateModule.Humanoid.PlatformStand = true;
						
						nateModule.RootPart:ApplyImpulse(Vector3.new(0, 500, 1000));
						nateModule.Wield.Unequip();
						nateModule.AvatarFace:Set("Unconscious");
						nateModule.PlayAnimation("Unconscious");
						remoteCameraShakeAndZoom:FireClient(player, 5, 0, 1, 2, false);
						josephModule.Movement:Face(robertModule.RootPart.Position);
						
						nateModule.Chat(nateModule.Owner, "Uagh!");
						for _, obj in pairs(waterBarrels:GetDescendants()) do
							if obj:IsA("BasePart") then
								obj.Anchored = false;
								obj:ApplyImpulse(Vector3.new(0, 60, -120));
							end
						end
						modAudio.Play("Barrels", nateModule.RootPart);
						wait(0.8);

						robertModule.Move:MoveTo(dallasModule.RootPart.Position);
						robertModule.Move.MoveToEnded:Wait(1);
						
						josephModule.Chat(josephModule.Owner, "Dallas!");
						josephModule.Movement:Face(robertModule.RootPart.Position);
						robertModule.PlayAnimation("Punch");
						modAudio.Play("Punch", robertModule.RootPart);
						wait(0.2);
						
						dallasModule.Humanoid.PlatformStand = true;
						
						dallasModule.RootPart:ApplyImpulse(Vector3.new(-800, 500, -400));
						dallasModule.Wield.Unequip();
						dallasModule.AvatarFace:Set("Unconscious");
						dallasModule.PlayAnimation("Unconscious");
						
						remoteCameraShakeAndZoom:FireClient(player, 5, 0, 1, 2, false);
						josephModule.Movement:Face(robertModule.RootPart.Position);
						wait(2);
						
						josephModule.Movement:SetWalkSpeed("default", 14);

						robertModule.Move:MoveTo(classPlayer.RootPart.Position);
						robertModule.Actions:WaitForOwner(6, nil, 0.1);
						
						robertModule.PlayAnimation("Punch");
						modAudio.Play("Punch", robertModule.RootPart);
						wait(0.2);
						
						classPlayer:UnequipTools();
						
						CutsceneSequence:NextScene("playerKnockout");
						shared.Notify(player, "*Helicopter approaching..*", "Message");
						
						local heliSound = modAudio.Play("HelicopterCore", workspace.Environment.ChopperSound);
						heliSound.Volume = 0;
						TweenService:Create(heliSound, TweenInfo.new(10), {Volume = 1;}):Play();
						
						remoteCameraShakeAndZoom:FireClient(player, 5, 0, 1, 2, false);
						robertModule.Actions:Teleport(CFrame.new(41.6181221, 162.593155, -48.860527, 0, 0, -1, 0, 1, 0, 1, 0, 0));
						wait(1);
						josephModule.Movement:Move(Vector3.new(39.078, 162.593, -50.709)):Wait();
						robertModule.Move:Face(josephModule.RootPart);
						wait(0.2);
						
						robertModule.PlayAnimation("RobertLoseHand")
						robertModule.AnimationController:LoopTracks("RobertLoseHand", function(trackData)
							local track = trackData.Track;
							track:GetMarkerReachedSignal("LoseHand"):Connect(function()
								robertModule.Prefab.RightLowerArm.Wound.Blood.Enabled = true;
								delay(0.1, function()
									robertModule.Prefab.RightHand.Transparency = 1;
								end)
								for a=1, 10 do
									robertModule.Prefab.RightLowerArm.Wound.Blood:Emit(4);
									RunService.Heartbeat:Wait();
									robertModule.Prefab.RightLowerArm.Wound.Blood:Emit(4);
									RunService.Heartbeat:Wait();
								end
							end);
						end)
						
						josephModule.Wield.PrimaryFireRequest();
						wait(0.1);
						robertModule.Chat(robertModule.Owner, "AHHHGH");
						modAudio.Play("Slice", robertModule.RootPart);
						local hurtSound = modAudio.Play("ZombieHurt", robertModule.RootPart);
						hurtSound.Volume = math.random(50,60)/100;
						hurtSound.PlaybackSpeed = 0.7;
						robertLeftHand.Parent = workspace.Environment;
						
						wait(1);
						spawn(function()
							for a=1, 2 do
								wait(0.1);
								robertModule.Humanoid.Health = robertModule.Humanoid.Health -1;
							end
						end)
						robertModule.RootPart.Anchored = true;
						robertModule.Actions:Teleport(CFrame.new(41.5883179, 162.593445, -48.8697166, 0.563169777, 4.99064043e-08, 0.826341212, -8.86618352e-08, 1, 3.05726382e-11, -0.826341212, -7.32821519e-08, 0.563169777));
						josephModule.RootPart.Anchored = true;
						josephModule.RootPart.CanCollide = false;
						josephModule.Actions:Teleport(CFrame.new(38.3455811, 162.593445, -51.0908356, -0.523620725, -3.62133896e-08, -0.85195148, 4.10249186e-08, 1, -6.77208547e-08, 0.85195148, -7.04112821e-08, -0.523620725));
						
						robertModule.PlayAnimation("RobertInvestigate1");
						
						local investigateTrack = josephModule.GetAnimation("JosephInvestigate1");
						investigateTrack:GetMarkerReachedSignal("Ugh"):Connect(function()
							josephModule.Chat(josephModule.Owner, "Ugh");
							josephModule.Wield.Unequip();
						end)
						investigateTrack:GetMarkerReachedSignal("LoseArm"):Connect(function()
							remoteCameraShakeAndZoom:FireClient(player, 5, 0, 1, 2, false);
							josephModule.Chat(josephModule.Owner, "UGGGHHH");
							modAudio.Play("WeakPointImpact", josephModule.RootPart);
							
							delay(0.3, function()
								josephModule.Prefab.LeftLowerArm.LeftElbow:Destroy();
								josephModule.Prefab.LeftLowerArm.CanCollide = true;
							end)
							josephModule.Prefab.LeftUpperArm.Wound.Blood.Enabled = true;
							
							for a=1, 10 do
								josephModule.Prefab.LeftUpperArm.Wound.Blood:Emit(8);
								RunService.Heartbeat:Wait();
								RunService.Heartbeat:Wait();
							end
						end)
						
						josephModule.PlayAnimation("JosephInvestigate1");
						
						for a=1, 7 do
							task.wait(1);
							Debugger:Log("investigateTrack waiting", investigateTrack.Length)
							if not investigateTrack.IsPlaying then break; end;
						end
						
						josephModule.PlayAnimation("JosephDown", 0);
						wait(1);
						robertModule.RootPart.Anchored = false;
						
						robertModule.Move:MoveTo(Vector3.new(-10.408, 162.593, -48.561));
						robertModule.Move.MoveToEnded:Wait(1);
						
						robertModule.PlayAnimation("Punch");
						modAudio.Play("Punch", robertModule.RootPart);
						wait(0.2);
						modAudio.Play("ConcreteSmash", robertModule.RootPart);
						wait(0.35);
						cutsceneWallDestroy:Destroy();
						remoteCameraShakeAndZoom:FireClient(player, 10, 0, 1, 2, false);
						local new = assetTheInvestigation.rockDebris:Clone();
						new.Parent = workspace.Debris;
						for _, obj in pairs(new:GetDescendants()) do
							if obj:IsA("BasePart") then
								obj.Anchored = false;
								obj:ApplyImpulse(Vector3.new(100, 60, 0));
							end
						end
						
						robertModule.Move:MoveTo(Vector3.new(-16.408, 162.593, -48.561));
						wait(1.5);
						robertModule:TeleportHide();
						--robertModule.Actions:Teleport(CFrame.new(38.07024, 176.987366, -44.433876, -1, 0, 0, 0, 1, 0, 0, 0, -1));
						
						wait(3);
						shared.Notify(player, "*Helicopter lands upstairs..*", "Message");
						TweenService:Create(heliSound, TweenInfo.new(5), {Volume = 0;}):Play();
						CutsceneSequence:NextScene("faint");
						wait(5);
						modMission:Progress(player, missionId, function(mission)
							mission.ProgressionPoint = 8;
						end)
						
					elseif mission.ProgressionPoint == 8 then
						zarkModule.Actions:Teleport(CFrame.new(12.7279015, 162.617722, -63.8735542, 0, 0, -1, 0, 1, 0, 1, 0, 0));
						banditModule.AvatarFace:Set("Serious");
						banditModule.Actions:Teleport(CFrame.new(6.9413929, 162.593445, -64.6298904, -1, 0, 0, 0, 1, 0, 0, 0, -1));
						banditModule.Wield.Equip("fnfal");
						banditModule.Movement:SetWalkSpeed("default", 0);
						banditModule.Movement:Move(Vector3.new(34.447, 162.593, -41.027));
						delay(1, function()
							banditModule.Movement:SetWalkSpeed("default", 6);
						end)
						
						zarkModule.Movement:Move(Vector3.new(24.827, 162.593, -49.793)):Wait();
						
						banditModule.Movement:Face(Vector3.new(34.447, 162.593, -34.47));
						zarkModule.Movement:SetWalkSpeed("default", 6);
						zarkModule.PlayAnimation("LookAround");
						zarkModule.Chat(zarkModule.Owner, "Hmmm, so Robert was indeed one of the infectors.");
						
						zarkModule.Movement:Move(Vector3.new(42.254, 162.593, -49.369)):Wait(5);
						
						zarkModule.AvatarFace:Set("Confident");
						wait(0.5);
						zarkModule.Actions:Teleport(CFrame.new(41.462471, 162.593445, -49.2249641, 0.0611268133, -2.64448197e-09, -0.998130023, 4.32557741e-08, 1, -3.95256121e-13, 0.998130023, -4.3174861e-08, 0.0611268133));
						
						zarkModule.PlayAnimation("CrouchLookAnim");
						task.wait(2.5);
						
						local newWeld = assetTheInvestigation.RobertLeftHandWeld:Clone();
						robertLeftHand.Parent = zarkModule.Prefab;
						newWeld.Parent = zarkModule.Prefab.RightHand;
						robertLeftHand.Anchored = false;
						newWeld.Part0 = zarkModule.Prefab.RightHand;
						newWeld.Part1 = robertLeftHand;
						wait(1);
						zarkModule.StopAnimation("CrouchLookAnim");
						zarkModule.Chat(zarkModule.Owner, "One's already been captured.. Soon we will get our hands on Robert and also put him on a leash.");
						banditModule.Movement:Face(Vector3.new(44.301, 162.593, -48.655));
						wait(5);
						zarkModule.Movement:Move(Vector3.new(14.223, 162.593, -63.75))
						wait(3);
						banditModule.Movement:Move(Vector3.new(14.223, 162.593, -63.75));
						wait(3);
						CutsceneSequence:NextScene("faint");
						CutsceneSequence:NextScene("playerWake");
						wait(3);
						zarkModule.Actions:Teleport(CFrame.new(38.07024, 176.987366, -44.433876, -1, 0, 0, 0, 1, 0, 0, 0, -1));
						banditModule.Actions:Teleport(CFrame.new(38.07024, 176.987366, -44.433876, -1, 0, 0, 0, 1, 0, 0, 0, -1));
						
						modMission:Progress(player, missionId, function(mission)
							mission.ProgressionPoint = 9;
						end)
						
					elseif mission.ProgressionPoint == 9 then
						josephModule.Interactable.Parent = josephModule.Prefab;
						josephModule.AvatarFace:Set("Frustrated");
						
					elseif mission.ProgressionPoint == 10 then
						local newStrap = cutStrap:Clone();
						newStrap.Parent = workspace.Interactables;
						
					elseif mission.ProgressionPoint == 12 then
						--josephModule.Prefab.Bandage.Handle.Transparency = 0;
						josephModule.Prefab.LeftUpperArm.Wound.Blood.Enabled = false;
						josephModule.PlayAnimation("JosephDown2", 0);
						josephModule.StopAnimation("JosephDown");
						
						nateModule.Interactable.Parent = nateModule.Prefab;
						
					elseif mission.ProgressionPoint == 13 then
						
						nateModule.Humanoid.PlatformStand = false;
						nateModule.RootPart.Velocity = Vector3.new();
						nateModule.StopAnimation("Unconscious");
						dallasModule.AvatarFace:Set("Grumpy");
						
						dallasModule.Humanoid.PlatformStand = false;
						dallasModule.RootPart.Velocity = Vector3.new();
						dallasModule.StopAnimation("Unconscious");
						dallasModule.AvatarFace:Set("Tired");
						
						nateModule.Actions:Teleport(CFrame.new(35.2659683, 162.593155, -36.1906471, 0.981627166, 0, -0.190808937, 0, 1, 0, 0.190808937, 0, 0.981627166));
						dallasModule.Actions:Teleport(CFrame.new(6.41975212, 162.593155, -58.1611061, -0.933579803, 0, -0.358367801, 0, 1, 0, 0.358367801, 0, -0.933579803));
						
					elseif mission.ProgressionPoint == 14 then
						nateModule.Movement:Move(Vector3.new(33.528, 162.593, -49.507));
						josephModule.StopAnimation("JosephDown2");
						josephModule.PlayAnimation("JosephNoArm");
						josephModule.Movement:SetWalkSpeed("default", 6);
						nateModule.Movement:SetWalkSpeed("default", 16);
						
						josephModule.RootPart.Anchored = false;
						josephModule.Actions:FollowOwner(function() return true end, nil, 12);
						nateModule.Actions:FollowOwner(function() return mission.ProgressionPoint == 15; end);
						nateModule.Wield.Equip("m4a4");
						nateModule.Actions:ProtectOwner(function()
							return true;
						end)
						nateModule.Chat(nateModule.Owner, "Let's go, I'll protect you guys..");
						
						modMission:Progress(player, missionId, function(mission)
							mission.ProgressionPoint = 15;
						end)
						
					elseif mission.ProgressionPoint == 15 then
						local new = radioStationTravel:Clone();
						new.Parent = workspace.Interactables;
						
					end
				elseif mission.Type == 3 then -- OnComplete


				end
			end
			mission.Changed:Connect(OnChanged);
			OnChanged(true);
		end)

		CutsceneSequence:NewScene("enableInterfaces", function()
			modConfigurations.Set("DisablePinnedMission", false);
			modConfigurations.Set("DisableHotbar", false);
			modConfigurations.Set("CanQuickEquip", true);
			modConfigurations.Set("DisableDialogue", false);
			modConfigurations.Set("DisableInventory", false);
			modConfigurations.Set("DisableHealthbar", false);
		end);
		
		local blurEffect;
		CutsceneSequence:NewScene("playerKnockout", function()
			local modCharacter = modData:GetModCharacter();
			local classPlayer = shared.modPlayers.Get(localPlayer);
			local head = classPlayer.Head;
			local humanoid = classPlayer.Humanoid;
			local rootPart = classPlayer.RootPart;

			local camera = workspace.CurrentCamera;
			
			blurEffect = Instance.new("BlurEffect");
			blurEffect.Name = "CutsceneBlur";
			blurEffect.Size = 6;
			blurEffect.Parent = camera;
			
			local unconsciousFace = head:FindFirstChild("face")
			if unconsciousFace then
				unconsciousFace = unconsciousFace:Clone();
				head.face.Parent = script;
				unconsciousFace.Parent = head;
				unconsciousFace.Texture = "rbxassetid://2255073000";
			end
			
			modConfigurations.Set("DisableHotbar", true);
			modConfigurations.Set("DisableInventory", true);
			modConfigurations.Set("DisableHealthbar", true);
			modConfigurations.Set("DisableWorkbench", true);
			modConfigurations.Set("DisableExperiencebar", true);
			modConfigurations.Set("DisableGeneralStats", true);
			modConfigurations.Set("DisableHotbar", true);
			modConfigurations.Set("CanQuickEquip", false);
			modConfigurations.Set("DisableSquadInterface", true);
			modConfigurations.Set("DisableMasteryMenu", true);
			
			rootPart.CFrame = CFrame.new(48.7122955, 162.593155, -49.6710472, 0, 0, 1, 0, 1, 0, -1, 0, 0);
			local unconsciousAnimation = humanoid:LoadAnimation(script:WaitForChild("Unconscious"));
			
			modCharacter.CharacterProperties.CanMove = false;
			modCharacter.CharacterProperties.CanInteract = false;
			modCharacter.MouseProperties.CameraSmoothing = 0.02;
			modCharacter.CharacterProperties.FirstPersonCamCFrame = CFrame.new(50.5999565, 162.369431, -49.1012726, 0.0182697475, 0.252551794, 0.967410922, -0, 0.967572391, -0.252593964, -0.999833107, 0.00461482815, 0.0176773053);
			rootPart.Anchored = true;
			unconsciousAnimation:Play();
		end);
		
		CutsceneSequence:NewScene("faint", function()
			local modInterface = modData:GetInterfaceModule();
			modInterface:ToggleGameBlinds(false, 3);
			task.wait(10);
			modInterface:ToggleGameBlinds(true, 6);
		end)
		
		CutsceneSequence:NewScene("playerWake", function()
			blurEffect.Size = 2;
			local modCharacter = modData:GetModCharacter();
			local classPlayer = shared.modPlayers.Get(localPlayer);
			local head = classPlayer.Head;
			local rootPart = classPlayer.RootPart;
			
			local unconsciousAnimation = modCharacter:GetAnimation("Unconscious");
			
			if head:FindFirstChild("newface") then head.newface:Destroy(); end
			if script:FindFirstChild("face") then script.face.Parent = head; end;
			rootPart.Anchored = false;
			if unconsciousAnimation then unconsciousAnimation:Stop(0.3); end
			
			modCharacter.MouseProperties.CameraSmoothing = 0;
			modCharacter.CharacterProperties.CanMove = true;
			modCharacter.CharacterProperties.CanInteract = true;
			modCharacter.CharacterProperties.FirstPersonCamCFrame = nil;
			modConfigurations.Set("DisablePinnedMission", false);
			modConfigurations.Set("DisableDialogue", false);
		end);



	elseif modBranchConfigs.IsWorld("TheMall") then
		-- MARK: TheMall
	
		local assetTheMall = script.Parent:WaitForChild("TheMallAssets");

		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, missionId);
			if mission == nil then return end;
				
			local nateModule = modNpc.GetPlayerNpc(player, "Nate");
			if nateModule == nil then
				local npc = modNpc.Spawn("Nate", CFrame.new(1105.325, 99.074, -578.587), function(npc, npcModule)
					npcModule.Owner = player;
					nateModule = npcModule;
				end);
				modReplicationManager.ReplicateOut(player, npc);
			end
			
			local josephModule = modNpc.GetPlayerNpc(player, "Joseph");
			if josephModule == nil then
				local npc = modNpc.Spawn("Joseph", CFrame.new(1105.325, 99.074, -578.587), function(npc, npcModule)
					npcModule.Owner = player;
					josephModule = npcModule;
				end);
				modReplicationManager.ReplicateOut(player, npc);
			end
			
			local mollyModule = modNpc.GetPlayerNpc(player, "Molly");
			if mollyModule == nil then
				local npc = modNpc.Spawn("Molly", nil, function(npc, npcModule)
					npcModule.Owner = player;
					mollyModule = npcModule;
				end);
				modReplicationManager.ReplicateOut(player, npc);
			end
			
			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable
					
				elseif mission.Type == 1 then -- OnActive
					if firstRun and mission.ProgressionPoint > 15 then
						modMission:Progress(player, missionId, function(mission)
							mission.ProgressionPoint = 15;
						end)
					else
						if mission.ProgressionPoint == 15 then
							nateModule.AvatarFace:Set("Grumpy");
							josephModule.SetAnimation("JosephNoArm", {script.JosephNoArm});
							josephModule.AvatarFace:Set("Frustrated");
							josephModule.PlayAnimation("JosephNoArm");
							
							josephModule.Movement:SetWalkSpeed("default", 6);
							nateModule.Movement:SetWalkSpeed("default", 16);
							
							josephModule.Actions:FollowOwner(function() return mission.ProgressionPoint == 15; end, nil, 12);
							
							nateModule.Wield.Equip("m4a4");
							nateModule.Actions:FollowOwner(function() return mission.ProgressionPoint == 15; end);
							nateModule.Actions:ProtectOwner(function()
								return mission.ProgressionPoint == 15;
							end)
							
							josephModule.Prefab.LeftLowerArm.Transparency = 1;
							josephModule.Prefab.LeftHand.Transparency = 1;
							
							nateModule.Interactable.Parent = script;
							josephModule.Interactable.Parent = script;
							remoteSetHeadIcon:FireClient(player, 1, "Joseph", "HideAll");
							
						elseif mission.ProgressionPoint == 16 then
							wait(0.5);
							nateModule.Actions:Teleport(CFrame.new(525.922974, 96.880806, -1094.84497, 1, 0, 0, 0, 1, 0, 0, 0, 1));
							josephModule.Actions:Teleport(CFrame.new(530.039429, 96.880806, -1094.13831, 1, 0, 0, 0, 1, 0, 0, 0, 1));
							
							spawn(function()
								josephModule.Movement:Move(Vector3.new(499.114, 96.781, -1096.703)):Wait();
								josephModule.Movement:Face(Vector3.new(502.829, 96.781, -1100.442));
								
							end)
							spawn(function()
								nateModule.Movement:Move(Vector3.new(510.818, 96.781, -1094.263)):Wait();
								nateModule.Movement:Face(Vector3.new(512.225, 96.781, -1100.017))
								nateModule.Wield.Unequip();
							end)
							
						elseif mission.ProgressionPoint == 17 then
							
							
						elseif mission.ProgressionPoint == 18 then
							
							josephModule.Actions:Teleport(CFrame.new(501.90802, 97.3525085, -1095.74792, 0.983893275, -1.08350854e-07, -0.178756803, 1.05717149e-07, 1, -2.42590161e-08, 0.178756803, 4.97062347e-09, 0.983893275));
							
							mollyModule.Movement:SetWalkSpeed("default", 8);
							mollyModule.Movement:Face(Vector3.new(512.225, 96.781, -1100.017))
							wait(1);
							
							mollyModule.Interactable.Parent = script;
							mollyModule.Movement:Move(Vector3.new(502.301, 96.881, -1098.085)):Wait();
							wait(0.6);
							mollyModule.Chat(mollyModule.Owner, "Alright.. Hold still..");
							josephModule.StopAnimation("JosephNoArm");
							josephModule.Movement:Face(Vector3.new(506.223, 96.261, -1097.082))
							wait(1);
							mollyModule.Chat(mollyModule.Owner, "*Patching*");
							mollyModule.PlayAnimation("Patching");
							wait(5);
							mollyModule.StopAnimation("Patching");
							mollyModule.Chat(mollyModule.Owner, "Done!");
							
							josephModule.Prefab.Bandage.Handle.Transparency = 0;
							wait(2);
							josephModule.Chat(josephModule.Owner, ".. Thanks..");
							josephModule.AvatarFace:Set("Skeptical");
							josephModule.Movement:Face(Vector3.new(504.616, 96.781, -1105.925))
							
							modMission:Progress(player, missionId, function(mission)
								if mission.ProgressionPoint == 18 then
									mission.ProgressionPoint = 19;
								end
							end)
							
						elseif mission.ProgressionPoint == 19 then
							josephModule.Interactable.Parent = josephModule.Prefab;
							mollyModule.Interactable.Parent = mollyModule.Prefab;
							mollyModule.Movement:Move(Vector3.new(508.767, 96.941, -1120.23)):Wait();
							mollyModule.Movement:Face(Vector3.new(509.305, 95.031, -1110.56));
							
						end
					end
				elseif mission.Type == 3 then -- OnComplete
					if not firstRun then
						josephModule.Movement:Move(Vector3.new(525.61, 99.44, -1089.824));
						wait(1);
						nateModule.Movement:Move(Vector3.new(525.61, 99.44, -1089.824)):Wait();
					end
					josephModule:TeleportHide();
					nateModule:TeleportHide();
					
				end
			end
			
			mission.Changed:Connect(OnChanged);
			OnChanged(true);
		end)


	else
		return;
	end

	return CutsceneSequence;
end;