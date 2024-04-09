local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Services;
local modEventSignal = require(game.ReplicatedStorage.Library.EventSignal);

--==
local StateVariable = {};
StateVariable.__index = StateVariable;
StateVariable.ClassName = "StateVariable";

function StateVariable.new(defaultValue)
	local self = {
		Value=defaultValue;
		Changed = modEventSignal.new("StateVariableChanged");
	};
	
	setmetatable(self, StateVariable);
	return self;
end

function StateVariable:Get()
	local v = self.Value;
	return v;
end

function StateVariable:Set(v)
	self.Value = v;
	self.Changed:Fire();
end

function StateVariable:Destroy()
	self.Value = nil;
	self.Changed:Destroy();
end

return StateVariable;