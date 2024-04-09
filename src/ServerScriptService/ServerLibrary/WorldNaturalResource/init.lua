local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local RunService = game:GetService("RunService");
--==
local WorldNaturalResource = {};
WorldNaturalResource.__index = WorldNaturalResource;

WorldNaturalResource.ActiveResource = {};

local resourceTemplates = script:WaitForChild("ResourceTemplates");
--== Script;

function WorldNaturalResource:Init(super)
	local baseResFolder = workspace.Environment:FindFirstChild("Game") and workspace.Environment.Game:FindFirstChild("NaturalResources");
	
	if baseResFolder then
		baseResFolder.Parent = script;
		local naturalResList = baseResFolder:GetChildren();
		
		local indexCounter = 0;
		for _, obj in pairs(naturalResList) do
			indexCounter = indexCounter + 1;
			obj:SetAttribute("Index", indexCounter);
		end
		
		local resFolder = Instance.new("Folder");
		resFolder.Name = "NaturalResources";
		resFolder.Parent = workspace.Environment.Game;
		
		local function spawnRes(excludeIndex)
			local rngIndex;
			for a=1, 6 do
				rngIndex = math.random(1, indexCounter);
				
				if self.ActiveResource[rngIndex] then
					continue;
				end
				
				if rngIndex ~= excludeIndex then break; end;
			end
			
			if #resFolder:GetChildren() > #game.Players:GetPlayers()*2 then
				return;
			end
			
			if self.ActiveResource[rngIndex] then return end;
			self.ActiveResource[rngIndex] = true;
			
			local pickPrefab = naturalResList[rngIndex];
			local prefabName = pickPrefab.Name;
			
			local maxAngle = 360;
			
			local newCframe = pickPrefab:GetPivot();
			
			if pickPrefab.Name ~= "NekronScales" then
				newCframe = CFrame.new(pickPrefab:GetPivot().Position) 
					* CFrame.Angles(math.rad(math.random(0, maxAngle)), math.rad(math.random(0, maxAngle)), math.rad(math.random(0, maxAngle)) );
			end
			
			
			local newPrefab = resourceTemplates:FindFirstChild(prefabName):Clone();
			newPrefab:SetAttribute("Index", rngIndex);
			newPrefab:PivotTo(newCframe);
			newPrefab.Parent = resFolder;
		end
		
		resFolder.ChildRemoved:Connect(function(prefab)
			self.ActiveResource[prefab:GetAttribute("Index")] = nil;
		end)
		
		task.spawn(function()
			for a=1, 2 do
				spawnRes();
			end
		end)
		
		local lastSpawn = tick();
		game.Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
			if (game.Lighting.ClockTime*20) % 1 == 0 then
				if lastSpawn > tick() then
					return;
				end
				
				lastSpawn = tick() + math.random(30, 60);

				if RunService:IsStudio() then
					lastSpawn = tick() + math.random(3, 6);
				end
				
				while #resFolder:GetChildren() < #game.Players:GetPlayers()*2 do
					spawnRes();
					task.wait(1);
				end
			end
		end)

	end
end

WorldNaturalResource:Init();

return WorldNaturalResource;
