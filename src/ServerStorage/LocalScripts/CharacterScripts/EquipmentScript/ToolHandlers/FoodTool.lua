local ToolHandler = {}

local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Services;
local RunService = game:GetService("RunService");

local character = script.Parent.Parent.Parent;
local humanoid = character:WaitForChild("Humanoid");
local animator = humanoid:WaitForChild("Animator");
local player = game.Players.LocalPlayer;

--== Modules;
local modData = require(player:WaitForChild("DataModule") :: ModuleScript);
local modCharacter = modData:GetModCharacter();

local modFlashlight = require(script.Parent.Parent:WaitForChild("Flashlight"));
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modTools = require(game.ReplicatedStorage.Library.Tools);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);

--== Remotes;
local remoteToolHandlerPrimaryFire = modRemotesManager:Get("ToolHandlerPrimaryFire");

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

	if storageItem.MockItem then
		toolConfig.MockItem = true;
	end
	
	local startHealingTick, progressBarTick;
	
	local function updateProgressionBar(p)
		p = p or 0;
		if progressBarTick == nil or tick()-progressBarTick > 0.1 then
			progressBarTick = tick();
			modData.UpdateProgressionBar(p, "Eating");
		end
	end
	
	local function reset()
		startHealingTick = nil;
		progressBarTick = nil;
		updateProgressionBar();
	end
	
	local toolModel = Equipped.RightHand.Prefab;
	local handle = toolModel and toolModel:WaitForChild("Handle") or nil;
	
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
		
		--animations[key].Priority = toolLib.Animations[key].Priority or Enum.AnimationPriority.Movement;
		if key ~= "Core" then
			animations[key].Priority = Enum.AnimationPriority.Action2;
		end
		
		animations[key]:GetMarkerReachedSignal("PlaySound"):Connect(function(paramString)
			modAudio.Preload(paramString, 1);
			modAudio.Play(paramString, handle, false);
		end)
		
		animations[key]:GetMarkerReachedSignal("SetTransparency"):Connect(function(paramString)
			local args = string.split(tostring(paramString), ";");
			
			local partObj = toolModel and toolModel:FindFirstChild(args[1]);
			local transparencyValue = partObj and args[2];
			
			if transparencyValue then
				partObj.Transparency = transparencyValue;
			end
		end)
	end;
	animations["Core"]:Play();
	characterProperties.HideCrosshair = true;
	characterProperties.UseViewModel = false;
	
	local animSoundConn;
	Equipped.RightHand.Unequip = function()
		characterProperties.UseViewModel = true;

		for key, _ in pairs(animations) do
			animations[key]:Stop();
			animations[key] = nil;
		end
		modCharacter.EquippedTool = nil;
		animSoundConn:Disconnect();
	end
	
	animSoundConn = animations["Use"].KeyframeReached:Connect(function(keyframe)
		if keyframe:sub(1, 6) == "Sound_" then
			local id = keyframe:sub(7, #keyframe);
			modAudio.Preload(id, 1);
			modAudio.PlayReplicated(id, handle);
		end
	end)
	
	
	RunService:BindToRenderStep("FoodTool", Enum.RenderPriority.Character.Value, function()
		if mouseProperties.Mouse1Down and characterProperties.CanAction then
			if not animations["Use"].IsPlaying then
				animations["Use"]:Play();
				animations["Use"]:AdjustSpeed(animations["Use"].Length/configurations.UseDuration);
			end
			if startHealingTick == nil then
				updateProgressionBar();
				startHealingTick = tick();
				remoteToolHandlerPrimaryFire:FireServer(storageItem.ID, 1);
				
			else
				local progress = (tick()-startHealingTick)/configurations.UseDuration;
				updateProgressionBar(progress);
				if progress >= 1 then
					mouseProperties.Mouse1Down = false;
					reset();
					if storageItem.MockItem ~= true then
						storageItem = modData.GetItemById(storageItem.ID);
					end
					remoteToolHandlerPrimaryFire:FireServer(storageItem.ID, 2);
				end
				
			end
		else
			animations["Use"]:Stop();
			reset();
		end
	end);
end

function ToolHandler:Unequip(storageItem)
	RunService:UnbindFromRenderStep("FoodTool");
	RunService.RenderStepped:Wait();
	modFlashlight:Destroy();
	modData.UpdateProgressionBar();
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