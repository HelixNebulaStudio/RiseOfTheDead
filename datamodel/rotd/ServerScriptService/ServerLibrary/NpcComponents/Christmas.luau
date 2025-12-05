local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Script;
local Component = {};
Component.ClassName = "NpcComponent";
Component.__index = Component;

function Component.new(npcClass: NpcClass)
	local self = {};
	
	setmetatable(self, Component);
	return self;
end

function Component:__call(npcClass: NpcClass)
	local npcChar = npcClass.Character;
	if npcChar.Name == "Mr. Klaws" then return end;
	if npcChar.Name == "Wraith" then return end;
	if npcChar.Name == "Witherer" then return end;
	if npcChar.Name == "Vein Of Nekron" then return end;

	if math.random(1, 10) ~= 1 then return end;
	local prefabs = game.ServerStorage.Prefabs:WaitForChild("NpcChristmas");
	local hairPrefabs = {
		prefabs:WaitForChild("SantaHat");
		prefabs:WaitForChild("Cartoony Santa");
		prefabs:WaitForChild("santahat");
	};

	local hair = hairPrefabs[math.random(1, #hairPrefabs)]:Clone();
	hair.Parent = npcChar;
	
	npcClass.Properties.SantaHat = true;
end

return Component;