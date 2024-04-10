
local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
if not workspace.Entity:IsAncestorOf(script) then return end;
--
local CollectionService = game:GetService("CollectionService");

local modLayeredVariable = require(game.ReplicatedStorage.Library.LayeredVariable);
local modDeadbodiesHandler = require(game.ReplicatedStorage.Library.DeadbodiesHandler);

--
local parallelNpc = {};
local prefab = script.Parent;

parallelNpc.Prefab = prefab;
parallelNpc.Actor = prefab:GetActor();

parallelNpc.Humanoid = prefab:FindFirstChildWhichIsA("Humanoid");

parallelNpc.MoveSpeed = modLayeredVariable.new(parallelNpc.Humanoid.WalkSpeed);

parallelNpc.Bind = prefab:WaitForChild("ActorBind"); -- BindableFunction
parallelNpc.Event = prefab:WaitForChild("ActorEvent"); -- BindableEvent;
parallelNpc.Remote = script:WaitForChild("NpcRemote"); -- UnreliableRemoteEvent;

parallelNpc.RootPart = prefab:WaitForChild("HumanoidRootPart");

parallelNpc.BindFunctions = {};
---

for _, componentModule in pairs(script:GetChildren()) do
	if not componentModule:IsA("ModuleScript") then continue end;
	local componentName = componentModule.Name;
	local component = require(componentModule).new(parallelNpc);
	
	if component.BindInvoke then
		parallelNpc.BindFunctions[componentName] = component.BindInvoke;
	end
	
	parallelNpc[componentName] = component;
end

parallelNpc.Event:Fire("init", parallelNpc);

function parallelNpc.Bind.OnInvoke(compName, ...)
	local callback = parallelNpc.BindFunctions[compName];
	if callback == nil then
		Debugger:Warn("Missing callback for ", compName);
		return;
	end;
	
	return callback(...);
end


parallelNpc.Humanoid:GetAttributeChangedSignal("IsDead"):ConnectParallel(function()
	parallelNpc.IsDead = parallelNpc.Humanoid:GetAttribute("IsDead");
end)

CollectionService:GetInstanceAddedSignal("Deadbody"):Connect(function(newDeadbody)
	local lastCheckTime = game.Debris:GetAttribute("LastClearDeadbodies");
	if lastCheckTime and tick()-lastCheckTime <= 5 then return end;
	game.Debris:SetAttribute("LastClearDeadbodies", tick());

	task.desynchronize();
	modDeadbodiesHandler:DespawnRequest();
end)