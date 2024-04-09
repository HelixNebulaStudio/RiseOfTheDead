local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local localPlayer = game.Players.LocalPlayer;

local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

local StatusClass = require(script.Parent.StatusClass).new();
--==
function StatusClass.OnApply(classPlayer, status)
	local humanoid = classPlayer.Humanoid;
	
	if RunService:IsClient() then
		if classPlayer:GetInstance() ~= localPlayer then return; end
		
		local modData = require(localPlayer:WaitForChild("DataModule"));
		local modCharacter = modData:GetModCharacter();
		
		modCharacter.CharacterProperties.IsWounded = true;
		
	else
		local newInteractable = script:WaitForChild("ReviveInteractable"):Clone();
		newInteractable.Name = "Interactable";
		newInteractable.Parent = classPlayer.Character;

		local reviveInteract = require(newInteractable);
		reviveInteract.Player = classPlayer:GetInstance();
		
		status.ReviveInteractable = newInteractable;
	end
	
end

function StatusClass.OnExpire(classPlayer, status)
	local humanoid = classPlayer.Humanoid;
	
	if RunService:IsServer() then
		local knockoutTime = modConfigurations.KnockoutOnDeath;
		
		if status.Revived then
			
		else
			if knockoutTime > 0 then
				if classPlayer.Properties.KnockedOut == nil then
					local statusTable = {
						ExpiresOnDeath=true;
						Duration=knockoutTime;
					};
					statusTable.Expires=modSyncTime.GetTime() + knockoutTime;

					classPlayer:SetProperties("Ragdoll", 1);
					classPlayer:SetProperties("KnockedOut", statusTable);
					
					classPlayer:UnequipTools();
				end

			else
				classPlayer:Kill();
				
			end
			
		end
		
		if status.ReviveInteractable then
			status.ReviveInteractable:Destroy();
			status.ReviveInteractable = nil;
		end
		
	else
		if classPlayer:GetInstance() ~= localPlayer then return; end
		
		local modData = require(localPlayer:WaitForChild("DataModule"));
		local modCharacter = modData:GetModCharacter();
		
		modCharacter.CharacterProperties.IsWounded = false;
		
	end
end

function StatusClass.OnTick(classPlayer, status)
	local humanoid = classPlayer.Humanoid;
	
	if humanoid.Health > 0 then
		status.Revived = true;
		status.Expires = modSyncTime.GetTime();
		return true;
	end
end

return StatusClass;
