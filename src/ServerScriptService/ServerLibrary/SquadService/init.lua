local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local SquadService = {};
SquadService.Squads = {};

local HttpService = game:GetService("HttpService");
local modUniversalBind = shared.modUniversalBind;
local modCommandHandler = require(game.ReplicatedStorage.Library.CommandHandler);
local modServerManager = require(game.ServerScriptService.ServerLibrary.ServerManager);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modProfile = shared.modProfile;
local modPlayers = require(game.ReplicatedStorage.Library.Players);
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local Squad = require(script:WaitForChild("Squad"))(SquadService);

local remoteSquadService = modRemotesManager:Get("SquadService");

local globalInviteCooldown = {};
local squadCache = {};

SquadService.Update = modUniversalBind.new("squad:update");
SquadService.Invite = modUniversalBind.new("squad:invite");
--== Script;
function SquadService.OnPlayerAdded(player)
	local profile = modProfile:Get(player);
	
	SquadService.ClearDeadSquads();
	if profile == nil then return end;
	if profile.ActiveSquad.Id and (profile.ActiveSquad.ExpireTick == nil or os.time()-profile.ActiveSquad.ExpireTick <= 60) then
		Debugger:Log("Active Squad available for (",player.Name,").");
		local squad = SquadService.GetSquad(profile.ActiveSquad.Id)
		if squad == nil then
			squad = Squad.new(profile.ActiveSquad);
			SquadService.Squads[squad.Id] = squad;
		end
		SquadService.Update:Fire(squad);
		squad:Update();
		delay(10,function() squad:Sync(); end);
	else
		profile.ActiveSquad = {};
	end
end

function SquadService.OnPlayerRemoving(playerInstance)
	local player = modPlayers.Get(playerInstance);
	if (player == nil or not player.IsTeleporting) and SquadService.GetSquadByPlayer(playerInstance) then
		SquadService.LeaveSquad(playerInstance);
	end
	globalInviteCooldown[playerInstance.Name] = nil;
	SquadService.ClearDeadSquads();
end

function SquadService.ClearDeadSquads()
	for id, squad in pairs(SquadService.Squads) do
		if squad.ClassName == "Squad" then
			local membersOnline = false;
			squad:LoopPlayers(function(name, data)
				if game.Players:FindFirstChild(name) then
					membersOnline = true;
					return true;
				end
			end)
			if not membersOnline then
				squad:Destroy();
			end
		else
			SquadService.Squads[id] = nil;
		end
	end
end

function Notify(player, message, messageType)
	shared.Notify(player, message, messageType);
end

function SquadService.RemoveInvitations(player)
	local profile = modProfile:Get(player);
	for a=#profile.Invitations, 1, -1 do
		local invitation = profile.Invitations[a];
		if invitation.Type == "Squad" then
			table.remove(profile.Invitations, a);
		end
	end
end

function SquadService.HasInvitation(player, leader)
	local profile = modProfile:Get(player);
	for a=#profile.Invitations, 1, -1 do
		local invitation = profile.Invitations[a];
		if invitation.Type == "Squad" and invitation.Name == leader.Name and os.time()-invitation.Time <= 20 then
			return true;
		end
		if os.time()-invitation.Time > 30 then
			table.remove(profile.Invitations, a);
		end
	end
	return false;
end

function SquadService.InvitePlayer(player, invitee)
	if invitee and invitee:IsA("Player") then
		local inviteeProfile = modProfile:Get(invitee);
		if not SquadService.HasInvitation(invitee, player) then
			local invitation = {Type="Squad"; Name=player.Name; UserId=player.UserId; Time=os.time()};
			table.insert(inviteeProfile.Invitations, invitation);
			spawn(function() inviteeProfile:OnInvitationsUpdated() end);
		end
	else
		Debugger:Warn("Invitee is invalid. (",invitee,")");
	end
end

function SquadService.GetSquad(squadId)
	return SquadService.Squads[squadId];
end

function SquadService.CreateSquad(leader, members)
	local squad = Squad.new();
	squad:SetLeader(leader);
	squad:AddMember(members);
	SquadService.Squads[squad.Id] = squad;
end

function SquadService.JoinSquad(squadId, player)
	local squad = SquadService.GetSquad(squadId);
	if squad then
		squad:LoopPlayers(function(name, data)
			if modServerManager:FindPlayerServer(name) == nil then
				squad:RemoveMember(name);
			end
		end)
		local membersCount = squad:LoopPlayers();
		if membersCount < 6 then
			squad:AddMember(player);
		else
			Notify(player, squad.Leader.."'s squad is full.", "Negative");
		end
	else
		Notify(player, "Squad does not exist.", "Negative");
	end
end

function SquadService.JoinPlayerSquad(player, leader)
	if leader and leader:IsA("Player") then
		local leaderProfile = modProfile:Get(leader);
		SquadService.RemoveInvitations(player);
		
		if leaderProfile.ActiveSquad.Id then
			--== Join squad;
			SquadService.JoinSquad(leaderProfile.ActiveSquad.Id, player);
		else
			--== Create new sqaud;
			SquadService.CreateSquad(leader, {leader, player});
		end
	else
		Debugger:Log("Attempt to join invalid target's squad");
	end
end

function SquadService.GetSquadByPlayer(player)
	local profile = modProfile:Find(player.Name);
	if profile and profile.ActiveSquad and profile.ActiveSquad.Id then
		return SquadService.GetSquad(profile.ActiveSquad.Id);
	end
end

function SquadService.LeaveSquad(player)
	local squad = SquadService.GetSquadByPlayer(player);
	if squad then
		squad:RemoveMember(player.Name);
	else
		Debugger:Log("LeaveSquad() Not in any squad");
	end
end

remoteSquadService.OnServerEvent:Connect(function(player, cmd, ...)
	if remoteSquadService:Debounce(player) then Debugger:Warn("RemoteSquadService debounced."); return end;
	if cmd == "invite" then
		local inviteeName = ...;
		if game.Players:FindFirstChild(inviteeName) then
			local inviteePlayer = game.Players[inviteeName];
			local profile = modProfile:Get(inviteePlayer);
			if profile and profile.Settings and profile.Settings.InviteFriendsOnly == 1 and not player:IsFriendsWith(inviteePlayer.UserId) then
				Notify(player, inviteeName.." can only receive invites from friends.", "Negative");
				return;
			end
			SquadService.InvitePlayer(player, inviteePlayer);
			Debugger:Log("Player (",player.Name,") Sending invitation server to, ",inviteeName);
			Notify(player, "Invitation sent to "..inviteeName, "Inform");
			
		elseif modServerManager:FindPlayerServer(inviteeName) then
			if globalInviteCooldown[player.Name] and tick()-globalInviteCooldown[player.Name] <= 5 then return end;
			globalInviteCooldown[player.Name] = tick();
			Debugger:Log("Player (",player.Name,") Sending invitation across server to, ",inviteeName);
			SquadService.Invite:Fire(player.Name, player.UserId, inviteeName, SquadService.GetSquadByPlayer(player));
			Notify(player, "Invitation sent to "..inviteeName, "Inform");
			
		else
			Debugger:Log("Player (",player.Name,") Can't send invitation server to, ",inviteeName);
			Notify(player, inviteeName.." is not available for invite.", "Negative");
		end
	elseif cmd == "join" then
		local leaderName = ...;
		if game.Players:FindFirstChild(leaderName) then
			local leader = game.Players[leaderName];
			if SquadService.HasInvitation(player, leader) then
				SquadService.JoinPlayerSquad(player, leader);
				Notify(player, "Joining "..leader.Name.."'s squad.", "Inform");
			else
				Notify(player, "Your invitation from "..leaderName.." no longer exist.", "Negative");
			end
		else
			local squadData;
			for id, squad in pairs(squadCache) do
				if squad.Members[leaderName] then
					squadData = squad;
					break;
				end
			end
			if squadData then
				Notify(player, "Joining "..leaderName.."'s squad across servers.", "Inform");
				SquadService.RemoveInvitations(player);
				SquadService.Squads[squadData.Id] = Squad.new(squadData);
				SquadService.JoinSquad(squadData.Id, player);
			else
				Notify(player, "Unable to join across servers, squad data not available.", "Negative");
			end
		end
		SquadService.RemoveInvitations(player);
	elseif cmd == "leave" then
		local squad = SquadService.GetSquadByPlayer(player);
		if squad then
			SquadService.LeaveSquad(player);
			Notify(player, "You have left the squad.", "Inform");
		else
			Notify(player, "You are not in any squad.", "Negative");
		end
	end
end)

SquadService.Update.Event:Connect(function(squadData)
	squadData = squadData or {};
	if squadData.Id then
		local squad = SquadService.GetSquad(squadData.Id);
		if squad then
			squad:Update(squadData);
		end
	end
end)

SquadService.Invite.Event:Connect(function(senderName, senderId, inviteeName, squadData)
	local player = game.Players:FindFirstChild(inviteeName);
	if player then
		Debugger:Log("Player (",inviteeName,") recieved invitation across server from,",senderName);
		SquadService.InvitePlayer({Name=senderName; UserId=senderId}, player);
		if squadData ~= nil then
			squadCache[squadData.Id] = squadData;
		end
	end
end)

return SquadService;