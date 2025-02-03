local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local StatusLibrary = {};
StatusLibrary.__index = StatusLibrary;
--== Script;
function StatusLibrary:Init(super)
	super.DebuffTags = {"Mobility"; "DOT"; "Confusion"};

	for _, ms in pairs(script:GetChildren()) do
		if not ms:IsA("ModuleScript") then continue end;
		if ms.Name == "Template" then continue end;
		
		super:LoadModule(ms);
	end

	for _, ms in pairs(script:WaitForChild("Skilltree"):GetChildren()) do
		if not ms:IsA("ModuleScript") then continue end;
		if ms.Name == "Template" then continue end;
		
		super:LoadModule(ms);
	end

end

return StatusLibrary;