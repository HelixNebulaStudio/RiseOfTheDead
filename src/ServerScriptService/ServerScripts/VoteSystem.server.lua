local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local HttpService = game:GetService("HttpService");

repeat task.wait() until shared.MasterScriptInit == true;
while shared.modProfile == nil do task.wait(0.1); end
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modDatabaseService = require(game.ServerScriptService.ServerLibrary.DatabaseService);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);

local remoteVoteSystem = modRemotesManager:Get("VoteSystem");

--==VoteKey
local VoteSystem  = {};
VoteSystem.__index = VoteSystem;

VoteSystem.Library = {
	["sfc"]={
		Active=false;
		Choices={
			{Id="fov"; Title="Flames Of Vengeance";};
			{Id="aoth"; Title="Attack Of The Horde";};
			{Id="eoup"; Title="Echoes Of Our Past";};
			{Id="jd"; Title="Jesse's Duty";};
			{Id="za"; Title="Zomborg Analysis";};
			
			{Id="sz"; Title="Sector Zymolytic";};
			{Id="ci"; Title="Chaotic Interview";};
			{Id="mba"; Title="Mason's Bizarre Adventure";};
			{Id="nti"; Title="Nick's Trapped Insanity";};
			{Id="amg"; Title="A Medical Greyzone";};
			
			{Id="sp"; Title="Suspicious Person";};
			{Id="thu"; Title="The Harbor Update";};
			{Id="tlf"; Title="The Lost Files";};
			{Id="yolo"; Title="You Only Live Once";};
		};
		EndTimeEpoch=1648728000;
	};
	["sfc23"]={
		Active=true;
		Choices={
			{Id="exo"; Title="Exodus";};
			{Id="wdlh"; Title="Wrighton Dale's Last Hope";};
			{Id="tzp"; Title="The Zricera Problem";};
			{Id="tht"; Title="The Hidden Truth";};
			{Id="tlgr"; Title="The Last Genesis Run";};
			
			{Id="aftlo"; Title="Adventure for The Last One";};
			{Id="tdmbha"; Title="The Day Mason Broke His ###";};
			{Id="li"; Title="Last Infector";};
			{Id="tf"; Title="The Factions";};
			{Id="ba"; Title="Breathe Again";};
		};
		EndTimeEpoch=1682899200;
	};
}

VoteSystem.Mem = modDatabaseService:GetDatabase("VoteSystem");

VoteSystem.Mem:OnUpdateRequest("submitvote", function(requestPacket)
	local oldData = requestPacket.RawData;
	local inputValues = requestPacket.Values;
	
	local userId = inputValues.UserId;
	local voteId = inputValues.VoteId;
	local updateVote = inputValues.UpdateVote == true;
	
	local data = {};
	if oldData then
		data = HttpService:JSONDecode(oldData);
	end

	if data[voteId] == nil then
		data[voteId] = {};
	end

	local alreadyVoted = false;

	for _, list in pairs(data) do
		local fIndex = table.find(list, userId);
		if fIndex then
			if updateVote then
				table.remove(list, fIndex);
			else
				alreadyVoted = true;
				break;
			end
		end
	end

	if not alreadyVoted then
		table.insert(data[voteId], userId);
	end

	return HttpService:JSONEncode(data);
end);

--==
local votesCache = {};
function VoteSystem:GetPolls(voteKey)
	local voteLib = VoteSystem.Library[voteKey];
	
	if voteLib and voteLib.Active then
		local rawData = VoteSystem.Mem:Get(voteKey);
		local pollsData = rawData and HttpService:JSONDecode(rawData) or {};
		
		local displayPoll = {};
		
		for id, voters in pairs(pollsData) do
			local voteCount = #voters;
			
			if votesCache[id] == nil or voteCount > votesCache[id] then
				votesCache[id] = voteCount;
			end
			table.insert(displayPoll, {Id=id; Count=math.max(votesCache[id], voteCount);});
		end
		
		table.sort(displayPoll, function(a, b)
			return a.Count > b.Count;
		end)
		
		return displayPoll;
	end
end

function VoteSystem:IsVoteEnded(voteKey)
	local voteLib = VoteSystem.Library[voteKey];
	
	if os.time()-voteLib.EndTimeEpoch >= 0 then
		return true;
	end
	return false;
end

function VoteSystem:Vote(player, voteKey, voteId, updateVote)
	if self:IsVoteEnded(voteKey) then Debugger:Warn("Vote ended"); return false end;
	local voteLib = VoteSystem.Library[voteKey];
	
	local choiceExist = false;
	for a=1, #voteLib.Choices do
		if voteLib.Choices[a].Id == voteId then
			choiceExist = true;
		end
	end
	
	if voteLib and choiceExist then
		self.Mem:UpdateRequest(voteKey, "submitvote", {
			VoteId=voteId;
			UserId=player.UserId;
			UpdateVote=updateVote;
		});
		shared.Notify(player, "Your vote has been submitted! The polls will update shortly.", "Inform");
		
		return true;
	else
		Debugger:Warn("Unknown vote:", voteKey, " id:", voteId);
	end
end

local function isOP(player)
	return player.UserId == 16170943 or player.UserId <= 0;
end

function remoteVoteSystem.OnServerInvoke(player, paramPacket)
	if remoteVoteSystem:Debounce(player) then return {Failed="Try again later.."} end;
	
	if modBranchConfigs.CurrentBranch.Name == "Dev" and not RunService:IsStudio() then
		return {Failed="Try again.."};
	end
	
	local profile = shared.modProfile:Get(player);
	local isEligible = profile and profile.TrustLevel >= 50 or false;
	if not isEligible then return {Failed="Not eligible"}; end;
	
	local voteKey = paramPacket.VoteKey;
	local voteId = paramPacket.VoteId;
	local voteFlag = profile.Flags:Get("vote:"..voteKey) or {Id="vote:"..voteKey;};
	
	if paramPacket.Action == "submit" and voteKey and voteId then
		if VoteSystem:IsVoteEnded(voteKey) then
			return {Failed="The vote ended."};
		end
		
		if voteFlag.Value == nil then
			local success = VoteSystem:Vote(player, voteKey, voteId, voteFlag.Value == nil);
			if success then
				voteFlag.Value = voteId;
				profile.Flags:Add(voteFlag);
				return {Success=true};
			end
			
		else
			return {Failed="You already voted."};
		end
	
	elseif paramPacket.Action == "get" then
		local polls = VoteSystem:GetPolls(paramPacket.VoteKey);
		
		return {
			Polls=polls;
			PlayerVote=voteFlag;
			VoteEnded=VoteSystem:IsVoteEnded(voteKey);
		};
	end
	
	return {Failed="Try again.."};
end


















--if true then return end; ------- Disable test vote
local modDropRateCalculator = require(game.ReplicatedStorage.Library.DropRateCalculator);

local function OnPlayerAdded(player)
	if not modBranchConfigs.IsWorld("MainMenu") then return end;
	local voteKey = modGlobalVars.VoteKey;
	
	if voteKey == nil then return end;
	
	local testVoteEnabled = VoteSystem.Mem:Get("TestVote");
	if testVoteEnabled ~= true then
		return;
	end
	
	local profile = shared.modProfile:Get(player);
	if profile and profile.TrustLevel >= 15 then
		
		local voteFlag = profile.Flags:Get("vote:"..voteKey);
		
		if voteFlag == nil then
			profile.Flags:Add({Id="vote:"..voteKey;});
			
			local choice = "exo";
			local voteLib = VoteSystem.Library[voteKey];
			
			local roll = modDropRateCalculator.RollDrop({
				Id=voteKey;
				Rewards={
					{Choice="tzp"; Chance=1/1};
					{Choice="wdlh"; Chance=1/1};
					{Choice="tht"; Chance=1/1};
					{Choice="exo"; Chance=1/1.3};
					{Choice="tlgr"; Chance=1/1.5};

					{Choice="aftlo"; Chance=1/1.5};
					{Choice="tdmbha"; Chance=1/1.6};
					{Choice="ba"; Chance=1/1.6};
					{Choice="li"; Chance=1/2};
					{Choice="tf"; Chance=1/5};
					
					--{Choice="yolo"; Chance=1/6.2};
					--{Choice="tlf"; Chance=1/6.6};
					--{Choice="jd"; Chance=1/6.7};
					--{Choice="thu"; Chance=1/6.8};
				};
			}, "Global")
			
			if roll and #roll > 0 then
				local choice = roll[1].Choice;
				
				Debugger:Warn("choice", choice);
				VoteSystem:Vote(player, voteKey, choice);
			end
		else
			Debugger:Warn("voteflag ", voteFlag);
		end
	end
	
end


local modEngineCore = require(game.ReplicatedStorage.EngineCore);
modEngineCore:ConnectOnPlayerAdded(script, OnPlayerAdded);

--for _, player in pairs(game.Players:GetPlayers()) do
--	onPlayerAdded(player);
--end
--game.Players.PlayerAdded:Connect(onPlayerAdded)