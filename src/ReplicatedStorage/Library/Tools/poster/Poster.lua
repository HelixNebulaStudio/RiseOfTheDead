local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);


local interactableModule = game.ReplicatedStorage.Prefabs.Objects:WaitForChild("InterfaceInteractable");
local posterPrefab = script.Parent:WaitForChild("PosterModel");


--==
local Poster = {};

local postersList = {};
Poster.List = postersList;

function Poster.Spawn(cframe, player)
	local new = posterPrefab:Clone();
	new:SetPrimaryPartCFrame(cframe);
	new.Parent = workspace.Environment;

	modReplicationManager.SetClientParent(player, new, workspace.Interactables);

	local posterData = {
		Player=player;
		Object = new;
		Tick=tick();
		Destroy = (function(self)
			self.Destroyed = true;
			game.Debris:AddItem(self.Object, 0);
			game.Debris:AddItem(self.Interactable, 0);
		end);
	}

	local playerPosters = {};
	for a=#postersList, 1, -1 do
		local obj = postersList[a];
		
		if obj.Player then 
			if not obj.Player:IsDescendantOf(game.Players) then
				obj:Destroy(); 
			end
			
		else
			if #postersList > 6 or tick()-obj.Tick >= 3600 then
				obj:Destroy();
			end
			
		end
		
		if obj.Destroyed then
			table.remove(postersList, a);
			continue;
		end

		if obj.Player and obj.Player == player then
			table.insert(playerPosters, obj);
		end
	end

	table.sort(playerPosters, function(a, b) return a.Tick < b.Tick; end);
	if #playerPosters >= 1 then
		playerPosters[1]:Destroy();
	end

	table.insert(postersList, posterData);
	
	if player then
		local newInteractableModule = interactableModule:Clone();
		newInteractableModule.Name = "Interactable";
		newInteractableModule:SetAttribute("InterfaceName", "PosterWindow");
		newInteractableModule.Parent = game.ReplicatedStorage;
		
		posterData.Interactable = newInteractableModule;
		
		modReplicationManager.ReplicateIn(player, newInteractableModule, new);
	end
	
	local posterObject = {};
	posterObject.Prefab = new;
	
	function posterObject:SetDecal(id)
		local decal = new:FindFirstChild("Decal", true);
		decal.Texture = id;
	end
	
	function posterObject:SetBackgroundDecal(id)
		local decal = new:FindFirstChild("BackgroundDecal", true);
		decal.Texture = id;
	end

	function posterObject:SetOverlayDecal(id)
		local decal = new:FindFirstChild("OverlayDecal", true);
		decal.Texture = id;
	end
	
	return posterObject;
end


function Poster.LoadPosters(model)
	
end

return Poster;
