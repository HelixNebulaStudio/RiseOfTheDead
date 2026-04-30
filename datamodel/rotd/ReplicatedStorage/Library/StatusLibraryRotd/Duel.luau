local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local RunService = game:GetService("RunService");

local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);
local modProjectile = shared.require(game.ReplicatedStorage.Library.Projectile);

local statusPackage = {
    Id = "Duel";
    Icon = "rbxassetid://4769236052";
    Name = "Duel";
    Description = "You are dueling with $TargetName!";
    Buff = true;
    ExpiresOnDeath = true;
};

function statusPackage.BindApply(statusClass: StatusClassInstance)
    if RunService:IsClient() then return end;
    local characterClass: CharacterClass = statusClass.StatusOwner :: CharacterClass;
    
    local theirName = statusClass.Values.TargetName;

    local defaultCanBeHurtByBoolString = characterClass.HealthComp.DefaultCanBeHurtByBoolString or "";
    characterClass.HealthComp:SetCanBeHurtBy(`{defaultCanBeHurtByBoolString}|{theirName}`);
end

function statusPackage.BindExpire(statusClass: StatusClassInstance)
    if RunService:IsClient() then return end;
    local characterClass: CharacterClass = statusClass.StatusOwner :: CharacterClass;
    local myName = characterClass.Name;

    local statusValues = statusClass.Values;
    local duelId = statusValues.DuelId;
    local theirCharacter = statusValues.TargetCharacter;
    local theirName = statusValues.TargetName;

    local theirHealthComp: HealthComp? = modHealthComponent.getByModel(theirCharacter);
    local theirCharacterClass: CharacterClass? = (theirHealthComp and theirHealthComp.CompOwner or nil) :: CharacterClass;

    characterClass.Properties.DuelData = nil;
    characterClass.HealthComp:SetCanBeHurtBy();

    if statusValues.WinnerName then 
        if statusValues.WinnerName == myName then
            task.spawn(function()
                local originCf = characterClass:GetCFrame() * CFrame.new(0, 5, 0);
                for a=1, 4 do
                    local projectileInstance: ProjectileInstance = modProjectile.fire("fireworks", {
                        OriginCFrame = originCf;
                        CharacterClass = characterClass;
                    });
                    modProjectile.serverSimulate(projectileInstance, {
                        Velocity = Vector3.yAxis;
                    });
                    task.wait(math.random(5, 25)/100);
                end
            end)
        end

        return;
    end;

    if statusValues.TargetValues == nil then
        local isExpired = workspace:GetServerTimeNow() > statusClass.Expires;

        if isExpired then
            shared.Notify(game.Players:GetPlayers(), `{duelId} was a tie!`, "Important", duelId);

        else
            statusValues.WinnerName = theirName;
            shared.Notify(game.Players:GetPlayers(), `{theirName} has won a duel against {myName}!`, "Important");

            if theirCharacterClass then
                local theirStatusComp = theirCharacterClass.StatusComp:GetOrDefault("Duel");
                if theirStatusComp and theirStatusComp.Values.DuelId == duelId then
                    theirStatusComp.Values.WinnerName = theirName;
                    theirStatusComp.IsExpired = true;
                end
            end
        end
    end
end

if RunService:IsServer() then
    function statusPackage.sendAndHandleRequest(player, targetName, dmgMulti)
		local playerClassA: PlayerClass = shared.modPlayers.get(player);

		local playerADuelData = playerClassA.Properties.DuelData;
		if playerADuelData == nil then
			playerClassA.Properties.DuelData = {};
			playerADuelData = playerClassA.Properties.DuelData;
		end
		
		if playerADuelData.Requesting and os.time()-playerADuelData.Requesting < 60 then
			shared.Notify(player, "You pvp request is on cooldown for ".. 60-(os.time()-playerADuelData.Requesting) .."s.", "Negative");
			return;
		end
			
		if player.Name == targetName then
			shared.Notify(player, "You can't duel yourself.", "Negative"); 
			return;
		end;
		
		local targetPlayer = game.Players:FindFirstChild(targetName);
		if targetPlayer == nil then
			shared.Notify(player, "Could not find player ("..targetName..")..", "Negative");
			return;
		end

        dmgMulti = dmgMulti or 1;

		local playerClassB: PlayerClass = shared.modPlayers.get(targetPlayer);
		local playerBDuelData = playerClassB.Properties.DuelData;

		if playerBDuelData 
		and playerBDuelData.InDuel == nil 
		and playerBDuelData.Name == player.Name 
		and os.time()-playerBDuelData.Requesting <= 30 then

			local players = {player, targetPlayer};
			shared.Notify(
                game.Players:GetPlayers(), 
                `A duel has broke out between {targetPlayer.Name} and {player.Name}."`, 
                "Important"
            );
			for a=5, 1, -1 do
				shared.Notify(players, `The duel begins in {a}.`, "Important");
				task.wait(1);
			end
			shared.Notify(players, "The duel has begun!", "Important");

			playerBDuelData.InDuel = player.Name;
			playerADuelData.InDuel = targetPlayer.Name;
			playerADuelData.DmgMultiplier = playerBDuelData.DmgMultiplier;
			
            local duelId = `{player.Name} vs {targetName}`;
            local curTime = workspace:GetServerTimeNow();
            local duelColor = Color3.fromRGB(199, 46, 19);

            playerClassA.StatusComp:Apply("Duel", {
                Expires = curTime + 150;
                Duration = 150;
                Values = {
                    IconColor = duelColor;
                    DuelId = duelId;
                    TargetName = playerClassB.Name;
                    TargetCharacter = playerClassB.Character;
                };
            });
            playerClassB.StatusComp:Apply("Duel", {
                Expires = curTime + 150;
                Duration = 150;
                Values = {
                    IconColor = duelColor;
                    DuelId = duelId;
                    TargetName = playerClassA.Name;
                    TargetCharacter = playerClassA.Character;
                };
            });

		else
			playerADuelData.Requesting = os.time();
			playerADuelData.Name = targetPlayer.Name;
			playerADuelData.DmgMultiplier = dmgMulti;

			shared.Notify(player, `Requesting {targetPlayer.Name} to a duel..`, "Important");
			
			local toastId = `duel_{targetPlayer.Name}`;

			local targetProfile = shared.modProfile:Get(targetPlayer);
			local curTime = workspace:GetServerTimeNow();

			local duelInviteToast = targetProfile.ToastPackets:GetById(toastId);
			if duelInviteToast == nil or (curTime-duelInviteToast.AddTime > 10) then
				shared.Notify(targetPlayer, `{player.Name} is requesting you to a duel..`, "Important");
			end

			targetProfile.ToastPackets:Add{
				Id = toastId;
				Type = "DuelInvite";
				AddTime = curTime;
				ExpireTime = curTime+60;
				SenderName = player.Name;
				SenderId = player.UserId;
			};
		end
    end
end

return modStatusClass.new(statusPackage);