local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modToolHandler = shared.require(game.ReplicatedStorage.Library.ToolHandler);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modGlobalVars = shared.require(game.ReplicatedStorage.GlobalVariables);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);

local toolHandler: ToolHandler = modToolHandler.new();
--==

function toolHandler.onRequire()
    remoteToolInputHandler = modRemotesManager:Get("ToolInputHandler");

	if RunService:IsServer() then
		modOnGameEvents = shared.require(game.ServerScriptService.ServerLibrary.OnGameEvents);
		modAnalyticsService = shared.require(game.ServerScriptService.ServerLibrary.AnalyticsService);
		
	elseif RunService:IsClient() then
		modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);
		modData = shared.require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);

	end
end

function toolHandler.Init(handler: ToolHandlerInstance)
end

function toolHandler.Equip(handler: ToolHandlerInstance)
	local equipmentClass: EquipmentClass = handler.EquipmentClass;

	local configurations = equipmentClass.Configurations;
	local properties = equipmentClass.Properties;

	handler:LoadWieldConfig();
	Debugger:Warn(`Equip ({handler.WieldComp.ItemId})`);
end


if RunService:IsClient() then -- MARK: Client
	function toolHandler.ClientEquip(handler: ToolHandlerInstance)
		local playerClass: PlayerClass = shared.modPlayers.get(localPlayer);
		local humanoid: Humanoid = playerClass.Humanoid;

		local modCharacter = modData:GetModCharacter();
		local modInterface = modData:GetInterfaceModule();
		
		local mouseProperties = modCharacter.MouseProperties;
		local characterProperties = modCharacter.CharacterProperties;

		local storageItem: StorageItem = handler.StorageItem;
		local equipmentClass: EquipmentClass = handler.EquipmentClass;
		local toolAnimator: ToolAnimator = handler.ToolAnimator;
	
		local siid = storageItem.ID;
		local itemId = storageItem.ItemId;
		
		local toolPackage = handler.ToolPackage;
		local animations = toolPackage.Animations;

	
		local configurations: ConfigVariable = equipmentClass.Configurations;
		local properties: PropertiesVariable<{}> = equipmentClass.Properties;
	
		characterProperties.HideCrosshair = true;
		characterProperties.UseViewModel = false;

		local startUseTick, progressBarTick;
		
		local mechanicsBarElement: InterfaceElement = modClientGuis.getElement("MechanicsBar");
		local function updateProgressionBar(p)
			p = p or 0;
			if progressBarTick == nil or tick()-progressBarTick > 0.1 then
				progressBarTick = tick();
				mechanicsBarElement.ProgressValue = p;
				mechanicsBarElement.ProgressType = "Eating";
			end
		end
		
		local function reset()
			startUseTick = nil;
			progressBarTick = nil;
			updateProgressionBar();
		end
		
		local mainToolModel = handler.MainToolModel;
		local handle = mainToolModel and mainToolModel:WaitForChild("Handle") or nil;
		
		toolAnimator:LoadAnimations(animations, toolPackage.DefaultAnimatorState, handler.Prefabs);
		toolAnimator:Play("Core");
        if toolPackage.Animations.Load then
            toolAnimator:Play("Load", {
                FadeTime=0;
            });
            if toolPackage.OnAnimationPlay then
                task.defer(function()
                    toolPackage.OnAnimationPlay("Load", handler, mainToolModel);
                end)
            end
        end
		
		RunService:BindToRenderStep("ToolRender", Enum.RenderPriority.Character.Value, function()
			if mouseProperties.Mouse1Down and characterProperties.CanAction then
				local track = toolAnimator:GetPlaying("Use");
				if track == nil then
					track = toolAnimator:Play("Use", {
						PlayLength = configurations.UseDuration;
					});
				end

				if startUseTick == nil then
					updateProgressionBar();
					startUseTick = tick();
					remoteToolInputHandler:FireServer(modRemotesManager.Compress({
						Action = "action";
						Siid = siid;
						ActionIndex = 1;
					}));
					
				else
					local progress = (tick()-startUseTick)/configurations.UseDuration;
					updateProgressionBar(progress);
					if progress >= 1 then
						mouseProperties.Mouse1Down = false;
						reset();
						remoteToolInputHandler:FireServer(modRemotesManager.Compress({
							Action = "action";
							Siid = siid;
							ActionIndex = 2;
						}));
					end
					
				end
			else
				toolAnimator:Stop("Use");
				reset();
			end
		end);
	end

	function toolHandler.ClientUnequip(handler: ToolHandlerInstance)
		
	end


elseif RunService:IsServer() then -- MARK: Server
	function toolHandler.ActionEvent(handler: ToolHandlerInstance, packet)
		local characterClass: CharacterClass = handler.CharacterClass;
		local actionIndex = packet.ActionIndex;

		local healthComp: HealthComp = characterClass.HealthComp;
		if healthComp.IsDead then return end;
	
		local statusComp: StatusComp = characterClass.StatusComp;

		local equipmentClass: EquipmentClass =  handler.EquipmentClass;
		local configurations = equipmentClass.Configurations;
		local properties = equipmentClass.Properties;

		local storageItem: StorageItem = handler.StorageItem;

		if actionIndex == 1 then
			properties.LastFire = tick();
			
		elseif actionIndex == 2 then
			local itemId = storageItem.ItemId;
			local itemLib = modItemsLibrary:Find(itemId);
			
			local useDuration = configurations.UseDuration;
			
			local lapsed = tick() - properties.LastFire;
			local inValidTimeRange = lapsed >= useDuration-0.5 and lapsed <= useDuration+0.5;
			
			if inValidTimeRange == false then
				Debugger:Warn("TimeLapsed invalid", inValidTimeRange, "configurations.UseDuration", configurations.UseDuration, "useDuration", useDuration);
				return;
			end

			local effectDuration = configurations.EffectDuration;
			local changeRef = {
				EffectDuration = effectDuration;
			};
			shared.modEventService:ServerInvoke("Tools_BindFoodTool", {}, "Consume", handler, changeRef);
			effectDuration = changeRef.EffectDuration;
			
			local maxHealthRate = 30;

			if storageItem and storageItem.Quantity <= 0 then return end;
			if configurations.EffectType == "Heal" then
				local curTime = workspace:GetServerTimeNow();

				local healStatus: StatusClassInstance = statusComp:GetOrDefault(configurations.HealSourceId);
				if healStatus == nil then
					healStatus = statusComp:Apply(configurations.HealSourceId, {
						Expires = curTime + effectDuration;
						Duration = effectDuration;
						
						Values = {
							LastDamageTaken = healthComp.LastDamageTaken;
							HealRate = configurations.HealRate;
							Stack = 1;
						};	
					});

				else
					healStatus.Values.Stack = healStatus.Values.Stack + 1;
					local deminishRate = 1/math.max(healStatus.Values.Stack, 1); 

					healStatus.Values.HealRate = math.min(healStatus.Values.HealRate + configurations.HealRate * deminishRate, maxHealthRate);
					
					local addDuration = effectDuration * deminishRate;
					local timeLeft = healStatus.Expires - curTime;

					healStatus.Duration = healStatus.Duration + addDuration;
					healStatus.Expires = curTime + timeLeft + addDuration;

					healStatus = statusComp:Apply(configurations.HealSourceId, healStatus);
				end

				healStatus.Text = `{math.round(healStatus.Values.HealRate*100)/10} hp/s`;
				healStatus:Sync();
				
			elseif configurations.EffectType == "Status" then
				local statusId = typeof(configurations.StatusId) == "table" 
					and configurations.StatusId[math.random(1, #configurations.StatusId)] or configurations.StatusId;
				if modStatusEffects[statusId] and characterClass.ClassName == "PlayerClass" then
					modStatusEffects[statusId]((characterClass :: PlayerClass):GetInstance(), effectDuration);
				end

			elseif configurations.EffectType == "Perks" then
				if characterClass.ClassName == "PlayerClass" then
					local player = (characterClass :: PlayerClass):GetInstance();
					local profile = shared.modProfile:Get(player);
					local playerSave = profile:GetActiveSave();

					profile:AddPlayPoints(3, "Gameplay:Use");
					if playerSave:GetStat("Perks") >= modGlobalVars.MaxPerks then
						shared.Notify(player, "You are too full to eat this. Perks maxed.", "Negative");
						return;
					end

					playerSave:AddStat("Perks", 1000);

					modAnalyticsService:Source{
						Player=player;
						Currency=modAnalyticsService.Currency.Perks;
						Amount=1000;
						EndBalance=playerSave:GetStat("Perks");
						ItemSKU=`Usage:{itemId}`;
					};
				end

			end
	
			characterClass.WieldComp:Unequip();

			if characterClass.ClassName == "PlayerClass" then
				local player = (characterClass :: PlayerClass):GetInstance();
				local profile = shared.modProfile:Get(player);
				local inventory = profile.ActiveInventory;

				inventory:Remove(handler.StorageItem.ID, 1);
				shared.Notify(player, ("1 $Item removed from your Inventory."):gsub("$Item", itemLib.Name), "Negative");
			end

			modOnGameEvents:Fire("OnFoodToolConsume", handler);

		end

	end
end

return toolHandler;