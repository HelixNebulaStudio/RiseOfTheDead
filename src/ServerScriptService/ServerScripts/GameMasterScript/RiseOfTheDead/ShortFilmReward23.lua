local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Sfc = {}

local Rewards = {
	First={Index=3;};
	Second={Index=2;};
	Others={Index=1;};
};

local participantIds = {
	--exo
	{UserId=86976526; Reward=Rewards.First};
	{UserId=568638188; Reward=Rewards.First};
	{UserId=993577280; Reward=Rewards.First};
	{UserId=679635342; Reward=Rewards.First};
	{UserId=684362868;}; -- lamp
	{UserId=572465429;}; -- chickens
	
	--wdlh
	{UserId=10139379; Reward=Rewards.Second;};
	{UserId=3680031868; Reward=Rewards.Second;};
	
	--tzp
	{UserId=2728557666; Reward=Rewards.Others;};
	
	--tht
	{UserId=439750975; Reward=Rewards.Others;};
	{UserId=158138984; Reward=Rewards.Others;};
	
	--tlgr
	{UserId=117392244; Reward=Rewards.Others;};
	{UserId=568019124; Reward=Rewards.Others;};
	{UserId=1135992932; Reward=Rewards.Others;};
	
	--tdmbha
	{UserId=1713374359;};

	--li
	{UserId=1300846062;};
	{UserId=151605822;};
	{UserId=558708066;};
	
	--aftlo
	{UserId=430432281;};
	{UserId=115051350;};
	{UserId=72528785;};
	{UserId=180965009;};

	--tf
	{UserId=62718;};
	
	--ba
	{UserId=2919565708;};
	{UserId=1539057250;};
	{UserId=1435641047;};
	{UserId=1431874104;};
	{UserId=1471707187;};
	{UserId=91780720;};
	
	{UserId=16170943; Reward=Rewards.First;};
}

function GetParticipantData(playerId)
	local isParticipant = nil;
	for a=1, #participantIds do
		if participantIds[a].UserId == playerId then
			isParticipant = participantIds[a]
			break;
		end
	end
	
	return isParticipant;
end

task.spawn(function()
	local modCommandHandler = require(game.ReplicatedStorage.Library.CommandHandler);
	
	local cmdId = "claimshortfilm23reward";
	
	Debugger.AwaitShared("modCommandsLibrary");
	shared.modCommandsLibrary:HookChatCommand(cmdId, {
		Permission = shared.modCommandsLibrary.PermissionLevel.All;

		RequiredArgs = 0;
		UsageInfo = "/"..cmdId;
		Function = function(player, args)
			local playerId = player.UserId;
			local profile = shared.modProfile:Get(player);
			local playerSave = profile:GetActiveSave();
			local inventory = profile.ActiveInventory;
			
			local participantData = GetParticipantData(playerId);
			
			if participantData then
				local claimFlag = profile.Flags:Get(cmdId);
				if claimFlag ~= nil then
					shared.Notify(player, "You have already claimed your rewards.", "Negative");
					return true;
				end
				
				if participantData.Reward then
					local hasSpace = inventory:SpaceCheck{{ItemId="machete"}};
					if hasSpace == false then
						shared.Notify(player, "Insufficient Inventory Space.", "Negative");
						return;
					end
					profile.Flags:Add({Id=cmdId});
					
					local index = participantData.Reward.Index;
					if playerId == 16170943 and tonumber(args[1]) then
						index = tonumber(args[1]);
						Debugger:Warn("Set reward to ", args[1]);
					end
					
					if index == 1 then
						local itemValues = {
							ItemUnlock="highvisjacketgalaxy";
							SkinLocked=true;
						};
						inventory:Add("highvisjacket", {Values=itemValues}, function(event, insert)
							shared.Notify(player, "You received a High Visibility Jacket Galaxy.", "Reward");
						end);
						
					elseif index == 2 then
						local itemValues = {
							ItemUnlock="dufflebaggalaxy";
							SkinLocked=true;
						};
						inventory:Add("dufflebag", {Values=itemValues}, function(event, insert)
							shared.Notify(player, "You received a Duffle Bag Galaxy.", "Reward");
						end);
						
						
					elseif index == 3 then
						local itemValues = {
							ActiveSkin=104;
							SkinWearId=568833;
						};
						inventory:Add("rusty48", {Values=itemValues}, function(event, insert)
							shared.Notify(player, "You received a Galaxy Rusty48.", "Reward");
						end);
						
					end
					
					
				else
					profile.Flags:Add({Id=cmdId});
					
				end
				
				shared.Notify(player, "Claiming rewards..", "Inform");
				playerSave:AwardAchievement("2023film", true);
				
				
			else
				shared.Notify(player, "There isn't any rewards for your account.", "Negative");
				
			end

			return true;
		end;
	});

end)

return Sfc;
