local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
return function()
	Debugger:Warn("Initializing npc manager script.");
	--== Configuration;
	
	--== Variables;
	local CollectionService = game:GetService("CollectionService");
	local RunService = game:GetService("RunService");
	local HttpService = game:GetService("HttpService");
	
	local localPlayer = game.Players.LocalPlayer;
	

	local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
	
	local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
	local modDeadbodiesHandler = require(game.ReplicatedStorage.Library.DeadbodiesHandler);

	local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);

	local remoteNpcFace = modRemotesManager:Get("NpcFace");
	local remoteNpcManager = modRemotesManager:Get("NpcManager");
	local remoteThreatSenseSkill = modRemotesManager:Get("ThreatSenseSkill");
	
	local entityFolder = workspace.Entity;

	--== Script;
	remoteNpcFace.OnClientEvent:Connect(function(npcFace, id)
		if npcFace then npcFace.Texture = id; end
	end)
	
	remoteThreatSenseSkill.OnClientEvent:Connect(function(prefab: Model, duration: number)
		if prefab == nil or prefab:GetAttribute("Invisible") == true or prefab:HasTag("Deadbody") then return end;
		local thrsenHighlight = prefab:FindFirstChild("thrsenHighlight") :: Highlight;
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
	
	-- MARK: Deadbody Handler
	local lastDbDespawnTick = tick();
	CollectionService:GetInstanceAddedSignal("Deadbody"):Connect(function(prefab: Model)
		--local humanoid = prefab:FindFirstChildWhichIsA("Humanoid") :: Humanoid;
		local parallelNpc = prefab:FindFirstChild("ParallelNpc");
		if parallelNpc then
			parallelNpc:Destroy();
		end

		local thrsenHighlight = prefab:FindFirstChild("thrsenHighlight") :: Highlight;
		if thrsenHighlight then
			thrsenHighlight:Destroy();
		end

		local deadbodyDespawnTimer = modData:GetSetting("DeadbodyDespawnTimer");
		local maxDeadbodies = modData:GetSetting("MaxDeadbodies");

		if deadbodyDespawnTimer < 61 then
			game.Debris:AddItem(prefab, deadbodyDespawnTimer);
		end
		
		if lastDbDespawnTick == nil or tick()-lastDbDespawnTick > 1 then
			lastDbDespawnTick = tick();
			modDeadbodiesHandler:DespawnRequest(maxDeadbodies);
		end

		if modData:GetSetting("DisableDeathRagdoll") == 1 then return end;
		if maxDeadbodies <= 0 then return end;

		local humanoidRootPart = prefab:FindFirstChild("HumanoidRootPart") :: BasePart;
		if humanoidRootPart == nil then return end;
		humanoidRootPart:GetPropertyChangedSignal("Anchored"):Once(function()
			for _, part in pairs(prefab:GetChildren()) do
				if not part:IsA("BasePart") then continue end;
				part.Anchored = false;
				
				if part.Name == "HumanoidRootPart" then continue end;
				part.CanCollide = true;
			end
		end)
	end)
	task.delay(5, function()
		modDeadbodiesHandler:DespawnRequest(modData:GetSetting("MaxDeadbodies"));
	end)
	
	local function CheckForPrefab(npc, npcPrefab)
		if npc == nil then return end;
		
		local humanoid = npc:FindFirstChildWhichIsA("Humanoid");
		if humanoid then
			local defaultType = humanoid.DisplayDistanceType;
			local function updateHumanoid()
				local cinematicMode = localPlayer:GetAttribute("CinematicMode") == true;
				if cinematicMode then
					humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None;
				else
					humanoid.DisplayDistanceType = defaultType;
				end
			end
			humanoid:GetPropertyChangedSignal("DisplayDistanceType"):Connect(updateHumanoid)
			updateHumanoid()
		end
	end
	
	remoteNpcManager.OnClientEvent:Connect(function(action, ...)
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

	Debugger.AwaitShared("modPlayers");
	local classPlayer = shared.modPlayers.Get(localPlayer);

	task.spawn(function()
		while true do
			task.wait(1);
			
			if classPlayer == nil then
				classPlayer = shared.modPlayers.Get(localPlayer);
				continue;
			end
			
			local character = classPlayer.Character;
			local playerHead = character and character:IsDescendantOf(workspace) and classPlayer.Head;

			if playerHead then
				npcScanOverlapParam.FilterDescendantsInstances = CollectionService:GetTagged("EntityRootPart");
				npcScanOverlapParam.MaxParts = 32;
				
				local partsInBounds = workspace:GetPartBoundsInRadius(playerHead.Position, 20, npcScanOverlapParam);
				
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
			if classPlayer == nil then return end;
			if modGlobalVars.IsMobile() then return end;
			
			local isFirstPerson = localPlayer:GetAttribute("IsFirstPerson") or false;
			
			local _playerHead = classPlayer.Head;
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