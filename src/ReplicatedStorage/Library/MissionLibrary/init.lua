local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modCutscene = require(game.ReplicatedStorage.Library:WaitForChild("Cutscene")); -- required to wait for cutscene to be loaded first.
local modDialogueLibrary = require(game.ReplicatedStorage.Library:WaitForChild("DialogueLibrary"));
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modMarkers = require(game.ReplicatedStorage.Library.Markers);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modAssetHandler = require(game.ReplicatedStorage.Library.AssetHandler);

local MissionLibrary = {};
MissionLibrary.Script = script;

local library = {};

local BoardTimeLimit = 3600;
local BoardRestockTimer = 3600;
-- if modBranchConfigs.CurrentBranch.Name == "Dev" then
-- 	BoardRestockTimer = 10;
-- end;
MissionLibrary.BoardMissionStockTimer = BoardRestockTimer;

MissionLibrary.MissionTypes = {
	Core=1;
	Side=2;
	Secret=3;
	Board=4;
	Premium=5;
	Event=6;
	Faction=7;
	Unreleased=8;
}

local typesIndexToKey = {};
for k, i in pairs(MissionLibrary.MissionTypes) do typesIndexToKey[i] = k end;
function MissionLibrary.GetTypeKey(i)
	return typesIndexToKey[i];
end

--[[
	MissionLibrary.Get(id: number)
	Gets the mission library of mission id.
	@param id number
]]
function MissionLibrary.Get(id: number)
	return library[id];
end

local missionCount = 0;
function MissionLibrary.List()
	return library, missionCount;
end

function MissionLibrary.CountMissions(types)
	local c = 0;
	for id, lib in pairs(library) do
		if types then
			if types[lib.MissionType] then
				c = c +1;
			end
		elseif lib.MissionType == MissionLibrary.MissionTypes.Core
			or lib.MissionType == MissionLibrary.MissionTypes.Side then
			c = c +1;
		end
	end
	return c;
end

function MissionLibrary.New(data)
	if library[data.MissionId] ~= nil then error("MissionLibrary>>  Mission ID ("..data.MissionId..") already exist for ("..data.Name..").") end;
	library[data.MissionId] = data;
	missionCount = missionCount +1;
	
	if data.UseAssets and RunService:IsServer() then
		local assetKey = `Missions/Mission{data.MissionId}`;
		local gameAssets = modAssetHandler:GetServer(assetKey);
		
		local missionDialogues = gameAssets and gameAssets:FindFirstChild("MissionDialogues") or nil;
		if missionDialogues then
			local loadedDialogues = false;
			data.LoadDialogues = function()
				if loadedDialogues then return end;
				loadedDialogues = true;
				
				Debugger:StudioWarn("Load dialogue", data.MissionId);
				missionDialogues = require(gameAssets.MissionDialogues);
				
				for npcName, pack in pairs(missionDialogues) do
					if pack.Dialogues == nil then continue end;
					
					modDialogueLibrary.AddDialogues(npcName, pack.Dialogues(), {
						MissionId = data.MissionId;
					});
				end
			end
			data.DialogueScript = missionDialogues;
		end;

		data.AssetKey = assetKey;

		local cutsceneScript = gameAssets and gameAssets:FindFirstChild("CutsceneScript") or nil;
		if cutsceneScript then
			data.Cutscene = data.Name;
			data.CutsceneScript = cutsceneScript;

		end

		local missionLogic = gameAssets and gameAssets:FindFirstChild("MissionLogic") or nil;
		if missionLogic then
			data.LogicScript = missionLogic;
			
		end

	end
	
	return function(func)
		if func == nil then return end;
		func(data);
	end;
end

local function getDayNumber() : number
	return tonumber(os.date("%j")) :: number;
end

local function getHourNumber() : number
	return tonumber(os.date("%H")) :: number;
end

local PerksReward = {
	Core=5;
	Side=20;
	
	Easy=5;
	Normal=10;
	Hard=25;
};
MissionLibrary.PerksReward = PerksReward;

local MoneyReward = {
	Core=100;
	Side=1000;
};
MissionLibrary.MoneyReward = MoneyReward;

local factionMissionExpireTime = 3600*20;
--===

-- MARK: 1 - Unconscious
MissionLibrary.New{
	MissionId=1;
	MissionType = MissionLibrary.MissionTypes.Core;
	Name="Unconscious";
	From="Mason";
	Description="Mason found you unconscious in the middle of the Wrighton Dale bridge.";
	Persistent=true;
	World="TheBeginning";
	Checkpoint={
		{Text="Wake up"; Notify=true;};
		{Text="Follow Mason"; Notify=true;};
		{Text="Take the pistol by pressing [E] while pointing at it with your mouse"; Notify=true;};
		{Text="Equip the P250 by clicking the pistol OR pressing [1]"; Notify=true;};
		{Text="Defend off the zombies"; Notify=true;};
	};
	GuideText="";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Core};
		{Type="Money"; Amount=MoneyReward.Core};
	};
	Markers={
		[2]={World="TheBeginning"; Label="Mason"; Target="Mason"; Type=modMarkers.MarkerTypes.Npc;};
		[4]={Label="Careful, Zombies"; Target=Vector3.new(4.307, 53.68, -150.452); Type=modMarkers.MarkerTypes.Waypoint;};
	};
	CanRedo={
		Travel="TheBeginning";
	};
	LinkNextMission=2;
	UseAssets=true;
};

-- MARK: 2 - Where am I
MissionLibrary.New{
	MissionId=2;
	MissionType = MissionLibrary.MissionTypes.Core;
	Name="Where am I";
	From="Mason";
	Description="You woke up in a warehouse after the explosion on the Wrighton Dale bridge.";
	Persistent=true;
	World="TheWarehouse";
	Checkpoint={
		{Text="Talk to Mason";};
		{Text="Exit the bedroom";};
		{Text="Talk to Dr. Deniski to ask him to heal you";};
		{Text="Talk to Mason";};
		{Text="Talk to Nick";};
		
		{Text="Purchase ammo from the store for your P250";};
		{Text="Return to Nick";};
		{Text="Leave the warehouse";};
		{Text="Kill $Kills zombies";};
		{Text="Return to Nick";};
	};
	SaveData={Kills=10;};
	GuideText="";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Core};
		{Type="Money"; Amount=MoneyReward.Core};
		{Type="Mission"; Id=5};
	};
	Markers={
		[1]={World="TheWarehouse"; Label="Mason"; Target="Mason"; Type=modMarkers.MarkerTypes.Npc;};
		[2]={World="TheWarehouse"; Label="Exit"; Target=Vector3.new(-5.8, 60.2, -23); Type=modMarkers.MarkerTypes.Waypoint;};
		[3]={World="TheWarehouse"; Label="Dr. Deniski"; Target="Dr. Deniski"; Type=modMarkers.MarkerTypes.Npc;};
		[4]={World="TheWarehouse"; Label="Mason"; Target="Mason"; Type=modMarkers.MarkerTypes.Npc;};
		[5]={World="TheWarehouse"; Label="Nick"; Target="Nick"; Type=modMarkers.MarkerTypes.Npc;};
		[6]={World="TheWarehouse"; Label="Shop"; Target=Vector3.new(-9.7, 61.0, 18.5); Type=modMarkers.MarkerTypes.Waypoint;};
		[7]={World="TheWarehouse"; Label="Nick"; Target="Nick"; Type=modMarkers.MarkerTypes.Npc;};
		[8]={World="TheWarehouse"; Label="Exit"; Target=Vector3.new(61.5, 60.2, -28.7); Type=modMarkers.MarkerTypes.Waypoint;};
		[10]={World="TheWarehouse"; Label="Nick"; Target="Nick"; Type=modMarkers.MarkerTypes.Npc;};
	};
	CanRedo={};
	UseAssets=true;
};

-- MARK: 3 - Stephanie's Book
MissionLibrary.New{
	MissionId=3;
	MissionType = MissionLibrary.MissionTypes.Side;
	Name="Stephanie's Book";
	From="Stephanie";
	Description="Stephanie is searching for a book, help her look for it.";
	Persistent=true;
	World="TheWarehouse";
	Objectives={
		["BookSearch"]={Index=1; Description="Search for the book in the warehouse"; Type="RequireItem"; ItemId="oddbluebook"};
	};
	ObjectivesCompleteText="Return the book to Stephanie";
	GuideText="Talk to Stephanie to start";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Side};
		{Type="Mission"; Id=9};
	};
	StartRequirements={
		Level=3;
	};
	UseAssets=true;
};

-- MARK: 4 - Lend A Hand
MissionLibrary.New{
	MissionId=4;
	MissionType = MissionLibrary.MissionTypes.Side;
	Name="Lend A Hand";
	From="Dr. Deniski";
	Description="Dr. Deniski wants you to find a zombie arm for his experiments.";
	Persistent=true;
	World="TheWarehouse";
	Objectives={
		["ArmSearch"]={Index=1; Description="Kill some zombies to look for a zombie arm"; Type="RequireItem"; ItemId="zombiearm"};
	};
	ObjectivesCompleteText="Return the zombie arm to Dr. Deniski";
	GuideText="Talk to Dr. Deniski to start";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Side};
		{Type="Mission"; Id=8};
	};
	StartRequirements={
		Level=2;
	};
	UseAssets=true;
};

-- MARK: 5 - Time To Upgrade
MissionLibrary.New{
	MissionId=5;
	MissionType = MissionLibrary.MissionTypes.Core;
	Name="Time To Upgrade";
	From="Mason";
	Description="Mason teaches you how to upgrade your weapons.";
	Persistent=true;
	World="TheWarehouse";
	Checkpoint={
		{Text="Use the workbench in the Warehouse";};
		{Text="Check the requirements for to build a Pistol Damage Mod";};
		{Text="Collect items to build Pistol Damage Mod";};
		{Text="Build the Pistol Damage Mod";};
		{Text="Wait for the mod to build";};

		{Text="Collect the Pistol Damage Mod from the workbench"; Notify=true;};
		{Text="Add the mod to your weapon using the workbench";};
		{Text="Upgrade the mod's damage by selecting the mod on the workbench";};
	};
	GuideText="Talk to Mason to learn how to upgrade your weapons";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Core};
		{Type="Money"; Amount=MoneyReward.Core};
		{Type="Item"; ItemId="pistolfireratebp"; Quantity=1;};
		{Type="Mission"; Id=3};
		{Type="Mission"; Id=4};
		{Type="Mission"; Id=6};
	};
	StartRequirements={
		Level=2;
	};
	Markers={
		[1]={World="TheWarehouse"; Label="Workbench"; Target=Vector3.new(29.8, 60.5, -40.5); Type=modMarkers.MarkerTypes.Waypoint;};
	};
	CanRedo={};
	UseAssets=true;
};

-- MARK: 6 - First Rescue
MissionLibrary.New{
	MissionId=6;
	MissionType = MissionLibrary.MissionTypes.Core;
	Name="First Rescue";
	From="Robert";
	Description="You found Robert trapped inside Bloxmart and you want to get him out.";
	Persistent=true;
	World="TheWarehouse";
	Checkpoint={
		{Text="Destroy the wooden barricade";};
		{Text="Bring Robert back to the safehouse";};
	};
	SaveData={HP=5;};
	GuideText="Someone is screaming for help in Bloxmart, go check it out";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Core};
		{Type="Money"; Amount=MoneyReward.Core};
		{Type="Mission"; Id=7};
	};
	StartRequirements={
		Level=3;
	};
	Markers={
		[1]={World="TheWarehouse"; Label="Destroy"; Target=Vector3.new(269.352, 62.881, 34.188); Type=modMarkers.MarkerTypes.Waypoint;};
		[2]={World="TheWarehouse"; Label="Warehouse Safehouse"; Target=Vector3.new(62.4, 63.2, -28.7); Type=modMarkers.MarkerTypes.Waypoint;};
	};
	CanRedo={};
	UseAssets=true;
};

-- MARK: 7 - The Prisoner
MissionLibrary.New{
	MissionId=7;
	MissionType = MissionLibrary.MissionTypes.Core;
	Name="The Prisoner";
	From="Robert";
	Description="Robert wants to get back to his safehouse, but there's something dangerous in the way.";
	Persistent=true;
	World="TheWarehouse";
	Checkpoint={
		{Text="Follow Robert to the armored door inside Bloxmart";};
		{Text="Enter the boss door and ready up to fight";};
		{Text="Defeat The Prisoner boss";};
		{Text="Exit the boss arena";};
		{Text="Press the green button to open the Bloxmart gate";};

		{Text="Exit the security room";};
		{Text="Run!"; Notify=true;};
	};
	GuideText="Help Robert get back to his safehouse";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Core};
		{Type="Money"; Amount=MoneyReward.Core};
		{Type="Mission"; Id=11};
		{Type="Mission"; Id=46;};
		{Type="Mission"; Id=40;};
		{Type="Mission"; Id=43;};
	};
	StartRequirements={
		Level=3;
	};
	Markers={
		[1]={World="TheWarehouse"; Label="Robert"; Target="Robert"; Type=modMarkers.MarkerTypes.Npc;};
		[2]={World="TheWarehouse"; Label="Boss"; Target=Vector3.new(308.37, 60.2, 62.06); Type=modMarkers.MarkerTypes.Waypoint;};
		[5]={World="TheWarehouse"; Label="Green Button"; Target=Vector3.new(303.242, 76.489, 10.267); Type=modMarkers.MarkerTypes.Waypoint;};
		[6]={World="TheWarehouse"; Label="Exit"; Target=Vector3.new(297.45, 74.85, -22.5); Type=modMarkers.MarkerTypes.Waypoint;};
		[7]={World="TheWarehouse"; Label="Robert"; Target="Robert"; Type=modMarkers.MarkerTypes.Npc;};
	};
	CanRedo={};
	UseAssets=true;
};

-- MARK: 8 - Bandage Up
MissionLibrary.New{
	MissionId=8;
	MissionType = MissionLibrary.MissionTypes.Side;
	Name="Bandage Up";
	From="Dr. Deniski";
	Description="Dr. Deniski has something for you to heal yourself while you're outside. He teaches you how to make medkits.";
	Persistent=true;
	World="TheWarehouse";
	Checkpoint={
		{Text="Build the Medkit from the Workbench";};
	};
	GuideText="Talk to Dr. Deniski to start";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Side};
	};
	AddRequirements={
		{Type="MissionCompleted"; Value={4; 7}};
	};
	StartRequirements={
		Level=7;
	};
	UseAssets=true;
};

-- MARK: 9 - Special Mods
MissionLibrary.New{
	MissionId=9;
	MissionType = MissionLibrary.MissionTypes.Side;
	Name="Special Mods";
	From="Stephanie";
	Description="Stephanie read the book you found and she finds something that you could use.";
	Persistent=true;
	World="TheWarehouse";
	Checkpoint={
		{Text="Build the Incendiary Rounds mod using the workbench";};
	};
	GuideText="Talk to Stephanie to start";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Side};
		{Type="Mission"; Id=15};
	};
	AddRequirements={
		{Type="MissionCompleted"; Value={3; 7}};
	};
	StartRequirements={
		Level=7;
	};
	UseAssets=true;
};

-- MARK: 10 - Infected
MissionLibrary.New{
	MissionId=10;
	MissionType = MissionLibrary.MissionTypes.Secret;
	Name="Infected";
	From="Jefferson";
	Description="You found Jefferson wounded outside the warehouse. You insisted on helping him.";
	Persistent=true;
	World="TheWarehouse";
	Objectives={
		["BioticsSearch"]={Index=1; Description="Search for antibiotics in Sunday's"; Type="RequireItem"; ItemId="antibiotics"};
	};
	ObjectivesCompleteText="Return the antibiotics to Jefferson";
	StartRequirements={
		MissionCompleted={7};
	};
	GuideText="Talk to Jefferson to start";
	RewardText="Unlocked Army Colors Pack";
	Rewards={};
	UseAssets=true;
};

-- MARK: 11 - Radio Signal
MissionLibrary.New{
	MissionId=11;
	MissionType = MissionLibrary.MissionTypes.Core;
	Name="Radio Signal";
	From="Jane";
	Description="Jane is searching for emergency signals on the radio and she needs help.";
	Persistent=true;
	World="TheWarehouse";
	Checkpoint={
		{Text="Repair the satellite on the roof";};
		{Text="Return back to Jane";};
	};
	GuideText="Talk to Jane to start";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Core};
		{Type="Money"; Amount=MoneyReward.Core};
		{Type="Mission"; Id=49};
	};
	StartRequirements={
		Level=5;
	};
	Markers={
		[1]={World="TheWarehouse"; Label="Satellite To Repair"; Target=Vector3.new(635.642, 95, -50.283); Type=modMarkers.MarkerTypes.Waypoint;};
		[2]={World="TheWarehouse"; Label="Jane"; Target="Jane"; Type=modMarkers.MarkerTypes.Npc;};
	};
	CanRedo={};
	UseAssets=true;
};

-- MARK: 12 - Factory Raid
MissionLibrary.New{
	MissionId=12;
	MissionType = MissionLibrary.MissionTypes.Core;
	Name="Factory Raid";
	From="Mason";
	Description="The warehouse is starting to run low on supplies, Mason needs your help on restocking them.";
	Persistent=true;
	World={"TheWarehouse", "Factory"};
	Checkpoint={
		{Text="Talk to Mason";};
		{Text="Follow Mason";};
		{Text="Destroy the barricade to enter the factory door";};
		{Text="Complete the factory raid";};
		{Text="Talk to Mason";};

		{Text="Return to the warehouse";};
	};
	GuideText="Talk to Mason to start";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Core};
		{Type="Money"; Amount=MoneyReward.Core};
		{Type="Mission"; Id=27};
		{Type="Mission"; Id=13};
		{Type="Mission"; Id=14};
		{Type="Mission"; Id=16};
		{Type="Mission"; Id=18};
	};
	StartRequirements={
		Level=7;
		MissionCompleted={49};
	};
	Markers={
		[1]={World="TheWarehouse"; Label="Mason"; Target="Mason"; Type=modMarkers.MarkerTypes.Npc;};
		[2]={World="TheWarehouse"; Label="Mason"; Target="Mason"; Type=modMarkers.MarkerTypes.Npc;};
		[3]={World="TheWarehouse"; Label="Raid"; Target=Vector3.new(12.6, 60.15, 177.3); Type=modMarkers.MarkerTypes.Waypoint;};
		[5]={World="Factory"; Label="Mason"; Target="Mason"; Type=modMarkers.MarkerTypes.Npc;};
		[6]={World="TheWarehouse"; Label="Warehouse"; Target=Vector3.new(62.4, 60.2, -28.7); Type=modMarkers.MarkerTypes.Waypoint;};
	};
	CanRedo={};
	UseAssets=true;
};

-- MARK: 13 - Crowd Control
MissionLibrary.New{
	MissionId=13;
	MissionType = MissionLibrary.MissionTypes.Side;
	Name="Crowd Control";
	From="Wilson";
	Description="The amount of zombies are increasing and Wilson needs you to get rid of them.";
	Persistent=true;
	World="TheWarehouse";
	Progression={
		"Kill $Kills zombies";
		"Return to Wilson";
	};
	SaveData={Kills=100;};
	LogEntry={};
	GuideText="Talk to Wilson to start";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Side};
	};
	StartRequirements={
		Level=20;
	};
	UseAssets=true;
};

-- MARK: 14 - Pigeon Post
MissionLibrary.New{
	MissionId=14;
	MissionType = MissionLibrary.MissionTypes.Side;
	Name="Pigeon Post";
	From="Nick";
	Description="Nick learnt that Jane is in another safehouse, and he needs your help with delivering a message.";
	Persistent=true;
	World="TheWarehouse";
	Progression={
		"Head to Sundays Safehouse";
		"Talk to Jane";
		"Return to Nick";
	};
	GuideText="Talk to Nick to start";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Side};
	};
	StartRequirements={
		Level=9;
	};
	UseAssets=true;
};

-- MARK: 15 - Chain Reaction
MissionLibrary.New{
	MissionId=15;
	MissionType = MissionLibrary.MissionTypes.Side;
	Name="Chain Reaction";
	From="Stephanie";
	Description="Stephanie worked out another blueprint for another elemental mod and she wants you to build it.";
	Persistent=true;
	World="TheWarehouse";
	Progression={
		"Build the Electric Charge mod using the workbench";
	};
	LogEntry={};
	GuideText="Talk to Stephanie to start";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Side};
	};
	AddRequirements={
		{Type="MissionCompleted"; Value={3, 7, 9, 12};};
	};
	StartRequirements={
		Level=25;
	};
	UseAssets=true;
};

-- MARK: 16 - A Good Deal
MissionLibrary.New{
	MissionId=16;
	MissionType = MissionLibrary.MissionTypes.Side;
	Name="A Good Deal";
	From="Jesse";
	Description="Jesse needs to restock some components in the shop, he thinks you're capable enough to help him.";
	Persistent=true;
	World="TheWarehouse";
	Objectives={
		["IgniterSearch"]={Index=1; Description="Find $Amount Igniters for Jesse"; Type="RequireItem"; ItemId="igniter"; Amount=2;};
	};
	ObjectivesCompleteText="Return to Jesse with the igniters";
	LogEntry={};
	GuideText="Talk to Jesse to start";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Side};
	};
	StartRequirements={
		Level=20;
	};
	UseAssets=true;
};

-- MARK: 17 - Restock
MissionLibrary.New{
	MissionId=17;
	MissionType = MissionLibrary.MissionTypes.Board;
	Name="Restock";
	Description="Jesse needs to restock some components in the shop.";
	Timer=BoardTimeLimit; 
	Persistent=true;
	World="TheWarehouse";
	Objectives={
		["Search"]={Index=1; Description="Find $Amount $ItemName for Jesse"; Type="RequireItem"; ItemIdOptions={"metalpipes"; "igniter"; "gastank"}; AmountRange={Min=1; Max=3};};
	};
	ObjectivesCompleteText="Return to Jesse with the $ItemName";
	GuideText="Talk to Jesse to start";
	Tier="Normal";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Normal};
		{Type="Item"; ItemId="deagleparts"; Quantity=1;};
	};
	AddRequirements={
		{Type="MissionCompleted"; Value={16}};
	};
	UseAssets=true;
};

-- MARK: 18 - A New Community
MissionLibrary.New{
	MissionId=18;
	MissionType = MissionLibrary.MissionTypes.Core;
	Name="A New Community";
	From="Jane";
	Description="Jane receives radio signals coming from the sewers. She wants you to find the source of the message.";
	Persistent=true;
	World={"TheWarehouse"; "TheUnderground"};
	Checkpoint={
		{Text="Ask Robert to join you";};
		{Text="Enter the sewers";};
		{Text="Look for the survivors in the sewers";};
		{Text="Follow Robert";};
		{Text="Enter the Underbridge safehouse";};

		{Text="Talk to the survivors";};
		{Text="Give Carlson 2 medkits";};
		{Text="Talk to Robert";};
		{Text="Talk to Carlson";};
	};
	LogEntry={};
	GuideText="Talk to Jane to start";
	LinkNextMission=24;
	Rewards={
		{Type="Perks"; Amount=PerksReward.Core};
		{Type="Money"; Amount=MoneyReward.Core};
		{Type="Mission"; Id=19};
		{Type="Mission"; Id=22};
		{Type="Mission"; Id=23};
		{Type="Mission"; Id=24};
	};
	StartRequirements={
		Level=10;
		MissionCompleted={8, 4};
	};
	Markers={
		[1]={World="TheWarehouse"; Label="Robert"; Target="Robert"; Type=modMarkers.MarkerTypes.Npc;};
		[2]={World="TheWarehouse"; Label="TheUnderground"; Target="TheUnderground"; Type=modMarkers.MarkerTypes.Travel;};
		[3]={World="TheUnderground"; Label="Search"; Target=Vector3.new(-69.526, 11.136, 158.6); Type=modMarkers.MarkerTypes.Waypoint;};
		[4]={World="TheUnderground"; Label="Robert"; Target="Robert"; Type=modMarkers.MarkerTypes.Npc;};
		[5]={World="TheUnderground"; Label="Enter"; Target=Vector3.new(-53.4, 10.715, 279.5); Type=modMarkers.MarkerTypes.Waypoint;};
		
		[7]={World="TheUnderground"; Label="Carlson"; Target="Carlson"; Type=modMarkers.MarkerTypes.Npc;};
		[8]={World="TheUnderground"; Label="Robert"; Target="Robert"; Type=modMarkers.MarkerTypes.Npc;};
		[9]={World="TheUnderground"; Label="Carlson"; Target="Carlson"; Type=modMarkers.MarkerTypes.Npc;};
	};
	CanRedo={};
	UseAssets=true;
};

-- MARK: 19 - Ticking Mess
MissionLibrary.New{
	MissionId=19;
	MissionType = MissionLibrary.MissionTypes.Side;
	Name="Ticking Mess";
	From="Wilson";
	Description="Wilson hates the ticks, they remind him of war. Wilson needs you to get rid of them.";
	Persistent=true;
	World="TheWarehouse";
	Progression={
		"Kill $Kills ticks zombies";
		"Return to Wilson";
	};
	SaveData={Kills=50;};
	GuideText="Talk to Wilson to start";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Side};
	};
	StartRequirements={
		Level=30;
	};
	AddRequirements={
		{Type="MissionCompleted"; Value={13}};
	};
	UseAssets=true;
};

-- MARK: 20 - Eight Legs
MissionLibrary.New{
	MissionId=20;
	MissionType = MissionLibrary.MissionTypes.Side;
	Name="Eight Legs";
	From="Erik";
	Description="Erik can't sleep because of the sounds of the Zpider in the cave across..";
	Persistent=true;
	World="TheUnderground";
	Progression={
		"Kill a Zpider";
		"Return to Erik";
	};
	SaveData={Kills=1;};
	GuideText="Talk to Erik to start";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Side};
	};
	StartRequirements={
		Level=30;
	};
	UseAssets=true;
};

-- MARK: 21 - Spring Killing
MissionLibrary.New{
	MissionId=21;
	MissionType = MissionLibrary.MissionTypes.Board;
	Name="Spring Killing";
	Description="Jane wants you to clear out all the bosses in W.D. Warehouse.";
	Timer=BoardTimeLimit;
	Persistent=true;
	World="TheWarehouse";
	Objectives={
		["The Prisoner"]={Index=1; Description="Kill The Prisoner"; Type="Kill";};
		["Tanker"]={Index=2; Description="Kill Tanker"; Type="Kill";};
		["Fumes"]={Index=3; Description="Kill Fumes"; Type="Kill";};
	};
	ObjectivesCompleteText="Return to Jane";
	GuideText="Talk to Jane to start";
	Tier="Easy";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Easy};
	};
	AddRequirements={
		{Type="Level"; Value=30};
	};
	UseAssets=true;
};

-- MARK: 22 - The Backup Plan
MissionLibrary.New{
	MissionId=22;
	MissionType = MissionLibrary.MissionTypes.Side;
	Name="The Backup Plan";
	From="Carlson";
	Description="Carlson hid something somewhere as backup for emergency situations, he needs someone to help him get that item.";
	Persistent=true;
	World="TheUnderground";
	Progression={
		"Search for a key in the break room";
		"Enter the maintenance room";
		"Search the wooden crate";
		"Return to Carlson with the items";
	};
	GuideText="Talk to Carlson to start";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Side};
		{Type="Mission"; Id=20};
		{Type="Mission"; Id=28};
	};
	StartRequirements={
		Level=35;
	};
	Markers={
		[1]={World="TheUnderground"; Label="Search"; Target=Vector3.new(-220.035, 16.43, 128.225); Type=modMarkers.MarkerTypes.Waypoint;};
		[2]={World="TheUnderground"; Label="Maintenance Room"; Target=Vector3.new(-128.612, 18.274, -73.399); Type=modMarkers.MarkerTypes.Waypoint;};
		[3]={World="TheUnderground"; Label="Wooden Crate"; Target=Vector3.new(-155.686, 19.493, -92.027); Type=modMarkers.MarkerTypes.Waypoint;};
		[4]={World="TheUnderground"; Label="Carlson"; Target="Carlson"; Type=modMarkers.MarkerTypes.Npc;};
	};
	UseAssets=true;
};

-- MARK: 23 - Sniper's Nest
MissionLibrary.New{
	MissionId=23;
	MissionType = MissionLibrary.MissionTypes.Premium;
	Name="Sniper's Nest";
	From="Lennon";
	Description="Snipe some zombies for Lennon.";
	Persistent=true;
	World="TheUnderground";
	Progression={
		"Snipe $Kills zombies in the end of the tunnel";
		"Return back to Lennon";
	};
	SaveData={Kills=25;};
	GuideText="Talk to Lennon to start";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Side};
		{Type="Item"; ItemId="sniperfocusrate";  Quantity=1;};
	};
	StartRequirements={
		Premium=true;
		Level=25;
	};
	Markers={
		[1]={World="TheUnderground"; Label="Targets"; Target=Vector3.new(-278.695, 22.56, -1.19); Type=modMarkers.MarkerTypes.Waypoint;};
		[2]={World="TheUnderground"; Label="Lennon"; Target="Lennon"; Type=modMarkers.MarkerTypes.Npc;};
	};
	UseAssets=true;
};

-- MARK: 24 - Missing In Action
MissionLibrary.New{
	MissionId=24;
	MissionType = MissionLibrary.MissionTypes.Core;
	Name="Missing In Action";
	From="Jane";
	Description="Robert went missing after leaving the Underbridge safehouse, you need to help search for him.";
	Persistent=true;
	World="TheUnderground";
	Checkpoint={
		{Text="Talk to Lennon to ask about Robert";};
		{Text="Search for clues in the sewers";};
		{Text="Talk to Carlson about Robert";};
		{Text="Enter the cave";};
		{Text="Kill the Bandit Zombie";};

		{Text="Return to Jane";};
	};
	GuideText="Talk to Jane to start";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Core};
		{Type="Money"; Amount=MoneyReward.Core};
		{Type="Mission"; Id=29};
		{Type="Mission"; Id=30};
	};
	LinkNextMission=30;
	StartRequirements={
		Level=15;
	};
	Markers={
		[1]={World="TheUnderground"; Label="Lennon"; Target="Lennon"; Type=modMarkers.MarkerTypes.Npc;};
		[2]={World="TheUnderground"; Label="Search The Area"; Target=Vector3.new(-80.663, 14.29, -54.408); Type=modMarkers.MarkerTypes.Waypoint;};
		[3]={World="TheUnderground"; Label="Carlson"; Target="Carlson"; Type=modMarkers.MarkerTypes.Npc;};
		[4]={World="TheUnderground"; Label="Cave"; Target=Vector3.new(138.553329, 12.2096834, 87.6066055); Type=modMarkers.MarkerTypes.Waypoint;};
		[6]={World="TheWarehouse"; Label="Jane"; Target="Jane"; Type=modMarkers.MarkerTypes.Npc;};
	};
	CanRedo={};
	UseAssets=true;
};

-- MARK: 25 - Christmas Rampage
MissionLibrary.New{
	MissionId=25;
	MissionType = MissionLibrary.MissionTypes.Event;
	Name="Christmas Rampage";
	From="Mr. Klaws";
	Description="Kill a bunch of enemies wearing a Santa hat.";
	Persistent=true;
	Progression={
		"Kill $Kills enemies wearing a Santa hat";
		"Return to Mr. Klaws";
	};
	SaveData={Kills=30;};
	GuideText="Talk to Mr. Klaws";
	RewardText="Rewarded +20 Perks and Christmas Skins Pack";
	AddRequirements={
		{Type="SpecialEvent"; Value="Christmas"};
	};
	LinkNextMission=57;
	Rewards={
		{Type="Perks"; Amount=PerksReward.Side};
		{Type="Mission"; Id=57};
	};
	UseAssets=true;
};

-- MARK: 26 - Blueprint Demands
MissionLibrary.New{
	MissionId=26;
	MissionType = MissionLibrary.MissionTypes.Board;
	Name="Blueprint Demands";
	Description="Diana is almost out of blueprints in the shop and needs you to get some more.";
	Timer=BoardTimeLimit;
	Persistent=true;
	World="TheUnderground";
	Objectives={
		["Search"]={Index=1; Description="Find a $ItemName for Diana"; Type="RequireItem"; ItemIdOptions={"m4a4bp", "awpbp", "minigunbp"}; Amount=1;};
	};
	ObjectivesCompleteText="Return to Diana with the $ItemName";
	GuideText="Talk to Diana to start";
	Tier="Normal";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Normal};
		{Type="Item"; ItemId="deagleparts"; Quantity=1;};
	};
	AddRequirements={
		{Type="Level"; Value=40};
	};
	UseAssets=true;
};

-- MARK: 27 - Focus Levels
MissionLibrary.New{
	MissionId=27;
	MissionType = MissionLibrary.MissionTypes.Side;
	Name="Focus Levels";
	From="Mason";
	Description="Mason teaches you which zombies you should focus on killing.";
	Persistent=true;
	World="TheWarehouse";
	Checkpoint={
		{Text="Open your social menu by pressing [G]";};
		{Text="Kill zombies according to your focus levels to earn a perk";};
	};
	GuideText="Talk to Mason";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Side};
	};
	CanRedo={};
	UseAssets=true;
};

-- MARK: 28 - Safety Safehouse
MissionLibrary.New{
	MissionId=28;
	MissionType = MissionLibrary.MissionTypes.Side;
	Name="Safety Safehouse";
	From="Carlson";
	Description="Carlson needs your help in reinforcing the safehouse.";
	Persistent=true;
	World="TheUnderground";
	Objectives={
		["addDoorway"]={Index=1; Description="Build a door way";};
		["addWall1"]={Index=1; Description="Build a metal wall";};
		["addWall2"]={Index=2; Description="Build a metal wall";};
		["addWall3"]={Index=3; Description="Build a metal wall";};
		["addWall4"]={Index=4; Description="Build a metal wall";};
	};
	ObjectivesCompleteText="Return to Carlson";
	GuideText="Talk to Carlson to start";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Side};
	};
	StartRequirements={
		Level=40;
	};
	Markers={
		["addDoorway"]={World="TheUnderground"; Label="Build Doorway"; Target=Vector3.new(-54.939, 27.972, 304.291); Type=modMarkers.MarkerTypes.Waypoint;};
		["addWall1"]={World="TheUnderground"; Label="Build A Wall"; Target=Vector3.new(-55.146, 27.972, 313.509); Type=modMarkers.MarkerTypes.Waypoint;};
		["addWall2"]={World="TheUnderground"; Label="Build A Wall"; Target=Vector3.new(-55.146, 27.972, 279.524); Type=modMarkers.MarkerTypes.Waypoint;};
		["addWall3"]={World="TheUnderground"; Label="Build A Wall"; Target=Vector3.new(-55.146, 27.972, 272.869); Type=modMarkers.MarkerTypes.Waypoint;};
		["addWall4"]={World="TheUnderground"; Label="Build A Wall"; Target=Vector3.new(-55.646, 27.972, 265.289); Type=modMarkers.MarkerTypes.Waypoint;};
	};
	UseAssets=true;
};

-- MARK: 29 - Lab Assistant
MissionLibrary.New{
	MissionId=29;
	MissionType = MissionLibrary.MissionTypes.Premium;
	Name="Lab Assistant";
	From="Hilbert";
	Description="You found a dead scientist with a blue note.";
	Persistent=true;
	World="TheUnderground";
	Checkpoint={
		{Text="Ask Lennon to see if he knew Hilbert";};
		{Text="Ask Dr. Deniski about the note";};
	};
	GuideText="Search the dead body to start";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Side};
	};
	StartRequirements={
		Premium=true;
		Level=30;
	};
	Markers={
		[1]={World="TheUnderground"; Label="Lennon"; Target="Lennon"; Type=modMarkers.MarkerTypes.Npc;};
		[2]={World="TheWarehouse"; Label="Dr. Deniski"; Target="Dr. Deniski"; Type=modMarkers.MarkerTypes.Npc;};
	};
	UseAssets=true;
};

-- MARK: 30 - Poke The Bear
MissionLibrary.New{
	MissionId=30;
	MissionType = MissionLibrary.MissionTypes.Core;
	Name="Poke The Bear";
	From="Stan";
	Description="You encounter another scavenger, he seems to live nearby, he might know something about what happened to Robert.";
	Persistent=true;
	World={"TheUnderground", "TheMall"};
	Checkpoint={
		{Text="Follow Stan";};
		{Text="Talk to Stan";};
		{Text="Travel to Wrighton Dale Mall";};
		{Text="Talk to Stan";};
		{Text="Follow Stan to the Bandit Camp";};

		{Text="Let Stan talk to Patrick";};
		{Text="Reason with Patrick";};
		{Text="Bribe Patrick with some Canned Beans";};
		{Text="Talk to Stan";};
		
	};
	GuideText="Talk to Stan";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Core};
		{Type="Money"; Amount=MoneyReward.Core};
		{Type="Mission"; Id=33};
	};
	LinkNextMission=33;
	StartRequirements={
		Level=20;
	};
	Markers={
		[1]={World="TheUnderground"; Label="Stan"; Target="Stan"; Type=modMarkers.MarkerTypes.Npc;};
		[2]={World="TheUnderground"; Label="Stan"; Target="Stan"; Type=modMarkers.MarkerTypes.Npc;};
		[3]={World="TheUnderground"; Label="TheMall"; Target="TheMall"; Type=modMarkers.MarkerTypes.Travel;};
		[4]={World="TheMall"; Label="Stan"; Target="Stan"; Type=modMarkers.MarkerTypes.Npc;};
		[5]={World="TheMall"; Label="Stan"; Target="Stan"; Type=modMarkers.MarkerTypes.Npc;};
		
		[7]={World="TheMall"; Label="Patrick"; Target="Patrick"; Type=modMarkers.MarkerTypes.Npc;};
		[8]={World="TheMall"; Label="Patrick"; Target="Patrick"; Type=modMarkers.MarkerTypes.Npc;};
		[9]={World="TheMall"; Label="Stan"; Target="Stan"; Type=modMarkers.MarkerTypes.Npc;};
	};
	CanRedo={};
	UseAssets=true;
};

-- MARK: 31 - Bunny Man's Eggs
MissionLibrary.New{
	MissionId=31;
	MissionType = MissionLibrary.MissionTypes.Event;
	Name="Bunny Man's Eggs";
	From="Bunny Man";
	Description="Find 3 Easter Eggs for Bunny Man.";
	Persistent=true;
	Objectives={
		["EggHunt"]={Index=1; Description="Bunny Man wants $Amount Easter Eggs"; Type="RequireItem"; ItemId="easteregg2023"; Amount=3;};
	};
	ObjectivesCompleteText="Return the $ItemName to Bunny Man";
	GuideText="Talk to Bunny Man";
	AddRequirements={
		{Type="SpecialEvent"; Value="Easter"};
	};
	Rewards={
		{Type="Perks"; Amount=PerksReward.Side};
		{Type="Item"; ItemId="bunnymanhead";  Quantity=1;};
		{Type="Mission"; Id=32};
	};
	UseAssets=true;
};

-- MARK: 32 - Easter Butchery
MissionLibrary.New{
	MissionId=32;
	MissionType = MissionLibrary.MissionTypes.Event;
	Name="Easter Butchery";
	From="Bunny Man";
	Description="Complete Bunny Man's challenge.";
	Persistent=true;
	Progression={
		"Talk to Bunny Man to travel";
		"Complete Bunny Man's challenge";
		"Talk to Bunny Man";
	};
	GuideText="Talk to Bunny Man";
	AddRequirements={
		{Type="SpecialEvent"; Value="Easter"};
	};
	Rewards={
		{Type="Perks"; Amount=PerksReward.Side};
		{Type="Mission"; Id=50};
	};
	UseAssets=true;
};

-- MARK: 33 - Awoken The Bear
MissionLibrary.New{
	MissionId=33;
	MissionType = MissionLibrary.MissionTypes.Core;
	Name="Awoken The Bear";
	From="Stan";
	Description="Patrick tells you about how to enter the Bandit Camp.";
	Persistent=true;
	World={"TheMall", "AwokenTheBear", "BanditOutpost"};
	Checkpoint={
		{Text="Follow Stan";};
		{Text="Talk to Patrick";};
		{Text="Enter the secret door";};
		{Text="Head to the top floor";};
		{Text="Follow Stan into the room";};

		{Text="Walk towards Zark";};
		{Text="Talk to Zark";};
		{Text="Talk to Zark";};
		{Text="Talk to Zark";};
		{Text="Talk to Zark";};

		{Text="Talk to Zark";};
		{Text="Unconscious";};
		{Text="Talk to Patrick";};
		{Text="Escape the Bandit Outpost";};
	};
	GuideText="Talk to Stan";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Core};
		{Type="Money"; Amount=MoneyReward.Core};
		{Type="Mission"; Id=54};
		{Type="Mission"; Id=38};
		{Type="Mission"; Id=47};
	};
	LinkNextMission=38;
	StartRequirements={
		Level=30;
	};
	Markers={
		[1]={World="TheMall"; Label="Stan"; Target="Stan"; Type=modMarkers.MarkerTypes.Npc;};
		[2]={World="TheMall"; Label="Patrick"; Target="Patrick"; Type=modMarkers.MarkerTypes.Npc;};
		[3]={World="TheMall"; Label="Enter the secret room"; Target=Vector3.new(834.101, 101.01, -713.806); Type=modMarkers.MarkerTypes.Waypoint;};
		[4]={World="AwokenTheBear"; Label="Top Floor"; Target=Vector3.new(-143.957703, 194.634598, -65.9168854); Type=modMarkers.MarkerTypes.Waypoint;};
		
		[6]={World="AwokenTheBear"; Label="Walk"; Target=Vector3.new(-99.4085159, 194.909668, -36.03228); Type=modMarkers.MarkerTypes.Waypoint;};
		[14]={World="BanditOutpost"; Label="Exit"; Target=Vector3.new(-20.444, 5.115, 30.344); Type=modMarkers.MarkerTypes.Waypoint;};
	};
	CanRedo={};
	UseAssets=true;
};

-- MARK: 34 - Escort
MissionLibrary.New{
	MissionId=34;
	MissionType = MissionLibrary.MissionTypes.Board;
	Name="Escort";
	Description="Molly wants you to escort a stranger to a location. Protect them at all costs.";
	Timer=BoardTimeLimit;
	Persistent=true;
	SaveData={
		Location=(function()
			local list = {"Mall Safehouse", "Train Station Safehouse", "Community Safehouse"};
			return list[math.fmod(getDayNumber(), #list) +1];
		end);
		Seed=(function()
			return math.random(1, 100000);
		end)
	};
	Progression={
		"Talk to Molly in the Clinic Safehouse for escorting the stranger";
		"Bring the stranger to, $Location";
		"Return back to Molly";
	};
	LogEntry={
	};
	GuideText="Talk to Molly to start";
	Tier="Hard";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Hard};
	};
	AddRequirements={
		{Type="Level"; Value=60};
	};
	CanFastTravelWhenActive={2};
	BoardPickFreq=5;
	UseAssets=true;
};

-- MARK: 35 - Food Airdrop
MissionLibrary.New{
	MissionId=35;
	MissionType = MissionLibrary.MissionTypes.Faction;
	ExpireTime=factionMissionExpireTime;
	Name="Food Airdrop";
	From="Faction";
	Description="Collect food airdrop to increase to your faction's Food supply.";
	Persistent=true;
	SaveData={
		Location=function()
			local list = {"Office"; "BanditOutpost"; "Tombs"; "Railways";};
			return list[math.fmod(getDayNumber(), #list) +1];
		end;
	};
	Checkpoint={
		{Text="Head to (Raid: $Location) to collect the food package";};
		{Text="Other factions has been alerted about the airdrop, times ticking";};
		{Text="Extract the food package";};
	};
	GuideText="Start by faction";
	FactionCosts={
		{Type="Resource"; Per="Player"; Id="Ammo"; Value=0.375;};
	};
	FactionRewards={
		{Type="Resource"; Id="Food"; Value=30;};
		{Type="Score"; Value=1;};
	};
	FactionSuccessCriteria={
		SuccessfulAgents=1;
	};
	QuotaLimit=16;
	PrintNote=function(missionPacket)
		local noteText = "";

		local shortestTime = math.huge;
		local mvpUsers = {};
		for userId, playerData in pairs(missionPacket.Players) do
			if playerData.Name == nil then continue end;
			local missionData = playerData.MissionData;
			if missionData == nil then continue end;

			local timeLapsed = missionData.Timelapsed or math.huge;
			if timeLapsed == shortestTime then
				table.insert(mvpUsers, playerData.Name);
			end
		end
		
		if #mvpUsers == 1 then
			noteText = mvpUsers[1].." is this mission's MVP for completing it within ".. modSyncTime.ToString(shortestTime) .."!";
			
		elseif #mvpUsers > 1 then
			noteText = table.concat(mvpUsers, ", ") .." are this mission's MVPs for completing it within ".. modSyncTime.ToString(shortestTime) .."!";
		end

		return noteText;
	end;
	UseAssets=true;
};

-- MARK: 36 - Calming Tunes
MissionLibrary.New{
	MissionId=36;
	MissionType = MissionLibrary.MissionTypes.Side;
	Name="Calming Tunes";
	From="Erik";
	Description="Help Erik from losing his sanity.";
	Persistent=true;
	World="TheUnderground";
	Objectives={
		["Musicbox"]={Index=1; Description="Give Erik a music box"; Type="RequireItem"; ItemId="musicbox"; Amount=1;};
	};
	ObjectivesCompleteText="Return to Erik with the music box";
	SaveData={};
	GuideText="Talk to Erik to start";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Side};
	};
	StartRequirements={
		Level=35;
	};
	UseAssets=true;
};

-- MARK: 37 - Joseph's Lettuce
MissionLibrary.New{
	MissionId=37;
	MissionType = MissionLibrary.MissionTypes.Side;
	Name="Joseph's Lettuce";
	From="Joseph";
	Description="Help Joseph water his lettuce.";
	Persistent=true;
	World="TheResidentials";
	Objectives={
		["wateringcan"]={Index=1; Description="Make a watering can";};
		["jlLettuce1"]={Index=2; Description="Water the plants";};
		["jlLettuce2"]={Index=3; Description="Water the plants";};
		["jlLettuce3"]={Index=4; Description="Water the plants";};
	};
	ObjectivesCompleteText="Return to Joseph";
	SaveData={};
	LogEntry={
	};
	GuideText="Talk to Joseph to start";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Side};
	};
	StartRequirements={
		Level=36;
	};
	Markers={
		["wateringcan"]={World="TheResidentials"; Label="Make Watering Can"; Target=Vector3.new(1146.179, 57.015, -93.945); Type=modMarkers.MarkerTypes.Waypoint;};
		["jlLettuce1"]={World="TheResidentials"; Label="Water plants"; Target=Vector3.new(1242.081, 57.213, -71.899); Type=modMarkers.MarkerTypes.Waypoint;};
		["jlLettuce2"]={World="TheResidentials"; Label="Water plants"; Target=Vector3.new(1242.231, 57.213, -56.169); Type=modMarkers.MarkerTypes.Waypoint;};
		["jlLettuce3"]={World="TheResidentials"; Label="Water plants"; Target=Vector3.new(1235.111, 57.213, -56.169); Type=modMarkers.MarkerTypes.Waypoint;};
	};
	UseAssets=true;
};

-- MARK: 38 - Something's Not Right
MissionLibrary.New{
	MissionId=38;
	MissionType = MissionLibrary.MissionTypes.Core;
	Name="Something's Not Right";
	From="Patrick";
	Description="You have unfinished bussiness after what happened at the Bandit Camp.";
	Persistent=true;
	World={"TheMall", "TheUnderground", "TheResidentials"};
	Checkpoint={
		{Text="Head to the train station safehouse to talk to Rachel";};
		{Text="You hear a familar noise outside, investigate outside";};
		{Text="Follow Robert";};
		{Text="Head to the residentials";};
		{Text="Look for Robert";};

		{Text="Talk to Robert";};
		{Text="Talk to Robert";};
	};
	GuideText="Talk to Patrick";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Core};
		{Type="Money"; Amount=MoneyReward.Core};
		{Type="Mission"; Id=36};
		{Type="Mission"; Id=39};
		{Type="Mission"; Id=52};
	};
	StartRequirements={
		Level=35;
	};
	Markers={
		[1]={World="TheUnderground"; Label="Rachel"; Target="Rachel"; Type=modMarkers.MarkerTypes.Npc;};
		[2]={World="TheUnderground"; Label="Investigate"; Target=Vector3.new(345.241, 9.125, -16.083); Type=modMarkers.MarkerTypes.Waypoint;};
		[3]={World="TheUnderground"; Label="Robert"; Target="Robert"; Type=modMarkers.MarkerTypes.Npc;};
		[4]={World="TheUnderground"; Label="Head to Residentials"; Target=Vector3.new(387.866, -21.482, 121.672); Type=modMarkers.MarkerTypes.Waypoint;};
		[5]={World="TheResidentials"; Label="Find Robert"; Target=Vector3.new(1126.97, 59.165, -179.74); Type=modMarkers.MarkerTypes.Waypoint;};
		[6]={World="TheResidentials"; Label="Robert"; Target="Robert"; Type=modMarkers.MarkerTypes.Npc;};

		[7]={World="TheResidentials"; Label="Robert"; Target="Robert"; Type=modMarkers.MarkerTypes.Npc;};
	};
	CanRedo={};
	UseAssets=true;
};

-- MARK: 39 - Spiking Up
MissionLibrary.New{
	MissionId=39;
	MissionType=MissionLibrary.MissionTypes.Side;
	Name="Spiking Up";
	From="Danny";
	Description="Danny is annoyed by the noise of the zombies banging on the store gate.";
	Persistent=true;
	World="TheMall";
	Objectives={
		["addWall1"]={Index=1; Description="Build a spiked fence";};
		["addWall2"]={Index=2; Description="Build a spiked fence";};
		["addWall3"]={Index=3; Description="Build a spiked fence";};
		["addWall4"]={Index=4; Description="Build a spiked fence";};
		["addWall5"]={Index=5; Description="Build a spiked fence";};
	};
	ObjectivesCompleteText="Return to Danny";
	GuideText="Talk to Danny to start";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Side};
	};
	StartRequirements={
		Level=50;
	};
	Markers={
		["addWall1"]={World="TheMall"; Label="Build A Spiked Fence"; Target=Vector3.new(724.63, 95.551, -703.974); Type=modMarkers.MarkerTypes.Waypoint;};
		["addWall2"]={World="TheMall"; Label="Build A Spiked Fence"; Target=Vector3.new(746.29, 95.551, -703.974); Type=modMarkers.MarkerTypes.Waypoint;};
		["addWall3"]={World="TheMall"; Label="Build A Spiked Fence"; Target=Vector3.new(775.345, 95.551, -703.974); Type=modMarkers.MarkerTypes.Waypoint;};
		["addWall4"]={World="TheMall"; Label="Build A Spiked Fence"; Target=Vector3.new(796.555, 99.391, -693.789); Type=modMarkers.MarkerTypes.Waypoint;};
		["addWall5"]={World="TheMall"; Label="Build A Spiked Fence"; Target=Vector3.new(796.555, 99.391, -672.399); Type=modMarkers.MarkerTypes.Waypoint;};
	};
	UseAssets=true;
};

-- MARK: 40 - Vindictive Treasure 1
MissionLibrary.New{
	MissionId=40;
	MissionType = MissionLibrary.MissionTypes.Side;
	Name="Vindictive Treasure 1";
	From="Victor";
	Description="Victor needs your help with something.";
	Persistent=true;
	World={"TheWarehouse"; "Tombs"};
	Progression={
		"Kill Zricera";
		"Kill Zricera";
		"Push the statue";
		"Jump into the hole";
		"Complete the Tombs raid";
		
		"Pick up the Nekron Mask";
		"Return to Victor";
	};
	SaveData={};
	GuideText="Talk to Victor to start";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Side};
		{Type="Mission"; Id=41};
	};
	LinkNextMission=41;
	StartRequirements={
		Level=100;
	};
	Markers={
		[1]={World="TheWarehouse"; Label="Kill Zricera"; Target=Vector3.new(352.02, 60.4, 225.46); Type=modMarkers.MarkerTypes.Waypoint;};
		[3]={World="TheWarehouse"; Label="Push"; Target=Vector3.new(352.495, -30.669, 1908.559); Type=modMarkers.MarkerTypes.Waypoint;};
		[5]={World="TheWarehouse"; Label="Tombs Raid"; Target=Vector3.new(453.381, 69.863, 225.211); Type=modMarkers.MarkerTypes.Waypoint;};
		[6]={World="Tombs"; Label="Pick up"; Target=Vector3.new(-89.549, 115.93, -64.867); Type=modMarkers.MarkerTypes.Waypoint;};
		[7]={World="TheWarehouse"; Label="Victor"; Target="Victor"; Type=modMarkers.MarkerTypes.Npc;};
	};
	EventFlags={
		{Id="takeNekronMask"; Clear=true};
	};
	UseAssets=true;
};

-- MARK: 41 - Vindictive Treasure 2
MissionLibrary.New{
	MissionId=41;
	MissionType = MissionLibrary.MissionTypes.Side;
	Name="Vindictive Treasure 2";
	From="Victor";
	Description="The cultists are hunting you down for what you have taken from them.";
	Persistent=true;
	Progression={
		"You are hunted by cultists";
		"Pick up the note from the cultist";
		"Talk to Victor";
		"Look for a cultist";
		"Pick up the cultist hood";
	};
	SaveData={Kills=5;};
	GuideText="Kill a cultist to start";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Side};
		{Type="Mission"; Id=42};
	};
	LinkNextMission=42;
	StartRequirements={
		MissionCompleted={40};
	};
	Markers={};
	UseAssets=true;
};

-- MARK: 42 - Vindictive Treasure 3
MissionLibrary.New{
	MissionId=42;
	MissionType = MissionLibrary.MissionTypes.Side;
	Name="Vindictive Treasure 3";
	From="Victor";
	Description="Victor needs your help with something in the tombs.";
	Persistent=true;
	Progression={
		"Talk to Victor when you are ready";
		"Talk to Victor";
		"Follow Victor";
		"Fight off the zombies";
		"Look for a weak spot in the walls";
		
		"Look for Victor";
		"Talk to Victor";
		"Pick up the Tactical Bow Blueprint";
	};
	SaveData={SaveVictor=0};
	LogEntry={
	};
	GuideText="Talk to Victor to start";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Side};
	};
	StartRequirements={
		MissionCompleted={41};
	};
	Markers={
		[8]={World="VindictiveTreasure3"; Label="Pick up"; Target=Vector3.new(-123.952, 278.229, 482.405); Type=modMarkers.MarkerTypes.Waypoint;};
	};
	EventFlags={
		{Id="mission42Bp"; Clear=true};
		{Id="mission42Bp2"; Clear=true};
	};
	UseAssets=true;
};

-- MARK: 43 - Missing Body 1
MissionLibrary.New{
	MissionId=43;
	MissionType = MissionLibrary.MissionTypes.Event;
	Name="Missing Body 1";
	From="Jack Reap";
	Description="A mysterious man needs your help searching for something..";
	Persistent=true;
	Progression={
		"Complete the office raid";
		"Talk to Jack Reap";
		"Head to the mall";
		"Go to the marker and find a way in";
		"Kill Jack the zombie";
	};
	World={"TheWarehouse"; "TheMall"};
	SaveData={};
	GuideText="Talk to Jack Reap";
	AddRequirements={
		{Type="SpecialEvent"; Value="Halloween"};
	};
	Rewards={
		{Type="Perks"; Amount=PerksReward.Side};
		{Type="Mission"; Id=44};
	};
	LinkNextMission=44;
	Markers={
		[1]={World="TheWarehouse"; Label="The Office Raid"; Target=Vector3.new(643.575, 60.15, 276.25); Type=modMarkers.MarkerTypes.Waypoint;};
		[4]={World="TheMall"; Label="Marker"; Target=Vector3.new(443.31, 95.481, -660.39); Type=modMarkers.MarkerTypes.Waypoint;};
	};
	UseAssets=true;
};

-- MARK: 44 - Missing Body 2
MissionLibrary.New{
	MissionId=44;
	MissionType = MissionLibrary.MissionTypes.Event;
	Name="Missing Body 2";
	From="Jack Reap";
	Description="Did you see a ghost?! Investigate further.";
	Persistent=true;
	Progression={
		"Follow the footsteps";
		"Investigate the area";
		"A mysterious green gas fills the room";
		"Escape";
	};
	World={"TheWarehouse"; "TheResidentials";};
	SaveData={};
	GuideText="Go to the office and read the note";
	AddRequirements={
		{Type="SpecialEvent"; Value="Halloween"};
	};
	Rewards={
		{Type="Perks"; Amount=PerksReward.Side};
		{Type="TweakPoints"; Amount=10};
	};
	Markers={
	};
	UseAssets=true;
};

-- MARK: 45 - Mike's Lucky Coin
MissionLibrary.New{
	MissionId=45;
	MissionType = MissionLibrary.MissionTypes.Side;
	Name="Mike's Lucky Coin";
	From="Mike";
	Description="Mike left his lucky coin in the prison that he escape, help him find it.";
	Persistent=true;
	Progression={
		"Talk to Mike to travel to Wrighton Dale Prison";
		"Complete survival waves";
		"Search for the lucky coin in every jail cells";
		"Bring it back to Mike";
	};
	World={"Prison";};
	SaveData={};
	GuideText="Talk to Mike";
	AddRequirements={
		{Type="Mission"; Id=38};
	};
	Rewards={
		{Type="Perks"; Amount=PerksReward.Side};
	};
	StartRequirements={
		Level=50;
	};
	Markers={
		[3]={World="Prison"; Label="Marker"; Target=Vector3.new(36.91, -9.045, 45.03); Type=modMarkers.MarkerTypes.Waypoint;};
	};
	UseAssets=true;
};

-- MARK: 46 - Warming Up
MissionLibrary.New{
	MissionId=46;
	MissionType = MissionLibrary.MissionTypes.Event;
	Name="Warming Up";
	From="Mr. Klaws";
	Description="Help warm up the safehouses by starting the fireplace.";
	Persistent=true;
	Progression={
		"Collect coal from zombies and add coal to the fireplace";
		"Set the fireplace on fire";
		"Talk to Mr. Klaws";
	};
	SaveData={};
	GuideText="Talk to Mr. Klaws";
	AddRequirements={
		{Type="SpecialEvent"; Value="Christmas"};
	};
	LinkNextMission=25;
	Rewards={
		{Type="Perks"; Amount=PerksReward.Side};
		{Type="Mission"; Id=25;};
	};
	UseAssets=true;
};

-- MARK: 47 - Sound of Music
MissionLibrary.New{
	MissionId=47;
	MissionType = MissionLibrary.MissionTypes.Premium;
	Name="Sound of Music";
	From="Carlos";
	Description="Carlos wants people to be hopeful in this apocalypses by sharing his music knowledge with others.";
	Persistent=true;
	World="TheWarehouse";
	Progression={
		"Talk to Carlos to obtain a flute";
		"Play the tune in near Carlos, C, C, G, F, D#, D, D, D, F, D#, D, C, C, D#, D, D#, D, D#";
		"Talk to Carlos";
	};
	SaveData={};
	GuideText="Talk to Carlos to start";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Side};
	};
	StartRequirements={
		Premium=true;
		Level=35;
	};
	Markers={
	};
	UseAssets=true;
};

-- MARK: 48 - Coming To The Rescue
MissionLibrary.New{
	MissionId=48;
	MissionType = MissionLibrary.MissionTypes.Board;
	Name="Coming To The Rescue";
	Description="A stranger is trapped somewhere in W.D. Mall and needs your help.";
	Timer=BoardTimeLimit;
	Persistent=true;
	SaveData={
		Id=(function()
			local list = {1;2;3;};
			return list[math.fmod(getDayNumber(), #list) +1];
		end);
		Seed=(function()
			return math.random(1, 100000);
		end)
	};
	Progression={
		"Find the stranded Stranger somewhere in W.D. Mall";
		"Bring the Stranger back to a safehouse";
	};
	GuideText="Help the Stranger break out";
	Tier="Normal";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Normal};
	};
	AddRequirements={
		{Type="Level"; Value=60};
	};
	NpcWorld="TheMall";
	Markers={
		[2]={World="TheMall"; Label="Stranger"; Target="Stranger"; Type=modMarkers.MarkerTypes.Npc;};
	};
	CanFastTravelWhenActive={2};
	UseAssets=true;
};

-- MARK: 49 - Navigation
MissionLibrary.New{
	MissionId=49;
	MissionType = MissionLibrary.MissionTypes.Core;
	Name="Navigation";
	From="Mason";
	Description="Mason needs help searching for a book.";
	Persistent=true;
	World="TheWarehouse";
	Checkpoint={
		{Text="Purchase a GPS from the shop";};
		{Text="Open your inventory and use (Right Click / Touch hold) the GPS to guide you to the office";};
		{Text="Navigate to the office and unlock it on the GPS";};
		{Text="Pick up the Vehicle Repair Manual";};
		{Text="Give the manual to Mason";};
	};
	GuideText="Talk to Mason";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Core};
		{Type="Money"; Amount=(MoneyReward.Core+1000)};
		{Type="Mission"; Id=12};
	};
	Markers={
		[4]={World="TheWarehouse"; Label="Book"; Target=Vector3.new(641.77, 61.36, 243.15); Type=modMarkers.MarkerTypes.Waypoint;};
		[5]={World="TheWarehouse"; Label="Mason"; Target="Mason"; Type=modMarkers.MarkerTypes.Npc;};
	};
	CanRedo={};
	UseAssets=true;
};

-- MARK: 50 - Easter Butchery 2
MissionLibrary.New{
	MissionId=50;
	MissionType = MissionLibrary.MissionTypes.Event;
	Name="Easter Butchery 2";
	From="Bunny Man";
	Description="Bunny Man gives player another job.";
	World="EasterButchery";
	Persistent=true;
	Progression={
		"Talk to Bunny Man";
		"Talk to Bunny Man";
		"Enter the door";
		"Follow Bunny Man";
		"Ignite the fire barrel";
		
		"Wait";
		"Fight off the cultists";
		"Talk to Bunny Man";
	};
	GuideText="Talk to Bunny Man";
	AddRequirements={
		{Type="SpecialEvent"; Value="Easter"};
	};
	StartRequirements={
		MissionCompleted={32};
	};
	Rewards={
		{Type="Perks"; Amount=PerksReward.Side};
	};
	UseAssets=true;
};

-- MARK: 51 - Quarantine Assessment
MissionLibrary.New{
	MissionId=51;
	MissionType = MissionLibrary.MissionTypes.Side;
	Name="Quarantine Assessment";
	From="Wilson";
	Description="Wilson recieves a radio broadcast from the military that they are sending in an inspector squad into the quarantine zone to assess the situation.";
	World={"TheUnderground"; "TheResidentials"};
	Persistent=true;
	Progression={
		"Make contact using the military radio in the Underbridge Community";
		"Head to the radio station in The Residentials";
		"Use the radio";
		"Respond to the radio";
		"Respond to the radio";

		"Talk to Wilson";
	};
	SaveData={};
	GuideText="Talk to Wilson";
	AddRequirements={
		{Type="Mission"; Id=19};
	};
	Rewards={
		{Type="Perks"; Amount=PerksReward.Side};
		{Type="Item"; ItemId="militarybootsdesert"; Quantity=1;};
		{Type="Mission"; Id=53};
	};
	StartRequirements={
		Level=300;
	};
	Markers={
		[1]={World="TheUnderground"; Label="Radio"; Target=Vector3.new(-76.697, 15.002, 259.405); Type=modMarkers.MarkerTypes.Waypoint;};
		[2]={World="TheResidentials"; Label="Radio Station"; Target=Vector3.new(1139.761, 76.133, -442.368); Type=modMarkers.MarkerTypes.Waypoint;};
		[3]={World="TheResidentials"; Label="Radio"; Target=Vector3.new(1092.714, 130.857, -508.18); Type=modMarkers.MarkerTypes.Waypoint;};
		[4]={World="TheResidentials"; Label="Radio"; Target=Vector3.new(1092.714, 130.857, -508.18); Type=modMarkers.MarkerTypes.Waypoint;};
		[5]={World="TheResidentials"; Label="Radio"; Target=Vector3.new(1092.714, 130.857, -508.18); Type=modMarkers.MarkerTypes.Waypoint;};
	};
	UseAssets=true;
};

-- MARK: 52 - The Investigation
MissionLibrary.New{
	MissionId=52;
	MissionType = MissionLibrary.MissionTypes.Core;
	Name="The Investigation";
	From="Joseph";
	Description="After finding Robert, something seems to be off about him. Investigate and find out what's going on.";
	Persistent=true;
	World={"TheResidentials"; "TheInvestigation"; "TheMall"};
	Progression={
		"Talk to Nate";
		"Talk to Robert";
		"Lure Robert into the basement to trap him";
		"Talk to Nate";
		"Investigating Robert";
		
		"Investigating Robert";
		"Listen to Nate";
		"Zark arrives";
		"Help Joseph";
		"Find something to stop the bleeding";
		
		"Patch Joseph up";
		"Wake up Nate";
		"Talk to Nate";
		"Help Joseph to the clinic";
		"Head to the clinic safehouse";
		
		"Convince Molly to help Joseph";
		"Give Molly an Advance Medkit";
		"Molly heals Joseph";
		"Talk to Joseph";
	};
	GuideText="Talk to Joseph";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Core};
		{Type="Money"; Amount=MoneyReward.Core};
		{Type="Mission"; Id=37};
		{Type="Mission"; Id=45};
		{Type="Mission"; Id=51};
		{Type="Mission"; Id=56};
	};
	Markers={
		[1]={World="TheResidentials"; Label="Nate"; Target="Nate"; Type=modMarkers.MarkerTypes.Npc;};
		[2]={World="TheResidentials"; Label="Robert"; Target="Robert"; Type=modMarkers.MarkerTypes.Npc;};
		[3]={World="TheResidentials"; Label="Basement"; Target=Vector3.new(1169.292, 50.515, -137.749); Type=modMarkers.MarkerTypes.Waypoint;};
		[4]={World="TheInvestigation"; Label="Nate"; Target="Nate"; Type=modMarkers.MarkerTypes.Npc;};
		[15]={World="TheMall"; Label="HA Clinic"; Target=Vector3.new(525.705, 99.735, -1102.795); Type=modMarkers.MarkerTypes.Waypoint;};
		[16]={World="TheMall"; Label="Molly"; Target="Molly"; Type=modMarkers.MarkerTypes.Npc;};
		[17]={World="TheMall"; Label="Molly"; Target="Molly"; Type=modMarkers.MarkerTypes.Npc;};
	};
	CanRedo={};
	UseAssets=true;
};

-- MARK: 53 - Quarantine Assessment 2
MissionLibrary.New{
	MissionId=53;
	MissionType = MissionLibrary.MissionTypes.Premium;
	Name="Quarantine Assessment 2";
	From="Wilson";
	Description="The quarantine inspectors are arriving.";
	World={"TheWarehouse";};
	Persistent=true;
	Checkpoint={
		{Text="Head to the roof";};
		{Text="Wait for Wilson";};
		{Text="Talk to Walter";};
		{Text="Acquire and equip a Entity Leash from the store";};
		{Text="Use the Entity Leash on a Zombie";};
		
		{Text="Bring the zombie to Walter";};
		{Text="Talk to Michael";};
		{Text="Bring the zombie to Walter";};
		{Text="Talk to Wilson";};
	};
	SaveData={};
	GuideText="Talk to Wilson";
	AddRequirements={
		{Type="Mission"; Id=51};
	};
	Rewards={
		{Type="Perks"; Amount=PerksReward.Side};
	};
	StartRequirements={
		Premium=true;
		Level=300;
	};
	Markers={};
	UseAssets=true;
};

-- MARK: 54 - Home Sweet Home
MissionLibrary.New{
	MissionId=54;
	MissionType = MissionLibrary.MissionTypes.Core;
	Name="Home Sweet Home";
	From="Mason";
	Description="Mason found a place and needs your help scavenging it.";
	World={"Safehome";};
	Persistent=true;
	Checkpoint={
		{Text="Talk to Mason to head out";};
		{Text="Talk to Mason";};
		{Text="Follow Mason";};
		{Text="Fight off the zombies";};
		{Text="Talk to Mason";};
	};
	SaveData={};
	GuideText="Talk to Mason";
	AddRequirements={
		{Type="Mission"; Id=12};
	};
	Rewards={
		{Type="Perks"; Amount=PerksReward.Core};
		{Type="Money"; Amount=MoneyReward.Core};
	};
	Markers={
		[1]={World="Safehome"; Label="Mason"; Target="Mason"; Type=modMarkers.MarkerTypes.Npc;};
		[2]={World="Safehome"; Label="Mason"; Target="Mason"; Type=modMarkers.MarkerTypes.Npc;};
		[5]={World="Safehome"; Label="Mason"; Target="Mason"; Type=modMarkers.MarkerTypes.Npc;};
	};
	UseAssets=true;
};

-- MARK: 55 - Another Survivor
MissionLibrary.New{
	MissionId=55;
	MissionType = MissionLibrary.MissionTypes.Board;
	Name="Another Survivor";
	Description="A survivor has arrive at your safehome.";
	World={"Safehome";};
	Timer=BoardTimeLimit;
	Persistent=true;
	Progression={
		"Talk to the survivor";
	};
	SaveData={};
	GuideText="Go to your Safehome";
	AddRequirements={
		{Type="Mission"; Id=38};
		{Type="Mission"; Id=54};
		{Type="SafehomeNpcLimit";};
		{Type="Cooldown"; Value=(3600 * 4)};
	};
	Tier="Easy";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Easy};
	};
	Markers={
	};
	BoardPickFreq=6;
	SkipDestroyIfAddRequirementsNotMet=true;
	UseAssets=true;
};

-- MARK: 56 - End Of The Line
MissionLibrary.New{
	MissionId=56;
	MissionType = MissionLibrary.MissionTypes.Core;
	Name="End Of The Line";
	From="Joseph";
	Description="Ah, here we go again.. Chasing after Robert.";
	Persistent=true;
	World={"TheResidentials"; "Genesis"};
	Checkpoint={
		{Text="Go back to the basement";};
		{Text="Figure out where Robert went";};
		{Text="Enter Genesis";};
		{Text="Hunt Robert in the map";};
		{Text="Kill Robert"; Notify=true;};
		
		{Text="Complete Genesis";};
	};
	GuideText="Talk to Joseph";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Core};
		{Type="Money"; Amount=MoneyReward.Core};
		{Type="Mission"; Id=58};
		{Type="Mission"; Id=77};
	};
	Markers={
		[1]={World="TheResidentials"; Label="Basement"; Target=Vector3.new(1169.292, 50.515, -137.749); Type=modMarkers.MarkerTypes.Waypoint;};
		[2]={World="TheResidentials"; Label="Enter"; Target=Vector3.new(1060.251, -20.875, -126.729); Type=modMarkers.MarkerTypes.Waypoint;};
		
	};
	CanRedo={};
	UseAssets=true;
};

-- MARK: 57 - Mr. Klaw's Workshop
MissionLibrary.New{
	MissionId=57;
	MissionType = MissionLibrary.MissionTypes.Event;
	Name="Mr. Klaw's Workshop";
	From="Mr. Klaws";
	Description="Mr. Klaws needs you to get something from his workshop.";
	Persistent=true;
	Progression={
		"Use Mr. Klaw's Workshop Map to travel to the workshop";
		"Retrieve Mr. Klaw's Journal";
		"Return the book back to Mr. Klaws";
	};
	SaveData={};
	GuideText="Talk to Mr. Klaws";
	AddRequirements={
		{Type="SpecialEvent"; Value="Christmas"};
	};
	Rewards={
		{Type="Perks"; Amount=PerksReward.Side};
	};
	Markers={
		[2]={World="KlawsWorkshop"; Label="Mr. Klaw's Journal"; Target=Vector3.new(-19.151, 103.838, -224.87); Type=modMarkers.MarkerTypes.Waypoint;};
	};
	UseAssets=true;
};

-- MARK: 58 - Double Cross
MissionLibrary.New{
	MissionId=58;
	MissionType = MissionLibrary.MissionTypes.Core;
	Name="Double Cross";
	From="Patrick";
	Description="Patrick has some bad news";
	Persistent=true;
	World={"TheHarbor"; "DoubleCross"; "Safehome"};
	Checkpoint={
		{Text="Talk to Caitlin";};
		{Text="Waiting for Revas's Response";};
		{Text="Talk to Caitlin";};
		{Text="Head to Revas's office";};
		{Text="Talk to Revas";};

		{Text="Take the letter";};
		{Text="Talk to Patrick";};
		{Text="Talk to Patrick";};
		{Text="Talk to Revas";};	--World Double Cross
		{Text="Get into the crate";};

		{Text="Stay hidden";};
		{Text="Get out of the crate";};
		{Text="Keep an eye out";};
		{Text="Do you want to pull the lever?"; Notify=true;};
		{Text="Rescue Patrick";};

		{Text="Find the escape boat";};
		{Text="Talk to Patrick";};	--World Safehome
		{Text="Get Patrick a medkit";};
	};
	StartRequirements={
		MissionCompleted={56};
	};
	GuideText="Talk to Patrick";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Core};
		{Type="Money"; Amount=MoneyReward.Core};
		{Type="Mission"; Id=62};
		{Type="Mission"; Id=63};
		{Type="Mission"; Id=75};
	};
	Markers={
		[1]={World="TheHarbor"; Label="Caitlin"; Target="Caitlin"; Type=modMarkers.MarkerTypes.Npc;};
		[4]={World="TheHarbor"; Label="Revas's Office"; Target=Vector3.new(-290.606, 107.853, 243.741); Type=modMarkers.MarkerTypes.Waypoint;};
	};
	CanRedo={};
	UseAssets=true;
}

-- MARK: 59 - Horde Clearance
MissionLibrary.New{
	MissionId=59;
	MissionType = MissionLibrary.MissionTypes.Faction;
	ExpireTime=factionMissionExpireTime;
	Timer=300;
	Name="Horde Clearance";
	From="Faction";
	Description="A horde appears to be heading towards our compound, clear them out and increase your faction's Material supply.";
	Persistent=true;
	SaveData={Kills=function() return 300; end;};
	Checkpoint={
		{Text="Kill $Kills zombies";};
	};
	GuideText="Start by faction";
	FactionCosts={
		{Type="Resource"; Per="Player"; Id="Food"; Value=0.4;};
		{Type="Resource"; Per="Player"; Id="Comfort"; Value=0.375;};
		{Type="Resource"; Per="Player"; Id="Ammo"; Value=0.1;};
	};
	FactionRewards={
		{Type="Resource"; Id="Material"; Value=30;};
		{Type="Score"; Value=1;};
	};
	FactionSuccessCriteria={
		SuccessfulAgents=1;
	};
	QuotaLimit=16;
	UseAssets=true;
};

-- MARK: 60 - Reconnaissance Duty
MissionLibrary.New{
	MissionId=60;
	MissionType = MissionLibrary.MissionTypes.Faction;
	ExpireTime=factionMissionExpireTime;
	Name="Reconnaissance Duty";
	From="Faction";
	Description="Keep your faction informed as to the on goings around and promote your faction to increase faction's Comfort level.";
	Persistent=true;
	SaveData={
		Location=function(mission)
			local list = {};

			if RunService:IsStudio() then
				mission.SaveData.WorldId = "BioXResearch";
				return "BioXResearch Lab";
			end
			
			local modGpsLibrary = require(game.ReplicatedStorage.Library.GpsLibrary);
			for _, lib in pairs(modGpsLibrary:ListByKeyValue("FactionBanner", true)) do
				table.insert(list, lib);
			end
			
			local pickLib = list[math.fmod(getDayNumber(), #list) +1];
			mission.SaveData.WorldId = pickLib.WorldName;
			
			return pickLib.Name;
		end;
		RepairItemId=function()
			local list = {"metal"; "wood"; "cloth"};
			return list[math.fmod(getDayNumber(), #list) +1];
		end;
		RepairCost=function()
			local list = {math.random(100, 150); math.random(20,35); math.random(150, 200);};
			return list[math.fmod(getDayNumber(), #list) +1];
		end;
	};
	Checkpoint={
		{Text="Check on your faction's banner located in $Location";};
		{Text="An enemy faction banner was reported to be located somewhere in $WorldId, find and destroy it";};
	};
	GuideText="Start by faction";
	FactionCosts={
		{Type="Resource"; Per="Player"; Id="Food"; Value=0.2;};
		{Type="Resource"; Per="Player"; Id="Material"; Value=0.2;};
	};
	FactionRewards={
		{Type="Resource"; Id="Comfort"; Value=60;};
		{Type="Score"; Value=1;};
	};
	FactionSuccessCriteria={
		SuccessfulAgents=1;
	};
	QuotaLimit=16;
	CanFastTravelWhenActive={2};
	UseAssets=true;
};

-- MARK: 61 - Ammo Manufacturing
MissionLibrary.New{
	MissionId=61;
	MissionType = MissionLibrary.MissionTypes.Faction;
	ExpireTime=factionMissionExpireTime;
	Timer=600;
	Name="Ammo Manufacturing";
	From="Faction";
	Description="Use some material to manufacture ammunition to increase faction's Ammo supply.";
	Persistent=true;
	Checkpoint={
		{Text="Craft Patrick an Ammo Box. Check Bandit's Market for Ammo Box Blueprint.";};
	};
	SaveData={};
	GuideText="Start by faction";
	FactionCosts={
		{Type="Resource"; Per="Player"; Id="Food"; Value=0.1;};
		{Type="Resource"; Per="Player"; Id="Material"; Value=0.2;};
	};
	FactionRewards={
		{Type="Resource"; Id="Ammo"; Value=60;};
		{Type="Score"; Value=1;};
	};
	FactionSuccessCriteria={
		SuccessfulAgents=1;
	};
	QuotaLimit=16;
	UseAssets=true;
};

-- MARK: 62 - Rats Recruitment
MissionLibrary.New{
	MissionId=62;
	MissionType = MissionLibrary.MissionTypes.Core;
	Name="Rats Recruitment";
	From="Patrick";
	Description="After the cargo ship disaster, you check up on Patrick to see what's up.";
	Persistent=true;
	World={"TheHarbor"; "SectorE"; "SectorF"};
	Checkpoint={
		{Text="Talk to Revas";};
		{Text="Talk to Revas to travel";};
		{Text="Talk to Revas";};
		{Text="Follow Revas";};
		{Text="Pay attention";};
		
		{Text="Inspect around";};
		{Text="Talk to Stan";};
		{Text="Use the terminal";};
		{Text="Talk to Stan";};
		{Text="Act natural";};

		{Text="Talk to Revas";};
		{Text="Head to Sector F";};
		{Text="Search for some research papers";};
		{Text="Return to Revas";};
		{Text="Eugene needs these items"; CompleteText="Give the cache to Eugene in Sector E"; Objectives={"Objective1"};};
	};
	Objectives={
		["Objective1"]={Index=1; Description="$Amount Nekron Particulate Cache"; Type="RequireItem"; ItemId="nekronparticulatecache"; Amount=2;};
	};
	StartRequirements={
		MissionCompleted={58};
	};
	GuideText="Talk to Patrick in the Safehome";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Core};
	};
	SkipDestroyIfAddRequirementsNotMet=true;
	AddRequirements={
		{Type="MissionCompleted"; Value={58;}};
		{Type="EventFlag"; Key="mission58choice"; 
			Value=function(eventObj) return eventObj.Rats == true; end; 
			FailMsg="You needed to helped the rats during Mission: Double Cross."
		};
	};
	Markers={
		[1]={World="TheHarbor"; Label="Revas"; Target="Revas"; Type=modMarkers.MarkerTypes.Npc;};
		[8]={World="SectorE"; Label="Terminal"; Target=Vector3.new(144.3, -7, -80.4); Type=modMarkers.MarkerTypes.Waypoint;};
		[15]={World="SectorE"; Label="Eugene"; Target="Eugene"; Type=modMarkers.MarkerTypes.Npc;};
	};
	CanRedo={};
	AddCache={
		RatsAllied=true;
	};
	UseAssets=true;
};

-- MARK: 63 - Bandits Recruitment
MissionLibrary.New{
	MissionId=63;
	MissionType = MissionLibrary.MissionTypes.Core;
	Name="Bandits Recruitment";
	From="Patrick";
	Description="After the cargo ship disaster, you check up on Patrick to see what's up.";
	Persistent=true;
	World={"TheMall"; "BanditsRecruitment"; };
	Checkpoint={
		{Text="Head to the Bandit Camp";};
		{Text="Talk to the bandit again when you are ready to travel";};
		{Text="Follow the bandit's orders";};
		{Text="Wait";};
		{Text="De-escalate";};

		{Text="Wait";};
		{Text="Get off the helicopter";};
		{Text="Follow the other recruits";};
		{Text="Talk to Zark";};
		{Text="Wait";};

		{Text="Talk to Zark";};
		{Text="Bandits needs these items"; CompleteText="Give the cache to Loran in Mall Bandit Camp"; Objectives={"Objective1"};};
	};
	Objectives={
		["Objective1"]={Index=1; Description="$Amount Nekron Particulate Cache"; Type="RequireItem"; ItemId="nekronparticulatecache"; Amount=2;};
	};
	StartRequirements={
		MissionCompleted={58};
	};
	GuideText="Talk to Patrick";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Core};
		{Type="Money"; Amount=MoneyReward.Core};
	};
	Markers={
		[1]={World="TheMall"; Label="Bandit"; Target=Vector3.new(798.55481, 162.668854, -728.297119); Type=modMarkers.MarkerTypes.Waypoint;};
		[12]={World="TheMall"; Label="Loran"; Target="Loran"; Type=modMarkers.MarkerTypes.Npc;};
	};
	SkipDestroyIfAddRequirementsNotMet=true;
	AddRequirements={
		{Type="MissionCompleted"; Value={58;}};
		{Type="EventFlag"; Key="mission58choice"; 
			Value=function(eventObj) return eventObj.Bandits == true; end; 
			FailMsg="You needed to helped the bandits during Mission: Double Cross."
		};
	};
	CanRedo={};
	AddCache={
		BanditsAllied=true;
	};
	UseAssets=true;
};

-- MARK: 64 - Joseph's Crossbow
MissionLibrary.New{
	MissionId=64;
	MissionType = MissionLibrary.MissionTypes.Secret;
	Name="Joseph's Crossbow";
	From="Joseph";
	Description="You showed Joseph your crossbow..";
	Persistent=true;
	World={"TheResidentials";};
	Checkpoint={
		{Text="Figure out how to build Joseph's Crossbow";};
	};
	StartRequirements={
		Level=500;
	};
	GuideText="Talk to Joseph";
	RewardText="Received a Arelshift Cross Antique Skin-Perm";
	Rewards={
		{Type="Item"; ItemId="arelshiftcrossantique"; Quantity=1;};
	};
	Markers={};
	AddRequirements={};
	UseAssets=true;
};

-- MARK: 65 - Eternal Inferno
MissionLibrary.New{
	MissionId=65;
	MissionType = MissionLibrary.MissionTypes.Board;
	Name="Eternal Inferno";
	Description="Joseph wants to see the effects of killing zombies with fire.";
	Timer=BoardTimeLimit;
	Persistent=true;
	World="TheResidentials";
	Checkpoint={
		{Text="Kill $Kills zombies with Fire Damage";};
	};
	SaveData={Kills=100;};
	GuideText="";
	Tier="Normal";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Normal};
	};
	AddRequirements={
		{Type="Level"; Value=30};
	};
	UseAssets=true;
};

-- MARK: 66 - Monorail
MissionLibrary.New{
	MissionId=66;
	MissionType = MissionLibrary.MissionTypes.Board;
	Name="Monorail";
	Description="Nate has been going to Sector D but he needs help with the monorail inside.";
	Timer=BoardTimeLimit;
	Persistent=true;
	Checkpoint={
		{Text="Objectives"; CompleteText="Well done"; Objectives={"CompleteSurvival", "ActivateMonorail"};};
	};
	Objectives={
		["CompleteSurvival"]={Index=1; Description="Complete Sector: D";};
		["ActivateMonorail"]={Index=2; Description="Activate the Monorail";};
	};
	CompleteAfterObjectives=true; -- complete if all objectives are done.
	SaveData={};
	GuideText="";
	Tier="Hard";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Hard};
	};
	AddRequirements={
		{Type="Level"; Value=30};
	};
	BoardPickFreq=8;
	UseAssets=true;
};

-- MARK: 67 - Capital Gains
MissionLibrary.New{
	MissionId=67;
	MissionType = MissionLibrary.MissionTypes.Board;
	Name="Capital Gains";
	Description="Help Lewis stabilize the economy by selling some things.";
	Timer=BoardTimeLimit;
	Persistent=true;
	World="TheResidentials";
	Checkpoint={
		{Text="Sell items in the shop: $$Money/$$MaxMoney";};
	};
	SaveData={Money=0; MaxMoney=10000;};
	GuideText="";
	Tier="Normal";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Normal};
	};
	AddRequirements={
		{Type="Level"; Value=30};
	};
	UseAssets=true;
};

-- MARK: 68 - Sunken Salvages
MissionLibrary.New{
	MissionId=68;
	MissionType = MissionLibrary.MissionTypes.Board;
	Name="Sunken Salvages";
	Description="Some cargo has been loss during the shipping, Cooper needs you to look for them in the sea.";
	Timer=BoardTimeLimit;
	Persistent=true;
	World="TheHarbor";
	Checkpoint={
		{Text="Search for $SalvagesLeft more sunken salvages in W.D Harbor.";};
	};
	SaveData={SalvagesLeft=3;};
	GuideText="";
	Tier="Normal";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Normal};
	};
	AddRequirements={
		{Type="Level"; Value=30};
	};
	UseAssets=true;
};

-- MARK: 69 - Reserved Weapons
MissionLibrary.New{
	MissionId=69;
	MissionType = MissionLibrary.MissionTypes.Board;
	Name="Reserved Weapons";
	Description="Get an amount of zombie kills with a type of weapon";
	Timer=BoardTimeLimit;
	Persistent=true;
	Checkpoint={
		{Text="Kill $Kills zombies with a $WeaponType";};
	};
	SaveData={
		Kills=50;
		WeaponType=function()
			local list = {"Pistol"; "Rifle"; "Submachine gun"; "Shotgun"; "Sniper";};
			return list[math.fmod(getDayNumber()*getHourNumber(), #list) +1];
		end;
	};
	GuideText="";
	Tier="Normal";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Normal};
	};
	AddRequirements={
		{Type="Level"; Value=30};
	};
	UseAssets=true;
};

-- MARK: 70 - Anti Immunity
MissionLibrary.New{
	MissionId=70;
	MissionType = MissionLibrary.MissionTypes.Board;
	Name="Anti Immunity";
	Description="Kill zombies that have immunity with a melee weapon";
	Timer=BoardTimeLimit;
	Persistent=true;
	Checkpoint={
		{Text="Kill $Kills immune zombies with melee";};
	};
	SaveData={
		Kills=10;
	};
	GuideText="";
	Tier="Normal";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Normal};
	};
	AddRequirements={
		{Type="Level"; Value=30};
	};
	UseAssets=true;
};

-- MARK: 71 - High Value Package
MissionLibrary.New{
	MissionId=71;
	MissionType = MissionLibrary.MissionTypes.Board;
	Name="High Value Package";
	Description="Help deliver a high value package.";
	Timer=BoardTimeLimit;
	Persistent=true;
	Checkpoint={
		{Text="Pick up the package from Greg near the Harbor Docks.";};
		{Text="Bring the package to $TargetPlace.";};
	};
	SaveData={
		TargetPlace=function()
			local list = {"Frank in Sunday's Safehouse"; "Diana in Underbridge Safehouse"};
			return list[math.fmod(getDayNumber() * getHourNumber(), #list) +1];
		end;
	};
	GuideText="";
	Tier="Hard";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Hard};
		{Type="Item"; ItemId="deagleparts"; Quantity=1;};
	};
	AddRequirements={
		{Type="Level"; Value=30};
	};
	SetMissionCheckpointOnStart=1;
	CanFastTravelWhenActive={2};
	UseAssets=true;
};

-- MARK: 72 - Weapons Expert
--MissionLibrary.New{
--	MissionId=72;
--	MissionType = MissionLibrary.MissionTypes.Core;
--	Name="Weapons Expert";
--	From="Niko";
--	Description="Niko teaches you how to tweak your weapons.";
--	Persistent=true;
--	Cutscene="Weapons Expert";
--	Checkpoint={
--	};
--	StartRequirements={
--		MissionCompleted={};
--	};
--	GuideText="";
--	Rewards={
--		{Type="Perks"; Amount=PerksReward.Core};
--	};
--	Markers={
--	};
--	CanRedo={};
--};

-- MARK: 73 - Deadly Zeniths Strike
MissionLibrary.New{
	MissionId=73;
	MissionType = MissionLibrary.MissionTypes.Faction;
	ExpireTime = factionMissionExpireTime;
	Name="Deadly Zeniths Strike";
	From="Faction";
	Description="A zenith boss is approaching your faction headquarters. Call up faction members to take down the boss together.";
	Persistent=true;
	OneAtATime=true;
	World={"Safehome"; "BioXResearch"};
	SaveData={};
	Checkpoint={
		{Text="Talk to Patrick";};
		{Text="Kill Zenith $BossName";};
	};
	GuideText="Start by faction";
	FactionCosts={
		{Type="Resource"; Per="Player"; Id="Food"; Value=8;};
		{Type="Resource"; Per="Player"; Id="Comfort"; Value=8;};
		{Type="Resource"; Per="Player"; Id="Ammo"; Value=8;};
	};
	FactionRewards={
		{Type="Resource"; Id="Food"; Value=30;};
		{Type="Resource"; Id="Material"; Value=30;};
		{Type="Score"; Value=10;};
		{Type="Gold"; Value=100;};
	};
	FactionSuccessCriteria={
		SuccessfulAgents=4;
	};
	QuotaLimit=10;
	UseAssets=true;
};

-- MARK: 74 - Breach by the Dead
MissionLibrary.New{
	MissionId=74;
	MissionType = MissionLibrary.MissionTypes.Board;
	Name="Breach by the Dead";
	Description="Help defend a safehouse from a breach.";
	Timer=BoardTimeLimit;
	Persistent=true;
	Checkpoint={
		{Text="Look for a safehouse which is getting breached right now, there may or may not be one right now.";};
		{Text="Keep killing zombies and barricade walls until the safehouse breach is over.";};
	};
	SaveData={};
	GuideText="";
	Tier="Hard";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Hard};
	};
	AddRequirements={
		{Type="Level"; Value=30};
	};
	UseAssets=true;
};

-- MARK: 75 - Medical Breakthrough
MissionLibrary.New{
	MissionId=75;
	MissionType = MissionLibrary.MissionTypes.Side;
	Name="Medical Breakthrough";
	From="Rachel";
	Description="Rachel has an epiphany about Stan and the possibility of his blood.";
	Persistent=true;
	Checkpoint={
		{Text="Talk to Rachel to pick up the blood samples";};
		{Text="Head to W.D. Mall's Clinic Safehouse"; Notify=true;};
		{Text="Find the laboratory in the Clinic Safehouse";};
		{Text="Look for fuel for the generator";};
		{Text="Activate the generator";};

		{Text="Figure out how to test the samples";}; -- 6
		{Text="Test the second sample";};
		{Text="Wait for the scan";};
		{Text="Talk to the patrol bandit";};
		--
		{Text="Fight off the bandits and finish testing the samples";};
		--
		
		{Text="Finish testing all the samples";}; -- 11
		{Text="Return to Rachel with the 4 sample reports";};
		
		{Text="Talk to Dr. Deniski in Warehouse Safehouse";};
		{Text="Return to Rachel with Dr. Deniski's insights";};
	};
	StartRequirements={
		MissionCompleted={8;};
	};
	GuideText="Talk to Rachel";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Side};
	};
	Markers={
	};
	UseAssets=true;
};

-- MARK: 76 - Ziphoning Serum
MissionLibrary.New{
	MissionId=76;
	MissionType = MissionLibrary.MissionTypes.Board;
	Name="Ziphoning Serum";
	Description="Rachel requires some items to create some Ziphoning Serum.";
	Timer=BoardTimeLimit; 
	Persistent=true;
	Checkpoint={
		{Text="Objectives"; CompleteText="Trade the items with Rachel"; Objectives={"Item1"; "Item2"};};
	};
	Objectives={
		["Item1"]={Index=1; Description="$Amount Nekron Scales"; Type="RequireItem"; ItemId="nekronscales"; Amount=8;};
		["Item2"]={Index=2; Description="$Amount Nekron Particulate"; Type="RequireItem"; ItemId="nekronparticulate"; Amount=3;};
	};
	GuideText="Talk to Rachel to start";
	Tier="Normal";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Normal};
	};
	AddRequirements={
		{Type="MissionCompleted"; Value={75}};
	};
	UseAssets=true;
};

-- MARK: 77 - Belly of the Beast
MissionLibrary.New{
	MissionId=77;
	MissionType = MissionLibrary.MissionTypes.Side;
	Name="Belly of the Beast";
	From="Mysterious Engineer";
	Description="You found a piece of blueprint from the SunkenShip Chest, ask the Mysterious Engineer about it.";
	Persistent=true;
	Checkpoint={
		{Text="Get eaten by Elder Vexeron";};
		{Text="Search for the missing blueprint pieces $PieceFound/2";};
		{Text="Exit Elder Vexeron at the end";};
		{Text="Talk to the Mysterious Engineer about the last piece";};
		{Text="Do the \"Sunken Salvages\" board mission when available";};

		{Text="Bring the final piece back to the Mysterious Engineer";};
	};
	LogEntry={
	};
	StartRequirements={
	};
	SaveData={PieceFound=0;};
	GuideText="Talk to Mysterious Engineer";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Side};
	};
	Markers={};
	UseAssets=true;
};

-- MARK: 78 - The Killer Hues
MissionLibrary.New{
	MissionId=78;
	MissionType = MissionLibrary.MissionTypes.Side;
	Name="The Killer Hues";
	From="Lydia";
	Description="Lydia wants to shoot some zombies but she doesn't have a gun.";
	Persistent=true;
	Checkpoint={
		{Text="Talk to Lydia and give her a weapon";};
		{Text="Look out for zombies breaching your safehome";};
		{Text="Kill $PlayerKills zombies while Lydia watches you kill them";};
		{Text="Let Lydia kill $LydiaKills zombies";};
		{Text="Kill the rest of the zombies";};
		
		{Text="Talk to Lydia";};
	};
	StartRequirements={
	};
	SaveData={
		PlayerKills=5;
		LydiaKills=10;
	};
	GuideText="Talk to Lydia";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Side};
	};
	Markers={};
	UseAssets=true;
};

-- MARK: 79 - Javelineer Prodigy
MissionLibrary.New{
	MissionId=79;
	MissionType = MissionLibrary.MissionTypes.Board;
	Name="Javelineer Prodigy";
	Description="Kill enemies with throwing weapons.";
	Timer=BoardTimeLimit; 
	Persistent=true;
	Checkpoint={
		{Text="Get $Kills Kills with a throwing weapon excluding explosives and flammables";};
	};
	SaveData={
		Kills=20;
	};
	GuideText="";
	Tier="Normal";
	Rewards={
		{Type="Perks"; Amount=PerksReward.Normal};
	};
	AddRequirements={
		{Type="Level"; Value=30};
	};
	UseAssets=true;
};


-- MARK: 666 - TestMission
MissionLibrary.New{
	MissionId=666;
	MissionType = MissionLibrary.MissionTypes.Unreleased;
	Name="TestMission";
	From="Mason";
	Description="Test mission.";
	Timer=30;
	Persistent=false;
	Checkpoint={
		{Text="Enter a door";};
	};
	GuideText="Talk to Mason to start";
	Rewards={
		{Type="Money"; Amount=20};
	};
};

return MissionLibrary;