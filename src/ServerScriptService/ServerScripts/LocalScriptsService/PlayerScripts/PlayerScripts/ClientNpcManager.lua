local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
return function()
	Debugger:Log("Initializing npc handler script.");
	--if not game:IsLoaded() then game.Loaded:Wait(); end;
	--== Configuration;
	
	--== Variables;
	local PhysicsService = game:GetService("PhysicsService");
	local CollectionService = game:GetService("CollectionService");
	local RunService = game:GetService("RunService");
	local TweenService = game:GetService("TweenService");
	local HttpService = game:GetService("HttpService");
	
	local camera = workspace.CurrentCamera;
	local player = game.Players.LocalPlayer;
	
	local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
	
	local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
	local modCustomizeAppearance = require(game.ReplicatedStorage.Library.CustomizeAppearance);
	local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
	local modCharacterInteractions = require(game.ReplicatedStorage.Library.CharacterInteractions);

	local remoteNpcFace = modRemotesManager:Get("NpcFace");
	local remoteNpcManager = modRemotesManager:Get("NpcManager");
	local remoteThreatSenseSkill = modRemotesManager:Get("ThreatSenseSkill");
	
	local entityFolder = workspace.Entity;
	local animationLibrary = game.ReplicatedStorage.Prefabs.Animations;
	
	local UserGameSettings = UserSettings():GetService("UserGameSettings");
	local quality = UserGameSettings.SavedQualityLevel;
	local qualityLevel = 10;
	
	--== Script;
	remoteNpcFace.OnClientEvent:Connect(function(npcFace, id)
		if npcFace then npcFace.Texture = id; end
	end)
	
	remoteThreatSenseSkill.OnClientEvent:Connect(function(prefab: Model, duration: number)
		if prefab == nil or prefab:GetAttribute("Invisible") == true or prefab:HasTag("Deadbody") then return end;
		local thrsenHighlight: Highlight = prefab:FindFirstChild("thrsenHighlight");
		if thrsenHighlight then return end;
		
		thrsenHighlight = Instance.new("Highlight");
		thrsenHighlight.Name = "thrsenHighlight";
		
		if modGlobalVars.IsMobile() then -- or RunService:IsStudio()
			thrsenHighlight.FillTransparency = 0.8;
			thrsenHighlight.FillColor = Color3.fromRGB(255,80,80);
			thrsenHighlight.OutlineTransparency = 1;
			
		else
			thrsenHighlight.FillTransparency = 1;
			thrsenHighlight.FillColor = Color3.fromRGB(255,80,80);
			thrsenHighlight.OutlineTransparency = 0.65;
			thrsenHighlight.OutlineColor = Color3.fromRGB(255,80,80);
			
		end
		
		thrsenHighlight.Parent = prefab;
		Debugger.Expire(thrsenHighlight, 10);
		
	end)
	
	CollectionService:GetInstanceAddedSignal("Deadbody"):Connect(function(prefab)
		local thrsenHighlight: Highlight = prefab:FindFirstChild("thrsenHighlight");
		if thrsenHighlight then
			thrsenHighlight:Destroy();
		end
	end)
	
	UserGameSettings.Changed:Connect(function()
		quality = UserGameSettings.SavedQualityLevel;
		if quality == Enum.SavedQualitySetting.QualityLevel1 then
			qualityLevel = 1;
		elseif quality == Enum.SavedQualitySetting.QualityLevel2 then
			qualityLevel = 2;
		elseif quality == Enum.SavedQualitySetting.QualityLevel3 then
			qualityLevel = 3;
		elseif quality == Enum.SavedQualitySetting.QualityLevel4 then
			qualityLevel = 4;
		elseif quality == Enum.SavedQualitySetting.QualityLevel5 then
			qualityLevel = 5;
		elseif quality == Enum.SavedQualitySetting.QualityLevel6 then
			qualityLevel = 6;
		elseif quality == Enum.SavedQualitySetting.QualityLevel7 then
			qualityLevel = 7;
		elseif quality == Enum.SavedQualitySetting.QualityLevel8 then
			qualityLevel = 8;
		elseif quality == Enum.SavedQualitySetting.QualityLevel9 then
			qualityLevel = 9;
		elseif quality == Enum.SavedQualitySetting.QualityLevel10  then
			qualityLevel = 10;
		end
		if qualityLevel <= 4 then
			
		end
		--game.Lighting.FogEnd = renderDistance-10;
	end)
	
	local function LoadNpc(dataBody, npcPrefab)
		--if not npcPrefab:IsA("Model") then return end;
		
		--repeat
		--	task.wait()
		--until dataBody:FindFirstChildWhichIsA("BasePart");
		
		--local rootPart = dataBody:WaitForChild("HumanoidRootPart");
		--rootPart.CollisionGroup = "RaycastIgnore";
		
		--local modData = player:FindFirstChild("DataModule") and require(player.DataModule);
		--if modData and modData.Settings and modData.Settings.DeadbodyParts then return end;
		
		--local humanoid = dataBody:FindFirstChildWhichIsA("Humanoid");
		--local dummyBody;
		
		--local dataBodyParts = dataBody:GetChildren();
		--if humanoid then
		--	humanoid.Died:Connect(function()
		--		local modData = player:FindFirstChild("DataModule") and require(player.DataModule);
		--		local settingsDeadbodyParts = nil;
		--		if modData and modData.Settings and modData.Settings.DeadbodyParts then
		--			settingsDeadbodyParts = false;
		--			return
		--		end;
				
		--		if qualityLevel > 4 then
		--			dummyBody = dataBody:Clone();
		--			dummyBody.Parent = BodiesCacheFolder;
		--			--for p, parts in pairs(dataBodyParts) do
		--			--	dataBody:WaitForChild(parts.Name);
		--			--end
		--		end

		--		if qualityLevel > 4 and dummyBody ~= nil and dummyBody.Parent ~= nil and settingsDeadbodyParts == nil then
		--			dataBodyParts = dataBody:GetChildren();
		--			game.Debris:AddItem(dummyBody, 10);
		--			local strength = random:NextNumber(15,30);
					
		--			local dummyHumanoid = dummyBody:FindFirstChildWhichIsA("Humanoid");
		--			if dummyHumanoid then
		--				dummyHumanoid.Health = 0;
		--				dummyHumanoid:ChangeState(Enum.HumanoidStateType.Dead);
		--				dummyHumanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff;
		--			end
					
		--			task.spawn(function()
		--				for a=1, 3 do
		--					game.Debris:AddItem(dummyBody:FindFirstChild("targetGui", true), 0);
		--				end
		--			end)
					
		--			dummyBody.Parent = workspace.Debris;
		--			dummyBody:BreakJoints();
					
		--			local bpNameCache = {};
		--			for a=1, #dataBodyParts do
		--				if dataBodyParts[a].Name == "HumanoidRootPart" then
		--				elseif dataBodyParts[a]:IsA("BasePart") then
		--					local dummyBodyPart = dummyBody and dummyBody:FindFirstChild(dataBodyParts[a].Name) or nil;
		--					if dummyBodyPart and random:NextInteger(1, (10-qualityLevel)) == 1 then
		--						bpNameCache[dataBodyParts[a].Name] = 1;
		--						dummyBodyPart.CFrame = dataBodyParts[a].CFrame;
		--						dummyBodyPart.CanCollide = true;
		--						dummyBodyPart.CollisionGroup = "Debris";
		--						dummyBodyPart.Velocity = rootPart.Velocity + Vector3.new(random:NextNumber(-strength, strength), random:NextNumber(-strength+10, strength+10), random:NextNumber(-strength, strength));
		--						dummyBodyPart.CFrame = dummyBodyPart.CFrame * CFrame.new(strength/200, 1, strength/200);
		--					else
		--						if dummyBodyPart then
		--							dummyBodyPart:Destroy();
		--						end
		--					end
		--					dataBodyParts[a]:Destroy();
		--				elseif dataBodyParts[a]:IsA("Shirt") or dataBodyParts[a]:IsA("Pants") then
		--					dataBodyParts[a]:Clone().Parent = dummyBody;
		--				elseif dataBodyParts[a]:IsA("Humanoid") then
		--				else
		--					local dummyBodyPart = dummyBody and dummyBody:FindFirstChild(dataBodyParts[a].Name) or nil;
		--					if dummyBodyPart then dummyBodyPart:Destroy() end;
		--					dataBodyParts[a]:Destroy();
		--				end
		--			end
		--			for _, object in pairs(dummyBody:GetChildren()) do
		--				if object:IsA("BasePart") and bpNameCache[object.Name] == nil then
		--					object:Destroy();
		--				end
		--			end
		--			dataBody.Parent = workspace.Debris;
		--		else
		--			game.Debris:AddItem(dummyBody, 0);
		--		end
		--	end)
		--end
	end
	
	local lastRequest = tick();
	local function CheckForPrefab(npc, npcPrefab)
		if npc == nil then return end;
		
		local humanoid = npc:FindFirstChildWhichIsA("Humanoid");
		if humanoid then
			local defaultType = humanoid.DisplayDistanceType;
			local function updateHumanoid()
				local cinematicMode = player:GetAttribute("CinematicMode") == true;
				if cinematicMode then
					humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None;
				else
					humanoid.DisplayDistanceType = defaultType;
				end
			end
			humanoid:GetPropertyChangedSignal("DisplayDistanceType"):Connect(updateHumanoid)
			updateHumanoid()
		end
		
		--if npc:IsA("Actor") then
		--	--warn("Skip prefab request for actor ("..npc.Name..").")
		--	return;
		--end
		
		--npcPrefab = npcPrefab or game.ReplicatedStorage.Prefabs.Npc:FindFirstChild(npc.Name);
		--if npcPrefab and npcPrefab:IsA("Model") then
		--	LoadNpc(npc, npcPrefab);
			
		--else
		--	if tick()-lastRequest >= 1 then
		--		lastRequest = tick();
		--		warn("Requesting for missing prefab. ("..npc.Name..")");
		--		npcPrefab = remotePrefabRequest:InvokeServer("Npc", npc.Name);
		--		if npcPrefab then npcPrefab.Parent = game.ReplicatedStorage.Prefabs.Npc; end;
		--	end
		--	if npcPrefab then LoadNpc(npc, npcPrefab); end;
		--end
	end
	
	remoteNpcManager.OnClientEvent:Connect(function(action, ...)
		if action == "loadprefab" then
			CheckForPrefab(...);
		end
	end)
	entityFolder.ChildAdded:Connect(CheckForPrefab);
	
	task.spawn(function()
		local sortedEntities = {};
		for _, entity in pairs(entityFolder:GetChildren()) do
			local rootPart = entity:FindFirstChild("HumanoidRootPart");
			if rootPart then
				table.insert(sortedEntities, {Npc=entity; Distance=(rootPart.Position.X^2+rootPart.Position.Z^2)});
			end
		end
		table.sort(sortedEntities, function(a,b) return a.Distance < b.Distance end);
		
		for a=1, #sortedEntities do
			local npcModel = sortedEntities[a].Npc;
			CheckForPrefab(npcModel);
			
			task.spawn(function()
				local repOwners = npcModel:GetAttribute("ReplicateOwners");
				if repOwners then
					local owners = HttpService:JSONDecode(repOwners);

					if table.find(owners, game.Players.LocalPlayer.Name) == nil then
						npcModel.Parent = game.ReplicatedStorage.Replicated;
					end
				end
			end)
		end 
	end);

	local npcScanOverlapParam = OverlapParams.new();
	npcScanOverlapParam.FilterType = Enum.RaycastFilterType.Include;

	repeat task.wait() until shared.modPlayers;
	local classPlayer = shared.modPlayers.Get(player);

	--if modBranchConfigs.WorldInfo.Type ~= modBranchConfigs.WorldTypes.Cutscene then
	task.spawn(function()
		while true do
			task.wait(1);
			
			if classPlayer == nil then
				classPlayer = shared.modPlayers.Get(player);
				continue;
			end
			
			local character = classPlayer.Character;
			local playerHead = character and character:IsDescendantOf(workspace) and classPlayer.Head;

			if qualityLevel >= 8 and playerHead then
				npcScanOverlapParam.FilterDescendantsInstances = CollectionService:GetTagged("EntityRootPart");
				npcScanOverlapParam.MaxParts = 32;
				
				local partsInBounds = workspace:GetPartBoundsInRadius(playerHead.Position, 20, npcScanOverlapParam);
				
				local targetNpcs = {};
				local cacheHeads = {};

				for a=1, #partsInBounds do
					local model = partsInBounds[a].Parent;
					local humanoid = model:FindFirstChildWhichIsA("Humanoid");
					local head = model:FindFirstChild("Head");
					
					if model and humanoid and humanoid.Health >= 0 and head then
						CollectionService:AddTag(head, "LookingHead");
						head:SetAttribute("IsLooking", true);
						cacheHeads[head] = true;
					end
				end
				
				local heads = CollectionService:GetTagged("LookingHead");
				for a=#heads, 1, -1 do
					local head = heads[a];
					
					local serverHeadTrack = head.Parent:FindFirstChild("HeadTrackObj");
					if serverHeadTrack then
						head:SetAttribute("IsLooking", true);
						cacheHeads[head] = true;
					end
					
					if head and cacheHeads[head] == nil then
						head:SetAttribute("IsLooking", false);
					end
				end
			end
		end
	end)
	
	local neckLimit = math.rad(75);
	task.spawn(function()
		RunService.Stepped:Connect(function()
			if qualityLevel < 5 then return end;
			if classPlayer == nil then return end;
			if modGlobalVars.IsMobile() then return end;
			
			local isFirstPerson = player:GetAttribute("IsFirstPerson") or false;
			
			local playerHead = classPlayer.Head;
			local playerPart = isFirstPerson and workspace.CurrentCamera or classPlayer:GetCharacterChild("UpperTorso");
			if playerPart == nil then return end;
			
			local playerRoot = playerPart.CFrame;
			
			if isFirstPerson then
				playerRoot = playerRoot * CFrame.new(0, -1.52, 0);
			end
			
			local heads = CollectionService:GetTagged("LookingHead");
			for a=#heads, 1, -1 do
				local head = heads[a];
				
				if head.Parent:GetAttribute("LookAtClient") == false then continue end;
				
				local neck = head:FindFirstChild("Neck");
				local face = head:FindFirstChild("face");
				if face and string.find(face.Texture, "2255073000") then continue end;
				if face and string.find(face.Texture, "4644356184") then continue end;
				
				
				local upperTorso = head.Parent:FindFirstChild("UpperTorso");
				local animator = head.Parent:FindFirstChild("Animator", true);
				
				local lerpR = 0.1 * (animator and animator:GetAttribute("Timescale") or 1);
				if lerpR <= 0 then continue end;
				
				local assemblyRootPart = head:GetRootPart();
				if neck == nil or assemblyRootPart == nil or upperTorso == nil then continue end;
				
				local neckCF = neck:FindFirstChild("NeckCFrame");
				if neckCF == nil then
					neckCF = Instance.new("CFrameValue");
					neckCF.Name = "NeckCFrame";
					neckCF.Parent = neck;
				end
				
				local target = playerRoot;
				local targetPosition = playerRoot.Position;
				
				if head.Parent:FindFirstChild("HeadTrackObj") and head.Parent.HeadTrackObj.Value ~= nil then
					target = head.Parent.HeadTrackObj.Value.CFrame;
					targetPosition = target.Position + Vector3.new(0, -2, 0);
				end
				
				local direction = (targetPosition-assemblyRootPart.Position).Unit;
				local relativeCframe = assemblyRootPart.CFrame:toObjectSpace(target);
				local dirAngle = math.atan2(relativeCframe.X, -relativeCframe.Z);
				
				local waistRot = upperTorso:GetAttribute("WaistRot") or 0;
				
				local rotOffset = upperTorso.CFrame.Rotation:inverse() * CFrame.Angles(0, -waistRot, 0);
				local lookAtCF = rotOffset * CFrame.lookAt(upperTorso.Position, targetPosition).Rotation
				
				local isLooking = head:GetAttribute("IsLooking");
				if isLooking then
					
					head:SetAttribute("StopLookingTick", nil);
					
					if math.abs(dirAngle) <= neckLimit and math.abs(upperTorso.Position.Y-targetPosition.Y) <= 16 then
						neck.Transform = neckCF.Value:Lerp(lookAtCF, lerpR);
						
					else
						neck.Transform = neckCF.Value:Lerp(CFrame.identity, lerpR);
						
					end
					
				else
					local stopLookTick = head:GetAttribute("StopLookingTick");
					if stopLookTick == nil then
						neck.Transform = neckCF.Value;
						head:SetAttribute("StopLookingTick", tick()+math.random(0, 300)/100);

					elseif tick() >= stopLookTick+1 then
						neck.Transform = neckCF.Value;
						CollectionService:RemoveTag(head, "LookingHead");
						head:SetAttribute("StopLookingTick", nil);
						
					else
						neck.Transform = neckCF.Value:Lerp(CFrame.identity, lerpR);
						
					end
					
				end
				neckCF.Value = neck.Transform;
			end
		end)
	end)
end