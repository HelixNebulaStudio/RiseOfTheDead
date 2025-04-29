local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = require(game.ReplicatedStorage.Library.EquipmentClass);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
--==
local attirePackage = {
	ItemId=script.Name;
	Class="Clothing";
	
	GroupName="HeadGroup";
	
	Configurations={
		HasFlinchProtection = true;
		NekronMask = true;
	};
	Properties={};
};

function attirePackage.OnEquip(classPlayer, storageItem)
	local player = classPlayer:GetInstance();
	if storageItem.Changed == nil then
		storageItem.Changed = function()
			attirePackage.OnEquip(classPlayer, storageItem);
		end
	end
	
	local _, storage = shared.modStorage.FindIdFromStorages(storageItem.ID, player);
	if storage == nil then Debugger:Log("Unknown storage to remove nekron mask."); return end;

	if classPlayer.Properties["NekronMask"] == nil then
		local expireTime = storageItem:GetValues("Expire");
		if expireTime == nil then
			local duration = 3600;
			
			classPlayer:SetProperties("NekronMask", {
				PresistUntilExpire=true;
				Expires=modSyncTime.GetTime()+duration; 
				Duration=duration;
				StorageItemId=storageItem.ID;
			});

			storage:SetValues(storageItem.ID, {
				Expire = (modSyncTime.GetTime()+duration);
				ExpireLength = duration;
			});
		else
			if classPlayer.Properties["NekronMask"] then
				storage:SetValues(storageItem.ID, {
					Expire = classPlayer.Properties.NekronMask.Expires;
					ExpireLength = classPlayer.Properties.NekronMask.Duration;
				});
			end
		end
	end
end

function attirePackage.newClass()
	return modEquipmentClass.new(attirePackage);
end

return attirePackage;