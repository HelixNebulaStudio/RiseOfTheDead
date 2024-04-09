local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Events = {};
--== Variables;
local RunService = game:GetService("RunService");

local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modMissionLibrary = require(game.ReplicatedStorage.Library.MissionLibrary);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);

local remotePlayerDataSync = modRemotesManager:Get("PlayerDataSync");

--== Script;
function Events.GetEvents(playerName)
	local timeout = tick();
	local eventSave;
	
	local player = game.Players:FindFirstChild(playerName);
	while game.Players:IsAncestorOf(player) do
		local profile = shared.modProfile.GetByName(playerName);
		local activeSave = profile and profile:GetActiveSave();
		eventSave = activeSave and activeSave.Events;
		task.wait();
		
		if eventSave then
			break;
		end
		if tick()-timeout >= 10 then
			break;
		end
	end
	if tick()-timeout >= 10 then Debugger:Warn("GetEvents timed-out for player(",playerName,")"); end
	
	return eventSave;
end

function Events:GetEvent(player, eventId)
	if player == nil then return end;
	local eventsProfile = self.GetEvents(player.Name);
	if eventsProfile == nil then return end;
	
	return eventsProfile:Get(eventId);
end

function Events:NewEvent(player, eventData, sync)
	if player == nil then return end;
	local eventsProfile = self.GetEvents(player.Name);
	if eventsProfile == nil then Debugger:Warn("Events (",player.Name,") event profile doesn't exist."); return end;
	eventsProfile:Add(eventData);
	
	if sync == true then
		eventsProfile:Sync("syncevent", eventData);
	end
	return eventData;
end

function Events:RemoveEvent(player, eventId, sync)
	if player == nil then return end;
	local eventsProfile = self.GetEvents(player.Name);
	if eventsProfile == nil then Debugger:Warn("Events (",player.Name,") event profile doesn't exist."); return end;
	eventsProfile:Remove(eventId);
	
	if sync == true then
		eventsProfile:Sync("destroyevent", eventId);
	end
end

function Events:SyncEvent(player, eventId)
	if player == nil then return end;
	local eventsProfile = self.GetEvents(player.Name);
	if eventsProfile == nil then Debugger:Warn("Events (",player.Name,") event profile doesn't exist."); return end;

	eventsProfile:Sync("syncevent", eventsProfile:Get(eventId));
end

function Events.new(player)
	local eventsMeta = {};
	eventsMeta.__index = eventsMeta;
	eventsMeta.Player = player;
	eventsMeta.Sync = function(self, action, data)
		if RunService:IsStudio() then
			if action == "syncevent" then
				Debugger:Warn("[Studio] Profile Sync Event: ", data.Id, "(",modRemotesManager.PacketSizeCounter.GetPacketSize{PacketData={data};},")");
				
			elseif action == "destroyevent" then
				Debugger:Warn("[Studio] Profile Destroy Event: ", data, "(",modRemotesManager.PacketSizeCounter.GetPacketSize{PacketData={data};},")");
				
			end
		end
		
		remotePlayerDataSync:Fire(player, {
			[modRemotesManager.Ref("Action")] = action;
			[modRemotesManager.Ref("Data")] = data;
		})
	end;
	
	local events = setmetatable({}, eventsMeta);
	
	local function NewEvent(input)
		if input.Id == nil then error("Events>>  Missing event id.") return end;
		
		if input.Id == "getfreepistolautomod" then
			input.Id = "sundaysGift";
		elseif input.Id == "" then
			input.Id = "sundaysGift";
		end
		
		local eventObject = {Id=input.Id;}
		for k, v in next, (input or {}) do
			if k ~= "Id" then
				eventObject[k]=v;
			end
		end
		return eventObject;
	end

	function eventsMeta:Get(id)
		for a=1, #self do
			if self[a].Id == id then
				return self[a], a;
			end
		end
	end
	function eventsMeta:Add(data)
		self:Remove(data.Id);
		table.insert(events, NewEvent(data));
	end
	
	function eventsMeta:Remove(id)
		for a=#events, 1, -1 do
			if events[a].Id == id then
				table.remove(events, a);
			end
		end
	end
	
	function eventsMeta:Load(rawData)
		for k, v in pairs(rawData or {}) do
			local loadEvent = NewEvent(v);
			if loadEvent then
				table.insert(events, loadEvent);
				spawn(function()
					if loadEvent.Script then
						local module = script:FindFirstChild(loadEvent.Script);
						if module then require(module)(loadEvent); end
					end
				end);
			end
			
		end
		return self;
	end
	
	return events;
end

return Events;