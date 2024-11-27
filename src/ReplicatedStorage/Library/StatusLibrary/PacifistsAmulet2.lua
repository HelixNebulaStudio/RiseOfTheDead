local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local localPlayer = game.Players.LocalPlayer;

local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);

local StatusClass = require(script.Parent.StatusClass).new();
--==
local key = string.lower(script.Name);

function StatusClass.OnTick(classPlayer, status, tickPack)
	if RunService:IsServer() then 
		if tickPack.ms100 ~= true then return end;
		local sync = false;

		local maxPacifistAp = status.MaxPacifistAp;
		
		if (classPlayer:GetBodyEquipment("WarmongerScales") or 0) > 0 then -- disable if warmonger present;
			maxPacifistAp = 0;
		end

		local aoSrcs = classPlayer.Properties.ArmorOverchargeSources;
		
		status.PacifistAp = (status.PacifistAp or 0);
		
		if maxPacifistAp > 0 then
			local equippedTools = classPlayer:GetEquippedTools();
			local itemId = equippedTools and equippedTools.ItemId;
			local isPacifist = not ((itemId and modItemsLibrary:HasTag(itemId, "Weapon")) or (workspace:GetServerTimeNow()-classPlayer.LastDamageDealt) < 5);

			local armorRate = classPlayer.Properties.ArmorRate;
			if isPacifist then
				local maxArmor = classPlayer.Properties.BaseMaxArmor + (classPlayer:GetBodyEquipment("ModArmorPoints") or 0);
				
				if classPlayer.Properties.Armor >= (maxArmor + status.PacifistAp) then
					status.PacifistAp = math.clamp(status.PacifistAp + armorRate, 0, maxPacifistAp);
				else
					status.PacifistAp = math.clamp(classPlayer.Properties.Armor-maxArmor , 0, maxPacifistAp);
				end
				
			else
				status.PacifistAp = math.clamp(status.PacifistAp - 0.2, 0, maxPacifistAp);
				
			end
			
			if status.PacifistAp > 0 then
				if status.LastPacifist == nil then
					status.LastPacifist = tick();
				end
				
				aoSrcs[key] = status.PacifistAp;
				status.Amount = math.floor(math.clamp(((tick()+10)-status.LastPacifist)/10, 0, 5));
				classPlayer:SetArmorSource(key, {
					Amount=status.Amount/10;
				});
				status.Visible = true;
				
			else
				status.LastPacifist = nil;
				status.Amount = 0;
				aoSrcs[key] = nil;
				classPlayer:SetArmorSource(key);
				status.Visible = false;
				
			end
			
		else
			aoSrcs[key] = nil;
			classPlayer:SetArmorSource(key);
			status.Visible = false;
			
		end
		
		return true;
	else
		
	end;
end

function StatusClass.OnExpire(classPlayer, status)
	if RunService:IsServer() then
		local aoSrcs = classPlayer.Properties.ArmorOverchargeSources;
		aoSrcs[key] = nil;
		classPlayer:SetArmorSource(key);
		
	end;
	
end

return StatusClass;