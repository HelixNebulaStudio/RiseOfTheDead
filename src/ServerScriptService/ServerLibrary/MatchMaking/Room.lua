local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modEventSignal = require(game.ReplicatedStorage.Library.EventSignal);
--==
local Room = {};
Room.__index = Room;

function Room.new()
	local meta = {
		OnPlayersChanged = modEventSignal.new("OnRoomPlayersChanged");
	};
	meta.__index = meta;
	
	local self = {
		MaxPlayers = 4;
		Players = {};
		Values = {};
	};
	
	setmetatable(self, meta);
	setmetatable(meta, Room);
	return self;
end

function Room:GetPlayer(player)
	for a=1, #self.Players do
		if self.Players[a].UserId == player.UserId then
			return self.Players[a];
		end
	end
end

function Room:SetReady(player, value)
	local playerData = self:GetPlayer(player);
	if playerData then
		playerData.Ready = value;
		self.OnPlayersChanged:Fire();
		return true;
	else
		return false;
	end
end

function Room:IsReady()
	if #self.Players <= 0 then return false end;
	for a=1, #self.Players do
		if not self.Players[a].Ready then
			return false;
		end
	end
	return true;
end

function Room:IsFull()
	return #self.Players >= self.MaxPlayers;
end

function Room:CanAddPlayer(player)
	if player == nil then Debugger:Warn("Missing player."); return "Missing Player"; end;
	if self:IsReady() then
		return "Room starting";
	elseif self:IsFull() then
		return "Is full";
	elseif self:GetPlayer(player) then
		return "Already in room";
	end
	return true;
end

function Room:ForEachPlayer(func)
	for a=1, #self.Players do
		func(self.Players[a]);
	end
end

function Room:GetInstancePlayers()
	local list = {};
	self:ForEachPlayer(function(playerData)
		table.insert(list, playerData.Instance);
	end)
	return list;
end

function Room:AddPlayer(player)
	local existingPlayer = self:GetPlayer(player);
	if self:GetPlayer(player) then return existingPlayer end;
	local data = {
		UserId = player.UserId;
		Name = player.Name;
		Ready = false;
		Instance = player;
	}
	table.insert(self.Players, data);
	
	self.OnPlayersChanged:Fire();
	return data;
end

function Room:AddPlayers(list)
	for a=1, #list do
		self:AddPlayer(list[a]);
	end
end

function Room:RemovePlayer(player)
	if player == nil then return end;
	for a=#self.Players, 1, -1 do
		if self.Players[a].UserId == player.UserId then
			table.remove(self.Players, a);
		end
	end
	self.OnPlayersChanged:Fire();
end

function Room:RemoveName(name)
	for a=#self.Players, 1, -1 do
		if self.Players[a].Name == name then
			table.remove(self.Players, a);
		end
	end
	self.OnPlayersChanged:Fire();
end

function Room:Refresh()
	for a=#self.Players, 1, -1 do
		if self.Players[a].Instance == nil or not self.Players[a].Instance:IsDescendantOf(game.Players) then
			table.remove(self.Players, a);
		end
	end
end

function Room:Destroy()
	local meta = getmetatable(self);
	for k, v in pairs(meta) do
		if k == "Prefabs" then
			for a=1, #meta[k] do
				game.Debris:AddItem(meta[k][a], 0);
			end
		elseif type(meta[k]) == "table" and meta[k].ClassName == "EventSignal" then
			meta[k]:Destroy();
		end
	end
end

return Room;
