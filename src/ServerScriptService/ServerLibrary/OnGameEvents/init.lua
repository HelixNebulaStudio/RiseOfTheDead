local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEventSignal = require(game.ReplicatedStorage.Library.EventSignal);
local OnGameEvents = {
	Listeners = {};
	HookedEvents = {};
};

function OnGameEvents:GetEvent(eventId)
	if self.Listeners[eventId] == nil then
		local eventHandlerModule = script:FindFirstChild(eventId);
		if eventHandlerModule == nil then Debugger:Log("There is no event handler for (",eventId,")"); return; end;
		
		self.Listeners[eventId] = require(eventHandlerModule);
	end
	return self.Listeners[eventId];
end

function OnGameEvents:ConnectEvent(eventId, func)
	if OnGameEvents.HookedEvents[eventId] == nil then
		OnGameEvents.HookedEvents[eventId] = modEventSignal.new(eventId);
	end
	return OnGameEvents.HookedEvents[eventId]:Connect(func);
end

function OnGameEvents:DisconnectEvent(eventId, func)
	if OnGameEvents.HookedEvents[eventId] then
		OnGameEvents.HookedEvents[eventId]:Disconnect(func);
	end
end

function OnGameEvents:Fire(eventId, player, ...)
	local eventListener = self:GetEvent(eventId);
	
	if eventListener then
		task.spawn(eventListener, player, ...);
	end

	if OnGameEvents.HookedEvents[eventId] then
		OnGameEvents.HookedEvents[eventId]:Fire(player, ...);
	end
end

function OnGameEvents:Invoke(eventId, player, ...)
	local eventListener = self:GetEvent(eventId);
	
	if eventListener then
		return eventListener(player, ...);
	end
end

local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));
local moddedSelf = modModEngineService:GetModule(script.Name);
if moddedSelf then
	moddedSelf:Init(OnGameEvents);
end

return OnGameEvents;