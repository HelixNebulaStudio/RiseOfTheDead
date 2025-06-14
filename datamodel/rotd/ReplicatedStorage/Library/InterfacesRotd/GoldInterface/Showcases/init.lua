local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Showcases = {};
Showcases.__index = Showcases;

function Showcases.new(showcaseType, interface, parent, library)
	local showcaseObject = script:FindFirstChild(showcaseType) and shared.require(script[showcaseType]) or nil;
	if showcaseObject == nil then return end;
	
	local new = showcaseObject.new(interface, parent, library);
	setmetatable(new, Showcases);
	return new;
end

return Showcases;