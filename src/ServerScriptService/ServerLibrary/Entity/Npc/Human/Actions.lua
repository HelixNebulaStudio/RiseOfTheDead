local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local random = Random.new();

local CollectionService = game:GetService("CollectionService");

local remotes = game.ReplicatedStorage.Remotes;
local bindOnDoorEnter = remotes.Interactable.OnDoorEnter;

local Human = {};

function Human.new(Npc)
	local Actions = {};
	
	function Actions:WaitForOwner(distance, externalChecks, interval)
		local playerDistance = 10000;
		repeat
			playerDistance = Npc.Owner and Npc.Owner:DistanceFromCharacter(Npc.RootPart.Position) or 10000;
		until Npc.Owner == nil or (externalChecks and externalChecks(playerDistance) or false) or playerDistance <= distance or not wait(interval or 1);
	end
	
	function Actions:DistanceFrom(pos)
		if pos == nil then Debugger:Warn("Missing pos param."); return 0 end;
		return Npc.RootPart and (Npc.RootPart.Position - pos).Magnitude;
	end
	
	function Actions:EnterDoor(door)
		local doorInstance = type(door) == "string" and workspace.Interactables:FindFirstChild(door) or door;
		if doorInstance == nil then Debugger:Warn("Missing door name (",door,")") return end;
		if Npc.Humanoid and Npc.Humanoid.SeatPart and Npc.Humanoid.SeatPart:FindFirstChild("SeatWeld") then 
			Npc.Humanoid.SeatPart.SeatWeld:Destroy();
		end
		
		Npc.PlayAnimation("OpenDoor");
		task.wait(0.3);
		Npc.RootPart.CFrame = CFrame.new(doorInstance:WaitForChild("Destination").WorldPosition + Vector3.new(0, 2.35, 0)) * CFrame.Angles(0, math.rad(doorInstance.Destination.WorldOrientation.Y-90), 0);
		task.wait(0.3);
	end
	
	function Actions:GetOwnerRoot()
		if Npc.Owner and Npc.Owner.Character and Npc.Owner.Character.PrimaryPart and Npc.Owner.Character.PrimaryPart:IsDescendantOf(workspace) then
			return Npc.Owner.Character.PrimaryPart;
		end
	end
	
	function Actions:Teleport(cframe: CFrame, cfAngle: CFrame)
		if Npc.Humanoid and Npc.Humanoid.SeatPart and Npc.Humanoid.SeatPart:FindFirstChild("SeatWeld") then 
			Npc.Humanoid.SeatPart.SeatWeld:Destroy();
		end
		if cframe then
			local cfAng = cframe.Rotation;
			if cfAng == CFrame.Angles(0, 0, 0) then
				cfAng = Npc.RootPart.CFrame.Rotation;
			end
			if cfAngle then
				cfAng = cfAngle;
			end
			Npc.RootPart.CFrame = CFrame.new(cframe.Position) * cfAng;
		else
			if Npc.Owner and Npc.Owner.Character and Npc.Owner.Character.PrimaryPart and Npc.Owner.Character.PrimaryPart:IsDescendantOf(workspace) then
				Npc.RootPart.CFrame = Npc.Owner.Character.PrimaryPart.CFrame;
			end
		end
	end
	
	function Actions:Unsit()
		local seatPart = Npc.Humanoid.SeatPart;
		if seatPart then
			local weld = seatPart:FindFirstChildWhichIsA("Weld");
			if weld.Name == "SeatWeld" then
				Npc.Humanoid.Sit = false;
				game.Debris:AddItem(weld, 0);
			end
		end
		Npc.Humanoid.Jump = true;
	end
	
	function Actions:FaceOwner(breakFunc)
		if Npc.Owner ~= nil then
			task.spawn(function()
				repeat
					local rootPart = Npc.Owner.Character and Npc.Owner.Character.PrimaryPart or nil;
					if rootPart then
						if Npc.Prefab:IsA("Actor") then
							Npc.Move:Face(rootPart);
							
						else
							Npc.Movement:Face(rootPart.Position);
							
						end
					end
					if breakFunc then
						task.wait(0.5);
						if breakFunc() == true then
							break;
						end
					else
						break;
					end
					if not workspace:IsAncestorOf(Npc.Owner.Character) then
						break;
					end
				until false;
			end)
		end
	end
	
	Actions.IsFollowingOwner = false;
	function Actions:FollowOwner(onUpdate, fDist, fSpeed)
		Actions.IsFollowingOwner = true;
		if Npc.OnDoorEnterEvent then Npc.OnDoorEnterEvent:Disconnect(); Npc.OnDoorEnterEvent = nil; end;
		Npc.OnDoorEnterEvent = bindOnDoorEnter.Event:Connect(function(player, interactData)
			if Npc.Owner == player and interactData.Object then
				if interactData.Object and Actions.IsFollowingOwner then
					if Npc.Prefab:IsA("Actor") then
					else
						Npc.Follow();
					end
					Npc.Actions:EnterDoor(interactData.Object);
				end
			end
		end)
		
		task.spawn(function()
			repeat
				local rootPart = Npc.Owner and Npc.Owner.Character and Npc.Owner.Character.PrimaryPart or nil;
				if rootPart then
					if Npc.Humanoid.Sit then Npc.Humanoid.Jump = true end;
					if Actions.IsFollowingOwner then
						local distance = Npc.Owner:DistanceFromCharacter(Npc.RootPart.Position);

						if Npc.Prefab:IsA("Actor") then
							if distance >= 64 then
								Npc.RootPart.CFrame = rootPart.CFrame;
								
							elseif distance >= 16 then
								Npc.Move:SetMoveSpeed("set", "sprint", fSpeed or 25, 2, 0.3);
								
							else
								Npc.Move:SetMoveSpeed("set", "walk", fSpeed and fSpeed/2 or 10, 2, 0.3);
								
							end
							
							Npc.Move:Recompute();
							Npc.Move:Follow(rootPart, fDist or 5, 2);
							
						else
							if distance >= 64 then
								Npc.RootPart.CFrame = rootPart.CFrame;
							elseif distance >= 16 then
								Npc.Humanoid.WalkSpeed = fSpeed or 25;
							else
								Npc.Humanoid.WalkSpeed = fSpeed and fSpeed/2 or 10;
							end
							
							Npc.Follow(rootPart, fDist or 2);
						end
					end
				end
				Actions.IsFollowingOwner = onUpdate();
				task.wait(0.1);
			until Npc.IsDead or Npc.Humanoid.RootPart == nil or not Actions.IsFollowingOwner;
			
			if not Npc.Prefab:IsA("Actor") then
				Npc.Follow();
			else
				Npc.Move:Stop();
			end
		end);
	end
	
	Actions.IsProtectingOwner = false;
	function Actions:ProtectOwner(onUpdate)
		if Actions.IsProtectingOwner then return end;
		Actions.IsProtectingOwner = true;
		task.spawn(function()
			repeat
				if Npc.Target and Npc.Target ~= Npc.Prefab then
					local enemyHumanoid = Npc.Target:FindFirstChildWhichIsA("Humanoid");

					local isHostile = enemyHumanoid.Name == "Zombie" or enemyHumanoid.Name == "Bandit" or enemyHumanoid.Name == "Rat";
					local isTargetAlive = isHostile and enemyHumanoid and enemyHumanoid.Health > 0;
					local isInVision =  isHostile and enemyHumanoid.RootPart and Npc.IsInVision(enemyHumanoid.RootPart);
					
					if isHostile and isTargetAlive and isInVision then
						Npc.Wield.SetEnemyHumanoid(enemyHumanoid);

						if Npc.Prefab:IsA("Actor") then
							Npc.Move:Face(enemyHumanoid.RootPart.Position);
						else
							Npc.Movement:Face(enemyHumanoid.RootPart.Position);
						end
						
						Npc.Wield.PrimaryFireRequest();
					else
						Npc.Target = nil;
					end
					
				else
					Npc.Wield.ReloadRequest();
					
				end
				
				Actions.IsProtectingOwner = onUpdate();
				task.wait(0.1);
			until Npc.IsDead or Npc.Humanoid.RootPart == nil or not Actions.IsProtectingOwner;

			if not Npc.Prefab:IsA("Actor") then
				Npc.Follow();
			end
		end);
	end
	
	Actions.IsHuntingTarget = false;
	function Actions:HuntTarget(targets, onUpdate)
		Actions.IsHuntingTarget = true;

		local target = table.remove(targets, 1);
		repeat
			if target then
				local enemyHumanoid = target:FindFirstChildWhichIsA("Humanoid");
				if enemyHumanoid and enemyHumanoid.Health > 0 and enemyHumanoid.RootPart then
					if Npc.Prefab:IsA("Actor") then
						Npc.Move:Follow(enemyHumanoid.RootPart, 16);
						
					else
						Npc.Follow(enemyHumanoid.RootPart, 16, 24);
						
					end
					
					if Npc.IsInVision(enemyHumanoid.RootPart) then
						Npc.Wield.SetEnemyHumanoid(enemyHumanoid);
						if Npc.Prefab:IsA("Actor") then
							Npc.Move:Face(enemyHumanoid.RootPart);
						else
							Npc.Movement:Face(enemyHumanoid.RootPart.Position);
						end
						Npc.Wield.PrimaryFireRequest();
					else
						target = nil;
					end
				else
					target = nil;
				end
			else
				Npc.Wield.ReloadRequest();
				target = table.remove(targets, 1);
			end
			
			Actions.IsHuntingTarget = onUpdate(target);
			task.wait(0.1);
			
			if #targets <= 0 and target == nil then break; end;
		until Npc.IsDead or Npc.Humanoid.RootPart == nil or not Actions.IsHuntingTarget;
		Npc.Follow();
	end
	
	return Actions;
end

return Human;