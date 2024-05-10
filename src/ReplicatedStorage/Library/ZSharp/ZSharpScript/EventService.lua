local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local modEventService = require(game.ReplicatedStorage.Library.EventService);

--
local ZSharp = {};

function ZSharp.Load(zSS, zEnv)
	local EventServiceMeta = {};
	EventServiceMeta.__index = EventServiceMeta;
	EventServiceMeta.__metatable = "The metatable is locked";
	
	
	local EventService = {};
	setmetatable(EventService, EventServiceMeta);
	

	EventServiceMeta.hintInvoke = "Invokes event listeners.";
	EventServiceMeta.descInvoke = [[
	<b>EventService:Invoke</b>(key: <i>string</i>, ...) -> nil, position: <i>number?</i>): <i>EventPacket</i>

	<b>EventPacket<b>: {
        Cancelled: boolean;
        Completed: boolean;
        Players: {[number]: Player};
	}
	]];
	function EventService:Invoke(key: string, ...): modEventService.EventPacket
		return zSS.Sandbox(modEventService:Invoke(key, ...));
	end


	EventServiceMeta.hintOnInvoked = "Connects a event listener.";
	EventServiceMeta.descOnInvoked = [[
	<b>EventService:OnInvoked</b>(key: <i>string</i>, func: (event: EventPacket, ...any) -> nil, position: <i>number?</i>): <i>() -> nil</i>
	]];
	function EventService:OnInvoked(key: string, func: (event: modEventService.EventPacket, ...any) -> nil, position: number?): () -> nil
		return zSS.Sandbox(modEventService:OnInvoked(key, zSS.Sandbox(func), position), "ZSignal");
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