local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local HttpService = game:GetService("HttpService");
local RunService = game:GetService("RunService");

--==
local RemoteConfigs = {};
RemoteConfigs.Vars = {};

function RemoteConfigs:Get(key)
	return RemoteConfigs.Vars[key];
end

script:GetAttributeChangedSignal("Configurations"):Connect(function()
	RemoteConfigs.Vars = HttpService:JSONDecode(script:GetAttribute("Configurations"));
end)

return RemoteConfigs;
