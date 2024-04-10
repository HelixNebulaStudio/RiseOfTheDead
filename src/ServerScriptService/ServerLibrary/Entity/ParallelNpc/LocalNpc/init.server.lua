local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Script;

local localPlayer = game.Players.LocalPlayer;
local modParallelData = require(game.ReplicatedStorage.ParallelLibrary:WaitForChild("DataModule"));

local remote = script.Parent:WaitForChild("NpcRemote");
local actor = script:GetActor();
if actor == nil then return end;

local prefab: Model = script.Parent.Parent :: Model;
if not workspace:IsAncestorOf(prefab) then return end;
local rootPart = prefab:WaitForChild("HumanoidRootPart");
local humanoid: Humanoid = prefab:FindFirstChildWhichIsA("Humanoid") :: Humanoid;

--
local localNpc = {};
localNpc.Prefab = prefab;
localNpc.RootPart = rootPart;
localNpc.Remote = remote;
localNpc.Humanoid = humanoid;

local localNpcModule = script:WaitForChild("Npc"):FindFirstChild(prefab.Name) and require(script.Npc[prefab.Name]) or nil;
if localNpcModule then
	localNpcModule.new(localNpc);
end

for _, componentModule in pairs(script:GetChildren()) do
	if not componentModule:IsA("ModuleScript") then continue end;
	local componentName = componentModule.Name;
	if componentName == "Template" then continue end;
	local component = require(componentModule).new(localNpc);
	
	localNpc[componentName] = component;
end

local function clearMovers(child)
	--if child.Name == "AlignOrientation" or child.Name == "AlignPosition" then -- child.Name == "LinearVelocity" or
	if child:IsA("LinearVelocity") or child:IsA("AlignOrientation") or child:IsA("AlignPosition") then
		child:Destroy();
	end
end
rootPart.ChildAdded:Connect(clearMovers);
for _, obj in pairs(rootPart:GetChildren()) do
	clearMovers(obj);
end
--

remote.OnClientEvent:Connect(function(action, ...)
	if action == "ApplyImpulseAtPosition" then
		local targetPart: BasePart, force, position = ...;
		targetPart:ApplyImpulseAtPosition(force, position);
		
	end
	
	local component = localNpc[action];
	if component and component.OnRemoteEvent then
		component:OnRemoteEvent(...);
	end
end)

task.defer(function()
	repeat task.wait(); until modParallelData:IsSettingsLoaded() == true;
	
	local useOldZombies = modParallelData:GetSetting("UseOldZombies");
	if prefab:GetAttribute("HasOldDesign") ~= true or useOldZombies ~= 1 then return end;
	
	local skinColor = Color3.fromRGB(211, 190, 150);
	local faceTexture = "rbxassetid://16307025188";
	
	(prefab:WaitForChild("Head") :: MeshPart).TextureID = faceTexture;

	local bodyPartNames = {"LeftUpperArm"; "RightUpperArm"; "UpperTorso"; "LeftUpperLeg"; "RightUpperLeg"; 
		"Head"; "LeftPinky"; "RightPinky"; "LeftMiddle"; "RightMiddle"; "LeftPoint"; "RightPoint"};
	
	local function setBpColor(bodyPart)
		if not bodyPart:IsA("BasePart") then return end;
		if table.find(bodyPartNames, bodyPart.Name) == nil then return end;
		
		bodyPart.Color = skinColor;
	end
	prefab.ChildAdded:Connect(setBpColor);
	
	for _, partName in pairs(bodyPartNames) do
		local bodyPart: BasePart = prefab:FindFirstChild(partName) :: BasePart;
		if bodyPart and bodyPart:IsA("BasePart") then
			bodyPart.Color = skinColor;
		end
	end
	
end)