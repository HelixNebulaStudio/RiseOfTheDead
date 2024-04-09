local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();
--==
local Handler = {};
Handler.__index = Handler;

local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modTools = require(game.ReplicatedStorage.Library.Tools);
local modProjectile = require(game.ReplicatedStorage.Library.Projectile);
local modAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);
local modTagging = require(game.ServerScriptService.ServerLibrary.Tagging);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);

local prefabsItems = game.ReplicatedStorage.Prefabs.Items;
local toolHandlers = game.ServerScriptService.ServerLibrary.ToolHandlers;

local dirRemotes = game.ReplicatedStorage.Remotes;
--== Script;

function Handler.new(npc, wield, toolItemId)
	local self = {
		Npc = npc;
		Wield = wield;
		ItemId = toolItemId;
		Binds = {};
	};
	
	setmetatable(self, Handler);
	return self;
end

function Handler:Equip()
	local toolLib = modTools[self.ItemId];

	self.AnimGroup = self.Npc.AnimationController:NewGroup(self.ItemId);
	
	local toolHandler = toolHandlers:FindFirstChild(toolLib.Type) and require(toolHandlers[toolLib.Type]) or nil;
	if toolHandler == nil then Debugger:Warn("Missing tool handler for ("..toolLib.Type..")"); return end;
	
	
	local destroyed = false;
	local function OnWeaponDestroyed()
		if destroyed then return end;
		destroyed = true;
	end
	

	local weldsCount = 0;
	for _,_ in pairs(toolLib.Welds) do
		weldsCount = weldsCount+1;
	end
	if weldsCount == 0 then Debugger:Warn("Tool (",self.ItemId,") does not have any welds"); end;
	
	for weldName, prefabName in pairs(toolLib.Welds) do
		local prefabTool = prefabsItems:FindFirstChild(prefabName);
		if prefabTool == nil then Debugger:Print(prefabName.." does not exist!"); return; end;
		
		local motor;
		if prefabTool:FindFirstChild("WieldConfig") and prefabTool.WieldConfig:FindFirstChild(weldName) then
			motor = prefabTool.WieldConfig[weldName]:Clone();

		elseif toolLib.Module:FindFirstChild(weldName) then
			motor = toolLib.Module[weldName]:Clone();

		end
		
		local cloneTool: Model = prefabTool:Clone();
		local handle = cloneTool:WaitForChild("Handle");
		cloneTool.Parent = self.Npc.Prefab;
		cloneTool:SetAttribute("InteractableParent", true);
		handle:SetNetworkOwner();

		table.insert(self.Wield.Instances, cloneTool);
		
		local parentChangeSignal;
		parentChangeSignal = cloneTool:GetPropertyChangedSignal("Parent"):Connect(function()
			if cloneTool.Parent == game.Debris then
				destroyed = true;

				self.Npc.JointRotations.WaistRot:Remove("tool");
				self.Npc.JointRotations.NeckRot:Remove("tool");
				
				self.AnimGroup:Destroy();

				RunService.Heartbeat:Wait();
				cloneTool:Destroy();
				if self.Wield.Instances ~= nil then
					for k, obj in pairs(self.Wield.Instances) do
						game.Debris:AddItem(obj, 0);
					end
				end
				self.Wield.Instances = {};
				self.Wield.ToolModule = nil;
			elseif cloneTool.Parent == nil or not cloneTool:IsDescendantOf(self.Npc.Prefab) then
				OnWeaponDestroyed();
			end
			if destroyed then
				parentChangeSignal:Disconnect();
			end
		end);
		
		local function createGrip(bodyPartName, cloneSyntax)
			local bodyPart = self.Npc.Prefab:FindFirstChild(bodyPartName);
			if weldsCount > 1 then cloneTool.Name = cloneSyntax..prefabName; end;

			local toolGrip = motor:Clone();
			toolGrip.Parent, toolGrip.Part1, toolGrip.Part0 = bodyPart, handle, bodyPart;

			return toolGrip;
		end

		if weldName == "ToolGrip" or weldName == "RightToolGrip" then
			self.Wield.Instances.RightModel = cloneTool;
			self.Wield.Instances.RightWeld = createGrip("RightHand", "Right");

		elseif weldName == "LeftToolGrip" then
			self.Wield.Instances.LeftModel = cloneTool;
			self.Wield.Instances.LeftWeld = createGrip("LeftHand", "Left");
			
		end
	end
	
	
	self.Wield.ToolHandler = toolHandler.new(nil, nil, toolLib, self.Wield.Instances);
	self.Wield.ToolHandler.NpcModule = self.Npc;
	self.Wield.ToolHandler.Character = self.Npc.Prefab;
	self.Wield.ToolHandler.TargetableEntities = self.Wield.Targetable;
	
	self.Wield.ToolModule = toolLib.NewToolLib();
	self.Wield.ToolModule.Library = toolLib;
	self.Wield.ToolModule.Animations = {};
	self.Wield.VictimsList = {};

	local toolWaistRotation = self.Wield.ToolModule.Configurations.WaistRotation or 0;

	self.Npc.JointRotations.WaistRot:Set("tool", toolWaistRotation, 1);
	self.Npc.JointRotations.NeckRot:Set("tool", toolWaistRotation, 1);
	
	for key, libAnimations in pairs(toolLib.Animations) do
		local animationFile = Instance.new("Animation");
		animationFile.Parent = self.Wield.Instances.RightModel;
		animationFile.AnimationId = "rbxassetid://"..(libAnimations.OverrideId or libAnimations.Id);
		
		local trackData = self.AnimGroup:LoadAnimation(key, animationFile);
		self.Wield.ToolModule.Animations[key] = trackData;
		
		local track: AnimationTrack = trackData.Track;
		track.Name = key;
		
		if key == "Core" then
			track.Priority = Enum.AnimationPriority.Action;
			
		elseif key == "Load" then
			self.AnimGroup:Play("Load");
			
			track.Priority = Enum.AnimationPriority.Action3;
		else
			track.Priority = Enum.AnimationPriority.Action2;
		end
		
		if self.Wield.ToolModule.OnMarkerEvent then
			self.Npc.AnimationController:ConnectMarker(self.AnimGroup.Id..key, "Event", function(...)
				self.Wield.ToolModule:OnMarkerEvent(self.Wield, ...);
			end)
		end
		
	end
	
	self.AnimGroup:Play("Core");
	if toolLib.Audio.Load then
		modAudio.Play(toolLib.Audio.Load.Id, self.Npc.RootPart);
	end

	local properties, audio = self.Wield.ToolModule.Properties, self.Wield.ToolModule.Library.Audio;
	local colliders = self.Wield.ToolHandler:OnToolEquip(self.Wield.ToolModule);
	for a=1, #colliders do
		colliders[a].Touched:Connect(function(hitPart)
			
			local damagable = modDamagable.NewDamagable(hitPart.Parent);
			
			if damagable then
				--local model = damagable.Model;
				
				--local exist = self.Wield.VictimsList[model] ~= nil;
				--self.Wield.VictimsList[model] = {Character=model; Damagable=damagable; HitPart=hitPart; HitTick=tick()};
				
				--if not exist and properties.Attacking then
				--	self.Wield.ToolHandler:PrimaryAttack(damagable, hitPart);
				--	modAudio.Play(audio.PrimaryHit.Id, self.Wield.Instances.RightModel.PrimaryPart, nil, audio.PrimaryHit.Pitch, audio.PrimaryHit.Volume);
				--end

				local model = damagable.Model;
				local victim = self.Wield.VictimsList[model];

				if victim then
					victim.HitTick=tick();
				else
					self.Wield.VictimsList[model] = {Model=model; Damagable=damagable; HitPart=hitPart; HitTick=tick()};
					victim = self.Wield.VictimsList[model];
				end

				if properties.Attacking and victim.Hit ~= true then
					victim.Hit = true;
					
					self.Wield.ToolHandler:PrimaryAttack(damagable, hitPart);
					modAudio.Play(audio.PrimaryHit.Id, self.Wield.Instances.RightModel.PrimaryPart, nil, audio.PrimaryHit.Pitch, audio.PrimaryHit.Volume);
				end
			end
		end)
	end
end

function Handler:Unequip()
	self.Wield.Controls.Mouse1Down = false; 
	if next(self.Wield.Instances) ~= nil then
		for key, obj in next, self.Wield.Instances do
			if obj.Parent ~= nil then obj.Parent = game.Debris; end
		end
	end

	self.AnimGroup:Destroy();
	
	self.Wield.ToolModule = nil;
end

function Handler:PrimaryFireRequest()
	if self.Wield.ToolModule == nil then return end;
	
	local configurations, properties, audio = self.Wield.ToolModule.Configurations, self.Wield.ToolModule.Properties, self.Wield.ToolModule.Library.Audio;
	if properties.Attacking then return end;
	
	self.AnimGroup:Stop("Inspect");
	
	properties.Attacking = true;
	self.Wield.VictimsList = {};
	
	local function primaryAttack()
		modAudio.Play(audio.PrimarySwing.Id, self.Wield.Instances.RightModel.PrimaryPart, nil, audio.PrimarySwing.Pitch, audio.PrimarySwing.Volume);
		
		self.AnimGroup:Play("PrimaryAttack", {FadeTime=0.05; Length=configurations.PrimaryAttackAnimationSpeed;});
	end
	
	if configurations.HeavyAttackSpeed then
		local charge = 0;
		local maxCharged = false;
		repeat
			charge = charge+ RunService.Heartbeat:Wait();
			if charge >= 0.15 then
				self.AnimGroup:Play("HeavyAttack", {FadeTime=0.05; Length=2/configurations.HeavyAttackSpeed;});
			end
			maxCharged = charge >= configurations.HeavyAttackSpeed
		until not self.Wield.Controls.Mouse1Down or maxCharged;
		
		if maxCharged then
			self.AnimGroup:Play("HeavyAttack", {Speed=1;});
			modAudio.Play(audio.PrimarySwing.Id, self.Wield.Instances.RightModel.PrimaryPart, nil, audio.PrimarySwing.Pitch, audio.PrimarySwing.Volume);
			
		else
			self.AnimGroup:Stop("HeavyAttack");
			primaryAttack();
			
		end
	else
		primaryAttack();
	end
	
	wait(configurations.PrimaryAttackSpeed);
	properties.Attacking = false;
end

function Handler:Destroy()
	self:Unequip();
end

return Handler;
