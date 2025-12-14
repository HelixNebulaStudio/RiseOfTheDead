local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);

local modToolsLibrary;
--==

local toolPackage = {
	Class = "Tool";
	HandlerType = "StructureTool";

	Animations={
		Core={Id=103715768327613;};
		Placing={Id=93883856367577};
	};
	Audio={};
	Configurations={
		WaistRotation = math.rad(0);
		PlaceOffset = CFrame.Angles(0, math.rad(0), 0);
	
		BuildDuration = 0.5;
		UseViewmodel = false;
	};
	Properties={};
};
toolPackage.__index = toolPackage;

function toolPackage.CustomSpawn(handler: ToolHandlerInstance, cframe)
	local modCrates = shared.require(game.ReplicatedStorage.Library.Crates);
	local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

	local itemId = handler.ToolPackage.ItemId;

	local charClass: CharacterClass = handler.CharacterClass;
	if charClass.ClassName ~= "PlayerClass" then return end;

	local player = (charClass :: PlayerClass):GetInstance();

	local rewards = modCrates.GenerateRewards(itemId, player);
	if #rewards > 0 then
		local prefab, interactable = modCrates.spawn(itemId, cframe, {player}, rewards);
		Debugger.Expire(prefab, 120);

		modAudio.Play("StorageWoodPickup", prefab.PrimaryPart, nil, false);
		interactable:Sync(nil, {EmptyLabel=`Owned by: {player.Name}`});
	end
end


function toolPackage.inherit(packet)
	local inheritPackage = packet;

	local itemId = packet.ItemId;
	local itemModel = modToolsLibrary.getModel(inheritPackage, script);
	
	inheritPackage.Welds = {
		ToolGrip=itemModel.Name;
	};

	setmetatable(inheritPackage, toolPackage);

	task.defer(function()
		local itemLib = modItemsLibrary:Find(itemId);
		local modCrateLibrary = shared.require(game.ReplicatedStorage.Library.CrateLibrary);
		
		if modCrateLibrary.Get(itemId) == nil then
			modCrateLibrary.New{
				Id = itemId;
				Name = itemLib.Name;
				Prefab = inheritPackage.CratePrefab or itemModel;

				RewardsId = itemId;
				StoragePresetId = "lootcrate";

				EmptyLabel = "Empty Chest";
			};
		end
	end)

	modToolsLibrary.set(inheritPackage);

	function inheritPackage.newClass()
		return modEquipmentClass.new(inheritPackage);
	end

	return inheritPackage;
end

function toolPackage.init(super)
	modToolsLibrary = super;

	-- warehouse
	toolPackage.inherit({
		ItemId = "factorycrate";
	});

	toolPackage.inherit({
		ItemId = "officecrate";
	});

	toolPackage.inherit({
		ItemId = "tombschest";
	});

	-- underground
	toolPackage.inherit({
		ItemId = "sectorfcrate";
	});
	
	toolPackage.inherit({
		ItemId = "ucsectorfcrate";
	});

	toolPackage.inherit({
		ItemId = "railwayscrate";
	});
	
	toolPackage.inherit({
		ItemId = "prisoncrate";
	});
	
	toolPackage.inherit({
		ItemId = "nprisoncrate";
	});

	toolPackage.inherit({
		ItemId = "banditcrate";
	});

	toolPackage.inherit({
		ItemId = "hbanditcrate";
	});

	-- residentials
	toolPackage.inherit({
		ItemId = "sectordcrate";
	});

	toolPackage.inherit({
		ItemId = "ucsectordcrate";
	});

	toolPackage.inherit({
		ItemId = "abandonedbunkercrate";
	});

	toolPackage.inherit({
		ItemId = "genesiscrate";
	});

	toolPackage.inherit({
		ItemId = "ggenesiscrate";
	});
	
	-- harbor
	toolPackage.inherit({
		ItemId = "sunkenchest";
	});
	
	
	-- MARK: Resource Crate
	local ResourceCrate = {
		Animations = {
			Core = {Id=89974091773254;};
			Placing = {Id=119557034210474};
		};
	};
	toolPackage.inherit({
		ItemId = "metalpackage";
		GenericItemModelName = "resourcecrate";
		Animations = ResourceCrate.Animations;
	});
	
	toolPackage.inherit({
		ItemId = "clothpackage";
		GenericItemModelName = "resourcecrate";
		Animations = ResourceCrate.Animations;
	});
	
	toolPackage.inherit({
		ItemId = "glasspackage";
		GenericItemModelName = "resourcecrate";
		Animations = ResourceCrate.Animations;
	});
	
	toolPackage.inherit({
		ItemId = "woodpackage";
		GenericItemModelName = "resourcecrate";
		Animations = ResourceCrate.Animations;
	});

	toolPackage.inherit({
		ItemId = "communitycrate";
		GenericItemModelName = "resourcecrate";
		Animations = ResourceCrate.Animations;
	});

	toolPackage.inherit({
		ItemId = "communitycrate2";
		GenericItemModelName = "resourcecrate";
		Animations = ResourceCrate.Animations;
	});


	-- MARK: Event Crates
	-- frostivus
	toolPackage.inherit({
		ItemId = "xmaspresent";
		Animations = ResourceCrate.Animations;
	});

	toolPackage.inherit({
		ItemId = "xmaspresent2020";
		Animations = ResourceCrate.Animations;
	});

	toolPackage.inherit({
		ItemId = "xmaspresent2021";
		Animations = ResourceCrate.Animations;
	});

	toolPackage.inherit({
		ItemId = "xmaspresent2022";
		Animations = ResourceCrate.Animations;
	});

	toolPackage.inherit({
		ItemId = "xmaspresent2023";
		Animations = ResourceCrate.Animations;
	});

	toolPackage.inherit({
		ItemId = "xmaspresent2024";
		Animations = ResourceCrate.Animations;
	});

	-- easter
	toolPackage.inherit({
		ItemId = "easteregg";
		Animations = ResourceCrate.Animations;
	});

	toolPackage.inherit({
		ItemId = "easteregg2021";
		Animations = ResourceCrate.Animations;
	});

	toolPackage.inherit({
		ItemId = "easteregg2023";
		Animations = ResourceCrate.Animations;
	});

	-- slaughterfest
	toolPackage.inherit({
		ItemId = "slaughterfestcandybag";
		Animations = {
			Core = {Id=85979089955779;};
			Placing = {Id=4527422890};
		};
	});
end

return toolPackage;