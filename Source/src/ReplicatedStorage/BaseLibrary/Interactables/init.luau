local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Interactables = {};
Interactables.__index = Interactables;

--== Script;
function Interactables:Init(super)
	super.Config = {};
	
	for _, obj in pairs(script:GetChildren()) do
		if not obj:IsA("ModuleScript") then continue end;
		task.spawn(function()
			require(obj).init(super);
		end)
	end
end

return Interactables;
