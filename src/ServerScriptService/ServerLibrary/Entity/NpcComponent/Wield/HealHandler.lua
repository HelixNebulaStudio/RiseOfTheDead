local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Handler = {};
Handler.__index = Handler;

local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modTools = require(game.ReplicatedStorage.Library.Tools);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);

local prefabsItems = game.ReplicatedStorage.Prefabs.Items;
local toolHandlers = game.ServerScriptService.ServerLibrary.ToolHandlers;
--== Script;

function Handler.new(npc, wield, toolItemId)
	local self = {
		Npc = npc;
		Wield = wield;
		ItemId = toolItemId;
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
	local function OnToolDestroyed()
		if destroyed then return end;
		destroyed = true;
	end

	local weldCount = 0;
	for weldName, prefabName in pairs(toolLib.Welds) do
		weldCount = weldCount +1;
	end
	
	for weldName, prefabName in pairs(toolLib.Welds) do
		local prefabTool = prefabsItems:FindFirstChild(prefabName);
		if prefabTool == nil then Debugger:Print(prefabName.." does not exist!"); return; end;

		local motor;
		if prefabTool:FindFirstChild("WieldConfig") and prefabTool.WieldConfig:FindFirstChild(weldName) then
			motor = prefabTool.WieldConfig[weldName]:Clone();

		elseif toolLib.Module:FindFirstChild(weldName) then
			motor = toolLib.Module[weldName]:Clone();

		end
		
		local cloneTool = prefabTool:Clone();
		local handle = cloneTool:WaitForChild("Handle");
		cloneTool.Parent = self.Npc.Prefab;
		cloneTool:SetAttribute("InteractableParent", true);
		handle:SetNetworkOwner();

		table.insert(self.Wield.Instances, cloneTool);

		local parentChangeSignal;
		parentChangeSignal = cloneTool:GetPropertyChangedSignal("Parent"):Connect(function()
			if cloneTool.Parent == game.Debris then
				destroyed = true;

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
				OnToolDestroyed();
			end
			if destroyed then
				parentChangeSignal:Disconnect();
			end
		end);

		local function createGrip(bodyPartName, cloneSyntax)
			local bodyPart = self.Npc.Prefab:FindFirstChild(bodyPartName);
			if weldCount > 1 then cloneTool.Name = cloneSyntax..prefabName; end;

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
	self.Wield.ToolHandler.Character = self.Npc.Prefab;
	self.Wield.ToolModule = self.Wield.ToolHandler.ToolConfig;
	
	self.Wield.ToolModule.Library = toolLib;
	self.Wield.ToolModule.Animations = {};
	
	
	for key, libAnimations in pairs(toolLib.Animations) do
		local animationFile = Instance.new("Animation");
		animationFile.Parent = self.Wield.Instances.RightModel;--Npc.Humanoid;
		animationFile.AnimationId = "rbxassetid://"..(libAnimations.OverrideId or libAnimations.Id);
		
		self.Wield.ToolModule.Animations[key] = self.AnimGroup:LoadAnimation(key, animationFile);
		
		if key == "Core" then
			self.Wield.ToolModule.Animations[key].Track.Priority = Enum.AnimationPriority.Action;
		else
			self.Wield.ToolModule.Animations[key].Track.Priority = Enum.AnimationPriority.Action2;
		end
	end
	self.AnimGroup:Play("Core");
	
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

function Handler:ActionRequest(action, ...)
	if self.Wield.ToolModule == nil then return end;
	
	if action == "heal" then
		
		local damagable = modDamagable.NewDamagable(self.Npc.Prefab); 
		
		self.Wield.ToolHandler:ProcessHeal({
			HealDealer = self.Npc.Prefab;
			HealDamagable = damagable;
			TargetRootPart = self.Npc.RootPart;
		})
	end
end

function Handler:Destroy()
	self:Unequip();
end

return Handler;
