local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

--== Variables;
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modAnalytics = shared.require(game.ServerScriptService.ServerLibrary.GameAnalytics);
local modFormatNumber = shared.require(game.ReplicatedStorage.Library.FormatNumber);
local modWorkbenchLibrary = shared.require(game.ReplicatedStorage.Library.WorkbenchLibrary);

return function(player, dialog, data)
	local modAnalyticsService = shared.require(game.ServerScriptService.ServerLibrary.AnalyticsService);

	local profile = shared.modProfile:Get(player);
	local playerSave = profile:GetActiveSave();
	local traderProfile = profile and profile.Trader;
	local inventory = playerSave.Inventory;
	
	
	local fortuneSkinCost = 100000;
	if traderProfile.Gold >= fortuneSkinCost then
		local equippedToolID = profile.EquippedTools.ID;
		local storageItem = inventory:Find(equippedToolID);
		local itemDisplayLib = storageItem and modWorkbenchLibrary.ItemAppearance[storageItem.ItemId];

		local function purchase1mPattern(dialog)
			local dialogPacket = {
				Face="Happy";
				Say="Yes, I would like to purchase it.";
			};

			if itemDisplayLib then
				local modSkinPerm = shared.require(game.ReplicatedStorage.Library.UsableItems.Generics.SkinPerm);
				local fortuneSkinId = "106";

				if not modSkinPerm.HasSkinPermanent(storageItem, fortuneSkinId) then
					dialogPacket.Reply="Here you go! The fortune skin permanent is now on your tool.";
					dialog:AddDialog(dialogPacket, function(dialog)

						traderProfile:AddGold(-fortuneSkinCost);

						modSkinPerm.AddSkinPermanent(storageItem, fortuneSkinId);

						modAnalyticsService:Sink{
							Player=player;
							Currency=modAnalyticsService.Currency.Gold;
							Amount=fortuneSkinCost;
							EndBalance=traderProfile.Gold;
							ItemSKU=`Purchase:fortunepatternperm`;
						};

						task.spawn(function()
							modAnalytics.RecordResource(player.UserId, fortuneSkinCost, "Sink", "Gold", "Purchase", "fortunepatternperm");
						end)
					end);

				else
					dialogPacket.Reply="The tool you equipped already has a skin permanent.";
					dialog:AddDialog(dialogPacket);

				end

			elseif storageItem then
				dialogPacket.Reply="The tool you equipped cannot be customized.";
				dialog:AddDialog(dialogPacket);

			else
				dialogPacket.Reply="Equip a tool that you want me to customize first.";
				dialog:AddDialog(dialogPacket);

			end
		end

		local costString = modFormatNumber.Beautify(fortuneSkinCost);
		dialog:AddDialog({
			Face="Disbelief";
			Say="What can I get for <b>".. costString .." gold</b>?";
			Reply=(
				storageItem == nil 
					and "Equip a tool first and I'll show you."
					or "Well, there's this special <b>Fortune</b> pattern for <b>".. costString .." gold</b>. Do you want it?"
			);
		}, function(dialog)
			if storageItem == nil then return end;

			local itemLib = modItemsLibrary:Find(storageItem.ItemId);
			dialog:AddDialog({
				Face="Surprise";
				Say="Yes, I want it..";
				Reply="Really? For <b>".. costString .." gold</b>, you really want it on your <b>".. itemLib.Name .."</b>?";
				InspectItem={
					ID=storageItem.ID;
					ItemId=storageItem.ItemId;
					Values={ActiveSkin=106;}; -- SkinWearId=372273;
				}
			}, function(dialog)
				purchase1mPattern(dialog)
				dialog:AddDialog({
					Face="Surprise";
					Say="Nevermind";
					Reply="Arg..";
				});

			end)
			dialog:AddDialog({
				Face="Surprise";
				Say="No thanks.";
				Reply="Oh well, come back anytime.";
			});
		end)

	end
end