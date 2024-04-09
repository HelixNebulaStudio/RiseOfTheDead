local Debugger = require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("Debugger")).new(script);
--== Variables;
local PrefabManager = {};

local remotePrefabRequest = game.ReplicatedStorage.Remotes:WaitForChild("PrefabRequest");

local prefabCache = {};

--== Script;
function PrefabManager:LoadPrefab(prefab, location, duration)
	if prefab == nil or location == nil then return end;
	
	local returnPrefab;
	local locationName = location.Name;
	if prefabCache[locationName] == nil then prefabCache[locationName] = {} end;
	if prefabCache[locationName][prefab.Name] and location:FindFirstChild(prefab.Name) then
		prefabCache[locationName][prefab.Name].Timer = os.time();
		returnPrefab = prefabCache[locationName][prefab.Name].Prefab;
	else
		returnPrefab = prefab:Clone();
		returnPrefab.Parent = location;
		prefabCache[locationName][prefab.Name] = {Prefab=returnPrefab; Timer=os.time()};
		
		local function onExpire()
			if prefabCache[locationName] and prefabCache[locationName][prefab.Name] and os.time()-prefabCache[locationName][prefab.Name].Timer+1 >= duration then
				prefabCache[locationName][prefab.Name].Prefab:Destroy();
				prefabCache[locationName][prefab.Name] = nil;
			else
				task.delay((duration/2), onExpire);
			end
		end
		if duration and type(duration) == "number" then
			task.delay(duration, onExpire);
		end
	end
	
	return returnPrefab;
end

local playerCache = {};
function remotePrefabRequest.OnServerInvoke(player, prefabType, prefabName)
	if playerCache[player.Name] == nil then playerCache[player.Name] = 0; delay(60, function() playerCache[player.Name] = nil; end) end;
	playerCache[player.Name] = playerCache[player.Name] +1;
	if prefabType == nil or prefabName == nil then return end;
	if playerCache[player.Name] < 10 then
		local existingPrefab = game.ReplicatedStorage.Prefabs.Npc:FindFirstChild(prefabName);
		if existingPrefab == nil then
			local dir = game.ServerStorage.PrefabStorage:FindFirstChild(prefabType);
			local prefab = dir and dir:FindFirstChild(prefabName);
			if prefab then
				return PrefabManager:LoadPrefab(prefab, game.ReplicatedStorage.Prefabs.Npc);
			else
				warn("Prefab ("..prefabName..") does not exist.");
			end
		else
			return existingPrefab;
		end
	else
		warn(player.Name.." is requesting for too many prefabs.");
	end
end

return PrefabManager;