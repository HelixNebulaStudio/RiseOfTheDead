local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Showcases = {};
Showcases.__index = Showcases;

function Showcases.new(showcaseType, parent, library)
	local showcaseObject = script:FindFirstChild(showcaseType) and require(script[showcaseType]) or nil;
	if showcaseObject == nil then return end;
	
	local new = showcaseObject.new(parent, library);
	if new == nil then return end;
	setmetatable(new, Showcases);
	return new;
end

return Showcases;
