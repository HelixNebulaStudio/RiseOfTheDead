local SquadService;
local Squad = {};

--== Services;
local HttpService = game:GetService("HttpService");
local Players = game:GetService("Players");

local modProfile = shared.modProfile;
local modEventSignal = require(game.ReplicatedStorage.Library.EventSignal);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modServerManager = require(game.ServerScriptService.ServerLibrary.ServerManager);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local remoteSquadSync = modRemotesManager:Get("SquadSync");

local squadColors = {"Orange"; "Yellow"; "Green"; "Blue"; "Purple"; "Pink";};
--== Script;
function Squad.new(data)
	data = data or {};
	
	local meta = {};
	meta.__index = meta;
	meta.ClassName = "Squad";
	meta.OnChanged = modEventSignal.new("OnSquadChanged");
	
	local squad = setmetatable({}, meta);
	squad.Id = data.Id or HttpService:GenerateGUID(false);
	squad.Members = data.Members or {};
	squad.Leader = data.Leader or nil;
	
	local function getRandomColor()
		local colors = {};
		for a=1, #squadColors do
			local found = false;
			for _, d in pairs(squad.Members) do
				if d.Color == squadColors[a] then found = true; break; end;
			end
			if not found then table.insert(colors, squadColors[a]); end;
		end
		return #colors > 0 and colors[math.random(1, #colors)] or squadColors[math.random(1, #squadColors)];
	end
	
	function meta:Update()
		for name, memberData in pairs(self.Members) do
			local playerInstance = game.Players:FindFirstChild(name);
			local placeId, jobId = game.PlaceId, game.JobId;
			if playerInstance == nil then
				placeId, jobId = modServerManager:FindPlayerServer(name);
			end
			local worldName = placeId and modBranchConfigs.GetWorldName(placeId) or nil;
			if worldName then
				self.Members[name].World = worldName;
			end
		end
	end
	
	function meta:SetLeader(player)
		self.Leader = player.Name;
		local profile = modProfile:Find(self.Leader);
		if profile then
			profile.ActiveSquad = self;
		end
		self:Sync();
		meta.OnChanged:Fire("Leader");
	end
	
	function meta:GetLeader()
		if self.Leader == nil or self.Members[self.Leader] == nil then
			if next(self.Members) then
				self.Leader = (next(self.Members));
				meta.OnChanged:Fire("Leader");
			end
		end
		return self.Members[self.Leader];
	end
	
	function meta:AddMember(members)
		members = type(members) == "table" and members or {members};
		for a=1, #members do
			self.Members[members[a].Name] = {UserId=members[a].UserId; Color=getRandomColor();};
			local profile = modProfile:Find(members[a].Name);
			if profile then
				self.Members[members[a].Name].Premium = profile.Premium;
				if profile.ActiveSquad.Id then
					local prevSquad = SquadService.GetSquad(profile.ActiveSquad.Id);
					if prevSquad then
						prevSquad:RemoveMember(members[a].Name);
					end
				end
				profile.ActiveSquad = self;
			end
		end
		self:LoopPlayers(function(name,data)
			local profile = modProfile:Find(name);
			if profile then
				if profile.ActiveSquad.Id ~= self.Id then
					self:RemoveMember(name);
				end
			end
		end)
		self:Sync();
		meta.OnChanged:Fire("Members");
	end
	
	function meta:RemoveMember(name)
		self.Members[name] = nil;
		if self:LoopPlayers() > 1 then
			self:GetLeader();
		else
			self:Destroy();
		end
		local profile = modProfile:Find(name);
		if profile then
			profile.ActiveSquad = {};
		end
		if game.Players:FindFirstChild(name) then
			remoteSquadSync:FireClient(game.Players[name], nil);
		end
		self:Sync();
		meta.OnChanged:Fire("Members");
	end
	
	function meta:LoopPlayers(callback)
		local c=0;
		for name, data in pairs(self.Members) do
			if callback then
				local r = callback(name, data);
				if r ~= nil then break; end;
			end
			c=c+1;
		end
		return c;
	end
	
	function meta:Destroy()
		self:LoopPlayers(function(name, data)
			local profile = modProfile:Find(name);
			if profile then
				profile.ActiveSquad = {};
			end
		end)
		meta.OnChanged:Destroy();
		SquadService.Squads[self.Id] = nil;
		
		self:LoopPlayers(function(name)
			if game.Players:FindFirstChild(name) then
				remoteSquadSync:FireClient(game.Players[name], nil);
			end
		end)
		self = nil;
	end
	
	function meta:Sync()
		self:Update();
		self:LoopPlayers(function(name)
			if game.Players:FindFirstChild(name) then
				remoteSquadSync:FireClient(game.Players[name], self);
			end
		end)
	end
	
	return squad;
end

return function(squadService)
	SquadService = squadService;
	return Squad;
end;
