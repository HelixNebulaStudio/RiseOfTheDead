local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local SpecialEvent = {};

local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);

local EventSpawns = workspace:WaitForChild("Event");

local mrKlawsSpawn = EventSpawns:WaitForChild("Mr. Klaws");
--==
modNpc.Spawn("Mr. Klaws", mrKlawsSpawn.CFrame * CFrame.Angles(0, math.rad(-90), 0) + Vector3.new(0, 2.3, 0));

local folderMapEvent = game.ServerStorage:FindFirstChild("MapEvents");
if folderMapEvent then
	local mapDecor = folderMapEvent:FindFirstChild("ChristmasEvent");
	if mapDecor then
		mapDecor.Parent = workspace.Environment;
		
		task.spawn(function()
			local winterTreelumSpawns = mapDecor:WaitForChild("WinterTreelumSpawns");
			winterTreelumSpawns = winterTreelumSpawns:GetChildren();
			
			while true do
				if workspace.Interactables:FindFirstChild("TreelumSapling") == nil then
					local newSpawn = winterTreelumSpawns[math.random(1, #winterTreelumSpawns)];
					
					local new = script.TreelumSapling:Clone();
					new:PivotTo(newSpawn.WorldCFrame);
					new.Parent = workspace.Interactables;
					
				end
				task.wait(60);
			end
		end)
		
	end
end

return SpecialEvent;
