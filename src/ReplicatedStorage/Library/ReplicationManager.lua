local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local ReplicationManager = {};

ReplicationManager.ObjectIndexCount = 0;
ReplicationManager.ReplicationObjList = {};
ReplicationManager.ReplicateReady = {};
ReplicationManager.ProxyOwners = {};

local CollectionService = game:GetService("CollectionService");
local RunService = game:GetService("RunService");
local HttpService = game:GetService("HttpService");

local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local remoteSetClientProperties = modRemotesManager:Get("SetClientProperties");
local remoteReplication = modRemotesManager:Get("Replication");

local replicateFolder;
--==

local function WaitForReady(player)
	local timeLapse = tick();
	
	while game.Players:IsAncestorOf(player) do
		if ReplicationManager.ReplicateReady[player] == nil then
			task.wait();
		else
			break;
		end;
		if tick()-timeLapse >= 60 then
			Debugger:Warn("Waiting for player (",player,") replication ready for 60s.", debug.traceback());
		elseif tick()-timeLapse >= 10 then
			Debugger:Warn("Waiting for player (",player,") replication ready for 10s.", debug.traceback());
		end
	end
	
	return game.Players:IsAncestorOf(player);
end
--==

local ReplicateTypes = {In=1; Out=2;};

local ReplicateObj = {};
ReplicateObj.__index = ReplicateObj;

function ReplicateObj.new(prefab)
	ReplicationManager.ObjectIndexCount = ReplicationManager.ObjectIndexCount +1;
	
	local self = {
		Index=ReplicationManager.ObjectIndexCount;
		ReplicateType=ReplicateTypes.In;
		Prefab=prefab;
		Owners={};
	}
	
	if RunService:IsServer() then
		self.ParentValue = Instance.new("ObjectValue");
		self.ParentValue.Name = self.Index;
		self.ParentValue.Parent = script;
	end
	
	setmetatable(self, ReplicateObj);
	return self;
end

function ReplicateObj:Destroy()
	Debugger.Expire(self.ParentValue);
	ReplicationManager.ReplicationObjList[self.Prefab] = nil;
	CollectionService:RemoveTag(self.Prefab, "ReplicateObject");
end

function ReplicateObj.Get(prefab, newIfNil)
	if newIfNil == true then
		if ReplicationManager.ReplicationObjList[prefab] == nil then
			ReplicationManager.ReplicationObjList[prefab] = ReplicateObj.new(prefab);
			CollectionService:AddTag(prefab, "ReplicateObject");
		end
	end
	return ReplicationManager.ReplicationObjList[prefab];
end

function ReplicateObj:Update()
	self.Prefab:SetAttribute("ReplicateObject", HttpService:JSONEncode(self));
	
	local interactObj = self.Prefab:FindFirstChild("Interactable", true);
	interactObj = interactObj and require(interactObj) or nil;
	if interactObj then 
		if #self.Owners > 0 then
			if interactObj.Whitelist == nil then interactObj.Whitelist = {}; end;
			for a=1, #self.Owners do
				interactObj.Whitelist[self.Owners[a]] = true;
			end
		else
			interactObj.Whitelist = nil;
		end
	end;
end

function ReplicateObj:AddOwner(player)
	if self:IsAOwner(player) then return end;
	table.insert(self.Owners, player.Name);
	
	self:Update();
end

function ReplicateObj:DelOwner(player, destroyIfNoOwner)
	for a=#self.Owners, 1, -1 do
		if self.Owners[a] == player.Name then
			table.remove(self.Owners, a);
		end
	end
	
	if destroyIfNoOwner == true and #self.Owners <= 0 then
		self:Destroy();
		Debugger.Expire(self.Prefab);
		
	else
		self:Update();
	end
end

function ReplicateObj:IsAOwner(player: Player)
	local proxyOwners = ReplicationManager.ProxyOwners[player.Name];
	
	if proxyOwners then
		if proxyOwners == true then Debugger:Warn("Player (",player.Name,") is proxy owner of (",self.Prefab,")") return true end;
		
		for a=1, #self.Owners do
			if table.find(proxyOwners, self.Owners[a]) then
				return true;
			end
		end
	end
	
	return table.find(self.Owners, player.Name) ~= nil;
end

function ReplicateObj:Load()
	if RunService:IsServer() then return end
	
	local rawRepObj = self.Prefab:GetAttribute("ReplicateObject") or "[]";
	rawRepObj = HttpService:JSONDecode(rawRepObj);
	
	self.Index = rawRepObj.Index;
	self.ReplicateType = rawRepObj.ReplicateType;
	self.ParentValue = script:WaitForChild(self.Index);
	
	table.clear(self.Owners)
	for a=1, #rawRepObj.Owners do
		table.insert(self.Owners, rawRepObj.Owners[a]);
	end
	
	local proxyOwners = script:GetAttribute("ProxyOwners") or "[]";
	proxyOwners = HttpService:JSONDecode(proxyOwners);
	ReplicationManager.ProxyOwners = proxyOwners;
end

--==
-- !outline: ReplicationManager.SetClientParent(player, prefab, parent)
function ReplicationManager.SetClientParent(player, prefab, parent)
	task.spawn(function()
		if WaitForReady(player) == false then return end;
		remoteReplication:InvokeClient("sync", player, prefab, parent);
	end)
end

-- !outline: ReplicationManager.UnreplicateFrom(player, prefab)
function ReplicationManager.UnreplicateFrom(player, prefab)
	if prefab == nil then Debugger:Warn("Prefab is nil."); return end;
	ReplicationManager.SetClientParent(player, prefab, nil) -- Set prefab parent to nil on client;
end

function ReplicationManager.GetReplicated(player, prefabName)
	local prefabList = {};
	
	for _, prefab in pairs(replicateFolder:GetChildren()) do
		if prefab.Name == prefabName then
			local repObj = ReplicateObj.Get(prefab, true);
			repObj:Load();
			
			if not repObj:IsAOwner(player) then continue end;
			
			table.insert(prefabList, prefab);
		end
	end

	for prefab, replicateObj in pairs(ReplicationManager.ReplicationObjList) do
		if prefab.Name == prefabName then
			replicateObj:Load();
			if not replicateObj:IsAOwner(player) then continue end;
			
			if table.find(prefabList, prefab) == nil then
				table.insert(prefabList, prefab);
			end
		end
	end
	
	return prefabList;
end


function ReplicationManager.ReplicateOnlyTo(player, prefab)
	Debugger:Warn("Deprecated method ReplicateOnlyTo", debug.traceback());
	ReplicationManager.ReplicateOut({player}, prefab);
end

function ReplicationManager.ReplicateOut(players, prefab) -- Replicates prefab out of workspace of non-owners;
	if prefab == nil then Debugger:Warn("Prefab is nil."); return end;
	players = typeof(players) == "table" and players or {players};

	local repObj = ReplicateObj.Get(prefab, true);
	repObj.ReplicateType = ReplicateTypes.Out;
	repObj.ParentValue.Value = prefab.Parent;
	
	for a=1, #players do
		local player = players[a];
		repObj:AddOwner(player);
	end
end

function ReplicationManager.ReplicateTo(player, prefab, parent)
	Debugger:Warn("Deprecated method ReplicateTo", debug.traceback());
	ReplicationManager.ReplicateIn({player}, prefab, parent);
end

function ReplicationManager.ReplicateIn(players, prefab, parent) -- Replicates into workspace of owners;
	if not RunService:IsServer() then return end;
	if prefab == nil then Debugger:Warn("Prefab or parent is nil."); return end;
	
	players = typeof(players) == "table" and players or {players};
	
	prefab.Parent = replicateFolder;

	local repObj = ReplicateObj.Get(prefab, true);
	repObj.ReplicateType = ReplicateTypes.In;
	repObj.ParentValue.Value = parent;
	
	for a=1, #players do
		local player = players[a];
		repObj:AddOwner(player);
	end
end

function ReplicationManager.ReplicateDefault(prefab, parent)
	local repObj = ReplicateObj.Get(prefab, false);
	if repObj then
		repObj:Destroy();
	end

	prefab.Parent = parent;
	
	for _, player in pairs(game.Players:GetPlayers()) do
		task.spawn(function() 
			remoteReplication:InvokeClient("sync", player, prefab, parent);
		end)
	end
end

--== Replicate Properties;
function ReplicationManager:SetClientProperties(players, list)
	players = typeof(players) ~= "table" and {players} or players;

	for a=1, #players do
		remoteSetClientProperties:FireClient(players[a], list);
	end
end


local function OnClientReplicateObjectUpdate(prefab: Instance)
	if prefab == nil then return end;
	
	local function load()
		if prefab:GetAttribute("ReplicateObject") == nil then return end;

		local repObj = ReplicateObj.Get(prefab, true);
		repObj:Load();

		local isOwner = repObj:IsAOwner(game.Players.LocalPlayer);
		
		if repObj.ReplicateType == ReplicateTypes.In then
			repObj.Prefab.Parent = isOwner and repObj.ParentValue.Value or replicateFolder;

		elseif repObj.ReplicateType == ReplicateTypes.Out then
			repObj.Prefab.Parent = isOwner and repObj.ParentValue.Value or replicateFolder;

		end
	end
	
	prefab:GetAttributeChangedSignal("ReplicateObject"):Connect(load)
	load();
end

local function LocalSync()
	replicateFolder = game.ReplicatedStorage:WaitForChild("Replicated");
	
	for _, prefab in pairs(CollectionService:GetTagged("ReplicateObject")) do
		task.spawn(function()
			OnClientReplicateObjectUpdate(prefab);
		end)
	end
end

if RunService:IsClient() then
	Debugger:Log("Initialized");
	local localPlayer = game.Players.LocalPlayer;
	
	remoteSetClientProperties.OnClientEvent:Connect(function(setData)
		local instances = typeof(setData.Instances) == "table" and setData.Instances or {setData.Instances};
		
		for _, obj in pairs(instances) do
			if typeof(obj) == "Instance" then
				local descendants = obj:GetDescendants();
				table.insert(descendants, obj);
				
				for a=1, #descendants do
					if setData.ClassName then
						for className, properties in pairs(setData.ClassName) do
							if descendants[a]:IsA(className) then
								for pk, pv in pairs(properties) do
									descendants[a][pk] = pv;
								end
							end
						end
					end
					
					if setData.Name then
						for name, properties in pairs(setData.Name) do
							if descendants[a].Name == name then
								for pk, pv in pairs(properties) do
									descendants[a][pk] = pv;
								end
							end
						end
					end
				end
			end
		end
	end)
	
	
	function remoteReplication.OnClientInvoke(action: string, prefab: Instance, parent: Instance)
		if action == "sync" then
			if prefab == nil then return false end;
			prefab.Parent = parent;
			
			return true;
			
		elseif action == "" then
			
			
		end
	end
	
	task.spawn(function()
		while remoteReplication:InvokeServer("ready") ~= true do
			task.wait(0.5);
		end
		LocalSync();
	end)
	
	CollectionService:GetInstanceAddedSignal("ReplicateObject"):Connect(OnClientReplicateObjectUpdate);
	CollectionService:GetInstanceRemovedSignal("ReplicateObject"):Connect(function(prefab)
		local repObj = ReplicateObj.Get(prefab, false);
		if repObj then
			repObj:Destroy();
		end
	end);
	
	script:GetAttributeChangedSignal("ProxyOwners"):Connect(function()
		LocalSync();	
	end);
	
else
	replicateFolder = Instance.new("Folder");
	replicateFolder.Name = "Replicated";
	replicateFolder.Parent = game.ReplicatedStorage;
	
	
	function remoteReplication.OnServerInvoke(player: Player, action: string)
		ReplicationManager.ReplicateReady[player] = true;
		Debugger:Warn("ReplicateReady (", player, ")");
		return true;
	end
	
end

local function OnPlayerAdded(player: Player)
	if RunService:IsClient() then
		
		player.CharacterAdded:Connect(LocalSync)
		LocalSync();
	end
end


game.Players.PlayerRemoving:Connect(function(player)	
	for p, _ in pairs(ReplicationManager.ReplicateReady) do
		if game.Players:IsAncestorOf(p) then continue end;
		
		ReplicationManager.ReplicateReady[p] = nil;
	end
	
	task.wait();
	for prefab, repObj in pairs(ReplicationManager.ReplicationObjList) do
		repObj:DelOwner(player, true);
	end
	
	ReplicationManager.ProxyOwners[player.Name] = nil;
end)

local modEngineCore = require(game.ReplicatedStorage.EngineCore);
modEngineCore:ConnectOnPlayerAdded(script, OnPlayerAdded)

if RunService:IsServer() then
	task.spawn(function()
		local modCommandHandler = require(game.ReplicatedStorage.Library.CommandHandler);

		Debugger.AwaitShared("modCommandsLibrary");
		shared.modCommandsLibrary:HookChatCommand("replicationmanager", {
			Permission = shared.modCommandsLibrary.PermissionLevel.DevBranch;

			RequiredArgs = 0;
			UsageInfo = "/replicationmanager";
			Description = [[Use for debuging client side replication.
		/replicationmanager show/hide [playerName/*]
		Shows or hides replication for specific client or * for all clients.
		]];
			Function = function(speaker: Player, args: {[number]: string})
				local isShow = args[1] == "show";

				local targetPlayer = nil;

				local playerName = args[2];
				
				if playerName == "*" then
				elseif playerName then
					local matches = modCommandHandler.MatchName(playerName);
					if #matches == 1 then
						targetPlayer = matches[1];

					elseif #matches > 1 then
						shared.modCommandsLibrary.GenericOutputs.MultipleMatch(speaker, matches);
						return;

					elseif #matches < 1 then
						table.insert(args, 2, "");
					end
				end
				
				if playerName == "*" then
					if isShow then
						ReplicationManager.ProxyOwners[speaker.Name] = true;
					else
						ReplicationManager.ProxyOwners[speaker.Name] = nil;
					end
					Debugger:Warn("Proxy owner set", ReplicationManager.ProxyOwners[speaker.Name]);
					
				else
					if targetPlayer == nil then
						shared.Notify(speaker, "No specified player", "Negative");
						return true;
					end

					if ReplicationManager.ProxyOwners[speaker.Name] == nil or ReplicationManager.ProxyOwners[speaker.Name] == true then
						ReplicationManager.ProxyOwners[speaker.Name] = {};
					end
					
					local proxyOwners = ReplicationManager.ProxyOwners[speaker.Name];


					local pOIndex = table.find(proxyOwners, targetPlayer.Name)
					if pOIndex == nil then
						if isShow then
							table.insert(proxyOwners, targetPlayer.Name);
						else
							table.remove(proxyOwners, pOIndex);
						end
					end
					Debugger:Warn("New ProxyOwners for (", targetPlayer ,"):", proxyOwners);
				end
				
				script:SetAttribute("ProxyOwners", HttpService:JSONEncode(ReplicationManager.ProxyOwners));
				Debugger:Warn("Syncing replication objects.");
				
				return true;
			end;
		});
	end)
end

return ReplicationManager;