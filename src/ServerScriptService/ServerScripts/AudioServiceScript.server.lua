local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
repeat task.wait() until shared.MasterScriptInit == true;

--== Variables;
local SoundService = game:GetService("SoundService");

local players = game.Players;
local audioModule = game.ReplicatedStorage.Library:FindFirstChild("Audio");
local dirRemotes = game.ReplicatedStorage:FindFirstChild("Remotes");
local serviceRemotes = script:WaitForChild("Remotes");

local remotePlayAudio = serviceRemotes:WaitForChild("PlayAudio");
local remoteStopAudio = serviceRemotes:WaitForChild("StopAudio");
-- Script;
if dirRemotes ~= nil then
	local remotes = serviceRemotes:GetChildren();
	for a=1, #remotes do
		remotes[a].Parent = dirRemotes;
	end
else
	serviceRemotes.Parent = game.ReplicatedStorage;
end

remotePlayAudio.OnServerEvent:Connect(function(client, audio, audioParent, pitch, volume)
	if audio == nil then return end;
	if audioParent == nil then return end;
	
	local playersList = players:GetPlayers();
	for a=1, #playersList do
		local player = playersList[a];
		if player ~= client and player:IsDescendantOf(game.Players) then
			remotePlayAudio:FireClient(player, audio, audioParent, pitch, volume);
		end
	end
end)

if audioModule ~= nil then require(audioModule) end;