local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modClothingProperties = require(game.ReplicatedStorage.Library.ClothingLibrary:WaitForChild("ClothingProperties"));
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);

local attirePackage = {
	GroupName="HeadGroup";
}

function attirePackage.NewToolLib(handler)
	local toolLib = {};

	toolLib.HasFlinchProtection = true;
	toolLib.NekronMask = true;
	
	function toolLib:OnEquip(classPlayer, storageItem)
		local player = classPlayer:GetInstance();
		if storageItem.Changed == nil then
			storageItem.Changed = function()
				self:OnEquip(classPlayer, storageItem);
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
	
	return modClothingProperties.new(toolLib);
end

return attirePackage;