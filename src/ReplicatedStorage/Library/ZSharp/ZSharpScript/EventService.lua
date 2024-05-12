local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local RunService = game:GetService("RunService");
local modEventService = require(game.ReplicatedStorage.Library.EventService);

--
local ZSharp = {};

function ZSharp.Load(zss, zEnv)
	local EventServiceMeta = {};
	EventServiceMeta.__index = EventServiceMeta;
	EventServiceMeta.__metatable = "The metatable is locked";
	
	
	local EventService = {};
	setmetatable(EventService, EventServiceMeta);
	EventServiceMeta.hint = "Invoking, listening and handling game events.";
	

	EventServiceMeta.hintInvoke = "Invokes event listeners.";
	EventServiceMeta.descInvoke = [[
	<b>EventService:Invoke</b>(key: <i>string</i>, invoker: <i>(Player | {Player})?</i>, ...): <i>EventPacket</i>

	@param <b>players</b>:
		[Server]: Can be nil or {Player}, if {Player} then invoke will be replicated to players with permission to listen to event.
		[Client]: Will always be replaced with LocalPlayer.

	<b>EventPacket<b>: {
        Cancelled: boolean;
        Completed: boolean;

		Player: Player?;
        Players: {[number]: Player}?;
	}
	]];
	function EventService:Invoke(key: string, players: {Player}?, ...): modEventService.EventPacket
		local sbPlayers = zss.UnSandbox(players);
		if RunService:IsServer() then
			return zss.Sandbox(modEventService:ServerInvoke(key, sbPlayers, ...));
		end
	
		if sbPlayers == nil or sbPlayers ~= game.Players.LocalPlayer then
			sbPlayers = game.Players.LocalPlayer;
		end

		if typeof(sbPlayers) == "Instance" and sbPlayers:IsA("Player") then
			return zss.Sandbox(modEventService:ClientInvoke(key, sbPlayers, ...));
		else
			error("Arguments players can only be type (Player)?.");
		end
	end


	EventServiceMeta.hintOnInvoked = "Connects a event listener.";
	EventServiceMeta.descOnInvoked = [[
	<b>EventService:OnInvoked</b>(key: <i>string</i>, func: (event: EventPacket, ...any) -> nil, position: <i>number?</i>): <i>Signal</i>
	]];
	function EventService:OnInvoked(key: string, func: (event: modEventService.EventPacket, ...any) -> nil, position: number?): () -> nil
		local function sandboxedFunc(event, ...)
			return func(event, unpack(zss.Sandbox({...}) or {}));
		end
		local signal = zss.newInstance("Signal", modEventService:OnInvoked(key, sandboxedFunc, position));
		signal.Name = `{key}#{signal.Id}`;
		return signal;
	end


	EventServiceMeta.hintListHandlers = "List all registered event handler keys.";
	EventServiceMeta.descListHandlers = [[Get a list of instances by name or matching name patterns.
	if search is false, pattern is be used to match instances name. 
	if search is true, pattern will be used in string.match to match instance names.
	<b>EventService:ListHandlers</b>(pattern: <i>string?</i>, search: boolean?): <i>{[number]: key}</i>
	]];
	function EventService:ListHandlers(pattern: string?, search: boolean?)
		local r = {};
		
		local keys = modEventService:GetHandlerKeys();
		for a=1, #keys do
			local key = keys[a];

			local add = false;
			if pattern == nil then
				add = true;
			elseif search == true and string.match(key, pattern) then
				add = true;
			elseif string.lower(key) == string.lower(pattern) then
				add = true;
			end
			
			if add then
				table.insert(r, key);
			end
		end

		table.sort(keys);
		return r;
	end
	
	zEnv.EventService = EventService;
end

return ZSharp;