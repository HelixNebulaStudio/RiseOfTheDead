local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Workbench = {};
local Interface = {} :: any;

local TweenService = game:GetService("TweenService");
local RunService = game:GetService("RunService");
local localplayer = game.Players.LocalPlayer;

local modData = shared.require(localplayer:WaitForChild("DataModule") :: ModuleScript);
local modItem = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modWorkbenchLibrary = shared.require(game.ReplicatedStorage.Library.WorkbenchLibrary);
local modBlueprintLibrary = shared.require(game.ReplicatedStorage.Library.BlueprintLibraryRotd);
local modTableManager = shared.require(game.ReplicatedStorage.Library.TableManager);

function Workbench.new()
	local listMenu = Interface.List.create();
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
				Interface:PlayButtonClick();
				Interface.ClearPages("customBuild");
				local activeBpMenu = Interface.Workbenches.Build.Workbench.new(bpId, bpLib);
				activeBpMenu.Menu.Name = "customBuild";
				Interface.SetPage(activeBpMenu.Menu);
			end)

			listMenu:AddSearchIndex(newBpListing, {bpId; bpLib.Name; itemLib.Name});
		end

		local order = modWorkbenchLibrary.CategorySorting[category] or 999;
		listMenu:Add(newCateTab, order);
		listMenu:Add(newGridList, order+1);
	end
	
	return listMenu;
end

function Workbench.init(interface)
	Interface = interface;
	return Workbench;
end

return Workbench;