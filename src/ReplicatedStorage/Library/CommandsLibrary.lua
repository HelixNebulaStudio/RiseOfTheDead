local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local TeleportService = game:GetService("TeleportService");
local RunService = game:GetService("RunService");
local MemoryStoreService = game:GetService("MemoryStoreService");
local HttpService = game:GetService("HttpService");
local MarketplaceService = game:GetService("MarketplaceService");
local TextService = game:GetService("TextService");

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local modCommandHandler = require(game.ReplicatedStorage.Library.CommandHandler);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modPlayers = require(game.ReplicatedStorage.Library.Players);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modColorsLibrary = require(game.ReplicatedStorage.Library:WaitForChild("ColorsLibrary"));
local modSkinsLibrary = require(game.ReplicatedStorage.Library:WaitForChild("SkinsLibrary"));
local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);
local modCrateLibrary = require(game.ReplicatedStorage.Library.CrateLibrary);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
--local modScheduler = require(game.ReplicatedStorage.Library.Scheduler);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);

local modGameModeLibrary = require(game.ReplicatedStorage.Library.GameModeLibrary);

local modDropRateCalculator = require(game.ReplicatedStorage.Library.DropRateCalculator);
local modGoldShopLibrary = require(game.ReplicatedStorage.Library.GoldShopLibrary);
local modRatShopLibrary = require(game.ReplicatedStorage.Library.RatShopLibrary);
local modSafehomesLibrary = require(game.ReplicatedStorage.Library.SafehomesLibrary);
local modAudio = require(game.ReplicatedStorage.Library.Audio);


if RunService:IsServer() then
	modServerManager = require(game.ServerScriptService.ServerLibrary.ServerManager);
	modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	modWorldEventSystem = require(game.ServerScriptService.ServerLibrary.WorldEventSystem);
	modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
	modCrates = require(game.ServerScriptService.ServerLibrary.Crates);
	modGameModeManager = require(game.ServerScriptService.ServerLibrary.GameModeManager);
	modMatchMaking = require(game.ServerScriptService.ServerLibrary.MatchMaking);
	modRaid = require(game.ServerScriptService.ServerLibrary.GameModeManager.Raid);
	modEvents = require(game.ServerScriptService.ServerLibrary.Events);
	modRedeemService = require(game.ServerScriptService.ServerLibrary.RedeemService);
	modDatabaseService = require(game.ServerScriptService.ServerLibrary.DatabaseService);
	modItemDrops = require(game.ServerScriptService.ServerLibrary.ItemDrops);
	
end


local remotes = game.ReplicatedStorage.Remotes;
local remoteConVarService = modRemotesManager:Get("ConVarService");
local bindPlayServerScene = remotes.Cutscene.PlayServerScene;

local updatedServerCode;
local Cache = {Group={};};
local PermissionLevel = {
	All=1;
	ServerOwner=2;
	DevBranch=3;
	Moderator=4;
	Admin=5;
	GameTester=6;
	DevBranchFree=7;
};

local Commands = {};

local GenericOutputs = {
	MultipleMatch=function(speaker, list)
		local namelist = {};
		for a=1, #list do
			table.insert(namelist, tostring(list[a]));
		end
		shared.Notify(speaker, "Found more than 1 similar names: "..table.concat(namelist, ", ")..".", "Negative");
	end;
	NoMatch=function(speaker, input)
		shared.Notify(speaker, "Could not find anyone matching: "..(input or ""), "Negative");
	end;
}

local function HasPermissions(player, cmdLib)
	local isCreator = modGlobalVars.IsCreator(player);
	
	if cmdLib.Permission == PermissionLevel.Admin then
		if isCreator then return true; end
		return false;
		
	elseif cmdLib.Permission == PermissionLevel.Moderator then
		if isCreator then return true; end
		return player:GetAttribute("IsModerator") == true;
		
	elseif cmdLib.Permission == PermissionLevel.DevBranch then
		if isCreator then return true; end
		if modBranchConfigs.CurrentBranch.Name ~= "Dev" then return false end;
		if player:GetAttribute("DbTinkerCmds") == true then return true end;

		if RunService:IsServer() then
			local cmdKey = cmdLib.CmdKey;
			shared.Notify(player, `Tinkering Commands is required for {(cmdKey and "/"..cmdKey or "this command")}.`, "Negative");
		end
		return false;
		
	elseif cmdLib.Permission == PermissionLevel.DevBranchFree then
		if isCreator then return true; end
		if modBranchConfigs.CurrentBranch.Name == "Dev" then return true end;
		return false;

	elseif cmdLib.Permission == PermissionLevel.GameTester then
		if isCreator then return true; end
		return modGlobalVars.IsTester(player);
		
	elseif cmdLib.Permission == PermissionLevel.ServerOwner then
		if isCreator then return true; end
		if (RunService:IsServer() and modServerManager:GetPrivateServerOwnerId() == player.UserId) then return true end;
		
		return false;

	elseif cmdLib.Permission == PermissionLevel.All then
		return true;
		
	end;
	
	return false;
end

local CommandsLibrary = {};
CommandsLibrary.__index = CommandsLibrary;
CommandsLibrary.HasPermissions = HasPermissions;
CommandsLibrary.Library = Commands;
CommandsLibrary.PermissionLevel = PermissionLevel;
CommandsLibrary.GenericOutputs = GenericOutputs;

local month = {"January"; "February"; "March"; "April"; "May"; "June"; "July"; "Augest"; "September"; "October"; "November"; "December";};
--== Debug cmds
Commands["engine"] = {
	Permission = PermissionLevel.All;
	Description = "Shows engine version.";

	RequiredArgs = 0;
	UsageInfo = "/engine";
	Function = function(player, args)
		shared.Notify(player, "Engine version: "..modGlobalVars.EngineVersion, "Inform", nil, {SndId="Collectible"});
		return true;
	end;
};

Commands["game"] = {
	Permission = PermissionLevel.All;
	Description = "Shows game version.";
	
	RequiredArgs = 0;
	UsageInfo = "/game";
	Function = function(player, args)
		shared.Notify(player, "Game version: "..modGlobalVars.GameVersion.."."..modGlobalVars.GameBuild .. " (".. modBranchConfigs.CurrentBranch.Name ..")", "Inform");
		return true;
	end;
};

Commands["testspawn"] = {
	Permission = PermissionLevel.Admin;
	Description = "Test";
	
	RequiredArgs = 0;
	UsageInfo = "/testspawn spawns a client side bandit zombie";
	Function = function(player, args)
		local npc = modNpc.Spawn("Bandit Zombie", CFrame.new(138.553329, 12.2096834, 87.6066055, 0, 0, 1, 0, 1, 0, -1, 0, 0), function(npc, npcModule)
			npcModule.NetworkOwners = {player};
		end);
		modReplicationManager.ReplicateOut(player, npc);
		shared.Notify(player, "test", "Inform");
		return true;
	end;
};

Commands["playcutscene"] = {
	Permission = PermissionLevel.Admin;
	Description = "Plays a cutscene.";
	
	RequiredArgs = 1;
	UsageInfo = "/playcutscene cutscene";
	Function = function(player, args)
		bindPlayServerScene:Invoke({player}, args[1]);
		shared.Notify(player, "Playing cutscene.", "Inform");
		return true;
	end;
};

--Commands["mission33"] = {
--	Permission = PermissionLevel.Admin;
--	Description = "mission33.";
--	
--	RequiredArgs = 0;
--	UsageInfo = "/mission33";
--	Function = function(player, args)
--		local gameLib = modGameModeLibrary.GetGameMode("Raid");
--		local stageLib = gameLib and modGameModeLibrary.GetStage("Raid", "BanditOutpost");
--		
--		local system = modRaid.new();
--		local room = modMatchMaking.Room.new();
--		
--		system:Init({
--			Type="Raid";
--			Stage="BanditOutpost";
--			StageLib=stageLib;
--		});
--		room.Mission=true;
--		room:AddPlayer(player);
--		system:Start(room);
--		return true;
--	end;
--};

--== Informational
Commands["cmds"] = {
	Permission = PermissionLevel.All;
	Description = "List commands available to you.";
	
	RequiredArgs = 0;
	UsageInfo = "/cmds [page]";
	Function = function(player, args)
		local page = args[1] or 1;
		
		local availableCmds = {};
		for cmd, cmdLib in pairs(Commands) do
			if HasPermissions(player, cmdLib) then
				table.insert(availableCmds, {Cmd=cmd; Lib=cmdLib});
			end
		end
		
		local pages = math.ceil(#availableCmds/5);
		page = math.clamp(page, 1, pages);
		shared.Notify(player, "Available Commands ("..page.."/"..pages.."):", "Inform");
		
		for a=1 + (page-1)*5, math.clamp((page-1)*5 + 5, 1, #availableCmds) do
			shared.Notify(player, "/"..(availableCmds[a].Cmd or "~")..": "..(availableCmds[a].Lib.Description or "~"), "Inform");
		end
		return true;
	end;
};

Commands["help"] = {
	Permission = PermissionLevel.All;
	Description = "Show more information about a command.";
	
	RequiredArgs = 0;
	UsageInfo = "/help [cmds]";
	Function = function(player, args)
		local cmd = #args > 0 and args[1]:lower() or "help";
		local cmdLib = Commands[cmd];
			
		if cmdLib then
			if HasPermissions(player, cmdLib) then
				shared.Notify(player, cmdLib.Description..(cmdLib.UsageInfo and "\n"..cmdLib.UsageInfo or ""), "Inform");
			else
				shared.Notify(player, "Insufficient permissions.", "Negative");
			end
		else
			shared.Notify(player, "Unknown command.", "Negative");
		end
		
		return true;
	end;
};

--Commands["test"] = {
--	Permission = PermissionLevel.DevBranch;
--	Description = "Placeholder command.";

--	RequiredArgs = 0;
--	UsageInfo = "/test";
--	Function = function(player, args)

--		return true;
--	end;
--};


Commands["item"] = {
	Permission = PermissionLevel.All;
	Description = "Show more information about an item.";
	
	Cooldown = 4;
	RequiredArgs = 0;
	UsageInfo = "/item [itemName or itemId]";
	Function = function(speaker, args)
		local itemStr = #args > 0 and table.concat(args, " ") or "p250";
		
		local tagMatches, matchCount = modCommandHandler.FilterSearchTag(modItemsLibrary.SearchTags, itemStr);
		
		--local matchesIds = modCommandHandler.MatchStringFromDict(itemStr, modItemsLibrary.Library:GetKeys());
		--local matchesNames = modCommandHandler.MatchStringFromDict(itemStr, modItemsLibrary.Library);
		
		local function present(tag) 
			local itemLib = modItemsLibrary:Find(tag);
			if itemLib then
				local itemId = itemLib.Id;
				--itemLib
				shared.Notify(speaker, ("========== "..itemLib.Name.." ("..itemLib.Id..") =========="), "Inform");
				shared.Notify(speaker, "Type: "..itemLib.Type, "Inform");
				shared.Notify(speaker, "Description: "..(itemLib.Description:gsub("\n", " ")), "Inform");
				shared.Notify(speaker, "Stackable: "..tostring(itemLib.Stackable), "Inform");
				shared.Notify(speaker, "Tradable: "..tostring(itemLib.Tradable), "Inform");
				
				local extraInfo = modItemDrops.Info(itemId, true);
				local sources = extraInfo and extraInfo.SourceText;
				
				if #sources > 0 then
					shared.Notify(speaker, "========== Sources ==========", "Inform");
					for a=1, #sources do
						shared.Notify(speaker, "• "..(sources[a]), "Inform");
					end
				else
					shared.Notify(speaker, "Sources: No way to obtain this item at the moment.", "Inform");
				end
				
			else
				shared.Notify(speaker, "No library for such item.", "Negative");
			end
		end

		local itemLib = modItemsLibrary:Find(itemStr);
		if itemLib then
			present(itemLib.Id);
		elseif matchCount == 1 then
			present((next(tagMatches)));
		elseif matchCount > 1 then
			shared.Notify(speaker, "========== Similar Results ==========", "Inform");
			shared.Notify(speaker, modCommandHandler.FormList(tagMatches), "Inform");
		else
			shared.Notify(speaker, "No similar result for: "..itemStr, "Inform");
		end
		
		return true;
	end;
};

Commands["info"] = {
	Permission = PermissionLevel.All;
	Description = "Show detail library information.";

	Cooldown = 2;
	RequiredArgs = 0;
	UsageInfo = "/item [subject] key";
	Info = function(speaker)
		shared.Notify(speaker, "========== /info Examples ==========", "Inform");
		shared.Notify(speaker, 'Check mission id 25: /info mission 25', "Inform");
		shared.Notify(speaker, 'Check mission title with keyword: /info mission "Book"', "Inform");
		shared.Notify(speaker, 'Check cmd: /info cmd give', "Inform");
		shared.Notify(speaker, 'Check projectile: /info projectile "50mm"', "Inform");
		shared.Notify(speaker, 'Check blueprint: /info blueprint "Tier"', "Inform");
		shared.Notify(speaker, "If there are any information you would like to see, suggest it to us~", "Inform");
	end;
	Function = function(speaker, args)
		local infoType = args[1] or "cmd";

		local modBlueprintLibrary = require(game.ReplicatedStorage.Library.BlueprintLibrary);
		if infoType == "cmd" then
			local cmdInput = args[2] or "info";
			
			local cmdLib = Commands[cmdInput];
			
			if not HasPermissions(speaker, cmdLib) then
				cmdLib = nil;
			end
			
			if cmdLib and cmdLib.Info then
				cmdLib.Info(speaker);
			else
				shared.Notify(speaker, "No available examples for /"..cmdInput..".", "Inform");
			end
			
		elseif infoType == "mission" then
			local key = args[2];
			
			local modMissionLibrary = require(game.ReplicatedStorage.Library.MissionLibrary);
			local function printMissionInfo(m)
				shared.Notify(speaker, "========== Mission:"..m.Name.." ("..m.MissionId..") ==========", "Inform");
				
				local typeStr = "("..m.MissionType..")";
				for k, v in pairs(modMissionLibrary.MissionTypes) do
					if v == m.MissionType then
						typeStr = k.." "..typeStr;
						break;
					end
				end
				
				shared.Notify(speaker, "MissionType: "..typeStr, "Inform");
				shared.Notify(speaker, "From: ".. m.From, "Inform");
				shared.Notify(speaker, "Rewards: ".. modCommandHandler.FormList(m.Rewards), "Inform");
				shared.Notify(speaker, "StartRequirements: ".. modCommandHandler.FormList(m.StartRequirements), "Inform");
				shared.Notify(speaker, "AddRequirements: ".. modCommandHandler.FormList(m.AddRequirements), "Inform");
				
				if m.Progression then
					shared.Notify(speaker, "ProgressionPoints: ".. modCommandHandler.FormList(m.Progression), "Inform");
				elseif m.Objectives then
					shared.Notify(speaker, "Objectives: ".. modCommandHandler.FormList(m.Objectives), "Inform");
				end
				
			end
			
			if typeof(key) == "string" then
				local missionTitles = {};
				local missionDict = {};
				for _, m in pairs(modMissionLibrary.List()) do
					table.insert(missionTitles, m.Name);
					missionDict[m.Name] = m;
				end
				
				local search = modCommandHandler.MatchStringFromList(key, missionTitles);
				
				if #search > 1 then
					shared.Notify(speaker, "Similar titles: "..table.concat(search, ", "), "Inform");
				elseif #search <= 0 then
					shared.Notify(speaker, "No mission title contains: "..args[2], "Inform");
				else
					printMissionInfo(missionDict[search[1]]);
				end
			elseif typeof(key) == "number" then
				local m = modMissionLibrary.Get(key);
				if m then
					printMissionInfo(m);
				else
					shared.Notify(speaker, "No mission id: "..args[2], "Inform");
				end
				
			else
				shared.Notify(speaker, "Unknown key: "..args[2], "Negative");
			end

		elseif infoType == "projectile" then
			local projectileMsrcs = {};
			
			for _, v in pairs(game.ReplicatedStorage.Library.Projectile:GetChildren()) do
				projectileMsrcs[v.Name] = v;
			end
			
			local key = args[2];

			if typeof(key) == "string" then
				local search = modCommandHandler.MatchStringFromDict(key, projectileMsrcs);

				if #search > 1 then
					shared.Notify(speaker, "Similar projectile id: "..table.concat(search, ", "), "Inform");
				elseif #search <= 0 then
					shared.Notify(speaker, "No projectile id contains: "..args[2], "Inform");
				else
					local new = require(projectileMsrcs[search[1]]).new();
					shared.Notify(speaker, "========== Projectile:"..search[1].." ==========", "Inform");
					shared.Notify(speaker, "Configurations: ".. modCommandHandler.FormList(new.Configurations), "Inform");
				end
				
			elseif args[2] == nil then
				shared.Notify(speaker, "========== List of Projectiles ==========", "Inform");
				shared.Notify(speaker, modCommandHandler.FormList(projectileMsrcs), "Inform");
				
			else
				shared.Notify(speaker, "Unknown key: "..args[2], "Negative");
			end

		elseif infoType == "blueprint" then
			local key = args[2];

			if typeof(key) == "string" then
				local search = modCommandHandler.MatchStringFromDict(key, modBlueprintLibrary.Identifiers);

				if #search > 1 then
					shared.Notify(speaker, "========== Similar Results ==========", "Inform");
					shared.Notify(speaker, modCommandHandler.FormList(modCommandHandler.FilterDict(modBlueprintLibrary.Identifiers, search)), "Inform");
					
				elseif #search <= 0 then
					shared.Notify(speaker, "No blueprint id contains: "..args[2], "Inform");
				else
					local bpLib = modBlueprintLibrary.Get(search[1]);
					shared.Notify(speaker, "========== Blueprint: "..search[1].." ==========", "Inform");
					shared.Notify(speaker, modCommandHandler.FormList(bpLib), "Inform");
					
				end
				
			elseif args[2] == nil then
				shared.Notify(speaker, "========== List of Blueprints ==========", "Inform");
				shared.Notify(speaker, modCommandHandler.FormList(modBlueprintLibrary.Identifiers), "Inform");
				
			else
				shared.Notify(speaker, "Unknown key: "..args[2], "Negative");
			end
			
		else
			shared.Notify(speaker, "No available information on ".. infoType.." yet. You can request it to be added by sending us a feedback using F3!", "Inform");
		end
		
		return true;
	end;
};

Commands["spawnitem"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Spawn an item drop.";

	RequiredArgs = 1;
	UsageInfo = "/spawnitem itemId quantity";
	Function = function(speaker, args)

		local classPlayer = modPlayers.Get(speaker);
		local rootPart = classPlayer.RootPart;

		local ItemDropTypes = modGlobalVars.ItemDropsTypes;
		
		local itemId = args[1];
		local quantity = (tonumber(args[2]) or 1);
		
		local definedType;
		for k, v in pairs(ItemDropTypes) do
			if v == itemId then
				definedType = ItemDropTypes[k];
				break;
			end
		end

		local modWeapons = require(game.ReplicatedStorage.Library.Weapons);
		local modTools = require(game.ReplicatedStorage.Library.Tools);
		
		local isTool = false;
		if definedType == nil then
			if modTools[itemId] then
				isTool = true;
			end
			if modWeapons[itemId] then
				isTool = true;
			end;
		end
		
		if definedType then
			modItemDrops.Spawn({Type=definedType; Quantity=quantity}, rootPart.CFrame, nil, false);
			
		elseif isTool then
			modItemDrops.Spawn({Type="Tool"; ItemId=itemId; Quantity=quantity}, rootPart.CFrame, nil, false);
			
		else
			modItemDrops.Spawn({Type="Custom"; ItemId=itemId; Quantity=quantity}, rootPart.CFrame, nil, false);
			
		end
		
		return true;
	end;
};

Commands["term"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Opens terminal and run cmd.";
	
	RequiredArgs = 0;
	UsageInfo = "/term [cmd]";
	Function = function(speaker, args)
		return true;
	end;
};

Commands["ui"] = {
	Permission = PermissionLevel.All;
	Description = "Toggles a user interface.";

	RequiredArgs = 1;
	UsageInfo = "/ui [interfaceName]";
	Function = function(speaker, args)
		return true;
	end;
};

Commands["report"] = {
	Permission = PermissionLevel.All;
	Description = "Toggles report interface.";
	
	UsageInfo = "/report";
	Function = function(speaker, args)
		return true;
	end;
};

Commands["vote"] = {
	Permission = PermissionLevel.All;
	Description = "Toggles vote interface.";
	
	UsageInfo = "/vote";
	Function = function(speaker, args)
		return true;
	end;
};

Commands["config"] = {
	Permission = PermissionLevel.Admin;
	Description = "Manually change a config setting.";
	
	RequiredArgs = 1;
	UsageInfo = "/config [config] value";
	Function = function(speaker, args)
		local configId = args[1];
		local value = args[2];
		
		if configId then
			modConfigurations.Set(configId, value);
			
			local rP = remoteConVarService:InvokeClient(speaker, "setconfig", {configId; value;});
			Debugger:Log("setconfig", rP);
			
		else
			shared.Notify(speaker, "Unknown configId", "Negative");
		end
		return true;
	end;
};

Commands["w"] = {
	Permission = PermissionLevel.All;
	Description = "Whisper to player.";
	
	RequiredArgs = 2;
	UsageInfo = "/w [playerName] [message]";
	Function = function(speaker, args)
		return true;
	end;
};
	
Commands["f"] = {
	Permission = PermissionLevel.All;
	Description = "Chat to faction.";

	RequiredArgs = 2;
	UsageInfo = "/f [message]";
	Function = function(speaker, args)
		return true;
	end;
};

Commands["e"] = {
	Permission = PermissionLevel.All;
	Description = "Use emotes.";
	
	RequiredArgs = 1;
	UsageInfo = "/e [emote]";
	Function = function(speaker, args)
		return true;
	end;
};

Commands["c"] = {
	Permission = PermissionLevel.All;
	Description = "Close channel.";
	
	RequiredArgs = 0;
	UsageInfo = "/c";
	Function = function(speaker, args)
		return true;
	end;
};

Commands["s"] = {
	Permission = PermissionLevel.All;
	Description = "Switch channel.";
	
	RequiredArgs = 1;
	UsageInfo = "/s [channelId]";
	Function = function(speaker, args)
		return true;
	end;
};

Commands["reloadgui"] = {
	Permission = PermissionLevel.All;
	Description = "Reload general user interface.";

	UsageInfo = "/reloadgui";
	Function = function(speaker, args)
		return true;
	end;
};

Commands["reloadchar"] = {
	Permission = PermissionLevel.All;
	Description = "Reload character script such as character script, interact script, etc..";

	UsageInfo = "/reloadchar";
	Function = function(speaker, args)
		shared.ReloadCharacter(speaker);
		return true;
	end;
};

Commands["unixtime"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Print the unix time.";

	UsageInfo = "/unixtime";
	Function = function(speaker, args)
		local clientUnixTime = args[1] or "0";
		local unixTime = DateTime.now().UnixTimestampMillis;
		shared.Notify(speaker, ("Client Unix time: ".. clientUnixTime)..("\nServer Unix time: ".. unixTime .. "\nDiff: ".. (unixTime-clientUnixTime)) .."ms", "Inform");
		return true;
	end;
};

Commands["console"] = {
	Permission = PermissionLevel.All;
	Description = "Opens up Roblox console.";

	UsageInfo = "/console";
	Function = function(speaker, args)
		return true;
	end;
};



--Commands["unstuck"] = {
--	Permission = PermissionLevel.All;
--	Description = "Unstuck player.";
	
--	RequiredArgs = 0;
--	UsageInfo = "/unstuck";
--	Function = function(speaker, args)
--		return true;
--	end;
--};

Commands["droptable"] = {
	Permission = PermissionLevel.All;
	Description = "Shows the drop table of a drop table.\nTo search for specific droptable: /droptable [search keyword]";
	
	RequiredArgs = 0;
	UsageInfo = "/droptable [id]";
	Function = function(player, args)
		local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);
		
		local tableId = args[1];
		
		local function listPossibleDropTables()
			if tableId== nil or #tableId <= 1 then
				return
			end
			local tables = modRewardsLibrary:GetAll();
			local validIds = {};
			
			for id, lib in pairs(tables) do
				if lib.Hidden then continue end;
				
				if string.match(id:lower() , tableId:lower()) then
					table.insert(validIds, id);
				end
			end
			shared.Notify(player, "Available drop tables:", "Inform");
			for a=1, math.min(#validIds, 10) do
				shared.Notify(player, a..": "..validIds[a], "Inform");
			end
			if #validIds > 10 then
				shared.Notify(player, "(10/".. #validIds ..") ...", "Inform");
			end
		end
		
		if tableId then
			local rewardsLib = modRewardsLibrary:Find(tableId);
			
			if rewardsLib and rewardsLib.Hidden then
				rewardsLib = nil;
			end
			
			if rewardsLib then
				local groups = modDropRateCalculator.Calculate(rewardsLib, {HardMode=true});
				shared.Notify(player, "DropTable ("..rewardsLib.Id.."):", "Inform");
				for a=1, #groups do
					local chance = 0;
					for b=1, #groups[a] do
						local rewardInfo = groups[a][b];
						chance = chance + rewardInfo.Chance;

						local itemValues = "";
						if rewardInfo.Values then
							itemValues = "[[".. HttpService:JSONEncode(rewardInfo.Values) .."]]";
						end
						
						if rewardInfo.ItemId or rewardInfo.Type then
							shared.Notify(player, a..": "..(rewardInfo.Weekday and "("..rewardInfo.Weekday..") " or "")..(rewardInfo.ItemId or rewardInfo.Type)..itemValues..": ".. math.ceil((rewardInfo.Chance/groups[a].TotalChance)*100000)/1000 .."%", "Inform");
						else
							
							shared.Notify(player, a..": "..rewardInfo.Name..itemValues..": ".. math.ceil((rewardInfo.Chance/groups[a].TotalChance)*100000)/1000 .."%", "Inform");
						end
					end
					if chance <= groups[a].TotalChance then
						shared.Notify(player, a..": nothing: ".. math.ceil(( (groups[a].TotalChance-chance) /groups[a].TotalChance)*100000)/1000 .."%", "Inform");
					end
				end
				shared.Notify(player, "- - - - - - - - - - - - -", "Inform");
			else
				shared.Notify(player, "Drop table id, "..tableId..", does not exist.", "Negative");
				listPossibleDropTables();
			end
			
		else
			listPossibleDropTables();
		end
		
		return true;
	end;
};

Commands["menu"] = {
	Permission = PermissionLevel.All;
	Description = "Teleport to main menu.";
	
	RequiredArgs = 0;
	UsageInfo = "/menu";
	Function = function(player, args)
		modServerManager:Travel(player, "MainMenu");
		return true;
	end;
};

Commands["settings"] = {
	Permission = PermissionLevel.All;
	Description = "Toggle settings menu.";
	
	Function = function(player, args)
		return true;
	end;
};

Commands["printsettings"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Print settings into the log.";

	Function = function(player, args)

		local profile = shared.modProfile:Get(player);
		Debugger:Log("self.Settings", profile.Settings);
		
		return true;
	end;
};

Commands["resetdata"] = {
	Permission = PermissionLevel.DevBranchFree;
	Description = "Completely resets player save data.";
	
	UsageInfo = "/resetdata [full]";
	Function = function(player, args)
		local profile = shared.modProfile:Get(player)
		local playerSave = profile:GetActiveSave();
		
		if args[1] == "full" then
			
			profile.Loaded = false;
			
			local DataStoreService = game:GetService("DataStoreService");
			DataStoreService:GetDataStore("Profiles"):RemoveAsync(tostring(profile.UserId));
			
			local worldName = "MainMenu";
			if updatedServerCode == nil then
				updatedServerCode = modServerManager:CreatePrivateServer(worldName);
			end;
			
			modServerManager:TeleportToPrivateServer(worldName, updatedServerCode, {player});
			
		else
			profile:ResetSave();
			modServerManager:Travel(player, "MainMenu");
		end
		shared.Notify(player, "Data reset complete.", "Positive");
		return true;
	end;
};

Commands["editmode"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Adds edit mode tag into player.";
	
	RequiredArgs = 0;
	UsageInfo = "/editmode";
	Function = function(speaker, args)
		local character = speaker.Character;
		
		if character and character:FindFirstChild("EditMode") then
			Debugger.Expire(character.EditMode, 0);
			shared.Notify(speaker, "Edit mode tag has been removed.", "Negative");
		else
			local new = Instance.new("BoolValue");
			new.Name = "EditMode";
			new.Parent = character;
			shared.Notify(speaker, "Edit mode tag has been added.", "Positive");
		end
			
		return true;
	end;
};

--== Server
Commands["npcstats"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "List npc module attributes.";

	RequiredArgs = 0;
	UsageInfo = "/npcstats";
	Function = function(player, args)
		local moduleNpc = game.ServerScriptService.ServerLibrary.Entity.Npc;
	
		local total = 0;
		local countTable = {};

		for a=1, #modNpc.NpcModules do
			local aNpcModule = modNpc.NpcModules[a] and modNpc.NpcModules[a].Module;
			local npcName = aNpcModule.Name;

			total = total +1;
			if countTable[npcName] == nil then
				local key = string.gsub(npcName, " ", "");
				key = string.gsub(key, "%.", "");
				countTable[npcName] = {SpawnCount=moduleNpc:GetAttribute(key)};
			end
			countTable[npcName].ActiveCount = (countTable[npcName].ActiveCount or 0) + 1;

		end

		shared.Notify(player, `Total: {total} / { moduleNpc:GetAttribute("ActiveNpcs") } ` , "Inform");
		for name, countInfo in pairs(countTable) do
			local txt = `{name}: {countInfo.ActiveCount} / { countInfo.SpawnCount }`
			print(txt);
			shared.Notify(player, txt , "Inform");
		end

		return true;
	end;
};


Commands["listnpcs"] = {
	Permission = PermissionLevel.Admin;
	Description = "List all npcs onto console";
	
	RequiredArgs = 0;
	UsageInfo = "/listnpcs";
	Function = function(player, args)
		Debugger:Log("NPC ("..#modNpc.NpcModules..")");
		for a=1, #modNpc.NpcModules do
			Debugger:Log("NPC:",modNpc.NpcModules[a].Module.Name,modNpc.NpcModules[a].Prefab);
		end
		return true;
	end;
};


Commands["garbagenpc"] = {
	Permission = PermissionLevel.Admin;
	Description = "garbagenpc.";
	
	RequiredArgs = 0;
	UsageInfo = "/garbagenpc";
	Function = function(player, args)
		local moduleNpc = game.ServerScriptService.ServerLibrary.Entity.Npc;
		
		if player:GetAttribute("garbagenpcPrompt") == true then
			player:SetAttribute("garbagenpcPrompt", nil);
			Debugger:Display(nil, {player});
		else
			player:SetAttribute("garbagenpcPrompt", true);
			coroutine.wrap(function()
				while player:GetAttribute("garbagenpcPrompt") do
					Debugger:Display(moduleNpc:GetAttributes(), {player});
					wait(1);

					if not player:IsDescendantOf(game) then break; end;
				end
			end)()
		end
		shared.Notify(player, "Printed garbage on dev console.", "Inform");
		
		return true;
	end;
};

Commands["startworldevent"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Start a world event such as HordeAttack, SafehomeBreach.";
	
	RequiredArgs = 0;
	UsageInfo = "/startworldevent [eventType]";
	Function = function(player, args)
		
		modWorldEventSystem.NextWorldEvent = args[1];
		modWorldEventSystem.NextEventTick = modSyncTime.GetTime();
		task.delay(2,function()
			shared.Notify(player, "Starting next event, ".. tostring(modWorldEventSystem.ActiveEvent and modWorldEventSystem.ActiveEvent.Name) ..".", "Inform");
		end)
		return true;
	end;
};

Commands["endworldevent"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "End a world event.";
	
	RequiredArgs = 0;
	UsageInfo = "/endworldevent";
	Function = function(player, args)
		shared.Notify(player, "Ending event, ".. tostring(modWorldEventSystem.ActiveEvent.Name) ..".", "Inform");
		modWorldEventSystem.EndBind:Fire();
		return true;
	end;
};

Commands["setsafehome"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Change safehome map.";
	
	RequiredArgs = 0;
	UsageInfo = "/setsafehome [mapId]";
	Function = function(player, args)
		local mapId = args[1] or "default";
		local safehomeLib = modSafehomesLibrary:Find(mapId);
		if safehomeLib == nil then mapId = "default"; end;
		
		shared.Notify(player, "Setting and loading safehome, ".. mapId ..".", "Inform");
		shared.modSafehomeService.LoadMap(mapId);
		
		return true;
	end;
};


Commands["listentities"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "List entities.";
	
	RequiredArgs = 0;
	UsageInfo = "/listentities [match]";
	Function = function(player, args)
		local matchKey = args[1];
		local nameList = {};
		
		for k, _ in pairs(modNpc.NpcBaseModules) do
			if matchKey == nil or k:match(matchKey) then
				table.insert(nameList, k);
			end
		end
		
		shared.Notify(player, ("Entities: ".. table.concat(nameList, ", ")) , "Inform");
		
		return true;
	end;
};

Commands["spawnentity"] = {
	Permission = PermissionLevel.DevBranch;
	Description = [[Spawn a entity. <[>config<]> arg uses JSON to load config table.
	/spawnentity "Zombie" {"Level":10,"Anchored":true}
	/spawnentity "Zombie" {"Level":2,"AttackRange":32,"DebugTTK":true}
	/spawnentity "Bandit Pilot" {"HardMode":true}
	
	"debug" flag is for developers.
	]];
	
	RequiredArgs = 1;
	UsageInfo = "/spawnentity \"entityName\" [[config]] \"debug\"";
	Function = function(player, args)
		local entityName = args[1];
		local config = args[2];
		local debugFlag = args[3];
		
		config = typeof(config) == "table" and config or nil;
		-- /spawnentity "Vexeron" [[{"HardMode":true}]]
		-- /spawnentity "Bandit" [[{"WeaponId":"minigun"}]]
		Debugger:Log("Cmd spawn entity:", entityName, " arg[1]=", args[1], " config",config);
		if entityName and modNpc.NpcBaseModules[entityName] then
			
			local classPlayerA = modPlayers.Get(player);
			local rootPartA = classPlayerA and classPlayerA.RootPart;
			
			--Debugger:Log("rootPartA.P", rootPartA.Position);
			
			local configDataRules = {
				Properties = {
					AttackSpeed = "number";
					AttackDamage = "number";
					AttackRange = "number";
				};
				Configuration = {
					Level = "number";
					ExperiencePool = "number";
				};
			}
			
			local printTable = {};
			
			local spawnCf = rootPartA.CFrame;
			local entityId = 1;
			modNpc.Spawn(entityName, spawnCf, function(npc, npcModule)
				if debugFlag == "debug" then
					npc:SetAttribute("Debug", true);

					table.insert(printTable, "Debug Enabled");
				end
				
				if config then
					if npcModule.Configuration == nil then
						npcModule.Configuration = {};
					end
					
					if config.DebugTTK then
						npcModule.DebugTTK = true;
						table.insert(printTable, "Print Time to kill enabled");
					end
					
					if config.DebugAnim then
						npcModule.DebugAnim = true;
						table.insert(printTable, "DebugAnim enabled");
					end
					
					if config.ResourceDrop then
						local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);
						npcModule.Configuration.ResourceDrop = modRewardsLibrary:Find(config.ResourceDrop);
						
						table.insert(printTable, "ResourceDrop Set "..config.ResourceDrop);
					end

					if tonumber(config.Level) then
						npcModule.Configuration.Level = tonumber(config.Level);

						table.insert(printTable, "Level Set");
					end
					
					if config.HardMode == true then
						npcModule.HardMode = true;
						
						table.insert(printTable, "HardMode Set");
					end

					if config.Owner == true then
						npcModule.Owner = player;
						
						table.insert(printTable, "Owner Set");
					end
					
					if config.Anchored == true then
						table.insert(printTable, "Anchored Set");
						task.spawn(function()
							while workspace:IsAncestorOf(npc) do
								if npc.PrimaryPart then
									break;
								end
								task.wait();
							end
							
							if npc.PrimaryPart then
								npc.PrimaryPart.Anchored = true;
							end
							
							while game:IsAncestorOf(npc) do
								npc:PivotTo(spawnCf);
								task.wait();
							end
						end)
					end
					
					if config.WeaponId and npcModule.Properties then
						npcModule.Properties.WeaponId = config.WeaponId;
						
						table.insert(printTable, "WeaponId Set");
					end
					
					if config.HideName then
						npcModule.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None;

						table.insert(printTable, "HideName Set");
					end
					
					if config.ShirtId then
						npcModule.RandomClothing = nil;
						local productInfo = MarketplaceService:GetProductInfo(config.ShirtId, Enum.InfoType.Asset)
						if productInfo and productInfo.AssetTypeId == 11 then
							local asset = game:GetService("InsertService"):LoadAsset(config.ShirtId)
							
							for _, obj in pairs(npc:GetChildren()) do
								if obj:IsA("Shirt") then
									obj:Destroy();
								end
							end
							
							asset.Shirt.Parent = npc;

							table.insert(printTable, "Shirt Set");
						end
					end
					if config.PantsId then
						npcModule.RandomClothing = nil;
						
						local productInfo = MarketplaceService:GetProductInfo(config.PantsId, Enum.InfoType.Asset)
						if productInfo and productInfo.AssetTypeId == 12 then
							local asset = game:GetService("InsertService"):LoadAsset(config.PantsId)
							
							for _, obj in pairs(npc:GetChildren()) do
								if obj:IsA("Pants") then
									obj:Destroy();
								end
							end
							
							asset.Pants.Parent = npc;

							table.insert(printTable, "Pants Set");
						end
					end
					
					for k, v in pairs(config) do
						if typeof(v) == "table" and configDataRules[k] and npcModule[k] then
							local ruleLib = configDataRules[k];
							for subK, subV in pairs(v) do
								if npcModule[k][subK] and typeof(subV) == ruleLib[subK] then
									npcModule[k][subK] = subV;
									
									table.insert(printTable, subK.." Set");
								end
							end
						end
					end
					
					entityId = npcModule.Id;
				end

				npcModule.Think:Fire();
				if npcModule.OnTarget then
					task.delay(1, function()
						--npcModule.ForgetEnemies = false;
						--npcModule.AutoSearch = true;
						
						local ff = player.Character:FindFirstChild("GodModeFF");
						if ff == nil then
							npcModule.Properties.TargetableDistance = 4096;
							npcModule.OnTarget(game.Players:GetPlayers());
							npcModule.NetworkOwners = game.Players:GetPlayers();
							
						end
					end)
				end
			end);
			
			shared.Notify(player, "Spawned "..entityName..", EntityId: "..entityId..".", "Inform");
			if #printTable > 0 then
				shared.Notify(player, entityName.. " spawned with: "..table.concat(printTable,", "), "Inform");
			end
		else
			shared.Notify(player, "Could not spawn "..(args[1] or "")..".", "Negative");
		end
		
		return true;
	end;
};

Commands["despawnentity"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Despawn an entity.";
	
	RequiredArgs = 1;
	UsageInfo = "/despawnentity \"entityName\"/id [amount]";
	Function = function(player, args)
		local entityName = args[1];
		local amount = args[2] or 1;
		
		local despawnCount = 0;
		for a=1, amount do
			if typeof(entityName) == "number" then
				local npcModule = modNpc.Get(entityName);
				if npcModule then
					npcModule:Destroy();
				end
			else
				local npcPrefab = workspace.Entity:FindFirstChild(entityName);
				if npcPrefab then
					npcPrefab:Destroy();
					despawnCount = despawnCount+1;
				end
			end
		end
		
		shared.Notify(player, "Despawned "..despawnCount..", "..entityName..".", "Inform");
		
		return true;
	end;
};

--== Character
Commands["itsshowtime"] = {
	Permission = PermissionLevel.All;
	Description = "Spawn your character in main menu.";
	
	RequiredArgs = 0;
	UsageInfo = "/itsshowtime";
	Function = function(player, args)
		if modBranchConfigs.IsWorld("MainMenu") then
			local classPlayer = shared.modPlayers.Get(player);
			classPlayer:Spawn();
		end
		return true;
	end;
};

Commands["forceloadcharacter"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Calls player:LoadCharacter().";
	
	RequiredArgs = 0;
	UsageInfo = "/forceloadcharacter";
	Function = function(player, args)
		player:LoadCharacter();
		return true;
	end;
};

Commands["resetsettings"] = {
	Permission = PermissionLevel.All;
	Description = "Reset all your settings.";

	RequiredArgs = 0;
	UsageInfo = "/resetsettings";
	Function = function(speaker, args)
		if speaker then
			local profile = shared.modProfile:Get(speaker);
			for k, _ in pairs(profile.Settings) do
				profile.Settings[k] = nil;
			end
			profile:RefreshSettings();
			profile:Sync("Settings", {Reset=true;});
			shared.Notify(speaker, "Settings resetted.", "Inform");
		end
		return true;
	end;
};

Commands["mute"] = {
	Permission = PermissionLevel.All;
	Description = "Togge mutes a player from your chat.";
	
	RequiredArgs = 1;
	UsageInfo = "/mute [playerName]";
	Function = function(speaker, args)
		local targetName = args[1];
		
		local matches = modCommandHandler.MatchName(args[1]);
		if #matches > 1 then
			GenericOutputs.MultipleMatch(speaker, matches);
			return false;
		elseif #matches < 1 then
			GenericOutputs.NoMatch(speaker, args[1]);
			return false;
		else
			targetName = matches[1].Name;
		end
		
		local ChatService = shared.ChatService;
		if targetName and ChatService then
			local setMute = not ChatService:IsMuted(speaker, targetName);
			ChatService:SetMute(speaker, targetName, setMute);
			
			if setMute then
				shared.Notify(speaker, "You have muted "..targetName..".", "Inform");
			else
				shared.Notify(speaker, "You have unmuted "..targetName..".", "Inform");
			end
		else
			Debugger:Warn("Missing chat service.");
		end
		return true;
	end;
};

Commands["god"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Toggle God mode.";
	
	RequiredArgs = 0;
	UsageInfo = "/god [playerName]";
	Function = function(speaker, args)
		local player = speaker;
		
		if #args == 1 then
			local matches = modCommandHandler.MatchName(args[1]);
			if #matches > 1 then
				GenericOutputs.MultipleMatch(speaker, matches);
				return false;
			elseif #matches < 1 then
				GenericOutputs.NoMatch(speaker, args[1]);
				return false;
			else
				player = matches[1];
			end
		end
		
		if modBranchConfigs.WorldName == "Slaughterfest" then
			shared.Notify(speaker, "God mode is not allowed here. :)", "Negative");
			return true;
		end
		
		if player then
			
			local ff = player.Character:FindFirstChild("GodModeFF");
			if ff then
				ff:Destroy();
				if player ~= speaker then
					shared.Notify(speaker, "God mode disabled for "..player.Name..".", "Reward");
				end
				shared.Notify(player, "God mode disabled.", "Reward");
			else
				ff = Instance.new("ForceField");
				ff.Name = "GodModeFF";
				ff.Visible = false;
				ff.Parent = player.Character;
				if player ~= speaker then
					shared.Notify(speaker, "God mode enabled for "..player.Name..".", "Reward");
				end
				shared.Notify(player, "God mode enabled.", "Reward");
			end
			
		end
		return true;
	end;
};

Commands["heal"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Fully heal a player.";
	
	RequiredArgs = 0;
	UsageInfo = "/heal [playerName]";
	Function = function(speaker, args)
		local player = speaker;
		
		if #args == 1 then
			local matches = modCommandHandler.MatchName(args[1]);
			if #matches > 1 then
				GenericOutputs.MultipleMatch(speaker, matches);
				return false;
			elseif #matches < 1 then
				GenericOutputs.NoMatch(speaker, args[1]);
				return false;
			else
				player = matches[1];
			end
		end
		
		if player then
			local classPlayer = modPlayers.Get(player);
			local humanoid = classPlayer.Humanoid;
			humanoid.Health = humanoid.MaxHealth;

			modStatusEffects.FullHeal(player);
			
			if player ~= speaker then
				shared.Notify(speaker, "Healed "..player.Name..".", "Reward");
			end
			shared.Notify(player, "You have been healed.", "Reward");
		end
		return true;
	end;
};

--== Teleport
Commands["joinplayer"] = {
	Permission = PermissionLevel.DevBranchFree;
	Description = "Travel to a player on a different server.";
	
	RequiredArgs = 1;
	UsageInfo = "/joinplayer playerName";
	Function = function(speaker, args)
		local player = speaker;
		local targetName = args[1];
		local success = modServerManager:TravelToPlayer(player, targetName);
		if not success then
			shared.Notify(player, "Requesting for "..targetName.."'s server.", "Inform");
			local placeId, accessCode = modServerManager:RequestPlayerServer(player, targetName);
			if placeId and accessCode then
				local worldName = modBranchConfigs.GetWorldName(placeId);
				shared.Notify(player, "Server recieved, joining "..targetName..".", "Inform");
				modServerManager:TeleportToPrivateServer(worldName, accessCode, {player});
			end
		end
		return true;
	end;
};


Commands["forcejoinplayer"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Travel to a player on a different server.";
	
	RequiredArgs = 1;
	UsageInfo = "/forcejoinplayer playerName";
	Function = function(speaker, args)
		local player = speaker;
		local targetName = args[1];
		shared.Notify(player, "Requesting for "..targetName.."'s server.", "Inform");
		local placeId, accessCode = modServerManager:RequestPlayerServer(player, targetName);
		Debugger:Log(placeId, accessCode)
		
		if placeId and accessCode then
			local worldName = modBranchConfigs.GetWorldName(placeId);
			shared.Notify(player, "Server recieved, joining "..targetName..".", "Inform");
			modServerManager:TeleportToPrivateServer(worldName, accessCode, {player});
		else
			shared.Notify(player, "Server could not be found for "..targetName..".", "Negative");
		end
		return true;
	end;
};

Commands["newserver"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Teleport to a player to a new server.";
	
	RequiredArgs = 0;
	UsageInfo = "/newserver [playerName/*]";
	Function = function(speaker, args)
		local player = speaker;
		local teleportOthers = false;
		
		if #args == 1 then
			if HasPermissions(player, {Permission = PermissionLevel.Admin}) then

				if args[1] == "*" then
					teleportOthers = true;
					
				else
					local matches = modCommandHandler.MatchName(args[1]);
					if #matches > 1 then
						GenericOutputs.MultipleMatch(player, matches);
						return false;
					elseif #matches < 1 then
						GenericOutputs.NoMatch(player, args[1]);
						return false;
					else
						player = matches[1];
					end
					
				end
				
			else
				shared.Notify(player, "You don't have permission to teleport others.", "Negative");
			end
		end
		
		if player then
			shared.Notify(player, "Teleporting to updated server.", "Inform");
			local worldName = modBranchConfigs.GetWorldName(game.PlaceId);
			if updatedServerCode == nil then
				updatedServerCode = modServerManager:CreatePrivateServer(worldName);
			end;
			local teleportPlayers = {player};
			
			if teleportOthers == true then
				teleportPlayers = game.Players:GetPlayers();
			end
			
			modServerManager:TeleportToPrivateServer(worldName, updatedServerCode, teleportPlayers);
		end
		return true;
	end;
};

Commands["tp"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Teleport to a player or location.";
	
	RequiredArgs = 1;
	UsageInfo = "/tp [playerName]";
	Function = function(speaker, args)
		local targetA = speaker;
		local targetB;
		local npcModel;
		
		
		if #args == 1 then
			local found = false;
			local matches = modCommandHandler.MatchName(args[1]);
			if #matches > 1 then
				GenericOutputs.MultipleMatch(speaker, matches);
			elseif #matches < 1 then
				GenericOutputs.NoMatch(speaker, args[1]);
			else
				targetB = matches[1];
				found = true;
			end
			
			if not found then
				npcModel = workspace.Entity:FindFirstChild(args[1]);
				if npcModel and npcModel.PrimaryPart then
					found = true;
				end
			end 
			
			if not found then
				return false;
			end
		end
		
		if targetA and targetB then
			local classPlayerA = modPlayers.Get(targetA);
			local rootPartA = classPlayerA and classPlayerA.RootPart;
			
			local classPlayerB = modPlayers.Get(targetB);
			local rootPartB = classPlayerB and classPlayerB.RootPart;
			
			if rootPartA and rootPartB then
				shared.modAntiCheatService:Teleport(targetA, rootPartB.CFrame);
				
				shared.Notify(targetA, "Teleported to "..targetB.Name..".", "Inform");
				if targetA.Name ~= "MXKhronos" then
					shared.Notify(targetB, targetA.Name.." teleported to you.", "Inform");
				end
			end
			
		elseif npcModel then
			if npcModel.PrimaryPart then
				local classPlayerA = modPlayers.Get(targetA);
				local rootPartA = classPlayerA and classPlayerA.RootPart;
				
				if rootPartA then
					shared.modAntiCheatService:Teleport(targetA, npcModel.PrimaryPart.CFrame);
					shared.Notify(targetA, "Teleported to "..npcModel.Name.." Npc.", "Inform");
				end
			end
			
		else
			return false;
		end
		return true;
	end;
};

Commands["getpos"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Shows your position.";
	
	RequiredArgs = 0;
	UsageInfo = "/getpos";
	Function = function(speaker, args)
		local player = speaker;
		
		local classPlayerA = modPlayers.Get(player);
		local rootPartA = classPlayerA and classPlayerA.RootPart;
		
		if rootPartA then
			shared.Notify(player, "Position: "..tostring(rootPartA.Position), "Inform");
		end
		return true;
	end;
};

Commands["tppos"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Teleport to a position.";
	
	RequiredArgs = 3;
	UsageInfo = "/tppos x y z";
	Function = function(speaker, args)
		local player = speaker;
		
		local classPlayerA = modPlayers.Get(player);
		local rootPartA = classPlayerA and classPlayerA.RootPart;
		
		local x = args[1];
		local y = args[2];
		local z = args[3];
		
		if typeof(x) == "string" then
			x = string.gsub(x, ",", "");
			y = string.gsub(y, ",", "");
			z = string.gsub(z, ",", "");
			
			x = tonumber(x);
			y = tonumber(y);
			z = tonumber(z);
		end
		
		if rootPartA then
			local tpPos = Vector3.new(x, y, z);
			shared.modAntiCheatService:Teleport(player, CFrame.new(tpPos));
			
			shared.Notify(player, "Teleported to "..tostring(tpPos)..".", "Inform");
		end
		return true;
	end;
};

Commands["tpme"] = {
	Permission = PermissionLevel.Admin;
	Description = "Teleport to a player to you.";
	
	RequiredArgs = 1;
	UsageInfo = "/tpme [playerName]";
	Function = function(speaker, args)
		local targetA = speaker;
		local targetB;
		
		if #args == 1 then
			local matches = modCommandHandler.MatchName(args[1]);
			if #matches > 1 then
				GenericOutputs.MultipleMatch(speaker, matches);
				return false;
			elseif #matches < 1 then
				GenericOutputs.NoMatch(speaker, args[1]);
				return false;
			else
				targetB = matches[1];
			end
		end
		
		if targetA and targetB then
			local classPlayerA = modPlayers.Get(targetA);
			local rootPartA = classPlayerA and classPlayerA.RootPart;
			
			local classPlayerB = modPlayers.Get(targetB);
			local rootPartB = classPlayerB and classPlayerB.RootPart;
			
			if rootPartA and rootPartB then
				shared.modAntiCheatService:Teleport(targetB, rootPartA.CFrame);
				
				shared.Notify(targetA, "Teleported "..targetB.Name.." to you.", "Inform");
				shared.Notify(targetB, targetA.Name.." teleported you.", "Inform");
			end
		else
			return false;
		end
		return true;
	end;
};


Commands["goto"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Teleport to a location on the map.";
	
	RequiredArgs = 0;
	UsageInfo = "/goto destination";
	Function = function(speaker, args)
		local classPlayer = modPlayers.Get(speaker);
		local rootPart = classPlayer.RootPart;
		
		local locations = {
			TheWarehouse={
				["cxF"] = CFrame.new(448.212, 61.15, -93.452);
				["sh1"] = CFrame.new(14.4731588, 57.6000252, 7.40512419);
				["sh2"] = CFrame.new(649.7, 60.89, -36.467);
				["egg1"] = CFrame.new(54.043, 75.95, 51.879);
				["egg2"] = CFrame.new(687.711, 74.35, -70.2);
				["boss1"] = CFrame.new(304.9, 55.4, 62);
				["boss2"] = CFrame.new(656.511, 55.3, 81.948);
				["boss3"] = CFrame.new(76.012, 55.6, 203.548);
				["test"] = CFrame.new(478.587, 56.9, 609.123);
				["sewers"] = CFrame.new(502, 35.121, 57.45);
				["zricera"] = CFrame.new(353.6, 59.85, 219.25);
				["office"] = CFrame.new(639.92, 60.34, 259);
			};
			TheUnderground={
				["sh3"] = CFrame.new(-92.8, 10.5, 282.0);
				["sh4"] = CFrame.new(272.3, 9.5, -3.6);
				["mine"] = CFrame.new(135.7, 12, -9.9);
				["entrance"] = CFrame.new(1.3, 12.612, -20);
				["breakroom"] = CFrame.new(-220.197, 13.496, 113.419);
				["maintenance"] = CFrame.new(-126.581, 13.374, -71.367);
				["watertreatment"] = CFrame.new(-250.991, 19.575, -59.451);
				["snipersnest"] = CFrame.new(-279.051, 10.055, 121.195);
				["egg1"] = CFrame.new(-63.695, 40.032, 297.605);
				["egg2"] = CFrame.new(367.271, 25.47, -191.933);
				["cave"] = CFrame.new(134.95, 16.929, 93.5);
				["boss3"] = CFrame.new(61.27, 18.45, -48.71);
				["boss4"] = CFrame.new(58.075, 8.132, 273.515);
				["boss5"] = CFrame.new(340.59, 10.075, 20.127);
			};
		};
		
		local pos;
		if #args > 0 then
			local targetLocation = args[1];
			
			if locations[modBranchConfigs.WorldName] then
				local destinations = locations[modBranchConfigs.WorldName];
				if destinations[targetLocation] then
					pos = destinations[targetLocation];
				else
					shared.Notify(speaker, "Invalid destination.", "Negative");
					
					local list = {};
					for n, _ in pairs(destinations) do
						table.insert(list, n);
					end
					shared.Notify(speaker, "List of locations: "..table.concat(list, ", "), "Inform");
				end
			else
				Debugger:Warn("Invalid placeid.");
			end
			if rootPart then
				if pos then
					shared.modAntiCheatService:Teleport(speaker, pos);
				end
			else
				Debugger:Warn("Missing pos or rootpart");
				return false;
			end
		else
			local destinations = locations[modBranchConfigs.WorldName];
			local list = {};
			for n, _ in pairs(destinations) do
				table.insert(list, n);
			end
			shared.Notify(speaker, "List of locations: "..table.concat(list, ", "), "Inform");
		end
		
		return true;
	end;
};

Commands["travel"] = {
	Permission = PermissionLevel.DevBranchFree;
	Description = "Travel to world.";
	
	RequiredArgs = 0;
	UsageInfo = "/travel worldName newServer";
	Function = function(speaker, args)
		local player = speaker;
		
		if #args > 0 then
			local worldName = args[1];
			local lib = modBranchConfigs.WorldLibrary[worldName];
			if lib then
				
				local newServer = args[2] == true;
				if newServer then
					shared.Notify(player, "Teleporting to updated server.", "Inform");
					if updatedServerCode == nil then
						updatedServerCode = modServerManager:CreatePrivateServer(worldName);
					end;
					modServerManager:TeleportToPrivateServer(worldName, updatedServerCode, {player});
					
				else
					shared.Notify(speaker, "Traveling to "..worldName, "Inform");
					modServerManager:Teleport(player, worldName);
				end
				
			else
				shared.Notify(speaker, "World id ("..worldName..") does not exist.", "Negative");
				
			end
		end
		
		return true;
	end;
};

Commands["offsettime"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Offsets time by x seconds.";
	
	RequiredArgs = 0;
	UsageInfo = "/offsettime [seconds]";
	Function = function(speaker, args)
		local player = speaker;
		
		local seconds = #args> 0 and tonumber(args[1]) or 0;
		modSyncTime.SetOffset(seconds);
		shared.Notify(speaker, "Time offset set to "..modSyncTime.TimeOffset.Value.."s.", "Inform");
		
		return true;
	end;
};


Commands["position"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Prints player position.";
	
	RequiredArgs = 0;
	UsageInfo = "/position";
	Function = function(speaker, args)
		local classPlayer = modPlayers.Get(speaker);
		local rootPart = classPlayer.RootPart;
		
		shared.Notify(speaker, "Position: "..tostring(rootPart.Position).."", "Inform");
		return true;
	end;
};

--== Fun;
Commands["targetdummy"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Spawns a target dummy.";
	
	RequiredArgs = 0;
	UsageInfo = "/targetdummy";
	Function = function(speaker, args)
		local player = speaker;
		Cache.TargetDummies = Cache.TargetDummies or {};
		if #Cache.TargetDummies > 3 then
			Cache.TargetDummies[1]:Destroy();
			table.remove(Cache.TargetDummies, 1);
		end
		
		local rootPart = player.Character.PrimaryPart;
		
		local origin = rootPart.CFrame.p + rootPart.CFrame.LookVector*4.5;
		local ray = Ray.new(origin, Vector3.new(0, -16, 0));
		local hit, pos = workspace:FindPartOnRayWithWhitelist(ray, {workspace.Environment});
		
		if hit then
			local targetDummy = game.ServerStorage.PrefabStorage.Objects.TargetDummy:Clone();
			targetDummy.Parent = workspace.Environment;
			targetDummy:SetPrimaryPartCFrame(CFrame.new(pos) * CFrame.Angles(0, math.rad(rootPart.Rotation.Y), 0));
			table.insert(Cache.TargetDummies, targetDummy);
			shared.Notify(player, "Target dummy spawned.", "Inform");
		else
			shared.Notify(player, "Could not hit ground.", "Negative");
		end
		
		return true;
	end;
};

Commands["spawnpet"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Spawns a companion.";
	
	RequiredArgs = 0;
	UsageInfo = "/spawnpet";
	Function = function(speaker, args)
		local player = speaker;
		local classPlayer = modPlayers.Get(speaker);
		
		local namesList = {"Jesse"; "Diana"; "Frank"; "Maverick"; "Larry"}
		
		if classPlayer.Properties.SpawnedPets == nil or classPlayer.Properties.SpawnedPets < 5 then
			modNpc.Spawn(namesList[math.random(1, #namesList)], classPlayer.RootPart.CFrame, function(npc, npcModule)
				npcModule.Humanoid.Name = "Pet";
				npcModule.Owner = player;
			end, require(game.ServerStorage.PrefabStorage.CustomNpcModules.PetNpcModule));
			
			classPlayer.Properties.SpawnedPets = (classPlayer.Properties.SpawnedPets or 0) + 1;
		end
		return true;
	end;
};

Commands["infammo"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Toggle infinite ammo.";
	
	RequiredArgs = 0;
	UsageInfo = "/infammo [type] [playerName]";
	Function = function(speaker, args)
		local player = speaker;
		local infType = nil;
		
		if #args >= 1 then
			infType = tonumber(args[1]) or 1;
		end
		if #args == 2 then
			local matches = modCommandHandler.MatchName(args[2]);
			if #matches > 1 then
				GenericOutputs.MultipleMatch(speaker, matches);
				return false;
			elseif #matches < 1 then
				GenericOutputs.NoMatch(speaker, args[2]);
				return false;
			else
				player = matches[1];
			end
		end
		
		if player then
			local profile = shared.modProfile:Get(player);
			
			if profile.InfAmmo ~= nil and infType == nil then
				profile.InfAmmo = nil;
				shared.Notify(player, "Disabled Infinite Ammo.", "Inform");
				if player ~= speaker then
					shared.Notify(speaker, "Disabled Infinite Ammo on "..player.Name..".", "Inform");
				end
				
			else
				if infType == nil then
					infType = 1;
				end
				profile.InfAmmo = infType;
				shared.Notify(player, "Enabled Infinite Ammo ("..profile.InfAmmo..").", "Inform");
				if player ~= speaker then
					shared.Notify(speaker, "Enabled Infinite Ammo on "..player.Name..".", "Inform");
				end
			end
			
		else
			return false;
		end
		return true;
	end;
};

local projectilesFolder = game.ReplicatedStorage.Library.Projectile;
Commands["setprojectile"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Set weapon projectile type for equipped weapon.";

	RequiredArgs = 0;
	UsageInfo = "/setprojectile [projectileId]";
	Function = function(speaker, args)
		local player = speaker;
		
		local projectileId;
		if #args == 1 then
			projectileId = args[1];
			
			if projectilesFolder:FindFirstChild(projectileId) == nil then
				local list = {};
				for _, obj in pairs(projectilesFolder:GetChildren()) do
					if obj.Name ~= "Projectile" and obj.Name ~= "template" then
						table.insert(list, obj.Name);
					end
				end
				shared.Notify(player, "Unknown projectile type. List: ".. table.concat(list, ", "), "Negative");
				return false;
			end
			
		end

		if player then
			local profile = shared.modProfile:Get(player);
			
			if profile.EquippedTools.ID == nil then
				shared.Notify(player, "Not equipping any tools.", "Negative");
				return false;
			end
			
			if profile.ActiveInventory == nil then
				shared.Notify(player, "Inventory not active.", "Negative");
				return false;
			end
			
			if projectileId == nil then
				shared.Notify(player, "Resetted custom projectile.", "Inform");
				profile.ActiveInventory:DeleteValues(profile.EquippedTools.ID, "CustomProj");
				return false;
				
			else
				profile.ActiveInventory:SetValues(profile.EquippedTools.ID, {CustomProj=projectileId});
				shared.Notify(player, "Custom projectile set to "..projectileId..".", "Inform");
				return true;
				
			end
		end
		return true;
		
	end;
};

Commands["applystatus"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Apply a status effect on yourself. Status(Case-Sensitive): FullHeal, Slowness, Stun and Dizzy.";
	
	RequiredArgs = 1;
	UsageInfo = "/applystatus statusName [parameters...]";
	Function = function(speaker, args)
		local statusName = table.remove(args, 1);
		
		if modStatusEffects[statusName] then
			modStatusEffects[statusName](speaker, unpack(args));
		else
			shared.Notify(speaker, "There is no such status effect called "..statusName..".", "Negative");
		end
		
		return true;
	end;
};

Commands["liststatuses"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "List every available statuses for players.";
	
	RequiredArgs = 0;
	UsageInfo = "/liststatuses [match]";
	Function = function(speaker, args)
		local matchString = args[1];
		local list = {};
		
		for k, v in pairs(modStatusEffects) do
			if matchString == nil or k:match(matchString) then
				table.insert(list, k);
			end
		end
		
		shared.Notify(speaker, "Status List: "..table.concat(list, ", "), "Inform");
		
		return true;
	end;
};

Commands["rolldroptable"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Roll and see what you get from the droptable.";
	
	RequiredArgs = 1;
	UsageInfo = "/rolldroptable id [amount]";
	Function = function(player, args)
		local tableId = args[1];
		local amount = tonumber(args[2]) or 1;
		
		if tableId then
			local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);
			local rewardsLib = modRewardsLibrary:Find(tableId);
			
			if rewardsLib and rewardsLib.Hidden and not HasPermissions(player, {Permission=PermissionLevel.Admin}) then
				rewardsLib = nil;
			end
			
			if rewardsLib then
				local groupRewards = {};
				
				for i=1, amount do
					local rewards = modDropRateCalculator.RollDrop(rewardsLib);
					
					for a=1, #rewards do
						local rewardInfo = rewards[a];
						
						local id = rewardInfo.ItemId or rewardInfo.Type;
						if groupRewards[id] == nil then groupRewards[id] = 0; end;
						groupRewards[id] = groupRewards[id] +1;
					end
					if #rewards <= 0 then
						groupRewards.nothing = (groupRewards.nothing or 0) + 1;
					end
				end
				shared.Notify(player, "DropTable ("..rewardsLib.Id.."):", "Inform");
				for name, count in pairs(groupRewards) do
					shared.Notify(player, name.." : ".. count, "Inform");
				end
				shared.Notify(player, "- - - - - - - - - - - - -", "Inform");
			else
				shared.Notify(player, "Drop table id, "..tableId..", does not exist.", "Negative");
			end
		else
			shared.Notify(player, "Drop table id missing.", "Negative");
		end
		
		return true;
	end;
};


Commands["pvp"] = {
	Permission = PermissionLevel.All;
	Description = "Request a player to a duel.";
	
	RequiredArgs = 1;
	UsageInfo = "/pvp playerName [damageMultiplier]";
	Function = function(speaker, args)
		local dmgMulti = tonumber(args[2]) or 1;
		
		local classPlayerSpeaker = modPlayers.Get(speaker);
		local speakerPvp = classPlayerSpeaker.Properties.Pvp;
		if speakerPvp == nil then
			classPlayerSpeaker.Properties.Pvp = {};
			speakerPvp = classPlayerSpeaker.Properties.Pvp;
		end
		
		if speakerPvp.Requesting and os.time()-speakerPvp.Requesting < 60 then
			shared.Notify(speaker, "You pvp request is on cooldown for ".. 60-(os.time()-speakerPvp.Requesting) .."s.", "Negative");
			return false;
		end
		
		local player;
		if args[1] then
			local matches = modCommandHandler.MatchName(args[1]);
			if #matches > 1 then
				GenericOutputs.MultipleMatch(speaker, matches);
				return false;
			elseif #matches < 1 then
				GenericOutputs.NoMatch(speaker, args[1]);
				return false;
			else
				player = matches[1];
			end
		end
		
		if player == speaker then
			shared.Notify(speaker, "You can't duel yourself.", "Negative"); 
			return false;
		end;
		
		if player then
			local classPlayerTarget = modPlayers.Get(player);
			local targetPvp = classPlayerTarget.Properties.Pvp;
			if targetPvp and targetPvp.InDuel == nil and targetPvp.Name == speaker.Name and os.time()-targetPvp.Requesting <= 30 then
				local players = {speaker, player};
				shared.Notify(game.Players:GetPlayers(), "A duel has broke out between "..player.Name.." and "..speaker.Name..".", "Defeated");
				for a=5, 1, -1 do
					shared.Notify(players, "The duel begins in "..a..".", "Defeated");
					wait(1);
				end
				shared.Notify(players, "The duel has begun!", "Defeated");
				targetPvp.InDuel = speaker.Name;
				speakerPvp.InDuel = player.Name;
				speakerPvp.DmgMultiplier = targetPvp.DmgMultiplier;
			else
				speakerPvp.Requesting = os.time();
				speakerPvp.Name = player.Name;
				speakerPvp.DmgMultiplier = dmgMulti;
				shared.Notify(speaker, "Requesting "..player.Name.." to a duel..\nThe request will expire in 30 seconds.\nPvp Damage Multiplier = "..dmgMulti, "Defeated");
				shared.Notify(player, speaker.Name.." is requesting you to a duel..\nType /pvp "..speaker.Name.." to start the duel.\nPvp Damage Multiplier = "..dmgMulti, "Defeated");
			end
		else
			shared.Notify(speaker, "Could not find player ("..args[1]..")..", "Negative");
		end
		return true;
	end;
};

Commands["freegold"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Get free gold.";
	
	RequiredArgs = 0;
	UsageInfo = "/freegold [amount]";
	Function = function(speaker, args)
		local profile = shared.modProfile:Get(speaker);
		local traderProfile = profile and profile.Trader;
		
		local amt = tonumber(args[1]);
		if traderProfile then
			if amt then
				traderProfile:AddGold(amt);
			else
				traderProfile:AddGold(10000);
			end
		end
		return true;
	end;
};

Commands["reservegold"] = {
	Permission = PermissionLevel.Admin;
	Description = "Check reserve gold.";

	UsageInfo = "/reservegold";
	Function = function(speaker, args)
		local profile = shared.modProfile:Get(speaker);
		local traderProfile = profile and profile.Trader;
		
		shared.Notify(speaker, "Reserve Gold: ".. traderProfile.ReserveGold, "Inform");
		
		return true;
	end;
};

Commands["repcheck"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Check a person's trading reputation.";
	
	RequiredArgs = 0;
	UsageInfo = "/repcheck [playerName]";
	Function = function(speaker, args)
		local player = speaker;
		
		if #args == 1 then
			local matches = modCommandHandler.MatchName(args[1]);
			if #matches > 1 then
				GenericOutputs.MultipleMatch(speaker, matches);
				return false;
			elseif #matches < 1 then
				GenericOutputs.NoMatch(speaker, args[1]);
				return false;
			else
				player = matches[1];
			end
		end
		
		if player then
			local profile = shared.modProfile:Get(player);
			local traderProfile = profile and profile.Trader;
			
			if traderProfile then
				shared.Notify(speaker, player.Name.." Trading Reputation: "..traderProfile:CalRep(), "Inform");
			end
		end
		return true;
	end;
};

--== Items;
Commands["give"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Give items to player.";
	
	RequiredArgs = 1;
	UsageInfo = "/give itemid [playerName] [amount] [data]";
	Info = function(speaker)
		shared.Notify(speaker, "========== /give Examples ==========", "Inform");
		shared.Notify(speaker, 'Give 5 metal scraps to yourself: /give metal 5', "Inform");
		shared.Notify(speaker, 'Give backpack with skin: /give survivorsbackpack 1 [[{"Name":"Galaxy Backpack","Values":{"ActiveSkin":"survivorsbackpackgalaxy"}}]]', "Inform");
		shared.Notify(speaker, 'Give a placable spotlight: /give placeitem 1 [[{"Values":{"PickUpItemId":"spotlight"}}]]', "Inform");
	end;
	Function = function(speaker, args)
		local player = speaker;
		local itemId = args[1];
		
		if #tostring(itemId) <= 1 then
			shared.Notify(speaker, "Unknown item id:"..itemId..".");
			return
		end;
		
		local itemLib = modItemsLibrary:Find(itemId);
		if itemLib == nil then
			local similarities = {};
			local matches = modCommandHandler.MatchStringFromList(itemId, modItemsLibrary.Library:GetKeys());
			if #matches == 1 then
				itemLib = modItemsLibrary:Find(matches[1]);
			else
				shared.Notify(speaker, "Unknown item id:"..itemId.."."..(#matches > 0 and " Similar IDs:"..table.concat(matches,", ") or " No similar matches either."), "Negative");
				return;
			end
		end
		
		local playerName = args[2];
		
		if playerName and tonumber(playerName) == nil then
			local matches = modCommandHandler.MatchName(playerName);
			if #matches == 1 then
				player = matches[1];
				
			elseif #matches > 1 then
				GenericOutputs.MultipleMatch(speaker, matches);
				return;
				
			elseif #matches < 1 then
				table.insert(args, 2, "");
			end
		else
			table.insert(args, 2, "");
		end
		
		local quantity = math.max(tonumber(args[3]) or 1, 1);
		local parsedArg4 = args[4];
		local itemData = typeof(parsedArg4) == "table" and parsedArg4 or {};
		Debugger:Log("/give>> ItemData ", itemData, " input:", args[4]);
		
		if player and itemLib then
			itemId = itemLib.Id;
			
			local profile = shared.modProfile:Get(player);
			local playerSave = profile:GetActiveSave();
			
			if profile.ActiveInventory then
				itemData.Quantity = quantity;
				
				local modStorageItem = require(game.ReplicatedStorage.Library.StorageItem);
				
				local storageItem = {ItemId=itemId; Quantity=quantity;};
				if parsedArg4 then
					storageItem = modStorageItem.new(nil, itemId, {Values=itemData;});
					storageItem.ID = profile:NewID();
				end
				
				local rPacket = profile.ActiveInventory:InsertRequest(storageItem);
				
				if rPacket.Success then
					local messageText;
					if player ~= speaker then
						messageText = "Item "..itemLib.Id.." given to "..player.Name..".";
					else
						messageText = "Recieved "..quantity.." "..itemLib.Id..".";
					end
					
					if rPacket.QuantityRemaining then
						messageText = messageText.." ".. rPacket.QuantityRemaining .." failed to be added.";
					end
					
					shared.Notify(speaker, messageText, "Reward");
					
				elseif rPacket.Failed == 1 then
					shared.Notify(speaker, "Not enough inventory space.", "Negative");

				end
				
				return;
			else
				shared.Notify(speaker, "No active inventory.", "Negative");
			end
		end
		return;
	end;
};

--== Save Data;
Commands["save"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Force a save.";
	
	RequiredArgs = 0;
	UsageInfo = "/save [playerName]";
	Function = function(speaker, args)
		local player = speaker;
		if #args == 2 then
			local matches = modCommandHandler.MatchName(args[1]);
			if #matches > 1 then
				GenericOutputs.MultipleMatch(player, matches);
				return false;
			elseif #matches < 1 then
				GenericOutputs.NoMatch(player, args[1]);
				return false;
			else
				player = matches[1];
			end
		end
		
		if player then
			local profile = shared.modProfile:Get(player)
			profile:Save(nil, true);
			
			if player ~= speaker then
				shared.Notify(speaker, "Force saved "..player.Name..".", "Reward");
			end
			shared.Notify(player, "Force saved.", "Reward");
		end
		return true;
	end;
};


Commands["printloadtimes"] = {
	Permission = PermissionLevel.Admin;
	Description = "Print load times into console.";

	RequiredArgs = 0;
	UsageInfo = "/printloadtimes";
	Function = function(speaker, args)
		Debugger.PrintLoadTimes();
		return;
	end;
};


Commands["printinv"] = {
	Permission = PermissionLevel.Admin;
	Description = "Print inventory data into console.";
	
	RequiredArgs = 0;
	UsageInfo = "/printinv";
	Function = function(speaker, args)
		local player = speaker;
		local profile = shared.modProfile:Get(player);
			
		if profile.ActiveInventory then
			Debugger:Log("ActiveInventory",profile.ActiveInventory);
		end
		return;
	end;
};

Commands["printprofile"] = {
	Permission = PermissionLevel.Admin;
	Description = "Print profile data into console.";
	
	RequiredArgs = 1;
	UsageInfo = "/printprofile name [key] [key] ...";
	Function = function(speaker, args)
		local player = speaker;
		
		local name = table.remove(args, 1);
		local matches = modCommandHandler.MatchName(name);
		if #matches > 1 then
			GenericOutputs.MultipleMatch(player, matches);
			return false;
		elseif #matches < 1 then
			GenericOutputs.NoMatch(player, name);
			return false;
		else
			player = matches[1];
		end
		
		local profile = shared.modProfile:Get(player);
		
		local dir = profile;
		local dirStr = ".";
		
		for a=1, #args do
			if profile[args[a]] then
				dir = profile[args[a]];
				dirStr = dirStr.."/"..args[a];
			else
				break;
			end
		end
		
		local encodedData
		local parseS, parseE = pcall(function()
			encodedData = HttpService:JSONEncode(dir);
		end)
		Debugger:Log("Printing",player.Name,"save:",dirStr);
		print(dir);
		return;
	end;
};

Commands["checktrust"] = {
	Permission = PermissionLevel.Admin;
	Description = "Checks trust level into console.";
	
	RequiredArgs = 1;
	UsageInfo = "/checktrust name";
	Function = function(speaker, args)
		local player = speaker;
		
		local name = table.remove(args, 1);
		local matches = modCommandHandler.MatchName(name);
		if #matches > 1 then
			GenericOutputs.MultipleMatch(player, matches);
			return false;
		elseif #matches < 1 then
			GenericOutputs.NoMatch(player, name);
			return false;
		else
			player = matches[1];
		end
		
		local profile = shared.modProfile:Get(player);
		local trustTable = profile:UpdateTrustLevel();
		
		Debugger:Log("TrustTable", trustTable);
		shared.Notify(speaker, player.Name.." Trust Level:"..(profile.TrustLevel or 0), "Inform");
		return;
	end;
};

Commands["ispremium"] = {
	Permission = PermissionLevel.All;
	Description = "Check whether someone is a Premium Member.";
	
	RequiredArgs = 0;
	UsageInfo = "/ispremium [playerName]";
	Function = function(speaker, args)
		local player = speaker;
		if #args == 1 then
			local matches = modCommandHandler.MatchName(args[1]);
			if #matches > 1 then
				GenericOutputs.MultipleMatch(player, matches);
				return false;
			elseif #matches < 1 then
				GenericOutputs.NoMatch(player, args[1]);
				return false;
			else
				player = matches[1];
			end
		end
		
		if player then
			local profile = shared.modProfile:Get(player);
			shared.Notify(speaker, player.Name.." is"..(profile.Premium and "" or " not").." Premium.", "Inform");
		end
		return true;
	end;
};

Commands["ban"] = {
	Permission = PermissionLevel.Admin;
	Description = "Bans a player.";
	
	RequiredArgs = 1;
	UsageInfo = "/ban playerName seconds";
	Function = function(speaker, args)
		local player = speaker;
		local name = args[1];
		local duration = tonumber(args[2] or 0);
		
		local matches = modCommandHandler.MatchName(args[1]);
		if #matches > 1 then
			GenericOutputs.MultipleMatch(player, matches);
			return false;
		elseif #matches < 1 then
			GenericOutputs.NoMatch(player, args[1]);
			return false;
		else
			player = matches[1];
		end
		
		if player then
			local profile = shared.modProfile:Get(player);
			profile.ShadowBan = duration;
			profile:Sync("ShadowBan");
			
			if profile.ShadowBan == -1  then
				shared.Notify(speaker, player.Name.." is permanently shadow banned.", "Inform");
				
			elseif profile.ShadowBan > 0 then
				local date = os.date("*t", profile.ShadowBan);
				shared.Notify(speaker, player.Name.." is shadow banned until "..date.day.." "..month[date.month]..", "..date.year.." ("..(date.hour > 12 and date.hour -12 or date.hour)..":"..date.min..":"..date.sec..").", "Inform");
			
			else
				shared.Notify(speaker, player.Name.." is unbanned.", "Inform");
			
			end
		end
		return true;
	end;
};

Commands["kick"] = {
	Permission = PermissionLevel.ServerOwner;
	Description = "Kick a player, player will not be able to rejoin until server re-opens. Use /unkick for undoing a kick.";
	
	RequiredArgs = 1;
	UsageInfo = "/kick playerName";
	Function = function(speaker, args)
		local player = speaker;
		local name = args[1];
		
		local matches = modCommandHandler.MatchName(args[1]);
		if #matches > 1 then
			GenericOutputs.MultipleMatch(player, matches);
			return false;
		elseif #matches < 1 then
			GenericOutputs.NoMatch(player, args[1]);
			return false;
		else
			player = matches[1];
		end
		
		if player then
			if HasPermissions(player, {Permission=PermissionLevel.Admin}) then
				player:Kick(args[2] or "You have been kicked.");
				
			else
				player:Kick("You have been kicked by the server owner.");
				
			end
			
			modServerManager.Kicked[player.Name] = true;
			shared.Notify(speaker, player.Name.." has been kicked.", "Defeated");
		end
		return true;
	end;
};

Commands["unkick"] = {
	Permission = PermissionLevel.ServerOwner;
	Description = "Unkicks a player. Use /kicklist to check who's been kicked.";
	
	RequiredArgs = 1;
	UsageInfo = "/unkick playerName";
	Function = function(speaker, args)
		local name = args[1];
		
		local matches = modCommandHandler.MatchStringFromDict(name, modServerManager.Kicked);
		if #matches > 1 then
			GenericOutputs.MultipleMatch(speaker, matches);
			return false;
		elseif #matches < 1 then
			GenericOutputs.NoMatch(speaker, args[1]);
			return false;
		else
			name = matches[1];
		end
		
		if name and modServerManager.Kicked[name] then
			modServerManager.Kicked[name] = nil;
			
			shared.Notify(speaker, name.." has been unkicked.", "Inform");
		else
			shared.Notify(speaker, "Could not find ".. tostring(name).." from kicked list.", "Negative");
		end
		return true;
	end;
};

Commands["kicklist"] = {
	Permission = PermissionLevel.ServerOwner;
	Description = "List of kicked players.";
	
	RequiredArgs = 0;
	UsageInfo = "/kicklist";
	Function = function(speaker, args)
		local empty = true;
		local list = "";
		for name, _ in pairs(modServerManager.Kicked) do
			list = list..name..", ";
			empty = false;
		end
		
		if not empty then
			local c = list:sub(1, #list-2);
			shared.Notify(speaker, "Kicked: "..c, "Inform");
		else
			shared.Notify(speaker, "Kicked list is empty.", "Inform");
		end
		
		return true;
	end;
};

Commands["setpremium"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Check whether someone is a Premium Member.";
	
	RequiredArgs = 1;
	UsageInfo = "/setpremium [playerName] boolean";
	Function = function(speaker, args)
		local player = speaker;
		local value = args[1];
		
		if #args == 2 then
			local matches = modCommandHandler.MatchName(args[1]);
			if #matches > 1 then
				GenericOutputs.MultipleMatch(player, matches);
				return false;
			elseif #matches < 1 then
				GenericOutputs.NoMatch(player, args[1]);
				return false;
			else
				player = matches[1];
				value = args[2];
			end
		end
		
		if player then
			local profile = shared.modProfile:Get(player);
			if value then
				profile:AwardPremium(true)
			else
				profile.Premium = false;
			end
			profile:Sync("Premium");
			shared.Notify(speaker, player.Name.."'s Premium status is now "..(tostring(profile.Premium))..".", "Inform");
		end
		return true;
	end;
};

Commands["addstat"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Add a stat for player.";
	
	RequiredArgs = 1;
	UsageInfo = "/addstat stat amount";
	Function = function(speaker, args)
		local player = speaker;
		local statName = args[1];
		local amount = tonumber(args[2]);
		
		if player and statName and amount then
			local targetSave = shared.modProfile:Get(player):GetActiveSave();
			targetSave:AddStat(statName, amount);
			
			shared.Notify(player, "Added "..amount.." to "..statName..".", "Reward");
		end
		return true;
	end;
};

Commands["addstatfor"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Add a stat for player.";
	
	RequiredArgs = 2;
	UsageInfo = "/addstatfor player stat amount";
	Function = function(speaker, args)
		local player = speaker;
		
		local matches = modCommandHandler.MatchName(args[1]);
		if #matches > 1 then
			GenericOutputs.MultipleMatch(player, matches);
			return false;
		elseif #matches < 1 then
			GenericOutputs.NoMatch(player, args[1]);
			return false;
		else
			player = matches[1];
		end
		
		local statName = args[2];
		local amount = tonumber(args[3]);
		
		if player and statName and amount then
			local targetSave = shared.modProfile:Get(player):GetActiveSave();
			targetSave:AddStat(statName, amount);
			
			shared.Notify(player, "Added "..amount.." to "..statName..".", "Reward");
			shared.Notify(speaker, "Added "..amount.." to "..statName.." for "..player.Name..".", "Reward");
		end
		return true;
	end;
};

Commands["addmission"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Adds mission into player's mission menu.";
	
	RequiredArgs = 1;
	UsageInfo = "/addmission [playerName] missionId";
	Function = function(speaker, args)
		local player = speaker;
		local missionId = tonumber(args[1]);
		
		if #args >= 2 then
			local matches = modCommandHandler.MatchName(args[1]);
			if #matches > 1 then
				GenericOutputs.MultipleMatch(player, matches);
				return false;
			elseif #matches < 1 then
				GenericOutputs.NoMatch(player, args[1]);
				return false;
			else
				player = matches[1];
				missionId = tonumber(args[2]);
			end
		end
		
		if player and missionId then
			local canAdd, failAddReason = modMission:CanAddMission(player, missionId);
			if canAdd then
				modMission:AddMission(player, missionId, nil, true);
				if player ~= speaker then
					shared.Notify(speaker, player.Name.."'s mission ("..missionId..") added.", "Reward");
				end
				shared.Notify(player, "Mission ("..missionId..") added.", "Reward");
			else
				shared.Notify(player, "Fail to add Mission ("..missionId.."). Reason: "..(failAddReason or "unknown"), "Negative");
			end
		end
		return true;
	end;
};

Commands["addmissionwithdata"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Adds mission into player's mission menu with data.\n    /addmissionwithdata Player1 55 [[{\"NpcName\":\"Rafael\"}]]";
	--/addmissionwithdata MXKhronos 55 [[{"NpcName":"Rafael"}]]
	
	RequiredArgs = 3;
	UsageInfo = "/addmissionwithdata playerName missionId data";
	Function = function(speaker, args)
		local matches = modCommandHandler.MatchName(args[1]);
		if #matches > 1 then
			GenericOutputs.MultipleMatch(speaker, matches);
			return false;
		elseif #matches < 1 then
			GenericOutputs.NoMatch(speaker, args[1]);
			return false;
		end
		
		local player = matches[1];
		local missionId = tonumber(args[2]);
		local mData = args[3];
		
		if player and missionId then
			local canAddS, canAddE = modMission:CanAddMission(player, missionId)
			if canAddS then
				modMission:AddMission(player, missionId, nil, true, mData);
				if player ~= speaker then
					shared.Notify(speaker, player.Name.."'s mission ("..missionId..") added.", "Reward");
				end
				shared.Notify(player, "Mission ("..missionId..") added.", "Reward");
			else
				shared.Notify(player, "Fail to add Mission ("..missionId.."). Reason: "..canAddE, "Negative");
			end
		end
		return true;
	end;
};

Commands["startmission"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Starts a mission.";
	
	RequiredArgs = 1;
	UsageInfo = "/startmission [playerName] missionId";
	Function = function(speaker, args)
		local player = speaker;
		local missionId = tonumber(args[1]);
		if #args == 2 then
			local matches = modCommandHandler.MatchName(args[1]);
			if #matches > 1 then
				GenericOutputs.MultipleMatch(player, matches);
				return false;
			elseif #matches < 1 then
				GenericOutputs.NoMatch(player, args[1]);
				return false;
			else
				player = matches[1];
				missionId = tonumber(args[2]);
			end
		end
		
		if player and missionId then
			local mission = modMission:GetMission(player, missionId);
			if mission == nil then
				modMission:AddMission(player, missionId, nil, true);
			end
			modMission:StartMission(player, missionId, nil, nil, true);
			if player ~= speaker then
				shared.Notify(speaker, player.Name.."'s mission ("..missionId..") started.", "Reward");
			end
			shared.Notify(player, "Mission ("..missionId..") started.", "Reward");
		end
		return true;
	end;
};

Commands["geteventflag"] = {
	Permission = PermissionLevel.Admin;
	Description = "Gets an event flag.";

	RequiredArgs = 2;
	UsageInfo = "/geteventflag playerName eventId";
	Function = function(speaker, args)
		local matches = modCommandHandler.MatchName(args[1]);
		if matches ~= 1 then
			if #matches > 1 then
				GenericOutputs.MultipleMatch(speaker, matches);
				return false;
			elseif #matches < 1 then
				GenericOutputs.NoMatch(speaker, args[1]);
				return false;
			end
		end

		local player = matches[1];
		local eventId = args[2];
		

		if player and eventId then
			local eventsProfile = modEvents.GetEvents(player.Name);
			local eventPacket = modEvents:GetEvent(player, eventId);

			if eventPacket == nil then
				shared.Notify(speaker, "Event ("..eventId..") does not exist for ("..player.Name..").", "Inform");
				return true;
			end

			shared.Notify(speaker, "Event ("..eventId..") for ("..player.Name..")= ".. HttpService:JSONEncode(eventPacket) , "Inform");
			Debugger:Warn("/geteventflag =", eventPacket);
		end
		return true;
	end;
};

Commands["seteventflag"] = {
	Permission = PermissionLevel.Admin;
	Description = "Sets an event flag.";
	
	RequiredArgs = 3;
	UsageInfo = "/seteventflag playerName eventId key value";
	Function = function(speaker, args)
		local matches = modCommandHandler.MatchName(args[1]);
		if matches ~= 1 then
			if #matches > 1 then
				GenericOutputs.MultipleMatch(speaker, matches);
				return false;
			elseif #matches < 1 then
				GenericOutputs.NoMatch(speaker, args[1]);
				return false;
			end
		end
		
		local player = matches[1];
		local eventId = args[2];
		local key = args[3];
		local value = args[4];
		
		if player and eventId and key then
			local eventsProfile = modEvents.GetEvents(player.Name);
			
			local indices = {};
			for a=1, #eventsProfile do
				if eventsProfile[a].Id == eventId then
					table.insert(indices, a);
				end
			end
			Debugger:Log("Duplicated indices: ", indices);
			
			local eventPacket = modEvents:GetEvent(player, eventId);
			
			if eventPacket == nil then
				shared.Notify(speaker, "Event ("..eventId..") does not exist for ("..player.Name..").", "Inform");
				shared.Notify(speaker, "Event ("..eventId..") key ("..key..")=("..tostring(value)..") added for ("..player.Name..").", "Inform");

				modEvents:NewEvent(player, {Id=eventId; [key]=value});
				return true;
			end
			
			eventPacket[key] = value;
			eventsProfile:Sync();
			shared.Notify(speaker, "Event ("..eventId..") key ("..key..") set to ("..tostring(value)..") for ("..player.Name..").", "Inform");
		end
		return true;
	end;
};

Commands["deleventflag"] = {
	Permission = PermissionLevel.Admin;
	Description = "Deletes an event flag.";
	
	RequiredArgs = 2;
	UsageInfo = "/deleventflag playerName eventId";
	Function = function(speaker, args)
		local matches = modCommandHandler.MatchName(args[1]);
		if matches ~= 1 then
			if #matches > 1 then
				GenericOutputs.MultipleMatch(speaker, matches);
				return false;
			elseif #matches < 1 then
				GenericOutputs.NoMatch(speaker, args[1]);
				return false;
			end
		end
		
		local player = matches[1];
		local eventId = args[2];
		
		if player and eventId then
			local eventPacket = modEvents:GetEvent(player, eventId);
			
			if eventPacket == nil then
				shared.Notify(speaker, "Event ("..eventId..") does not exist for ("..player.Name..").", "Inform");
				return false;
			end
			
			modEvents:RemoveEvent(player, eventId)
			shared.Notify(speaker, "Event ("..eventId..") removed for ("..player.Name..").", "Inform");
		end
		return true;
	end;
};

Commands["delmission"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Deletes mission from player's missions.";
	
	RequiredArgs = 1;
	UsageInfo = "/delmission [playerName] missionId";
	Function = function(speaker, args)
		local player = speaker;
		local missionId = tonumber(args[1]);
		if #args == 2 then
			local matches = modCommandHandler.MatchName(args[1]);
			if #matches > 1 then
				GenericOutputs.MultipleMatch(player, matches);
				return false;
			elseif #matches < 1 then
				GenericOutputs.NoMatch(player, args[1]);
				return false;
			else
				player = matches[1];
				missionId = tonumber(args[2]);
			end
		end
		
		if player and missionId then
			Debugger:Log(player, "Deleting mission ", missionId)
			local missionProfile = modMission.GetMissions(player.Name);
			local mission = modMission:GetMission(player, missionId);
			if mission == nil then
				shared.Notify(speaker, player.Name.."'s mission ("..missionId..") does not exist.", "Negative");
				return true;
			end
			missionProfile:Destroy(mission);
			missionProfile:Sync();
			
			if player ~= speaker then
				shared.Notify(speaker, player.Name.."'s mission ("..missionId..") deleted.", "Reward");
			end
			shared.Notify(player, "Mission ("..missionId..") deleted.", "Reward");
		end
		return true;
	end;
};

Commands["setmissionpoint"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Set mission's progression point.";
	
	RequiredArgs = 2;
	UsageInfo = "/setmissionpoint missionId point";
	Function = function(speaker, args)
		local player = speaker;
		local missionId = tonumber(args[1]);
		local progressionPoint = tonumber(args[2]);
		
		if player and missionId then
			modMission:Progress(player, missionId, function(mission)
				mission.ProgressionPoint = progressionPoint;
			end)
			shared.Notify(player, "Mission ("..missionId..") Progression Point set to "..progressionPoint..".", "Reward");
		end
		return true;
	end;
};

Commands["setmissionobjective"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Set mission's objective.";

	RequiredArgs = 1;
	UsageInfo = "/setmissionpoint missionId objectiveId value";
	Function = function(speaker, args)
		local player = speaker;
		local missionId = args[1];
		local objectiveId = args[2];
		local value = args[3]

		if player and missionId then
			if objectiveId == nil then
				local mission = modMission:GetMission(player, missionId);
				local objectiveIds = {};
				for objId, _ in pairs(mission.ObjectivesCompleted) do
					table.insert(objectiveIds, objId);
				end
				
				shared.Notify(player, "Mission (".. missionId ..") has objective Ids: ".. table.concat(objectiveIds, ", "), "Inform");
				
				return true;
			end	
			
			modMission:Progress(player, missionId, function(mission)
				if mission.ObjectivesCompleted[objectiveId] == nil then 
					shared.Notify(player, "Mission (".. missionId ..") does not have objectiveId "..objectiveId , "Negative");
					return 
				end;
				
				if value == nil then
					value = true;
				end
				mission.ObjectivesCompleted[objectiveId] = value;
				shared.Notify(player, "Mission ("..missionId..") Objective set to "..tostring(value)..".", "Reward");
			end)
		end
		return true;
	end;
};

Commands["failmission"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Set a mission to be failed.";

	RequiredArgs = 1;
	UsageInfo = "/failmission [playerName] missionId";
	Function = function(speaker, args)
		local player = speaker;
		local missionId = tonumber(args[1]);
		if #args == 2 then
			local matches = modCommandHandler.MatchName(args[1]);
			if #matches > 1 then
				GenericOutputs.MultipleMatch(player, matches);
				return false;
			elseif #matches < 1 then
				GenericOutputs.NoMatch(player, args[1]);
				return false;
			else
				player = matches[1];
				missionId = tonumber(args[2]);
			end
		end

		if player and missionId then
			modMission:FailMission(player, missionId, "Set failmission");

			if player ~= speaker then
				shared.Notify(speaker, player.Name.."'s mission ("..missionId..") failed.", "Reward");
			end
			shared.Notify(player, "Mission ("..missionId..") failed.", "Reward");
		end
		return true;
	end;
};

Commands["completemission"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Set a mission to be completed.";
	
	RequiredArgs = 1;
	UsageInfo = "/completemission [playerName] missionId";
	Function = function(speaker, args)
		local player = speaker;
		local missionId = tonumber(args[1]);
		if #args == 2 then
			local matches = modCommandHandler.MatchName(args[1]);
			if #matches > 1 then
				GenericOutputs.MultipleMatch(player, matches);
				return false;
			elseif #matches < 1 then
				GenericOutputs.NoMatch(player, args[1]);
				return false;
			else
				player = matches[1];
				missionId = tonumber(args[2]);
			end
		end
		
		if player and missionId then
			modMission:CompleteMission(player, missionId);
			
			if player ~= speaker then
				shared.Notify(speaker, player.Name.."'s mission ("..missionId..") completed.", "Reward");
			end
			shared.Notify(player, "Mission ("..missionId..") completed.", "Reward");
		end
		return true;
	end;
};

Commands["wipemissions"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Wipe all missions from your save.";
	
	UsageInfo = "/wipemissions";
	Function = function(speaker, args)
		local player = speaker;

		if player then
			local missionsProfile = modMission.GetMissions(player.Name);
			
			while #missionsProfile > 0 do
				local mission = missionsProfile[1];
				missionsProfile:Destroy(modMission:GetMission(player, mission.Id));
			end
			
			shared.Notify(player, "All missions wiped. Type /menu to rejoin.", "Reward");
		end
		return true;
	end;
};


Commands["resethomenpc"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Resets a safehome NPC progress.";
	
	RequiredArgs = 1;
	UsageInfo = "/resethomenpc npcName";
	Function = function(speaker, args)
		local player = speaker;
		local npcName = args[1] or "";
		
		local profile = shared.modProfile:Get(player);
		local safehomeData = profile.Safehome;

		local npcData = safehomeData:GetNpc(npcName);
		if npcData == nil then 
			shared.Notify(player, "Npc ("..npcName..") does not exist.", "Negative");
			return;
		end
		
		safehomeData.Npc[npcName] = nil;
		if modBranchConfigs.IsWorld("Safehome") then
			local survivorNpcModule = modNpc.GetPlayerNpc(player, npcName);
			if survivorNpcModule then
				Debugger.Expire(survivorNpcModule.Prefab, 0);
			end
		end
		shared.Notify(player, "Npc ("..npcName..") has been reset and removed.", "Reward");
		return true;
	end;
};




Commands["setleveloffset"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Set player's mastery level for weapon called Dummy.";
	
	RequiredArgs = 1;
	UsageInfo = "/setleveloffset [playerName] level";
	Function = function(player, args)
		local player = player;
		local level = tonumber(args[1]);
		if #args == 2 then
			local matches = modCommandHandler.MatchName(args[1]);
			if #matches > 1 then
				GenericOutputs.MultipleMatch(player, matches);
				return false;
			elseif #matches < 1 then
				GenericOutputs.NoMatch(player, args[1]);
				return false;
			else
				player = matches[1];
				level = tonumber(args[2]);
			end
		end
		
		if player and level then
			local targetSave = shared.modProfile:Get(player):GetActiveSave();
			targetSave:SetMasteries("Dummy", level);
			targetSave:CalculateLevel();
			shared.Notify(player, "Level set to "..level.." for weapon 'Dummy'.", "Reward");
		end
		return true;
	end;
};

Commands["setwlevel"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Set weapon level of weapon while holding it. Requires re-equip to update.";
	
	RequiredArgs = 1;
	UsageInfo = "/setwlevel level";
	Function = function(player, args)
		local player = player;
		local level = math.clamp(tonumber(args[1]) or 0, 0, 20);
		if #args == 2 then
			local matches = modCommandHandler.MatchName(args[1]);
			if #matches > 1 then
				GenericOutputs.MultipleMatch(player, matches);
				return false;
			elseif #matches < 1 then
				GenericOutputs.NoMatch(player, args[1]);
				return false;
			else
				player = matches[1];
				level = tonumber(args[2]);
			end
		end
		
		if player and level then
			local profile = shared.modProfile:Get(player);
			local activeSave = profile:GetActiveSave();
			local inventory = profile.ActiveInventory;
	
			local equippedTool = profile.EquippedTools.ID;
			if equippedTool == nil then
				shared.Notify(player, "You're not holding any tool.", "Negative");
				
			else
				local storageItem = inventory ~= nil and inventory:Find(equippedTool) or nil;
				if storageItem then
					inventory:SetValues(storageItem.ID, {
						EG=1;
						E=1;
						L=level;
					});
					
				else
					shared.Notify(player, "Missing storage item.", "Negative");
				end
			end
		end
		return true;
	end;
};

--Commands["checkscheduler"] = {
--	Permission = PermissionLevel.DevBranch;
--	Description = "Checks a statistic on the system scheduler.";

--	RequiredArgs = 0;
--	UsageInfo = "/checkscheduler key";
--	Function = function(speaker, args)
--		local player = speaker;
--		local key = tostring(args[1]);
		
--		if args[1] == nil then
--			for k, v in pairs(modScheduler.Script:GetAttributes()) do
--				shared.Notify(player, "Scheduler:"..k.." = "..v, "Inform");
--			end
--		else
--			shared.Notify(player, "Scheduler:"..key.." = "..modScheduler.Script:GetAttribute(key), "Inform");
--		end
--		return true;
--	end;
--};

Commands["unlockpack"] = {
	Permission = PermissionLevel.Admin;
	Description = "Unlock a color or skin pack.";
	
	RequiredArgs = 1;
	UsageInfo = "/unlockpack packid";
	Function = function(speaker, args)
		local player = speaker;
		local packName = args[1];
		
		local profile = shared.modProfile:Get(player);
		if modColorsLibrary.Packs[packName] then
			local category = "ColorPacks";
			local key = packName;
			
			if profile[category][key] == true then
				profile[category][key] = nil;
				profile:Sync(category.."/"..key);
				shared.Notify(speaker, "Re-locked (".. category..":"..key ..")", "Inform");
			else
				profile:Unlock(category, key, true); 
			end
		end
		if modSkinsLibrary.Packs[packName] then
			local category = "SkinsPacks";
			local key = packName;

			if profile[category][key] == true then
				profile[category][key] = nil;
				profile:Sync(category.."/"..key);
				shared.Notify(speaker, "Re-locked (".. category..":"..key ..")", "Inform");
				
			else
				profile:Unlock("SkinsPacks", packName, true);
			end
		end
		return true;
	end;
};

Commands["award"] = {
	Permission = PermissionLevel.Admin;
	Description = "Unlock an achievement.";
	
	RequiredArgs = 1;
	UsageInfo = "/award achievementId";
	Function = function(speaker, args)
		local player = speaker;
		local achievementId = args[1];
		
		local profile = shared.modProfile:Get(player);
		local activeSave = profile:GetActiveSave();
		
		activeSave:AwardAchievement(achievementId);
		
		return true;
	end;
};


Commands["groll"] = {
	Permission = PermissionLevel.Admin;
	Description = "Global roll rng.";
	
	RequiredArgs = 1;
	UsageInfo = "/groll key";
	Function = function(speaker, args)
		local player = speaker;
		local key = args[1];
		
		local modGlobalRandom = require(game.ServerScriptService.ServerLibrary.GlobalRandom);
		
		shared.Notify(player, key.."-Roll: "..modGlobalRandom:NextNumber(key), "Inform");
		return true;
	end;
};

Commands["settargetableentitiesconfig"] = {
	Permission = PermissionLevel.Admin;
	Description = "Adds humanoid to targetable config.";

	RequiredArgs = 1;
	UsageInfo = "/settargetableentitiesconfig key value";
	Function = function(speaker, args)
		local player = speaker;
		local key = args[1];
		local value = args[2];

		shared.Notify(player, "TargetableEntities: ".. tostring(key) .. " = ".. (value or "nil"), "Inform");
		
		local config = modConfigurations.TargetableEntities
		
		config[key] = value;
		
		modConfigurations.Set("TargetableEntities", config);
		
		return true;
	end;
};

Commands["itemvalues"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Set item values.";

	RequiredArgs = 2;
	UsageInfo = '/itemvalues storageItemID/equip valueKey value';
	Function = function(speaker, args)
		local player = speaker;
		local profile = shared.modProfile:Get(player);
		
		local storageItemID = args[1];
		
		if storageItemID == "equip" then
			storageItemID = profile and profile.EquippedTools and profile.EquippedTools.ID;
		end
		
		local valueKey = args[2];
		local valueValue = args[3];

		local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
		local storageItem, storage = modStorage.FindIdFromStorages(storageItemID, player);
		if storage then
			storage:SetValues(storageItemID, {[valueKey]=valueValue});
			shared.Notify(player, "Value set ID:"..storageItemID.." Values: "..valueKey.."="..(tostring(valueValue) or "nil")..".", "Inform");
		else
			shared.Notify(player, "Could not find storage item "..storageItemID..".", "Negative");
			
		end

		return true;
	end;
};

local modToolTweaks = require(game.ReplicatedStorage.Library.ToolTweaks);
Commands["tweak"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Set equipped item tweak.";

	UsageInfo = "/tweak [tier]";
	Function = function(speaker, args)
		local player = speaker;
		local profile = shared.modProfile:Get(player);
		
		local tier = tonumber(args[1]);
		local tweakTierTitles = tier and modToolTweaks.TierTitles[tier] or nil;
		
		if profile.ActiveInventory then
			
			local storageItemID = profile and profile.EquippedTools and profile.EquippedTools.ID;
			local itemId = profile.EquippedTools.ItemId;
			
			if profile.ActiveInventory:Find(storageItemID) then
				
				if tier == nil then
					profile.ActiveInventory:DeleteValues(storageItemID, {"Tweak"});
					shared.Notify(player, "Value set ID:"..storageItemID.." Tweak cleared.", "Inform");
					
				elseif tweakTierTitles then
					
					local traitSeed, traitGen;
					local a=0;
					repeat
						traitSeed = math.random(0, 999999);
						traitGen = modToolTweaks.LoadTrait(itemId, traitSeed);
						
						
						a = a +1;
						
						if math.fmod(a, 1000) ==0 then
							task.wait();
						end
					until traitGen.Tier == tier;
					Debugger:Log("traitGen", traitGen);
					
					profile.ActiveInventory:SetValues(storageItemID, {Tweak=traitSeed});
					shared.Notify(player, "Value set ID:"..storageItemID.." Tweak set as ("..traitGen.Title..").", "Inform");
					
				else
					shared.Notify(player, "Equipped tool can not be tweaked.", "Negative");
				end
				
				
			else
				shared.Notify(player, "Could not find an equipped tool.", "Negative");
				
			end
		end

		return true;
	end;
};


local modItemSkinWear = require(game.ReplicatedStorage.Library.ItemSkinWear);
Commands["toolcondition"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Set equipped item condition.";
	
	UsageInfo = "/toolcondition float";
	Function = function(speaker, args)
		local player = speaker;
		local profile = shared.modProfile:Get(player);

		local wearFloat = tonumber(args[1]);
		
		if profile.ActiveInventory then

			local storageItemID = profile and profile.EquippedTools and profile.EquippedTools.ID;
			local itemId = profile.EquippedTools.ItemId;

			if profile.ActiveInventory:Find(storageItemID) then

				if wearFloat == nil then
					shared.Notify(player, "Missing wear float.", "Inform");

				else
					local closestFloat, closestSeed = math.huge, 0;
					local seed, traitGen;
					local a=0;
					repeat
						seed = math.random(0, 999999);
						traitGen = modItemSkinWear.LoadFloat(itemId, seed);
						
						local dist = math.abs(traitGen.Float-wearFloat);
						if dist < closestFloat then
							closestFloat = math.abs(traitGen.Float-wearFloat);
							closestSeed = seed;
							
							if dist <= 0.01 then
								seed = closestSeed;
								Debugger:Log("Found closest at ", a);
								break;
							end
						end
						
						a = a +1;
						
						if a >= 50000 then
							seed = closestSeed;
							break;
						elseif math.fmod(a, 1000)==0 then
							
							Debugger:Log("Rolling floats so far", a);
							task.wait();
						end
						
					until a >= 50000;
					
					traitGen = modItemSkinWear.LoadFloat(itemId, seed);
					Debugger:Log("wearGen", traitGen, seed);

					profile.ActiveInventory:SetValues(storageItemID, {SkinWearId=seed});
					shared.Notify(player, "Value set ID:"..storageItemID.." similar float found.", "Inform");
					
				end


			else
				shared.Notify(player, "Could not find an equipped tool.", "Negative");

			end
		end

		return true;
	end;
};

Commands["itemunlockables"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Prints Profile.ItemUnlockables.";

	RequiredArgs = 0;
	UsageInfo = "/itemunlockables";
	Function = function(speaker, args)
		local player = speaker;
		local profile = shared.modProfile:Get(player);
		
		Debugger:Log("profile.ItemUnlockables", profile.ItemUnlockables);
		
		return true;
	end;
};

Commands["crate"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Spawns a crate.";
	
	RequiredArgs = 1;
	UsageInfo = "/crate crateId";
	Function = function(speaker, args)
		local player = speaker;
		local rootPart = player.Character.PrimaryPart;
		local crateId = args[1];
		
		local origin = rootPart.CFrame.p + rootPart.CFrame.LookVector*4.5;
		local ray = Ray.new(origin, Vector3.new(0, -16, 0));
		local hit, pos = workspace:FindPartOnRayWithWhitelist(ray, {workspace.Environment});
		
		if hit then
			local crateLib = modCrateLibrary.Get(crateId);
			if crateLib then
				local rewards = modCrates.GenerateRewards(crateId);
				if #rewards > 0 then
					local prefab = modCrates.Spawn(crateId, CFrame.new(pos), {player}, rewards);
					delay(30, function() prefab:Destroy(); end)
				end
				shared.Notify(player, crateId.." crate spawned.", "Inform");
			else
				shared.Notify(player, "Invalid crate id.", "Negative");
			end;
		else
			shared.Notify(player, "Could not hit ground.", "Negative");
		end
		
		return true;
	end;
};

Commands["setshirt"] = {
	Permission = PermissionLevel.All;
	Description = "Change Shirt";
	
	RequiredArgs = 0;
	UsageInfo = "/setshirt shirtId";
	Function = function(speaker, args)
		local profile = shared.modProfile:Get(speaker)
		
		local character = speaker.Character;
		
		local clothing = character:FindFirstChildWhichIsA("Shirt");
		if clothing == nil then
			clothing = Instance.new("Shirt");
			clothing.Name = "Shirt";
			clothing.Parent = character;
		end
		
		local shirtId = tonumber(args[1]);
		
		if shirtId == nil then
			if profile.Cache.Shirt then
				clothing.ShirtTemplate = profile.Cache.Shirt
			end
		else
			if profile.Cache.Shirt == nil then
				profile.Cache.Shirt = clothing.ShirtTemplate;
			end
			
			local productInfo = MarketplaceService:GetProductInfo(shirtId, Enum.InfoType.Asset)
			if productInfo and productInfo.AssetTypeId == 11 then
				local asset = game:GetService("InsertService"):LoadAsset(shirtId)
				clothing.ShirtTemplate = asset.Shirt.ShirtTemplate;
				asset:Destroy();
			else
				shared.Notify(speaker, "Invalid shirt id", "Inform");
			end
		end
		
		return true;
	end;
};

Commands["setpants"] = {
	Permission = PermissionLevel.All;
	Description = "Change Pants";
	
	RequiredArgs = 0;
	UsageInfo = "/setpants pantsId";
	Function = function(speaker, args)
		local profile = shared.modProfile:Get(speaker)
		
		local character = speaker.Character;
		
		local clothing = character:FindFirstChildWhichIsA("Pants");
		if clothing == nil then
			clothing = Instance.new("Pants");
			clothing.Name = "Pants";
			clothing.Parent = character;
		end
		
		local pantsId = tonumber(args[1]);
		
		if pantsId == nil then
			if profile.Cache.Pants then
				clothing.PantsTemplate = profile.Cache.Pants
			end
		else
			if profile.Cache.Pants == nil then
				profile.Cache.Pants = clothing.PantsTemplate;
			end
			
			local productInfo = MarketplaceService:GetProductInfo(pantsId, Enum.InfoType.Asset)
			if productInfo and productInfo.AssetTypeId == 12 then
				local asset = game:GetService("InsertService"):LoadAsset(pantsId)
				clothing.PantsTemplate = asset.Pants.PantsTemplate;
				asset:Destroy();
			else
				shared.Notify(speaker, "Invalid pants id", "Inform");
			end
		end
		
		return true;
	end;
};

local modEmotes = require(game.ReplicatedStorage.Library.EmotesLibrary);
Commands["npcanim"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Plays an animation of a NPC";
	
	RequiredArgs = 3;
	UsageInfo = "/npcanim \"npcName\"/id play/stop emoteId";
	Function = function(speaker, args)
		local player = speaker;
		local npcName = args[1];
		local shouldPlay = args[2] == "play";
		local emoteId = args[3];
		
		local animLib = modEmotes:Find(emoteId);
		if animLib then
			local npcModule;
			if typeof(npcName) == "number" then
				npcModule = modNpc.Get(npcName);
			end
			if workspace.Entity:FindFirstChild(npcName) then
				npcModule = modNpc.GetNpcModule(workspace.Entity[npcName]);
			end
			
			if npcModule then
				if shouldPlay then
					npcModule.PlayAnimation(emoteId);
				else
					npcModule.StopAnimation(emoteId);
				end
			else
				shared.Notify(speaker, "Could not find npcName.", "Inform");
			end
		else
			shared.Notify(speaker, "Unknown emoteId. Try: "..table.concat(modEmotes.Keys, ", "), "Inform");
		end
		
		return true;
	end;
};

local modDisguiseMechanics = require(game.ReplicatedStorage.Library.DisguiseMechanics);

Commands["disguise"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Disguise yourself, /disguise \"Dr. Deniski\"";
	
	RequiredArgs = 0;
	UsageInfo = "/disguise entityName";
	Function = function(speaker, args)
		Debugger:Log("args", args);
		
		local profile = shared.modProfile:Get(speaker)
		
		local disguiseId = args[1] or "clear";
		local disguiseLib = modDisguiseMechanics.Library:Find(disguiseId);
		
		
		if disguiseLib == nil then
			local libByName = modDisguiseMechanics.Library:FindByKeyValue("Name", disguiseId);
			if libByName then
				disguiseLib = libByName;
				disguiseId = libByName.Id;
			end
		end
		
		if disguiseLib == nil then
			local prefab = game.ServerStorage.PrefabStorage.Npc:FindFirstChild(disguiseId);
			if prefab then
				disguiseLib = modDisguiseMechanics.Library:Add{
					Id=disguiseId;
					Name=prefab.Name;
					Type="Npc";
				}
			end
		end
		
		if disguiseLib then
			modDisguiseMechanics:Disguise(speaker, disguiseId);
			--shared.Notify(speaker, "Disguised as "..disguiseLib.Id, "Inform");
			Debugger:WarnClient(speaker, "Disguised as "..disguiseLib.Id);
		else
			shared.Notify(speaker, "Invalid disguise id, if your entityName has spaces, use \"s. e.g. /disguise \"Dr. Deniski\"", "Inform");
		end
		
		return true;
	end;
};


Commands["testskin"] = {
	Permission = PermissionLevel.DevBranch;
	Description = [[
	Sets an active accessories with a custom decal id as texture. Accessories has to be equipped. Examples: 
		/testskin scraparmor rbxassetid://7021770174
	]];
	
	RequiredArgs = 1;
	UsageInfo = "/testskin itemid [decalId]";
	Function = function(speaker, args)
		local itemId = args[1];
		local decalId = args[2];
		
		
		local character = speaker.Character;
		local accessoryTable = {};
		
		for _, obj in pairs(character:GetChildren()) do
			if obj:GetAttribute("ItemId") == itemId then
				table.insert(accessoryTable, obj);
			end
		end
		
		local modItemUnlockablesLibrary = require(game.ReplicatedStorage.Library.ItemUnlockablesLibrary);
		
		if #accessoryTable > 0 then
			if decalId == nil then
				local textureId = modItemUnlockablesLibrary.UpdateTexture(accessoryTable[1])
				shared.Notify(speaker, itemId.." current texture: ".. tostring(textureId), "Inform");
				return true;
			end
			
			for a=1, #accessoryTable do
				local obj = accessoryTable[a];
				
				if obj then
					modItemUnlockablesLibrary.UpdateTexture(obj, decalId);
				end
				shared.Notify(speaker, itemId.." set texture: ".. tostring(decalId), "Inform");
				
			end
			
		else
			shared.Notify(speaker, "Could not find equipped gear with itemid:"..(itemId or "nil") , "Negative");
		end
		
		return true;
	end;
};


Commands["achieve"] = {
	Permission = PermissionLevel.Admin;
	Description = "Unlock achievement.";

	RequiredArgs = 1;
	UsageInfo = "/achieve";
	Function = function(player, args)
		local id = args[1];
		local activeSave = shared.modProfile:Get(player):GetActiveSave();
		activeSave:AwardAchievement(id);
		shared.Notify(player, "Awarding Achievement "..id..".", "Inform");

		return true;
	end;
};

Commands["isdevbranch"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Checks if engine is on dev branch mode.";
	
	RequiredArgs = 0;
	UsageInfo = "/isdevbranch";
	Function = function(player, args)
		shared.Notify(player, "CurrentBranch: ".. tostring(modBranchConfigs.CurrentBranch.Name) .."", "Inform");
		return true;
	end;
};

Commands["globalannounce"] = {
	Permission = PermissionLevel.Admin;
	Description = "Global broadcast message.";

	RequiredArgs = 1;
	UsageInfo = "/globalannounce msg";
	Function = function(speaker, args)
		local msg = table.concat(args, " ");
		
		shared.ChatService:ProccessGlobalChat("Game", "Server", msg, {Style="Announce"})
		return true;
	end;
};

Commands["poster"] = {
	Permission = PermissionLevel.Admin;
	Description = "Spawn a poster.";

	RequiredArgs = 1;
	UsageInfo = "/poster id";
	-- /poster http://www.roblox.com/asset/?id=11347301232
	Function = function(speaker, args)
		local classPlayer = modPlayers.Get(speaker);
		
		local decalId = args[1];
		
		local modPoster = require(game.ReplicatedStorage.Library.Tools.poster.Poster);
		
		local posterObject = modPoster.Spawn(classPlayer.RootPart.CFrame);
		posterObject:SetDecal(decalId);
		
		return true;
	end;
};

Commands["setredeemcode"] = {
	Permission = PermissionLevel.Admin;
	Description = "Set a redeem code.";

	RequiredArgs = 1;
	UsageInfo = "/setredeemcode code amount secs";
	Function = function(speaker, args)
		local redeemCode = args[1];
		local amount = args[2] and tonumber(args[2]);
		local secs = args[3] and tonumber(args[3])
		
		if modRedeemService:SetCode(redeemCode, amount, secs) == true then
			shared.Notify(speaker, "Redeem Codes ("..redeemCode..") set to "..amount, "Positive");	
		else
			shared.Notify(speaker, "Redeem Codes ("..redeemCode..") failed to set.", "Negative");	
		end
		return true;
	end;
};

Commands["listredeemcodes"] = {
	Permission = PermissionLevel.Admin;
	Description = "List all redeem codes.";

	RequiredArgs = 0;
	UsageInfo = "/listredeemcodes";
	Function = function(speaker, args)
		
		local list = modRedeemService:GetRedeemCodes();
		
		shared.Notify(speaker, "Redeem Codes ("..#list..")", "Inform");
		for i, data in pairs(list) do
			shared.Notify(speaker, "[".. data.key .."]: ".. data.value, "Inform");
		end
	
		return true;
	end;
};

Commands["dataclear"] = {
	Permission = PermissionLevel.Admin;
	Description = "Clears Globalstore data.";

	RequiredArgs = 2;
	UsageInfo = "/dataclear storeId storeKey";
	Function = function(player, args)
		local storeId = args[1];
		local storeKey = args[2];

		local mem = MemoryStoreService:GetSortedMap("storeId");
		mem:RemoveAsync(storeKey);
		
		shared.Notify(player, storeId..":/"..storeKey.." Cleared.", "Inform");


		return true;
	end;
};

Commands["dataset"] = {
	Permission = PermissionLevel.Admin;
	Description = "Set Globalstore data.";

	RequiredArgs = 3;
	UsageInfo = "/dataset storeId storeKey storeValue";
	Function = function(player, args)
		local storeId = args[1];
		local storeKey = args[2];
		local storeValue = args[3];
		
		if storeValue ~= nil then
			local mem = modDatabaseService:GetDatabase(storeId);
			
			local returnPacket = mem:UpdateRequest(storeKey, "default", storeValue);
			Debugger:Log("Set default(".. storeId ..":/".. storeKey ..")", returnPacket);
			
			shared.Notify(player, storeId..":/"..storeKey.." Set="..tostring(storeValue).." ("..typeof(storeValue)..")", "Inform");
		else
			shared.Notify(player, storeId..":/"..storeKey.." Failed to set as nil.", "Negative");
		end
		

		return true;
	end;
};

Commands["dataget"] = {
	Permission = PermissionLevel.Admin;
	Description = "Get Globalstore data.";

	RequiredArgs = 2;
	UsageInfo = "/dataget storeId storeKey";
	Function = function(player, args)
		local storeId = args[1];
		local storeKey = args[2];
		
		local mem = modDatabaseService:GetDatabase(storeId);
		
		local storeValue = mem:Get(storeKey);
		shared.Notify(player, Debugger:Stringify(storeId..":/"..storeKey.." Get=",Debugger:Stringify(storeValue)," ("..typeof(storeValue)..")"), "Inform")
		Debugger:Log(":Dataget",storeValue);

		return true;
	end;
};

Commands["traitroll"] = {
	Permission = PermissionLevel.Admin;
	Description = "Test trait roll.";

	RequiredArgs = 1;
	UsageInfo = "/traitroll userId";
	Function = function(player, args)
		local userId = tonumber(args[1]) or 0;
		local rolls = tonumber(args[2]) or 1;
		
		local rng = Random.new(userId);
		
		print("UserId ", userId, " rolls", rolls);
		for a=1, rolls do
			local traitId = rng:NextNumber(0, 999999);
			local random = Random.new(traitId);
			local generateTier = random:NextNumber(0, 1);
			local tier = 1;
			
			if generateTier <= 0.002 then
				tier = 6;
				print("Nekro!")
			elseif generateTier <= 0.008 then
				tier = 5;
			elseif generateTier <= 0.032 then
				tier = 4;
			elseif generateTier <= 0.166 then
				tier = 3;
			elseif generateTier <= 0.334 then
				tier = 2;
			end
			
			print(a,"tier", tier);
		end
		
		return true;
	end;
};

Commands["getrc"] = {
	Permission = PermissionLevel.Admin;
	Description = "Get RemoteConfig.";

	RequiredArgs = 0;
	UsageInfo = "/getrc key [name]";
	Function = function(speaker, args)
		local key = args[1];
		
		local player = speaker;
		local playerName = args[2];

		if playerName then
			local matches = modCommandHandler.MatchName(playerName);
			if #matches == 1 then
				player = matches[1];

			elseif #matches > 1 then
				GenericOutputs.MultipleMatch(speaker, matches);
				return;

			elseif #matches < 1 then
				table.insert(args, 2, "");
			end
		end
		
		if key == nil then
			local profile = shared.modProfile:Get(player);
			Debugger:Log("profile:GetRemoteConfigs()", profile:GetRemoteConfigs());
			return;
		end
		
		local modAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);
		
		if modAnalytics:isRemoteConfigsReady(player.UsedId) then
			shared.Notify(player, "Remote Config (".. key ..") = ".. (modAnalytics:GetRemoteConfig(player.UsedId, key) or "nil"), "Inform");
			
		else
			shared.Notify(player, "Remote Configs not ready", "Negative");
		end
		
		return true;
	end;
};

Commands["setrc"] = {
	Permission = PermissionLevel.Admin;
	Description = "Set RemoteConfig.";

	RequiredArgs = 1;
	UsageInfo = "/getrc json";
	Function = function(player, args)
		local json = args[1];

		local modAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);
		
		modAnalytics.RemoteConfigJson = json;
		modAnalytics:SyncRemoteConfigs(player);
		
		Debugger:Log("RemoteConfigJson set", json);

		return true;
	end;
};


Commands["loadmainsave"] = {
	Permission = PermissionLevel.DevBranchFree;
	Description = "Attempts to load your save from main branch.";

	RequiredArgs = 0;
	UsageInfo = "/loadmainsave"; --/loadmainsave userId (bool)devBranch
	Function = function(speaker, args)
		local player = speaker;
		local profile = shared.modProfile:Get(player);
		local userId = player.UserId;
		
		if shared.modApiService == nil then
			shared.Notify(player, "Could not fetch main save.", "Negative");
			return
		end;
		

		if #args >= 1 then
			if HasPermissions(player, {Permission = PermissionLevel.Admin}) then
				userId = args[1];
			end
		end
		
		local rawData;
		
		local dB = false;
		if #args == 2 then
			local DataStoreService = game:GetService("DataStoreService");
			local profilesDataStore = DataStoreService:GetDataStore("Profiles");
			
			rawData = HttpService:JSONDecode(profilesDataStore:GetAsync(tostring(userId)));
			dB = true;
		else
			rawData = shared.modApiService:FetchMainBranchSave(userId);
		end
		
		if typeof(rawData) == "table" then
			profile:Save(rawData, true);
			profile.SaveCooldown = os.time()+10;
			if userId ~= player.UserId then
				shared.Notify(player, (dB and "Dev branch" or "Main branch") .." userid ("..userId..") save loaded.", "Positive");
			else
				shared.Notify(player, (dB and "Dev branch" or "Main branch") .." save loaded.", "Positive");
			end
			modServerManager:Travel(player, "MainMenu");
		else
			shared.Notify(player, "No save data available.", "Negative");
		end
		
		return;
	end;
};

Commands["mockequip"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Equip/unequip any tool as a proxy.";

	RequiredArgs = 0;
	UsageInfo = "/mockequip itemid";
	Function = function(speaker, args)
		local player = speaker;
		local profile = shared.modProfile:Get(player);
		
		local itemId = args[1] or "fotlcardgame";
		
		shared.EquipmentSystem.ToolHandler(player, "equip", {MockEquip=true; ItemId=itemId});
		
		return;
	end;
};

Commands["searchaudio"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Search for available audio tracks.";

	RequiredArgs = 0;
	UsageInfo = "/searchaudio search";
	Function = function(speaker, args)
		local player = speaker;
		local searchtag = string.lower(args[1] or "");
		
		if #searchtag <= 2 then
			shared.Notify(player, "Search tags too short.", "Negative");
			return;
		end
		
		local audioList = {};
		
		for _, sound in pairs(game.ReplicatedStorage.Library.Audio:GetChildren()) do
			if string.lower(sound.Name):match(searchtag) then
				table.insert(audioList, sound.Name);
			end
		end
		

		shared.Notify(player, "Searching for audio matching (".. searchtag ..")", "Inform");
		for a=1, #audioList do
			shared.Notify(player, ""..a..": <b>".. audioList[a] .. "</b>", "Inform");
		end
		
		return;
	end;
};

Commands["playaudio"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Play audio tracks.";

	RequiredArgs = 0;
	UsageInfo = "/playaudio trackName";
	Function = function(speaker, args)
		local player = speaker;
		local trackName = args[1] or "";

		local classPlayer = modPlayers.Get(player);
		
		if game.ReplicatedStorage.Library.Audio:FindFirstChild(trackName) then
			for _, obj in pairs(classPlayer.Head:GetChildren()) do
				if obj:IsA("Sound") and obj.Name == "cmdSndTrack" then
					Debugger.Expire(obj, 0);
				end
			end
			local cmdSndTrack = modAudio.Play(trackName, classPlayer.Head);
			cmdSndTrack.Name = "cmdSndTrack";
			shared.Notify(player, "Playing track ".. trackName..".", "Inform");
		else
			shared.Notify(player, "Invalid track name.", "Negative");
		end

		return;
	end;
};

Commands["takedamage"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Take an amouth of damage.";

	RequiredArgs = 0;
	UsageInfo = "/takedamage amount";
	Function = function(speaker, args)
		local player = speaker;
		local dmg = tonumber(args[1] or 1);

		local classPlayer = modPlayers.Get(player);
		
		classPlayer:TakeDamagePackage(modDamagable.NewDamageSource{
			Damage=dmg;
			OriginPosition=classPlayer.RootPart.Position + Vector3.new(math.random(-10, 10), math.random(-10, 10), math.random(-10, 10));
		})
		
		return;
	end;
};

Commands["specialevents"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Check special events flags.";

	RequiredArgs = 0;
	UsageInfo = "/specialevents";
	Function = function(speaker, args)

		shared.Notify(speaker, "Special Events:", "Inform");
		for k, v in pairs(modConfigurations.SpecialEvent) do
			shared.Notify(speaker, k..":"..tostring(v), "Inform");
		end
		
		return true;
	end;
};

Commands["talktome"] = {
	Permission = PermissionLevel.DevBranch;
	Description = "Makes an npc manually talk to you.\nThis is for testing server-side initiated dialogue without a player interacting with the npc.";

	RequiredArgs = 1;
	UsageInfo = "/talktome npcName";
	Function = function(speaker, args)
		
		local npcModel = workspace.Entity:FindFirstChild(args[1]);
		if npcModel == nil then
			shared.Notify(speaker, "No npc found for:"..args[1], "Negative");
			return;
		end
		
		shared.OnDialogueHandler(speaker, "talk", {
			NpcModel=npcModel;
		});
		
		return true;
	end;
};



Commands["toggledebug"] = {
	Permission = PermissionLevel.Admin;
	Description = "Toggle debug attribute on scripts.";

	RequiredArgs = 0;
	UsageInfo = "/toggledebug scriptName bool";
	Function = function(speaker, args)
		local player = speaker;
		
		Debugger:Log("Args:", args);
		local scriptName = args[1];
		
		if scriptName == nil then
			shared.Notify(player, "Could not parse script name.", "Inform");
			return true;
		end
		
		local parent = game;
		
		if scriptName:sub(1,6) == "local:" then
			scriptName = scriptName:sub(7, #scriptName);
			parent = player;
		end
		
		local scriptInstance = parent:FindFirstChild(scriptName, true);
		
		if scriptInstance and (scriptInstance:IsA("Script") or scriptInstance:IsA("ModuleScript") or scriptInstance:IsA("LocalScript")) then
			local debugEnabled = scriptInstance:GetAttribute("Debug");
			
			if debugEnabled == true then
				scriptInstance:SetAttribute("Debug", false);
			else
				scriptInstance:SetAttribute("Debug", true);
			end
		end

		return;
	end;
};

Commands["dm"] = {
	Permission = PermissionLevel.All;
	Description = "Directly message a friend across servers.";

	RequiredArgs = 2;
	UsageInfo = "/dm name message";
	Function = function(speaker, args)
		local player = speaker;

		Debugger:Log("Args:", args);
		local targetName = args[1];
		local message = table.concat(args, " ", 2, #args);
		
		if targetName == player.Name then
			shared.Notify(player, tostring(targetName).." doesn't want to talk to you.", "Negative");
			return;
		end
		
		local userId;
		local getUserIdS, getUserIdE = pcall(function()
			userId = game.Players:GetUserIdFromNameAsync(targetName);
		end) if not getUserIdS then Debugger:Warn("/m failed", getUserIdE) end;
		
		if targetName == "Player1" then
			userId = -1;
		elseif targetName == "Player2" then
			userId = -2;
		end
		if userId == nil then
			shared.Notify(player, "Unknown user with the name: "..tostring(targetName), "Negative");
			return;
		end
		
		local isFriend = false;
		local checkIsFriendS, checkIsFriendE = pcall(function()
			isFriend = player:IsFriendsWith(userId);
		end)
		if RunService:IsStudio() or modBranchConfigs.CurrentBranch.Name == "Dev" or player.UserId == 16170943 then
			isFriend = true;
		end
		
		if not isFriend then
			shared.Notify(player, "You are not friends with: "..tostring(targetName), "Negative");
			return;
		end
		
		local liveProfile = shared.modProfile:GetLiveProfile(userId)
		
		if liveProfile:IsOnline() then
			local profile = shared.modProfile:Get(player);
			local activeSave = profile and profile:GetActiveSave();
			
			local message = message:sub(1, 200);
			
			local filteredResult = TextService:FilterStringAsync(message, player.UserId);
			local filtered = filteredResult:GetNonChatStringForBroadcastAsync();
			
			profile:SendMsg("Msg"..userId, {
				Request = "DirectMessage";
				SenderUserId = player.UserId;
				ReceiverUserId = userId;
				ChannelId = targetName;
				SpeakerName = player.Name;
				Text = filtered;
				Extra = {
					Dm={
						SenderUserId = player.UserId;
						SpeakerName = player.Name;
					};
					MsgTime = tostring(DateTime.now().UnixTimestampMillis);
					Style = profile.Premium and "Premium" or "Level"..(activeSave and activeSave:GetStat("Level") or 0);
				};
			})
		else
			shared.Notify(player, tostring(targetName).." is not online.", "Negative");
		end
		
		return;
	end;
};

Commands["golddata"] = {
	Permission = PermissionLevel.Admin;
	Description = "Gold data.";

	RequiredArgs = 0;
	UsageInfo = "/golddata";
	Function = function(speaker, args)
		local player = speaker;
		
		local trackingDatabase = modDatabaseService:GetDatabase("GoldBase");
		local goldSource = trackingDatabase:Get("GoldSource") or 0;
		local goldSink = trackingDatabase:Get("GoldSink") or 0;

		shared.Notify(player, "+"..goldSource.."/"..goldSink.."-  Supply: "..(goldSource-goldSink), "Inform");
		
		return;
	end;
};


Commands["liveprofile"] = {
	Permission = PermissionLevel.Admin;
	Description = "Get LiveProfile.";

	RequiredArgs = 0;
	UsageInfo = "/liveprofile [userId]";
	Function = function(speaker, args)
		local player = speaker;
		local key = args[1] or player.UserId;
		
		local liveProfile = shared.modProfile:GetLiveProfile(tostring(key));
		
		Debugger:Log("liveProfile", liveProfile);
		local unixTime = DateTime.now().UnixTimestamp;
		shared.Notify(player, "LastOnline: "..(unixTime- (liveProfile.LastOnline or unixTime+1) ).."s", "Inform");
		shared.Notify(player, "AccessCode: "..tostring(liveProfile.AccessCode), "Inform");
		shared.Notify(player, "LiveProfile: "..(HttpService:JSONEncode(liveProfile)), "Inform");

		return;
	end;
};

Commands["error"] = {
	Permission = PermissionLevel.Admin;
	Description = "Do error.";

	RequiredArgs = 0;
	UsageInfo = "/error";
	Function = function(speaker, args)
		local player = speaker;
		
		player.FakeProperty = 0;
		
		return;
	end;
};


--== Methods
local hookedCommands = {};
function CommandsLibrary:HookChatCommand(cmd, cmdLib)
	if Commands[cmd] then
		error("Attempt to hook already existing command ("..cmd..").");
	end
	
	Commands[cmd] = cmdLib;
	if cmdLib.UsageInfo == nil then
		cmdLib.UsageInfo = "/"..cmd;
	end
	
	if RunService:IsServer() then
		hookedCommands[cmd]={
			Permission=cmdLib.Permission;
			Description=cmdLib.Description;
			RequiredArgs=cmdLib.RequiredArgs;
			UsageInfo=cmdLib.UsageInfo;
		}
		
		script:SetAttribute("HookedCommands", HttpService:JSONEncode(hookedCommands));
	end
end

if RunService:IsClient() then
	local function loadServerCommands()
		local cmdsJson = script:GetAttribute("HookedCommands");
		if cmdsJson == nil or #cmdsJson <= 0 then return end;
		local serverCommands = HttpService:JSONDecode(cmdsJson);

		for k, v in pairs(serverCommands) do
			Commands[k] = v;
		end
	end
	script:GetAttributeChangedSignal("HookedCommands"):Connect(loadServerCommands);
	loadServerCommands();
end

shared.modCommandsLibrary = CommandsLibrary;
return CommandsLibrary;