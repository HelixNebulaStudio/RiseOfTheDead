local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--

--
local ZSharp = {};

function ZSharp.Load(zSS, zEnv)
	local TemplateMeta = {};
	TemplateMeta.__index = TemplateMeta;
	TemplateMeta.__metatable = "The metatable is locked";
	
	TemplateMeta.hintFunc = "Hint of the function.";
	TemplateMeta.descFunc = [[Description of the function.
		<b>Template:Func</b>(soundName: <i>number?</i>): <i>boolean</i>
	]];
	
	local Template = {};
	setmetatable(Template, TemplateMeta);
	
	function Template:Func(index: number?)
		return true;
	end	
	
	--zEnv.Template = Template;
end

return ZSharp;