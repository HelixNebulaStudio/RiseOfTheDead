local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modInfoBubbles = shared.require(game.ReplicatedStorage.Library.InfoBubbles);
local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
--==

function modStatusEffects.onRequire()
    if RunService:IsServer() then
		modSkillTree = shared.require(game.ServerScriptService.ServerLibrary.SkillTree);

    elseif RunService:IsClient() then
		modCameraGraphics = shared.require(game.ReplicatedStorage.PlayerScripts.CameraGraphics);

    end
end


function modStatusEffects.Slowness(player: Player, amount: number, duration: number)
	amount = amount or 10;
	duration = duration or 1;
	
	local playerClass: PlayerClass = shared.modPlayers.get(player);
	local statusComp: StatusComp = playerClass.StatusComp;

	local applyParams: StatusCompApplyParam = {
		Duration = duration;
		Values = {
			Amount = amount;
		};
	};

    shared.modEventService:ServerInvoke("Status_OnMovementImpairment", {ReplicateTo={player}}, player, applyParams);
	modSkillTree:TriggerSkills(player, "OnMovementImpairment", applyParams.Duration, function(newDuration)
        applyParams.Duration = newDuration;
    end);

	applyParams.Expires = workspace:GetServerTimeNow() + applyParams.Duration;
    statusComp:Apply("Slowness", applyParams)

	modInfoBubbles.Create{
		Players={player};
		Position=(playerClass.Head and playerClass.Head.Position);
		Type="Status";
		ValueString="Slowed!";
	};
end


function modStatusEffects.Stun(player: Player, duration: number)
	duration = duration or 1;

	local playerClass: PlayerClass = shared.modPlayers.get(player);
	local statusComp: StatusComp = playerClass.StatusComp;

	local applyParams: StatusCompApplyParam = {
		Expires = workspace:GetServerTimeNow() + duration;
		Duration = duration;
		ExpiresOnDeath = true;
	};

    shared.modEventService:ServerInvoke("Status_OnMovementImpairment", {ReplicateTo={player}}, player, applyParams);
	modSkillTree:TriggerSkills(player, "OnMovementImpairment", applyParams.Duration, function(newDuration)
		applyParams.Duration = newDuration;
	end);

	applyParams.Expires = workspace:GetServerTimeNow() + applyParams.Duration;
    statusComp:Apply("Stun", applyParams);
end

function modStatusEffects.ForceField(player, duration)
	duration = duration or 60;

	local playerClass: PlayerClass = shared.modPlayers.get(player);
	local statusComp: StatusComp = playerClass.StatusComp;

	local applyParams: StatusCompApplyParam = {
		Expires = workspace:GetServerTimeNow() + duration;
		Duration = duration;
	};

	applyParams.Expires = workspace:GetServerTimeNow() + applyParams.Duration;
	statusComp:Apply("ForceField", applyParams);
end

function modStatusEffects.Dizzy(player: Player, duration: number, dizzyType)
	duration = duration or 1;

	local playerClass: PlayerClass = shared.modPlayers.get(player);
	local statusComp: StatusComp = playerClass.StatusComp;

    statusComp:Apply("Dizzy", {
		ExpiresOnDeath = true;
		Expires = workspace:GetServerTimeNow() + duration;
		Duration = duration;

        Values = {
            Amount = duration;
            DizzyType = dizzyType;
        }
    });
end


function modStatusEffects.BloxyRush(player: Player, duration: number)
	duration = duration or 2.5;

	local playerClass: PlayerClass = shared.modPlayers.get(player);
	local statusComp: StatusComp = playerClass.StatusComp;

    statusComp:Apply("BloxyRush", {
		Expires = workspace:GetServerTimeNow() + duration;
		Duration = duration;
	});
end


function modStatusEffects.Burn(player: Player, damage: number, duration: number)
	damage = damage or 10;
	duration = duration or 2.5;

	local playerClass: PlayerClass = shared.modPlayers.get(player);
	local statusComp: StatusComp = playerClass.StatusComp;

	local dmgPS = math.ceil(damage/(duration*2));
    
    statusComp:Apply("Burn", {
		ExpiresOnDeath = true;
		Expires = workspace:GetServerTimeNow() + duration;
		Duration = duration;

        Values = {
            Amount = dmgPS;
        };
	});
end


function modStatusEffects.FrostivusSpirit(player: Player, duration: number, startAmount: number)
	duration = duration or 120;

	local playerClass: PlayerClass = shared.modPlayers.get(player);
	local statusComp: StatusComp = playerClass.StatusComp;

	statusComp:Apply("FrostivusSpirit", {
		Expires = workspace:GetServerTimeNow() + duration;
		Duration = duration;
        Values = {
            Amount = (startAmount or 0);
        }; 
	});
end


function modStatusEffects.Reinforcement(player: Player, duration: number)
	duration = duration or 60;

	local playerClass: PlayerClass = shared.modPlayers.get(player);
	local statusComp: StatusComp = playerClass.StatusComp;
	if RunService:IsClient() then return end;

	local applyParams: StatusCompApplyParam = {
		Expires = workspace:GetServerTimeNow() + duration;
		Duration = duration;
	};

	applyParams.Expires = workspace:GetServerTimeNow() + applyParams.Duration;
    statusComp:Apply("Reinforcement", applyParams);
end


function modStatusEffects.XpBoost(player: Player, duration: number)
	duration = duration or 10;

	local playerClass: PlayerClass = shared.modPlayers.get(player);
	local statusComp: StatusComp = playerClass.StatusComp;

	statusComp:Apply("XpBoost", {
		Expires = workspace:GetServerTimeNow() + duration;
		Duration = duration;
	});
end


function modStatusEffects.Superspeed(player: Player, duration: number)
	duration = duration or 60;

	local playerClass: PlayerClass = shared.modPlayers.get(player);
	local statusComp: StatusComp = playerClass.StatusComp;

	local applyParams: StatusCompApplyParam = {
		Expires = workspace:GetServerTimeNow() + duration;
		Duration = duration;
	};

	applyParams.Expires = workspace:GetServerTimeNow() + applyParams.Duration;
	statusComp:Apply("Superspeed", applyParams);
end


function modStatusEffects.Lifesteal(player: Player, duration: number, amount: number)
	duration = duration or 120;
	amount = amount or 5;

	local playerClass: PlayerClass = shared.modPlayers.get(player);
	local statusComp: StatusComp = playerClass.StatusComp;

	statusComp:Apply("Lifesteal", {
		Expires = workspace:GetServerTimeNow() + duration;
		Duration = duration;
        Values = {
            Amount=amount;
        };
	});
end


function modStatusEffects.StatusResistance(player: Player, duration: number, percent: number)
	duration = duration or 1;
	percent = percent or 30;

	local playerClass: PlayerClass = shared.modPlayers.get(player);
	local statusComp: StatusComp = playerClass.StatusComp;

	statusComp:Apply("StatusResistance", {
		Expires = workspace:GetServerTimeNow() + duration;
		Duration = duration;
        Values = {
            Percent=percent;
        };
	});
end


function modStatusEffects.TiedUp(player: Player, duration: number)
	duration = duration or 2.5;

	local playerClass: PlayerClass = shared.modPlayers.get(player);
	local statusComp: StatusComp = playerClass.StatusComp;

    local applyParams: StatusCompApplyParam = {
        Expires = workspace:GetServerTimeNow() + duration;
        Duration = duration;
    };

    shared.modEventService:ServerInvoke("Status_OnMovementImpairment", {ReplicateTo={player}}, player, applyParams);
    modSkillTree:TriggerSkills(player, "OnMovementImpairment", applyParams.Duration, function(newDuration)
        applyParams.Duration = newDuration;
    end);

    applyParams.Expires = workspace:GetServerTimeNow() + applyParams.Duration;
    statusComp:Apply("TiedUp", applyParams);

    -- TODO Deprecated;
    if true then return end;
	if RunService:IsServer() then

        modStatusEffects.Replicate(player, "TiedUp", applyParams.Duration);

		local rootPart = playerClass.RootPart;
		if rootPart then
            game.Debris:AddItem(playerClass.Character:FindFirstChild("rope") , 0);

            local newRope = script:WaitForChild("rope"):Clone();
			local joint = newRope:WaitForChild("Weld");
			newRope.Parent = playerClass.Character;
			joint.Part0 = newRope;
			joint.Part1 = rootPart;
			Debugger.Expire(newRope, applyParams.Duration);
		end

	else
		local modData = shared.require(localPlayer:WaitForChild("DataModule"));
		local modCharacter = modData:GetModCharacter();

		local animator = playerClass.Humanoid:WaitForChild("Animator");
		local track = animator:LoadAnimation(script.TiedUp);
		track:Play(0.25);
		modCharacter.CharacterProperties.CanMove = false;
		modCharacter.CharacterProperties.CanAction = false;
		modCharacter.MouseProperties.Mouse1Down = false;
		modCharacter.MouseProperties.Mouse2Down = false;
		modCharacter.UpdateWalkSpeed();
		spawn(function()
			if playerClass.Properties["isTiedUp"] then return end;
			playerClass.Properties["isTiedUp"] = true;
			repeat until modSyncTime.Clock.Value >= (playerClass.Properties.TiedUp and playerClass.Properties.TiedUp.Expires or modSyncTime.Clock.Value-1) or not RunService.Heartbeat:Wait();
			if modCharacter then
				track:Stop(0.25);
				modCharacter.CharacterProperties.CanMove = true;
				modCharacter.CharacterProperties.CanAction = true;
				modCharacter.UpdateWalkSpeed();
			end
			playerClass.Properties["isTiedUp"] = false;
		end)
	end
end


function modStatusEffects.Poisoned(player: Player, duration: number)
	duration = duration or 1;

	local playerClass: PlayerClass = shared.modPlayers.get(player);
	local statusComp: StatusComp = playerClass.StatusComp;

	local applyParams: StatusCompApplyParam = {
		Expires = workspace:GetServerTimeNow() + duration;
		Duration = duration;
        Values = {
            Amount=duration;
        };
	};
	statusComp:Apply("Poisoned", applyParams);
end

function modStatusEffects.NightVision(player: Player)
	local playerClass: PlayerClass = shared.modPlayers.get(player);
	local statusComp: StatusComp = playerClass.StatusComp;

    local nightVision: StatusClassInstance = statusComp:GetOrDefault("NightVision");

    if nightVision then
        statusComp:Apply("NightVision", nil);
    else
        statusComp:Apply("NightVision", {});
    end
end


function modStatusEffects.CritBoost(player, duration, amount)
	duration = duration or 60;
	amount = amount or 10;

	local playerClass: PlayerClass = shared.modPlayers.get(player);
	local statusComp: StatusComp = playerClass.StatusComp;

    statusComp:Apply("CritBoost", {
        Expires = workspace:GetServerTimeNow() + duration;
        Duration = duration; 
        Values = {
            Amount=amount;
        }
    });
end


function modStatusEffects.Ziphoning(player: Player, duration: number)
	duration = duration or 60;

	local playerClass: PlayerClass = shared.modPlayers.get(player);
	local statusComp: StatusComp = playerClass.StatusComp;

    statusComp:Apply("Ziphoning", {
        Expires = workspace:GetServerTimeNow() + duration;
        Duration = duration;
        Values = {
            Pool = 0;
            Amount = 0;
        };
    });
end


function modStatusEffects.Withering(player: Player, duration: number)
	if RunService:IsClient() then return end
	duration = duration or 30;

	local playerClass: PlayerClass = shared.modPlayers.get(player);
	local statusComp: StatusComp = playerClass.StatusComp;

	statusComp:Apply("Withering", {
		Expires = workspace:GetServerTimeNow() + duration;
		Duration = duration;
		Alpha = 0;
	});
end


function modStatusEffects.VexBile(player: Player, duration: number)
	duration = duration or 1;

	local playerClass: PlayerClass = shared.modPlayers.get(player);
	local statusComp: StatusComp = playerClass.StatusComp;

    statusComp:Apply("VexBile", {
        Expires = workspace:GetServerTimeNow() + duration;
        Duration = duration;
    });
end


function modStatusEffects.Freezing(player, duration)
	duration = duration or 2.5;

	local playerClass: PlayerClass = shared.modPlayers.get(player);
	local statusComp: StatusComp = playerClass.StatusComp;

	statusComp:Apply("Freezing", {
		Expires = workspace:GetServerTimeNow() + duration;
		Duration = duration;
	});
end


function modStatusEffects.CorruptVision(player: Player, val: boolean, params)
	params = typeof(params) == "table" and params or {};
	val = val == true;

	if RunService:IsServer() then
		modStatusEffects.Replicate(player, "CorruptVision", val, params);
	else
		if val == true then
			modCameraGraphics.TintColor:Set("corrupt", params.TintColor or Color3.fromRGB(204, 157, 151), 1);

			local corruptAtmosphere: Atmosphere = script.CorruptAtmosphere;

			corruptAtmosphere.Density = params.Density or corruptAtmosphere.Density;
			corruptAtmosphere.Offset = params.Offset or corruptAtmosphere.Offset;

			corruptAtmosphere.Color = params.Color or corruptAtmosphere.Color;
			corruptAtmosphere.Decay = params.Decay or corruptAtmosphere.Decay;
			corruptAtmosphere.Glare = params.Glare or corruptAtmosphere.Glare;
			corruptAtmosphere.Haze = params.Haze or corruptAtmosphere.Haze;

			modCameraGraphics:SetAtmosphere(corruptAtmosphere, "corrupt", modCameraGraphics.EffectsPriority.Sky);
		else
			modCameraGraphics.TintColor:Remove("corrupt");
			modCameraGraphics:ClearAtmosphere("corrupt");
		end
	end
end


function modStatusEffects.Chained(player: Player, duration: number, position: Vector3, anchorHealth, isHardMode)
	if RunService:IsClient() then return end
	duration = duration or 10;
	anchorHealth = anchorHealth or 100;

	local playerClass: PlayerClass = shared.modPlayers.get(player);
	local statusComp: StatusComp = playerClass.StatusComp;

	local statusClass: StatusClassInstance = statusComp:GetOrDefault("Chained");
	if statusClass == nil then
        statusClass = statusComp:Apply("Chained", {
			Expires = workspace:GetServerTimeNow() + duration;
			Duration = duration;
        })
	end

	return statusClass:Chain(duration, position, anchorHealth, isHardMode);
end


function modStatusEffects.FumesGas(player: Player, damage: number)
	if RunService:IsClient() then return end
	damage = damage or 6;

	local playerClass: PlayerClass = shared.modPlayers.get(player);
	local statusComp: StatusComp = playerClass.StatusComp;

    local statusClass: StatusClassInstance = statusComp:GetOrDefault("FumesGas");
    if statusClass then
        statusClass.Values.LastRefresh = tick();
        return;
    end

	statusComp:Apply("FumesGas", {
        Values = {
            Damage = damage;
        }
    });
end


return modStatusEffects;