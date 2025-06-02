local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local localPlayer = game.Players.LocalPlayer;

local modItem = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modWorkbenchLibrary = shared.require(game.ReplicatedStorage.Library.WorkbenchLibrary);
local modBlueprintLibrary = shared.require(game.ReplicatedStorage.Library.BlueprintLibraryRotd);
local modTableManager = shared.require(game.ReplicatedStorage.Library.TableManager);

local WorkbenchClass = {};
--==

function WorkbenchClass.init(interface: InterfaceInstance, workbenchWindow: InterfaceWindow)
	local modData = shared.require(localPlayer:WaitForChild("DataModule"));

	local binds = workbenchWindow.Binds;

	function WorkbenchClass.new()
		local listMenu = binds.List.create();
		listMenu.Menu.Name = "blueprints";

		local blueprintsData = modTableManager.GetDataHierarchy(modData.Profile, "GameSave/Blueprints") or {};
		local unlockedBlueprints = blueprintsData.Unlocked;

		local cateList = modBlueprintLibrary:SortCategories(unlockedBlueprints or {});

		for category, idList in pairs(cateList) do
			local newGridList = listMenu:NewGridList();
			newGridList.Name = category.."list";
			local newCateTab = listMenu:NewTab(newGridList);
			newCateTab.Name = category.."tab";
			newCateTab.titleLabel.Text = category..(" ($u/$t)"):gsub("$u", tostring(#idList)):gsub("$t", tostring(math.max(modBlueprintLibrary:CountCategory(category), #idList)));

			for a=1, #idList do
				local bpId = idList[a];
				local bpLib = modBlueprintLibrary.Get(bpId);
				local itemLib = modItem:Find(bpId);

				local newBpListing = listMenu:NewItemButton(bpId);
				local quantityTag = newBpListing:WaitForChild("QuantityLabel");

				quantityTag.Text = bpLib.Amount or "";
				newBpListing.Name = bpLib.Name;
				newBpListing.Image = itemLib.Icon;
				newBpListing.ImageColor3 = modItem.TierColors[itemLib.Tier];
				newBpListing.Parent = newGridList.list;

				newBpListing.MouseButton1Click:Connect(function()
					interface:PlayButtonClick();
					binds.ClearPages("customBuild");
					local activeBpMenu = binds.Workbenches.Build.Workbench.new(bpId, bpLib);
					activeBpMenu.Menu.Name = "customBuild";
					binds.SetPage(activeBpMenu.Menu);
				end)

				listMenu:AddSearchIndex(newBpListing, {bpId; bpLib.Name; itemLib.Name});
			end

			local order = modWorkbenchLibrary.CategorySorting[category] or 999;
			listMenu:Add(newCateTab, order);
			listMenu:Add(newGridList, order+1);
		end
		
		return listMenu;
	end

	return WorkbenchClass;
end

return WorkbenchClass;