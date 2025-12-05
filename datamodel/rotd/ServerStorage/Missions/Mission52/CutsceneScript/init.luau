local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);

--== Variables;
local MISSION_ID = 52;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

	if modBranchConfigs.IsWorld("TheInvestigation") then
		shared.modEventService:OnInvoked("Interactables_BindButtonInteract", function(eventPacket: EventPacket, ...)
			local player: Player? = eventPacket.Player;
			if player == nil then return end;

			local playerClass: PlayerClass = shared.modPlayers.get(player);
			if playerClass == nil then return end;

			local interactable: InteractableInstance = ...;
			if interactable == nil then return end;

			if interactable.Id == "mission52_CutStrap" then
				interactable.Part:Destroy();

				workspace.Environment:WaitForChild("StrapPart").Transparency = 1;
				modAudio.Play("HardSlice", workspace.Environment.StrapPart).PlaybackSpeed = 2;

				modMission:Progress(player, MISSION_ID, function(mission)
					mission.ProgressionPoint = 11;
				end)
			end
		end)
		

	elseif modBranchConfigs.IsWorld("TheMall") then
		shared.modEventService:OnInvoked("Interactables_BindDoorInteract", function(eventPacket: EventPacket, ...)
			local player: Player? = eventPacket.Player;
			if player == nil then return end;

			local interactable: InteractableInstance = ...;

			if interactable.Id == "clinicSafehouseEntrance" then
				modMission:Progress(player, MISSION_ID, function(mission) 
					if mission.ProgressionPoint == 15 then 
						mission.ProgressionPoint = 16;
					end;
				end)

			end
		end)

	end
else
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	local remotes = game.ReplicatedStorage:WaitForChild("Remotes");
	local remoteSetHeadIcon = remotes:WaitForChild("SetHeadIcon");
	
	if modBranchConfigs.IsWorld("TheResidentials") then
		-- MARK: TheResidentials
		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;
				
			local robertNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Robert");
			if robertNpcClass == nil then
				robertNpcClass = modNpcs.spawn2{
					Name = "Robert";
					Player = player;
					ReplicateOut = true;
				};
			end
			
			robertNpcClass:GetComponent("AvatarFace"):Set("Confident");

			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable
					
				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint == 1 then
						robertNpcClass:SetCFrame(CFrame.new(1076.85449, 57.5146675, -125.994919, 1, 0, 0, 0, 1, 0, 0, 0, 0.999996185));
						
					elseif mission.ProgressionPoint == 2 then
						robertNpcClass.Move:SetMoveSpeed("set", "default", 8);
						robertNpcClass.Move:MoveTo(Vector3.new(1127.26965, 57.664669, -60.4100342));
						
					elseif mission.ProgressionPoint == 3 then
						robertNpcClass.Move:SetMoveSpeed("set", "default", 16);
						
						robertNpcClass:GetComponent("FollowPlayer")(nil, function() 
							return mission.Type == 1 and mission.ProgressionPoint == 3;
						end)
						
					elseif mission.ProgressionPoint >= 15 then
						robertNpcClass:TeleportHide()

						local nateNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Nate");
						if nateNpcClass then
							modReplicationManager.UnreplicateFrom(player, nateNpcClass.Character);
						end
						
						local josephNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Joseph");
						if josephNpcClass then
							modReplicationManager.UnreplicateFrom(player, josephNpcClass.Character);
						end
						
					elseif mission.ProgressionPoint >= 4 then
						modMission:Progress(player, MISSION_ID, function(mission)
							mission.ProgressionPoint = 3;
						end)
						
					end
				elseif mission.Type == 3 then -- OnComplete
					robertNpcClass:TeleportHide();
					
				end
			end
			mission.OnChanged:Connect(OnChanged);
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
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;
				
	
			local robertNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Robert");
			if robertNpcClass == nil then
				robertNpcClass = modNpcs.spawn2{
					Name = "Robert";
					CFrame = CFrame.new(12.7279015, 162.617722, -63.8735542, 0, 0, -1, 0, 1, 0, 1, 0, 0);
					Player = player;
					ReplicateOut = true;
				};
				robertNpcClass.Properties.Immortal = 0.5;
			end
			
			local nateNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Nate");
			if nateNpcClass == nil then
				nateNpcClass = modNpcs.spawn2{
					Name = "Nate";
					CFrame = CFrame.new(35.2480125, 162.593155, -34.3742752, -1, 0, 0, 0, 1, 0, 0, 0, -1);
					Player = player;
					ReplicateOut = true;
				};
			end
			
			local dallasNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Dallas");
			if dallasNpcClass == nil then
				dallasNpcClass = modNpcs.spawn2{
					Name = "Dallas";
					CFrame = CFrame.new(38.07024, 176.987366, -44.433876, -1, 0, 0, 0, 1, 0, 0, 0, -1);
					Player = player;
					ReplicateOut = true;
				};
				--dallasNpcClass.Character:SetAttribute("LookAtClient", false);
			end
			
			local josephNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Joseph");
			if josephNpcClass == nil then
				josephNpcClass = modNpcs.spawn2{
					Name = "Joseph";
					CFrame = CFrame.new(38.07024, 176.987366, -44.433876, -1, 0, 0, 0, 1, 0, 0, 0, -1);
					Player = player;
					ReplicateOut = true;
				};
				--josephNpcClass.Character:SetAttribute("LookAtClient", false);
			end
			
			local zarkNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Zark");
			if zarkNpcClass == nil then
				zarkNpcClass = modNpcs.spawn2{
					Name = "Zark";
					CFrame = CFrame.new(38.07024, 176.987366, -44.433876, -1, 0, 0, 0, 1, 0, 0, 0, -1);
					Player = player;
					ReplicateOut = true;
				};
			end
			
			local banditNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Bandit");
			if banditNpcClass == nil then
				banditNpcClass = modNpcs.spawn2{
					Name = "Bandit";
					CFrame = CFrame.new(38.07024, 176.987366, -44.433876, -1, 0, 0, 0, 1, 0, 0, 0, -1);
					Player = player;
					ReplicateOut = true;
					PackageOverride = "Human";
				};
			end
			
			robertNpcClass:GetComponent("AvatarFace"):Set("Skeptical");
			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable
					
				elseif mission.Type == 1 then -- OnActive
					if firstRun and mission.ProgressionPoint > 3 then
						modMission:Progress(player, MISSION_ID, function(mission)
							mission.ProgressionPoint = 3;
						end)
					end

					if mission.ProgressionPoint == 3 then
						CutsceneSequence:NextScene("enableInterfaces");
						modMission:Progress(player, MISSION_ID, function(mission)
							mission.ProgressionPoint = 4;
						end)
						robertNpcClass:ToggleInteractable(false)
						
					elseif mission.ProgressionPoint == 4 then
						robertNpcClass.Chat(player, "What's going on here..");
						
						robertNpcClass:GetComponent("FollowPlayer")(nil, function()
							if (robertNpcClass.RootPart.Position-Vector3.new(37.134, 164.003, -45.589)).Magnitude <= 16 then
								modMission:Progress(player, MISSION_ID, function(mission)
									mission.ProgressionPoint = 5;
								end)
							end

							return mission.Type == 1 and mission.ProgressionPoint == 4;
						end);
						
						nateNpcClass:ToggleInteractable(false);
						dallasNpcClass:ToggleInteractable(false);
						josephNpcClass:ToggleInteractable(false);
						zarkNpcClass:ToggleInteractable(false);
						
					elseif mission.ProgressionPoint == 5 then
						robertNpcClass.SetAnimation("Punch", {assetTheInvestigation.Punch});
						robertNpcClass.SetAnimation("RobertLoseHand", {assetTheInvestigation.RobertLoseHand});
						robertNpcClass.SetAnimation("RobertInvestigate1", {assetTheInvestigation.RobertInvestigate1});
						josephNpcClass.SetAnimation("JosephInvestigate1", {assetTheInvestigation.JosephInvestigate1});
						josephNpcClass.SetAnimation("JosephDown", {assetTheInvestigation.JosephDown});
						josephNpcClass.SetAnimation("JosephDown2", {assetTheInvestigation.JosephDown2});
						josephNpcClass.SetAnimation("JosephNoArm", {script.JosephNoArm});
						zarkNpcClass.SetAnimation("LookAround", {assetTheInvestigation.LookAround});
						zarkNpcClass.SetAnimation("CrouchLookAnim", {assetTheInvestigation.CrouchLookAnim});
						
						remoteSetHeadIcon:FireClient(player, 1, "Joseph", "HideAll");
						dallasNpcClass:SetCFrame(CFrame.new(12.7279015, 162.617722, -63.8735542, 0, 0, -1, 0, 1, 0, 1, 0, 0));
						dallasNpcClass.Move:MoveTo(Vector3.new(27.336, 162.593, -48.273));
						dallasNpcClass.Move:HeadTrack(robertNpcClass.Head, 60);

						josephNpcClass:SetCFrame(CFrame.new(12.7279015, 162.617722, -63.8735542, 0, 0, -1, 0, 1, 0, 1, 0, 0));
						josephNpcClass.Move:SetMoveSpeed("set", "default", 10);
						task.wait(0.2);
						robertNpcClass.Move:MoveTo(Vector3.new(36.017, 162.593, -44.846));
						robertNpcClass.Move.OnMoveToEnded:Wait(10);
						
						nateNpcClass.Chat(player, "Hold it right there buddy.");
						nateNpcClass.Move:HeadTrack(robertNpcClass.Head, 30);
						robertNpcClass.Move:HeadTrack(nateNpcClass.Head, 30);

						nateNpcClass.WieldComp:Equip{
							ItemId = "m4a4";
						};
						nateNpcClass.WieldComp.TargetableTags.Robert = true;
						dallasNpcClass.WieldComp:Equip{
							ItemId = "m4a4";
						};
						dallasNpcClass.WieldComp.TargetableTags.Robert = true;

						nateNpcClass.Move:Face(robertNpcClass.RootPart);
						robertNpcClass:GetComponent("AvatarFace"):Set("Disbelief");
						nateNpcClass:GetComponent("AvatarFace"):Set("Angry");
						dallasNpcClass:GetComponent("AvatarFace"):Set("Suspicious");
						josephNpcClass:GetComponent("AvatarFace"):Set("Skeptical");
						robertNpcClass.Move:Face(nateNpcClass.RootPart);
						
						wait(0.45);
						robertNpcClass.PlayAnimation("Surrender");
						task.wait(1.5);
						robertNpcClass.Chat(player, "Huh?!");
						modMission:Progress(player, MISSION_ID, function(mission)
							mission.ProgressionPoint = 6;
						end)
						
					elseif mission.ProgressionPoint == 6 then
						josephNpcClass.Move:MoveTo(Vector3.new(34.36, 162.593, -53.878));
						josephNpcClass.Move.OnMoveToEnded:Wait(5);
						josephNpcClass.Move:Face(robertNpcClass.RootPart.Position);
						dallasNpcClass.Move:Face(robertNpcClass.RootPart.Position);
						josephNpcClass.PlayAnimation("CrossedArm");
						
						robertNpcClass.Move:HeadTrack(nateNpcClass.Head, 60);
						nateNpcClass.Move:HeadTrack(robertNpcClass.Head, 60);
						josephNpcClass.Move:HeadTrack(robertNpcClass.Head, 60);
						dallasNpcClass.Move:HeadTrack(robertNpcClass.Head, 60);

						nateNpcClass.Chat(player, "WHO ARE YOU?!");
						wait(5);
						robertNpcClass.Chat(player, "What!? What's going on?!");
						wait(5);
						nateNpcClass.Chat(player, "You are an infector, aren't you!?");
						wait(5);
						robertNpcClass.Chat(player, "What? What make you think that!? I saved your life!");
						robertNpcClass:GetComponent("AvatarFace"):Set("Disgusted");
						wait(5);
						nateNpcClass.Chat(player, "YES, but you just wanted to know about this safehouse..");
						wait(5);
						robertNpcClass.Chat(player, "I SWEAR, I'M NOT AN INFECTOR!! HOW CAN I PROVE MYSELF?!");
						robertNpcClass:GetComponent("AvatarFace"):Set("Grumpy");
						wait(5);
						josephNpcClass.Chat(player, "Shoot him");
						wait(0.5);
						dallasNpcClass:GetComponent("AvatarFace"):Set("Surprise");
						nateNpcClass:GetComponent("AvatarFace"):Set("Disbelief");
						wait(0.5);
						robertNpcClass:GetComponent("AvatarFace"):Set("Scared");
						nateNpcClass.Chat(player, "Joseph, are you sure?!");
						wait(1);
						robertNpcClass.Chat(player, "WHAT?! NO!");
						wait(1);
						dallasNpcClass.Chat(player, "Oof");
						wait(5);
						josephNpcClass.Chat(player, "Yes. Shoot him");
						josephNpcClass.Move:HeadTrack(nateNpcClass.Head, 5);
						
						local lastDamaged = tick();
						robertNpcClass.Garbage:Tag(robertNpcClass.HealthComp.OnHealthChanged:Connect(function(oldHp, newHp, reason)
							robertNpcClass.Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn;
							lastDamaged = tick();
							delay(2, function()
								if tick()-lastDamaged > 2 and robertNpcClass.Humanoid then
									robertNpcClass.Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
								end;
							end);
							
							RunService.Heartbeat:Wait();
							local hurtSound = modAudio.Play("ZombieHurt", robertNpcClass.RootPart);
							hurtSound.Volume = math.random(50, 60)/100;
							hurtSound.PlaybackSpeed = math.random(110, 120)/100;
						end));
						
						task.wait(1.2);
						
						local dir = (robertNpcClass.RootPart.Position - nateNpcClass.RootPart.Position).Unit;
						nateNpcClass.WieldComp:InvokeToolAction("PrimaryFireRequest", dir, robertNpcClass.Humanoid);
						josephNpcClass.Move:HeadTrack(robertNpcClass.Head, 5);
						delay(0.6, function()
							nateNpcClass.WieldComp.Controls.Mouse1Down = false;
						end)
						
						wait(0.3);
						josephNpcClass.Move:HeadTrack(nateNpcClass.Head, 5);
						josephNpcClass.StopAnimation("CrossedArm");
						robertNpcClass.StopAnimation("Surrender");
						
						robertNpcClass.Chat(player, "*Infector Ouch*");
						task.spawn(function()
							for a=1, 3 do
								local hurtSound = modAudio.Play(`ZombieHurt{math.random(1,2)}`, robertNpcClass.Head);
								hurtSound.Volume = math.random(50, 60)/100;
								hurtSound.PlaybackSpeed = math.random(110, 120)/100;
								robertNpcClass.PlayAnimation("Flinch", 0.05, nil, 2);
								task.wait(0.15);
								robertNpcClass.StopAnimation("Flinch");
							end
						end)
						
						robertNpcClass:GetComponent("AvatarFace"):Set("Infector");
						nateNpcClass:GetComponent("AvatarFace"):Set("Scared");
						dallasNpcClass:GetComponent("AvatarFace"):Set("Scared");
						josephNpcClass:GetComponent("AvatarFace"):Set("Serious");
						wait(1);
						josephNpcClass.WieldComp:Equip{ItemId = "pickaxe"};
						wait(1);
						dallasNpcClass.Chat(player, "Oh snap..");
						wait(1);
						josephNpcClass.Chat(player, "Hmmm..");
						wait(1);
						robertNpcClass.Chat(player, "Heh heh heh...");
						wait(1);
						nateNpcClass.Chat(player, "SHOOT!! SHOOOT!!!");
						modMission:Progress(player, MISSION_ID, function(mission)
							mission.ProgressionPoint = 7;
						end)
						
					elseif mission.ProgressionPoint == 7 then
						wait(1);
						local playerClass: PlayerClass = shared.modPlayers.get(player);
						
						robertNpcClass.Chat(player, "Well, guess there will be a minor setback for my plans..");
						robertNpcClass.Move:HeadTrack(nateNpcClass.Head, 10);
						
						local nateDir = (robertNpcClass.RootPart.Position - nateNpcClass.RootPart.Position).Unit;
						nateNpcClass.WieldComp:InvokeToolAction("PrimaryFireRequest", nateDir, robertNpcClass.Humanoid);
						nateNpcClass.Move:HeadTrack(robertNpcClass.Head, 10);
						
						local dallasDir = (robertNpcClass.RootPart.Position - nateNpcClass.RootPart.Position).Unit;
						dallasNpcClass.WieldComp:InvokeToolAction("PrimaryFireRequest", dallasDir, robertNpcClass.Humanoid);
						dallasNpcClass.Move:HeadTrack(robertNpcClass.Head, 10);
						
						wait(1.5);
						robertNpcClass.Chat(player, "I'm done with this..");
						wait(1.5);
						robertNpcClass.Move:SetMoveSpeed("set", "default", 30);

						robertNpcClass.Move:MoveTo(nateNpcClass.RootPart.Position);
						task.wait(0.5);
						
						robertNpcClass.PlayAnimation("Punch");
						modAudio.Play("Punch", robertNpcClass.RootPart);
						task.wait(0.2);
						task.spawn(function()
							dallasNpcClass.WieldComp:InvokeToolAction("ReloadRequest");
						end)
						nateNpcClass.Humanoid.PlatformStand = true;
						
						nateNpcClass.RootPart:ApplyImpulse(Vector3.new(0, 500, 1000));
						nateNpcClass.WieldComp:Unequip();
						nateNpcClass:GetComponent("AvatarFace"):Set("Unconscious");
						nateNpcClass.PlayAnimation("Unconscious");
						nateNpcClass.Move:HeadTrack(nil);

						shared.modPlayers.cameraShakeAndZoom(player, 5, 0, 1, 2, false);
						josephNpcClass.Move:Face(robertNpcClass.RootPart.Position);
						
						nateNpcClass.Chat(player, "Uagh!");
						for _, obj in pairs(waterBarrels:GetDescendants()) do
							if obj:IsA("BasePart") then
								obj.Anchored = false;
								obj:ApplyImpulse(Vector3.new(0, 60, -120));
							end
						end
						modAudio.Play("PlasticBarrelHit", nateNpcClass.RootPart);
						
						robertNpcClass.Move:HeadTrack(dallasNpcClass.Head, 10);
						wait(0.8);

						robertNpcClass.Move:MoveTo(dallasNpcClass.RootPart.Position);
						robertNpcClass.Move.OnMoveToEnded:Wait(1);
						
						josephNpcClass.Chat(player, "Dallas!");
						josephNpcClass.Move:Face(robertNpcClass.RootPart.Position);
						josephNpcClass.Move:HeadTrack(dallasNpcClass.Head, 10);
						robertNpcClass.PlayAnimation("Punch");
						modAudio.Play("Punch", robertNpcClass.RootPart);
						
						wait(0.2);
						
						dallasNpcClass.Humanoid.PlatformStand = true;
						
						dallasNpcClass.RootPart:ApplyImpulse(Vector3.new(-800, 500, -400));
						dallasNpcClass.WieldComp:Unequip();
						dallasNpcClass:GetComponent("AvatarFace"):Set("Unconscious");
						dallasNpcClass.PlayAnimation("Unconscious");
						dallasNpcClass.Move:HeadTrack(nil);
						
						shared.modPlayers.cameraShakeAndZoom(player, 5, 0, 1, 2, false);
						josephNpcClass.Move:Face(robertNpcClass.RootPart.Position);
						task.wait(1);
						
						robertNpcClass.Move:HeadTrack(playerClass.Head, 10);
						task.wait(1);
						josephNpcClass.Move:SetMoveSpeed("set", "default", 14);

						robertNpcClass.Move:MoveTo(playerClass.RootPart.Position);
						
						local robertWaitForPlayerComp = robertNpcClass:GetComponent("WaitForPlayer");
						robertWaitForPlayerComp(6);
						robertWaitForPlayerComp.FacePlayerWhileWaiting = false;
						
						robertNpcClass.PlayAnimation("Punch");
						modAudio.Play("Punch", robertNpcClass.RootPart);
						wait(0.2);
						
						playerClass.WieldComp:Unequip();
						josephNpcClass.Move:HeadTrack(nil);
						robertNpcClass.Move:HeadTrack(nil);
						
						CutsceneSequence:NextScene("playerKnockout");
						shared.Notify(player, "*Helicopter approaching..*", "Message");
						
						local heliSound = modAudio.Play("HelicopterCore", workspace.Environment.ChopperSound);
						heliSound.Volume = 0;
						TweenService:Create(heliSound, TweenInfo.new(10), {Volume = 1;}):Play();
						
						shared.modPlayers.cameraShakeAndZoom(player, 5, 0, 1, 2, false);
						robertNpcClass:SetCFrame(CFrame.new(41.6181221, 162.593155, -48.860527, 0, 0, -1, 0, 1, 0, 1, 0, 0));
						wait(1);

						josephNpcClass.Move:HeadTrack(robertNpcClass.Head, 4);
						robertNpcClass.Move:HeadTrack(josephNpcClass.Head, 4);

						josephNpcClass.Move:MoveTo(Vector3.new(39.078, 162.593, -50.709))
						josephNpcClass.Move.OnMoveToEnded:Wait();
						robertNpcClass.Move:Face(josephNpcClass.RootPart);
						wait(0.2);
						
						robertNpcClass.PlayAnimation("RobertLoseHand")
						robertNpcClass.AnimationController:LoopTracks("RobertLoseHand", function(trackData)
							local track = trackData.Track;
							track:GetMarkerReachedSignal("LoseHand"):Connect(function()
								local robertChar = robertNpcClass.Character;

								robertChar.RightLowerArm.Wound.Blood.Enabled = true;
								delay(0.1, function()
									robertChar.RightHand.Transparency = 1;
								end)
								for a=1, 10 do
									robertChar.RightLowerArm.Wound.Blood:Emit(4);
									RunService.Heartbeat:Wait();
									robertChar.RightLowerArm.Wound.Blood:Emit(4);
									RunService.Heartbeat:Wait();
								end
							end);
						end)
						
						josephNpcClass.WieldComp:InvokeToolAction("PrimarySwingRequest");
						wait(0.1);

						robertNpcClass.Chat(player, "AHHHGH");
						modAudio.Play("Slice", robertNpcClass.RootPart);
						local hurtSound = modAudio.Play(`ZombieHurt{math.random(1,2)}`, robertNpcClass.RootPart);
						hurtSound.Volume = math.random(50,60)/100;
						hurtSound.PlaybackSpeed = 0.7;
						robertLeftHand.Parent = workspace.Environment;
						
						wait(1);
						spawn(function()
							for a=1, 2 do
								wait(0.1);
								robertNpcClass.Humanoid.Health = robertNpcClass.Humanoid.Health -1;
							end
						end)
						robertNpcClass.RootPart.Anchored = true;
						robertNpcClass:SetCFrame(CFrame.new(41.5883179, 162.593445, -48.8697166, 0.563169777, 4.99064043e-08, 0.826341212, -8.86618352e-08, 1, 3.05726382e-11, -0.826341212, -7.32821519e-08, 0.563169777));
						josephNpcClass.RootPart.Anchored = true;
						josephNpcClass.RootPart.CanCollide = false;
						josephNpcClass:SetCFrame(CFrame.new(38.3455811, 162.593445, -51.0908356, -0.523620725, -3.62133896e-08, -0.85195148, 4.10249186e-08, 1, -6.77208547e-08, 0.85195148, -7.04112821e-08, -0.523620725));
						
						robertNpcClass.PlayAnimation("RobertInvestigate1");
						
						local investigateTrack = josephNpcClass.GetAnimation("JosephInvestigate1");
						investigateTrack:GetMarkerReachedSignal("Ugh"):Connect(function()
							josephNpcClass.Chat(player, "Ugh");
							josephNpcClass.WieldComp:Unequip();
						end)
						investigateTrack:GetMarkerReachedSignal("LoseArm"):Connect(function()
							shared.modPlayers.cameraShakeAndZoom(player, 5, 0, 1, 2, false);
							josephNpcClass.Chat(player, "UGGGHHH");
							josephNpcClass.Move:HeadTrack(nil);
							modAudio.Play("WeakPointImpact", josephNpcClass.RootPart);
							
							local josephChar = josephNpcClass.Character;
							
							delay(0.3, function()
								josephChar.LeftLowerArm.LeftElbow:Destroy();
								josephChar.LeftLowerArm.CanCollide = true;
							end)
							josephChar.LeftUpperArm.Wound.Blood.Enabled = true;
							
							for a=1, 10 do
								josephChar.LeftUpperArm.Wound.Blood:Emit(8);
								RunService.Heartbeat:Wait();
								RunService.Heartbeat:Wait();
							end
						end)
						
						josephNpcClass.PlayAnimation("JosephInvestigate1");
						
						for a=1, 7 do
							task.wait(1);
							Debugger:Log("investigateTrack waiting", investigateTrack.Length)
							if not investigateTrack.IsPlaying then break; end;
						end
						
						josephNpcClass.PlayAnimation("JosephDown", 0);
						wait(1);
						robertNpcClass.RootPart.Anchored = false;
						
						robertNpcClass.Move:MoveTo(Vector3.new(-10.408, 162.593, -48.561));
						robertNpcClass.Move.OnMoveToEnded:Wait(1);
						
						robertNpcClass.PlayAnimation("Punch");
						modAudio.Play("Punch", robertNpcClass.RootPart);
						wait(0.2);
						modAudio.Play("ConcreteSmash", robertNpcClass.RootPart);
						wait(0.35);
						cutsceneWallDestroy:Destroy();
						shared.modPlayers.cameraShakeAndZoom(player, 10, 0, 1, 2, false);
						local new = assetTheInvestigation.rockDebris:Clone();
						new.Parent = workspace.Debris;
						for _, obj in pairs(new:GetDescendants()) do
							if obj:IsA("BasePart") then
								obj.Anchored = false;
								obj:ApplyImpulse(Vector3.new(100, 60, 0));
							end
						end
						
						robertNpcClass.Move:MoveTo(Vector3.new(-16.408, 162.593, -48.561));
						wait(1.5);
						robertNpcClass:TeleportHide();
						--robertModule.Actions:Teleport(CFrame.new(38.07024, 176.987366, -44.433876, -1, 0, 0, 0, 1, 0, 0, 0, -1));
						
						wait(3);
						shared.Notify(player, "*Helicopter lands upstairs..*", "Message");
						TweenService:Create(heliSound, TweenInfo.new(5), {Volume = 0;}):Play();
						CutsceneSequence:NextScene("faint");
						wait(5);
						modMission:Progress(player, MISSION_ID, function(mission)
							mission.ProgressionPoint = 8;
						end)
						
					elseif mission.ProgressionPoint == 8 then
						zarkNpcClass:SetCFrame(CFrame.new(12.7279015, 162.617722, -63.8735542, 0, 0, -1, 0, 1, 0, 1, 0, 0));
						banditNpcClass:GetComponent("AvatarFace"):Set("Serious");
						banditNpcClass:SetCFrame(CFrame.new(6.9413929, 162.593445, -64.6298904, -1, 0, 0, 0, 1, 0, 0, 0, -1));
						banditNpcClass.WieldComp:Equip{ItemId = "fnfal"};
						banditNpcClass.Move:SetMoveSpeed("set", "default", 0);
						banditNpcClass.Move:MoveTo(Vector3.new(34.447, 162.593, -41.027));
						delay(1, function()
							banditNpcClass.Move:SetMoveSpeed("set", "default", 6);
						end)
						
						zarkNpcClass.Move:MoveTo(Vector3.new(24.827, 162.593, -49.793));
						zarkNpcClass.Move.OnMoveToEnded:Wait(10);
						
						banditNpcClass.Move:Face(Vector3.new(34.447, 162.593, -34.47));
						zarkNpcClass.Move:SetMoveSpeed("set", "default", 6);
						zarkNpcClass.PlayAnimation("LookAround");
						zarkNpcClass.Chat(zarkNpcClass.Player, "Hmmm, so Robert was indeed one of the infectors.");
					
						zarkNpcClass.Move:MoveTo(Vector3.new(42.254, 162.593, -49.369));
						zarkNpcClass.Move.OnMoveToEnded:Wait(10);
						
						zarkNpcClass:GetComponent("AvatarFace"):Set("Confident");
						wait(0.5);
						zarkNpcClass:SetCFrame(CFrame.new(41.462471, 162.593445, -49.2249641, 0.0611268133, -2.64448197e-09, -0.998130023, 4.32557741e-08, 1, -3.95256121e-13, 0.998130023, -4.3174861e-08, 0.0611268133));
						
						zarkNpcClass.PlayAnimation("CrouchLookAnim");
						task.wait(2.5);
						
						local zarkChar = zarkNpcClass.Character;
						local newWeld = assetTheInvestigation.RobertLeftHandWeld:Clone();
						robertLeftHand.Parent = zarkChar;
						newWeld.Parent = zarkChar.RightHand;
						robertLeftHand.Anchored = false;
						newWeld.Part0 = zarkChar.RightHand;
						newWeld.Part1 = robertLeftHand;
						wait(1);

						zarkNpcClass.StopAnimation("CrouchLookAnim");
						zarkNpcClass.Chat(zarkNpcClass.Player, "One's already been captured.. Soon we will get our hands on Robert and also put him on a leash.");
						banditNpcClass.Move:Face(Vector3.new(44.301, 162.593, -48.655));
						wait(5);

						zarkNpcClass.Move:MoveTo(Vector3.new(14.223, 162.593, -63.75))
						wait(3);

						banditNpcClass.Move:MoveTo(Vector3.new(14.223, 162.593, -63.75));
						wait(3);

						CutsceneSequence:NextScene("faint");
						CutsceneSequence:NextScene("playerWake");
						wait(3);

						zarkNpcClass:SetCFrame(CFrame.new(38.07024, 176.987366, -44.433876, -1, 0, 0, 0, 1, 0, 0, 0, -1));
						banditNpcClass:SetCFrame(CFrame.new(38.07024, 176.987366, -44.433876, -1, 0, 0, 0, 1, 0, 0, 0, -1));
						
						modMission:Progress(player, MISSION_ID, function(mission)
							mission.ProgressionPoint = 9;
						end)
						
					elseif mission.ProgressionPoint == 9 then
						josephNpcClass:ToggleInteractable(true);
						josephNpcClass:GetComponent("AvatarFace"):Set("Frustrated");
						
					elseif mission.ProgressionPoint == 10 then
						local newStrap = cutStrap:Clone();
						newStrap.Parent = workspace.Interactables;
						
					elseif mission.ProgressionPoint == 12 then
						--josephModule.Prefab.Bandage.Handle.Transparency = 0;
						local josephChar = josephNpcClass.Character;
						josephChar.LeftUpperArm.Wound.Blood.Enabled = false;
						josephNpcClass.PlayAnimation("JosephDown2", 0);
						josephNpcClass.StopAnimation("JosephDown");
						
						nateNpcClass:ToggleInteractable(true);
						
					elseif mission.ProgressionPoint == 13 then
						
						nateNpcClass.Humanoid.PlatformStand = false;
						nateNpcClass.RootPart.AssemblyLinearVelocity = Vector3.new();
						nateNpcClass.StopAnimation("Unconscious");
						dallasNpcClass:GetComponent("AvatarFace"):Set("Grumpy");
						
						dallasNpcClass.Humanoid.PlatformStand = false;
						dallasNpcClass.RootPart.AssemblyLinearVelocity = Vector3.new();
						dallasNpcClass.StopAnimation("Unconscious");
						dallasNpcClass:GetComponent("AvatarFace"):Set("Tired");
						
						nateNpcClass:SetCFrame(CFrame.new(35.2659683, 162.593155, -36.1906471, 0.981627166, 0, -0.190808937, 0, 1, 0, 0.190808937, 0, 0.981627166));
						dallasNpcClass:SetCFrame(CFrame.new(6.41975212, 162.593155, -58.1611061, -0.933579803, 0, -0.358367801, 0, 1, 0, 0.358367801, 0, -0.933579803));
						
					elseif mission.ProgressionPoint == 14 then
						nateNpcClass.Move:MoveTo(Vector3.new(33.528, 162.593, -49.507));
						josephNpcClass.StopAnimation("JosephDown2");
						josephNpcClass.PlayAnimation("JosephNoArm");
						josephNpcClass.Move:SetMoveSpeed("set", "default", 6);
						nateNpcClass.Move:SetMoveSpeed("set", "default", 16);
						
						josephNpcClass.RootPart.Anchored = false;

						josephNpcClass:GetComponent("FollowPlayer")();
						nateNpcClass:GetComponent("FollowPlayer")(nil, function()
							return mission.ProgressionPoint == 15;
						end);
						
						nateNpcClass.WieldComp:Equip{ ItemId = "m4a4" };
						nateNpcClass:GetComponent("ProtectPlayer")();
						nateNpcClass.Chat(player, "Let's go, I'll protect you guys..");
						
						modMission:Progress(player, MISSION_ID, function(mission)
							mission.ProgressionPoint = 15;
						end)
						
					elseif mission.ProgressionPoint == 15 then
						local new = radioStationTravel:Clone();
						new.Parent = workspace.Interactables;
						
					end
				elseif mission.Type == 3 then -- OnComplete


				end
			end
			mission.OnChanged:Connect(OnChanged);
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
			local playerClass: PlayerClass = shared.modPlayers.get(localPlayer);
			local head = playerClass.Head;
			local humanoid = playerClass.Humanoid;
			local rootPart = playerClass.RootPart;

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
			local playerClass: PlayerClass = shared.modPlayers.get(localPlayer);
			local head = playerClass.Head;
			local rootPart = playerClass.RootPart;
			
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
	
		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player: Player = players[1];
			local mission = modMission:GetMission(player, MISSION_ID);
			if mission == nil then return end;
				
			local nateNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Nate");
			if nateNpcClass == nil then
				nateNpcClass = modNpcs.spawn2{
					Name = "Nate";
					CFrame = CFrame.new(1105.325, 99.074, -578.587);
					Player = player;
					ReplicateOut = true;
				};
			end
			
			local josephNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Joseph");
			if josephNpcClass == nil then
				josephNpcClass = modNpcs.spawn2{
					Name = "Joseph";
					CFrame = CFrame.new(1105.325, 99.074, -578.587);
					Player = player;
					ReplicateOut = true;
				};
			end
			
			local mollyNpcClass: NpcClass = modNpcs.getPlayerNpc(player, "Molly");
			if mollyNpcClass == nil then
				mollyNpcClass = modNpcs.spawn2{
					Name = "Molly";
					CFrame = CFrame.new();
					Player = player;
					ReplicateOut = true;
				};
			end
			
			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable
					
				elseif mission.Type == 1 then -- OnActive
					local josephChar = josephNpcClass.Character;

					if firstRun and mission.ProgressionPoint >= 16 then
						nateNpcClass:SetCFrame(CFrame.new(510.818, 96.781, -1094.263));
						josephNpcClass:SetCFrame(CFrame.new(499.114, 96.781, -1096.703));
						
						task.wait(0.1);
						josephNpcClass.Move:Face(Vector3.new(502.829, 96.781, -1100.442));
						nateNpcClass.Move:Face(Vector3.new(512.225, 96.781, -1100.017))

						nateNpcClass:GetComponent("AvatarFace"):Set("Grumpy");
						josephNpcClass.SetAnimation("JosephNoArm", {script.JosephNoArm});
						josephNpcClass:GetComponent("AvatarFace"):Set("Frustrated");
						josephNpcClass.PlayAnimation("JosephNoArm");

						josephChar.LeftLowerArm.Transparency = 1;
						josephChar.LeftHand.Transparency = 1;
						
						if mission.ProgressionPoint  < 19 then
							nateNpcClass:ToggleInteractable(false);
							josephNpcClass:ToggleInteractable(false);
							remoteSetHeadIcon:FireClient(player, 1, "Joseph", "HideAll");
						end
					end

					if mission.ProgressionPoint == 15 then
						nateNpcClass:GetComponent("AvatarFace"):Set("Grumpy");
						josephNpcClass.SetAnimation("JosephNoArm", {script.JosephNoArm});
						josephNpcClass:GetComponent("AvatarFace"):Set("Frustrated");
						josephNpcClass.PlayAnimation("JosephNoArm");
						
						josephNpcClass.Move:SetMoveSpeed("set", "default", 6);
						nateNpcClass.Move:SetMoveSpeed("set", "default", 16);
						
						josephNpcClass:GetComponent("FollowPlayer")(nil, function()
							return mission.ProgressionPoint == 15; 
						end, 10);
						
						nateNpcClass.WieldComp:Equip{
							ItemId = "m4a4";
						};
						nateNpcClass:GetComponent("FollowPlayer")(nil, function() 
							return mission.ProgressionPoint == 15; 
						end, 16);
						
						nateNpcClass:GetComponent("ProtectPlayer")(function() 
							return mission.ProgressionPoint == 15;
						end);

						josephChar.LeftLowerArm.Transparency = 1;
						josephChar.LeftHand.Transparency = 1;
						
						nateNpcClass:ToggleInteractable(true);
						josephNpcClass:ToggleInteractable(true);
						remoteSetHeadIcon:FireClient(player, 1, "Joseph", "HideAll");
						
					elseif mission.ProgressionPoint == 16 then
						wait(0.5);
						nateNpcClass:SetCFrame(CFrame.new(525.922974, 96.880806, -1094.84497, 1, 0, 0, 0, 1, 0, 0, 0, 1));
						josephNpcClass:SetCFrame(CFrame.new(530.039429, 96.880806, -1094.13831, 1, 0, 0, 0, 1, 0, 0, 0, 1));
						
						spawn(function()
							josephNpcClass.Move:MoveTo(Vector3.new(499.114, 96.781, -1096.703));
							josephNpcClass.Move.OnMoveToEnded:Wait(5);
							josephNpcClass.Move:Face(Vector3.new(502.829, 96.781, -1100.442));
							
						end)
						spawn(function()
							nateNpcClass.Move:MoveTo(Vector3.new(510.818, 96.781, -1094.263));
							nateNpcClass.Move.OnMoveToEnded:Wait(5);
							nateNpcClass.Move:Face(Vector3.new(512.225, 96.781, -1100.017))
							nateNpcClass.WieldComp:Unequip();
						end)
						
					elseif mission.ProgressionPoint == 17 then
						
						
					elseif mission.ProgressionPoint == 18 then
						
						josephNpcClass:SetCFrame(CFrame.new(501.90802, 97.3525085, -1095.74792, 0.983893275, -1.08350854e-07, -0.178756803, 1.05717149e-07, 1, -2.42590161e-08, 0.178756803, 4.97062347e-09, 0.983893275));
						
						mollyNpcClass.Move:SetMoveSpeed("set", "default", 8);
						mollyNpcClass.Move:Face(Vector3.new(512.225, 96.781, -1100.017))
						task.wait(1);
						
						mollyNpcClass.Move:HeadTrack(josephNpcClass.Head, 10);
						josephNpcClass.Move:HeadTrack(mollyNpcClass.Head, 6);

						mollyNpcClass:ToggleInteractable(true);
						mollyNpcClass.Move:MoveTo(Vector3.new(502.301, 96.881, -1098.085));
						mollyNpcClass.Move.OnMoveToEnded:Wait(3);
						task.wait(0.6);

						mollyNpcClass.Chat(mollyNpcClass.Player, "Alright.. Hold still..");
						josephNpcClass.StopAnimation("JosephNoArm");
						josephNpcClass.Move:Face(Vector3.new(506.223, 96.261, -1097.082))
						task.wait(1);

						mollyNpcClass.Chat(mollyNpcClass.Player, "*Patching*");
						mollyNpcClass.PlayAnimation("Patching");
						task.wait(5);

						mollyNpcClass.StopAnimation("Patching");
						mollyNpcClass.Chat(mollyNpcClass.Player, "Done!");
						
						josephChar.Bandage.Handle.Transparency = 0;
						task.wait(2);
						
						josephNpcClass.Chat(josephNpcClass.Player, ".. Thanks..");
						josephNpcClass:GetComponent("AvatarFace"):Set("Skeptical");
						josephNpcClass.Move:Face(Vector3.new(504.616, 96.781, -1105.925))
						
						modMission:Progress(player, MISSION_ID, function(mission)
							if mission.ProgressionPoint == 18 then
								mission.ProgressionPoint = 19;
							end
						end)
						
					elseif mission.ProgressionPoint == 19 then
						josephNpcClass:ToggleInteractable(true);
						mollyNpcClass:ToggleInteractable(true);
						mollyNpcClass.Move:MoveTo(Vector3.new(508.767, 96.941, -1120.23));
						mollyNpcClass.Move.OnMoveToEnded:Wait(5);
						mollyNpcClass.Move:Face(Vector3.new(509.305, 95.031, -1110.56));
						
					end
						
				elseif mission.Type == 3 then -- OnComplete
					if not firstRun then
						josephNpcClass.Move:MoveTo(Vector3.new(525.61, 99.44, -1089.824));
						wait(1);
						nateNpcClass.Move:MoveTo(Vector3.new(525.61, 99.44, -1089.824));
						nateNpcClass.Move.OnMoveToEnded:Wait(5);

					end
					josephNpcClass:TeleportHide();
					nateNpcClass:TeleportHide();
					
				end
			end
			
			mission.OnChanged:Connect(OnChanged);
			OnChanged(true);
		end)


	else
		return;
	end

	return CutsceneSequence;
end;