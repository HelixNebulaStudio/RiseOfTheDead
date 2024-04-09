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

		local maxAddAp = status.AddAp;
		local addAr = status.AddAr;

		if classPlayer.Properties.WarmongerScales then -- disable if warmonger present;
			maxAddAp = 0;
		end

		local aoSrcs = classPlayer.Properties.ArmorOverchargeSources;
		
		status.Ap = (status.Ap or 0);
		
		if maxAddAp > 0 then
			local equippedTools = classPlayer:GetEquippedTools();
			local itemId = equippedTools and equippedTools.ItemId;
			local isPacifist = (itemId and (modItemsLibrary:HasTag(itemId, "Heal") or modItemsLibrary:HasTag(itemId, "Food")))

			local armorRate = classPlayer.Properties.ArmorRate;
			if isPacifist then
				local maxArmor = classPlayer.Properties.BaseMaxArmor + (classPlayer:GetBodyEquipment("ModArmorPoints") or 0);
				status.Ap = math.clamp(status.Ap + armorRate, 0, maxAddAp);
				
			else
				status.Ap = math.clamp(status.Ap - 0.2, 0, maxAddAp); -- 2 per sec
				
			end
			
			if status.Ap > 0 then
				
				aoSrcs[key] = status.Ap;
				classPlayer:SetArmorSource(key, {
					Amount=addAr/10;
				});
				if not status.Visible then
					status.Visible = true;
					sync = true;
				end
				
			else
				aoSrcs[key] = nil;
				classPlayer:SetArmorSource(key);
				if status.Visible then
					status.Visible = false;
					sync = true;
				end
				
			end
			
		else
			aoSrcs[key] = nil;
			classPlayer:SetArmorSource(key);
			if status.Visible then
				status.Visible = false;
				sync = true;
			end
			
		end
		
		return sync;
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
