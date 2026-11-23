local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modToolHandler = shared.require(game.ReplicatedStorage.Library.ToolHandler);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local remoteToolInputHandler = modRemotesManager:Get("ToolInputHandler");
--==
local toolHandler: ToolHandler = modToolHandler.new();

if RunService:IsClient() then -- MARK: Client
	modData = shared.require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);

	function toolHandler.ClientEquip(handler: ToolHandlerInstance)
		local toolPackage = handler.ToolPackage;
		local animations = {
			Use={Id=76029161876673};
		};

		local toolAnimator: ToolAnimator = handler.ToolAnimator;
		toolAnimator:LoadAnimations(animations, toolPackage.DefaultAnimatorState, handler.Prefabs);
			
		local modCharacter = modData:GetModCharacter();
		local characterProperties = modCharacter.CharacterProperties;

		characterProperties.UseViewModel = false;
	end

elseif RunService:IsServer() then -- MARK: Server

end

function toolHandler.InputEvent(handler: ToolHandlerInstance, inputData)
	local healthComp: HealthComp = handler.CharacterClass.HealthComp;
	if healthComp.IsDead then return end;
	
	local toolPackage = handler.ToolPackage;
	if inputData.InputState ~= "Begin" then return end;
	if inputData.KeyIds.KeyFire ~= true then return end;

	local equipmentClass: EquipmentClassRotd = handler.EquipmentClass;
	local properties = equipmentClass.Properties;

	if properties.LastPush and tick() < properties.LastPush then
		return;
	end

	local curTick = tick();
	properties.LastPush = curTick+1;

	local playerClass: PlayerClass;
	if handler.CharacterClass and handler.CharacterClass.ClassName == "PlayerClass" then
		playerClass = handler.CharacterClass :: PlayerClass;
	end

	if RunService:IsClient() then
		local toolAnimator: ToolAnimator = handler.ToolAnimator;
		toolAnimator:Play("Use", {
			-- FadeTime = 0.3;
		});

		local modCharacter = modData:GetModCharacter();
		local mouseProperties = modCharacter.MouseProperties;

		inputData.PushAim = {
			Direction = mouseProperties.Direction;
		}

		return true;
	end

	if playerClass == nil then return end;

	local playerChars: {Model} = shared.modPlayers.listCharacters();
	
	local pushAim = inputData.PushAim;
	local PUSH_REACH_DIST = 4;
	local PUSH_RADIUS = 2;
	local aimOrigin: Vector3 = (playerClass.RootPart.CFrame * CFrame.new(0, 1, -1)).Position;
	local aimDir: Vector3 = pushAim.Direction.Unit;

	modAudio.Play("Throw", playerClass.RootPart);

	local function pushTarget(player)
		shared.modPlayers.cameraShakeAndZoom(player, 5, 1, 2, 0.01, true);
		modStatusEffects.Throw(player, aimDir, 0.5);
	end

	local rayParams = RaycastParams.new();
	rayParams.IncludeInstances = playerChars;
	rayParams.ExcludeInstances = {playerClass.Character};
	rayParams.SizeGradient = -0.75;
	rayParams.IgnoreWater = true;

	local rayResult: RaycastResult? = workspace:Spherecast(aimOrigin, PUSH_RADIUS, aimDir * PUSH_REACH_DIST, rayParams);
	if rayResult == nil then return end;
	local hitPart = rayResult.Instance;

	local playerChar: Model? = nil;
	for _, char in ipairs(playerChars) do
		if not char:IsAncestorOf(hitPart) then continue end;
		playerChar = char;
		break;
	end

	local player: Player? = playerChar and game.Players:GetPlayerFromCharacter(playerChar);
	if player then
		pushTarget(player);
		properties.LastPush = curTick+1.5;
	end

	return;
end

return toolHandler;