local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local baseInteractable = script:WaitForChild("Interactable");

local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modDropAppearance = require(game.ReplicatedStorage.Library.DropAppearance);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);

local toolPackage = {
	Type="StructureTool";
	Animations={
		Core={Id=4696835207;};
		Placing={Id=4696837086};
	};
};

function toolPackage.NewToolLib(handler)
	local Tool = {};

	Tool.WaistRotation = math.rad(0);
	Tool.PlaceOffset = CFrame.Angles(0, math.rad(-90), 0);

	Tool.BuildDuration = 0.5;
	Tool.UseViewmodel = false;

	function Tool:CustomSpawn(cframe)
		local modCrates = require(game.ServerScriptService.ServerLibrary.Crates);

		local owner = self.Player;

		local rewards = modCrates.GenerateRewards(self.ItemId, owner);
		if #rewards > 0 then
			local prefab, interactable = modCrates.Spawn(self.ItemId, cframe, {owner}, rewards);

			local dropAppearanceLib = modDropAppearance:Find(self.ItemId);
			if dropAppearanceLib then
				modDropAppearance.ApplyAppearance(dropAppearanceLib, prefab);
			end

			modAudio.Play("StorageWoodPickup", prefab.PrimaryPart, nil, false);
			interactable:Sync(nil, {EmptyLabel="Owned by: "..owner.Name});
			Debugger.Expire(prefab, 120);
		end
	end
	
	Tool.__index = Tool;
	setmetatable(Tool, handler);
	return Tool;
end;

function toolPackage.Inherit(itemId, animations)
	toolPackage.__index = toolPackage;
	local ToolInherit = {};
	
	ToolInherit.Animations = animations;
	
	function ToolInherit.NewToolLib(handler)
		local self = toolPackage.NewToolLib(handler);
		
		self.ItemId = itemId;
		self.Prefab = itemId or "crate";
		
		return self;
	end
	
	task.defer(function()
		local itemLib = modItemsLibrary:Find(itemId);
		local modCrateLibrary = require(game.ReplicatedStorage.Library.CrateLibrary);
		
		if modCrateLibrary.Get(itemId) == nil then
			modCrateLibrary.New{
				Id=itemId;
				Name=itemLib.Name;
				PrefabName=itemId;
				RewardsId=itemId;
				Configurations={
					Persistent=false;
					Settings={
						WithdrawalOnly=true;
						DestroyOnEmpty=true;
					}
				};

				EmptyLabel="Empty Chest";
			};
		end
	end)
	
	setmetatable(ToolInherit, toolPackage);
	return ToolInherit;
end

return toolPackage;