local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
repeat task.wait(); until script.Parent.Enabled == true;

--== Variables;
local localplayer = game.Players.LocalPlayer;
local playerGui = localplayer.PlayerGui;

local squadFrame = script.Parent:WaitForChild("SquadMenu");
local squadMemberFrame = script:WaitForChild("SquadMember");
local addSquadFrame = script:WaitForChild("AddSquadFrame");


local modData = require(localplayer:WaitForChild("DataModule"));
local modSquadInterface = require(playerGui:WaitForChild("SquadInterface"));
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);

local remoteOnInvitationsUpdate = modRemotesManager:Get("OnInvitationsUpdate");
local remoteSquadSync = modRemotesManager:Get("SquadSync");

local squadConnections = {};
--== Script;
local invitationInterface = modSquadInterface.setInvitationList(squadFrame:WaitForChild("InvitationList"), script:WaitForChild("InvitationFrame"));
modSquadInterface.new(squadFrame, squadMemberFrame, {AddSquadFrame=addSquadFrame; Order=modSquadInterface.ArrangementOrder.SmallToLarge});

squadFrame.Visible = not modConfigurations.DisableSquadInterface or false;
modConfigurations.OnChanged("DisableSquadInterface", function(oldValue, value) squadFrame.Visible = value; end)

remoteOnInvitationsUpdate.OnClientEvent:Connect(function(invitations)
	if invitations ~= nil and invitationInterface then
		invitationInterface:NewInvitations(invitations);
	end
end)

remoteSquadSync.OnClientEvent:Connect(function(squad)
	modSquadInterface:Update(modData:SetSquad(squad));
end)
modSquadInterface:Update(modData.Squad);