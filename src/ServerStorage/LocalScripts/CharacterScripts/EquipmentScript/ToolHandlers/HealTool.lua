local ToolHandler = {}

local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Services;
local RunService = game:GetService("RunService");

local character = script.Parent.Parent.Parent;
local humanoid = character:WaitForChild("Humanoid");
local animator = humanoid:WaitForChild("Animator");
local localPlayer = game.Players.LocalPlayer;
local camera = workspace.CurrentCamera;

--== Modules;
local modData = require(localPlayer:WaitForChild("DataModule"));
local modCharacter = modData:GetModCharacter();
local modInterface = modData:GetInterfaceModule();

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modTools = require(game.ReplicatedStorage.Library.Tools);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modFlashlight = require(script.Parent.Parent:WaitForChild("Flashlight"));
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modPlayers = require(game.ReplicatedStorage.Library.Players);
local modInteractables = require(game.ReplicatedStorage.Library.Interactables);

local modCameraUtil = require(game.ReplicatedStorage.Library.Util.CameraUtil);

--== Remotes;
local remoteToolInputHandler = modRemotesManager:Get("ToolInputHandler");

--== Vars;
local mouseProperties = modCharacter.MouseProperties;
local characterProperties = modCharacter.CharacterProperties;

local Equipped;
local animationFiles = {};
--== Script;

function ToolHandler:Equip(storageItem, toolModels)
	local itemId = storageItem.ItemId;
	local toolLib = modTools[itemId];
	local toolConfig = toolLib.NewToolLib();
	local configurations = toolConfig.Configurations;
	local classPlayer = modPlayers.GetByName(localPlayer.Name);

	if storageItem.MockItem then
		toolConfig.MockItem = true;
	end
	
	local startHealingTick, progressBarTick;

	local function updateProgressionBar(p)
		p = p or 0;
		if progressBarTick == nil or tick()-progressBarTick > 0.1 then
			progressBarTick = tick();
			modData.UpdateProgressionBar(p, "Heal");
		end
	end
	
	local function reset()
		startHealingTick = nil;
		progressBarTick = nil;
		characterProperties.ClearInteractHold();
		updateProgressionBar();
	end
	
	
	local animations = Equipped.Animations;
	for key, _ in pairs(toolLib.Animations) do
		
		local animationId = "rbxassetid://"..(toolLib.Animations[key].OverrideId or toolLib.Animations[key].Id);
		local animationFile = animationFiles[animationId] or Instance.new("Animation");
		animationFile.AnimationId = animationId;
		animationFile.Parent = humanoid;
		animationFiles[animationId] = animationFile;
		if animations[key] then animations[key]:Stop(); end
		animations[key] = animator:LoadAnimation(animationFile);
		animations[key].Name = (storageItem.ID)..":"..key;
		
		animations[key].Priority = toolLib.Animations[key].Priority or Enum.AnimationPriority.Movement;
		
	end;
	animations["Core"]:Play();

	local healProxyInteract = modInteractables.InteractProxy();
	healProxyInteract.CanInteract = false;
	
	
	Equipped.RightHand.Unequip = function()
		for key, _ in pairs(animations) do
			animations[key]:Stop();
		end
		modCharacter.EquippedTool = nil;
		if characterProperties.ProxyInteractable == healProxyInteract then
			characterProperties.ProxyInteractable = nil;
		end
		healProxyInteract.CanInteract = false;
		healProxyInteract = nil;
	end
	
	local toolModel = Equipped.RightHand.Prefab;
	local handle = toolModel and toolModel:WaitForChild("Handle") or nil;
	local trailEffect = handle and handle:FindFirstChild("BandageTrail") or nil;
	
	local useDuration = configurations.UseDuration;

	local isWounded = false;
	local function refreshUseDuration()
		-- Skill: First Aid Training;
		if classPlayer.Properties.fiaitr then
			useDuration = configurations.UseDuration * (100-classPlayer.Properties.fiaitr.Percent)/100;
		end
		
		if isWounded then
			useDuration = useDuration * 3;
		end
	end
	refreshUseDuration();
	
	

	local function activate(activateMethod)
		if storageItem.MockItem ~= true then
			storageItem = modData.GetItemById(storageItem.ID);
		end

		remoteToolInputHandler:Fire(modRemotesManager.Compress{
			Action = "action";
			SiId = storageItem.ID;
			ActionIndex = 2;
			TargetPlayer = activateMethod == 2 and healProxyInteract.Player or localPlayer;
		});

		if storageItem.Quantity <= 1 then
			ToolHandler:Unequip(storageItem);
		end
	end
	
	function healProxyInteract:OnStartInteract()
		if not characterProperties.CanAction then return end;
	end

	function healProxyInteract:OnInteracted(library)
		if not characterProperties.CanAction then return end;
		Debugger:Warn("HealTool OnInteracted");
		activate(2);
	end
	
	local minRad = math.pi*2;
	local lastScan, previousPlayer = tick(), nil;
	local activateMethod = nil;
	
	RunService:BindToRenderStep("HealTool", Enum.RenderPriority.Character.Value, function()
		if modInterface.modHealthInterface and modInterface.modHealthInterface.PreviewBar then
			modInterface.modHealthInterface.PreviewBar.Visible = true;
			modInterface.modHealthInterface.PreviewBar.BorderSizePixel = 2;
			modInterface.modHealthInterface.PreviewBar.Size = UDim2.new(math.clamp((humanoid.Health+configurations.HealAmount)/humanoid.MaxHealth, 0, 1), 0, 1, 0);
		end
		
		if mouseProperties.Mouse1Down then
			activateMethod = 1;
		elseif activateMethod == 1 then
			activateMethod = nil;
		end
		if activateMethod == nil and characterProperties.InteractionActive then
			activateMethod = 2;
		elseif activateMethod == 2 and not characterProperties.InteractionActive then
			activateMethod = nil;
		end
		
		local active = false;
		local function stop()
			if animations["Use"].IsPlaying then
				animations["Use"]:Stop();
			end
			if animations["UseOthers"].IsPlaying then
				animations["UseOthers"]:Stop();
			end
			if trailEffect then trailEffect.Enabled = false; end
			reset();
		end
		
		if not characterProperties.CanAction then
			stop();
			return;
		end

		if tick()-lastScan >= 0.2 then
			lastScan = tick();

			local targetPlayer, targetRad;
			if characterProperties.CanAction and activateMethod ~= 1 then
				targetPlayer, targetRad = modCameraUtil.GetClosestPlayerToCamera(minRad, function(classPlayer)
					return not classPlayer.IsAlive;
				end);
			end

			if targetPlayer then
				if targetPlayer ~= previousPlayer then
					reset();
				end
				previousPlayer = targetPlayer;

				local classPlayer = modPlayers.Get(targetPlayer);

				healProxyInteract.Player = targetPlayer;
				healProxyInteract.Label = "Heal "..targetPlayer.Name;
				healProxyInteract.InteractDuration = useDuration;
				healProxyInteract.Object = classPlayer.RootPart;
				healProxyInteract.CanInteract = true;

				characterProperties.ProxyInteractable = healProxyInteract;

			else
				healProxyInteract.Player = nil;
				healProxyInteract.CanInteract = false;

				characterProperties.ProxyInteractable = nil;
			end
		end
		if activateMethod == 2 and healProxyInteract.Player == nil then 
			activateMethod = nil;
		end;
		
		if activateMethod then
			if activateMethod == 1 then
				if not animations["Use"].IsPlaying then
					animations["Use"]:Play();
				end
			elseif activateMethod == 2 then
				if not animations["UseOthers"].IsPlaying then
					animations["UseOthers"]:Play();
				end
			end
			if trailEffect then trailEffect.Enabled = true; end
			
			if startHealingTick == nil then
				updateProgressionBar();
				startHealingTick = tick();

				remoteToolInputHandler:Fire(modRemotesManager.Compress{
					Action = "action";
					SiId = storageItem.ID;
					ActionIndex = 1;
				});

				isWounded = classPlayer.Properties.Wounded ~= nil;
				refreshUseDuration();
				active = true;

			else
				if not isWounded and classPlayer.Properties.Wounded ~= nil then
					active = false;
				end
				
				local progress = 0;
				if activateMethod == 1 then
					progress = (tick()-startHealingTick) / useDuration;
				elseif activateMethod == 2 then
					progress = characterProperties.InteractAlpha;
				end
				active = true;
				
				updateProgressionBar(progress);
				if progress >= 1 then
					active = false;
					reset();
					activate(1);
				end
			end
			
		end
		if not active then
			stop();
		end
		
	end);
end

function ToolHandler:Unequip(storageItem)
	RunService:UnbindFromRenderStep("HealTool");
	RunService.RenderStepped:Wait();
	modFlashlight:Destroy();
	modData.UpdateProgressionBar();
	if modInterface.modHealthInterface and modInterface.modHealthInterface.PreviewBar then
		modInterface.modHealthInterface.PreviewBar.Visible = false;
	end
	for key, equipment in pairs(Equipped) do
		if typeof(equipment) == "table" and equipment.Item and equipment.Item.ID == storageItem.ID then
			if equipment.Unequip then equipment.Unequip(); end
			Equipped[key] = {Data={};};
		end;
	end
end

function ToolHandler:Initialize(equipped)
	if Equipped ~= nil then return end;
	Equipped = equipped;
end

return ToolHandler;
