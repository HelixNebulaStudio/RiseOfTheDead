local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local ModerationSystem = {};
ModerationSystem.__index = ModerationSystem;

local modDatabaseService = require(game.ServerScriptService.ServerLibrary.DatabaseService);

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modGameLogService = require(game.ReplicatedStorage.Library.GameLogService);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);

local moderationDatabase = modDatabaseService:GetDatabase("Moderation");

local moderationMode = 1; -- RotD=1;

local globalModerators = {16170943; 3295490081; 3409920565; 2845993902;} -- mxk, dan, hns, missingtexture
--==

function ModerationSystem:IsModerator(player)
	local userId = tostring(player.UserId);

	--local liveProfile = shared.modProfile:GetLiveProfile(userId);
	
	if table.find(globalModerators, player.UserId) ~= nil then
		return true;
	end
	
	return false;
end

local function onPlayerAdded(player)
	if ModerationSystem:IsModerator(player) then
		player:SetAttribute("IsModerator", true);
	end
end

game.Players.PlayerAdded:Connect(onPlayerAdded);


task.spawn(function()
	local modCommandHandler = require(game.ReplicatedStorage.Library.CommandHandler);
	Debugger.AwaitShared("modCommandsLibrary");

	shared.modCommandsLibrary:HookChatCommand("moderation", {
		Permission = shared.modCommandsLibrary.PermissionLevel.Moderator;
		Description = [[Server moderation commands:
		
		/moderation customizationban playerName [true/false]
		]];

		RequiredArgs = 0;
		Function = function(speaker, args)
			local action = args[1];
			
			if action == "movecheck" then
				local player = modCommandHandler.GetPlayerFromString(args[2], speaker);
				if player == nil then return end;
				
				local rPacket = shared.modAntiCheatService.InvokeClient(player, "setactive", "Terrorblade");
				local setActive = rPacket.Active == true;
				
				shared.Notify(speaker, "Player (".. player.Name ..") has movecheck set to = ".. tostring(setActive), "Inform");
				
			elseif action == "customizationban" then

				local playerName = args[2];
				local player = modCommandHandler.GetPlayerFromString(playerName, speaker);
				if player == nil then return end;

				local profile = shared.modProfile:Get(player);
				if profile == nil then return end;
				
				if args[3] ~= nil then
					local setBanned = args[3] == true;
					if setBanned then
						profile.ItemCustomizationBan = 1;
					else
						profile.ItemCustomizationBan = 0;
					end
				end
				shared.Notify(speaker, `Player ({player.Name}) [Item Customization] Ban Status: {profile.ItemCustomizationBan == 1}`, "Inform");

			else
				shared.Notify(speaker, "Unknown action for /moderation", "Negative");
				
			end
			
			return;
		end;
	});
	
end)

return ModerationSystem;
