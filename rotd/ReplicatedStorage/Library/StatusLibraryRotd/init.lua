local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local modStatusLibrary = shared.require(game.ReplicatedStorage.Library.StatusLibrary);

--== Script;
function modStatusLibrary.onRequire()
	modStatusLibrary.DebuffTags = {"Mobility"; "DOT"; "Confusion"};

	for _, ms in pairs(script:GetChildren()) do
		if not ms:IsA("ModuleScript") then continue end;
		if ms.Name == "Template" then continue end;
		
		modStatusLibrary:LoadModule(ms);
	end

	for _, ms in pairs(script:WaitForChild("Skilltree"):GetChildren()) do
		if not ms:IsA("ModuleScript") then continue end;
		if ms.Name == "Template" then continue end;
		
		modStatusLibrary:LoadModule(ms);
	end

end

return modStatusLibrary;