local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RemotesManager = {};
RemotesManager.__index = RemotesManager;

local RunService = game:GetService("RunService");

local modRemotePacketSizeCounter = require(script.RemotePacketSizeCounter);
local modBridgeNet = require(game.ReplicatedStorage:WaitForChild("Dependencies"):WaitForChild("BridgeNet2"));

local bindWaitForRemotesReady = Instance.new("BindableEvent");
local isRemotesReady = false;


--== Script;
RemotesManager.PacketSizeCounter = modRemotePacketSizeCounter;

RemotesManager.NewRef = modBridgeNet.ReferenceIdentifier;
RemotesManager.DeRef = modBridgeNet.Deserialize;
RemotesManager.Ref = modBridgeNet.Serialize;

RemotesManager.AllPlayers = modBridgeNet.AllPlayers;
RemotesManager.PlayersExcept = modBridgeNet.PlayersExcept;
RemotesManager.Players = modBridgeNet.Players;


RemotesManager.Remotes = {};
RemotesManager.Bridges = {};
RemotesManager.LogRemotes = false;
RemotesManager.WarnInsecure = true;

RemotesManager.RecordRemotes = RunService:IsStudio();
RemotesManager.Records = {};

local function loop(t, cb)
	for k,v in pairs(t) do
		if typeof(v) == "table" then
			loop(v, cb);
		else
			cb(k, v);
		end
	end
end

function RemotesManager:Record(remoteName, callType, data)
	if not RemotesManager.RecordRemotes then return end
	
	task.spawn(function()
		if RemotesManager.Records[remoteName] == nil then RemotesManager.Records[remoteName] = {}; end
		local remoteRecords = RemotesManager.Records[remoteName];

		if remoteRecords[callType] == nil then
			remoteRecords[callType] = {
				Calls=0;
				MaxSize=0;
				MinSize=math.huge;
				TotalSize=0;
				LastSubmission=tick();
			};
		end;
		local callTable = remoteRecords[callType];

		callTable.Calls = callTable.Calls +1;
		local dataSize = modRemotePacketSizeCounter.GetPacketSize{
			PacketData=data;
		};
		if dataSize > callTable.MaxSize then
			callTable.MaxSize = dataSize;
		end
		if dataSize < callTable.MinSize then
			callTable.MinSize = dataSize;
		end
		callTable.TotalSize = callTable.TotalSize + dataSize;
	end)
end


function RemotesManager:NewUnreliableEventRemote(instanceOrName)
	local remoteName = type(instanceOrName) == "string" and instanceOrName or instanceOrName.Name;
	if self.Remotes[remoteName] then
		Debugger:Warn("Remote (",remoteName,") already exist.");
		return self.Remotes[remoteName];
	end
	local remoteInstance: UnreliableRemoteEvent = type(instanceOrName) == "userdata" and instanceOrName or Instance.new("UnreliableRemoteEvent");
	remoteInstance.Name = remoteName;

	
	local remote = {Remote=remoteInstance; DebounceInterval=0; DebounceList={}; Deprecated=false;};
	local meta = {};
	
	if RunService:IsServer() then
		remoteInstance.OnServerEvent:Connect(function(player, ...)
			local param = {...};
			
			if RemotesManager.LogRemotes then Debugger:Log(remote.Remote.Name..">> OnServerEvent. (",...,")"); end;
			RemotesManager:Record(remote.Remote.Name, "OnServerEvent", param);
		end)
	else
		remoteInstance.OnClientEvent:Connect(function(...)
			if RemotesManager.LogRemotes then Debugger:Log(remote.Remote.Name..">> OnClientEvent. (",...,")"); end;
			RemotesManager:Record(remote.Remote.Name, "OnClientEvent", {...});
		end)
	end
	
	function meta.__index(t, k)
		if k:lower() == "fireserver" then
			return function(remoteTable, ...)
				if RemotesManager.LogRemotes then Debugger:Log(remote.Remote.Name..">> Fired Server. (",...,")"); end;
				RemotesManager:Record(remote.Remote.Name, "FireServer", {...});
				if remote.Deprecated then
					Debugger:Warn(remote.Remote.Name..">> Deprecated trace:", debug.traceback());
				end
				
				remote.Remote:FireServer(...);
			end
		elseif k:lower() == "fireclient" then
			return function(remoteTable, ...)
				if RemotesManager.LogRemotes then Debugger:Log(remote.Remote.Name..">> Fired Client. (",...,")"); end;
				RemotesManager:Record(remote.Remote.Name, "FireClient", {...});
				if remote.Deprecated then
					Debugger:Warn(remote.Remote.Name..">> Deprecated trace:", debug.traceback());
				end
				
				remote.Remote:FireClient(...);
			end
		elseif k:lower() == "fireallclients" then
			return function(remoteTable, ...)
				if RemotesManager.LogRemotes then Debugger:Log(remote.Remote.Name..">> Fired All Client. (",...,")"); end;
				RemotesManager:Record(remote.Remote.Name, "FireAllClients", {...});
				if remote.Deprecated then
					Debugger:Warn(remote.Remote.Name..">> Deprecated trace:", debug.traceback());
				end
				
				remote.Remote:FireAllClients(...);
			end
		end
		return meta[k] or remote.Remote[k];
	end;
	
	function meta:Debounce(player, resetDebounce)
		local playerName = player and player.Name or "nil";
		if remote.DebounceList[playerName] and tick()-remote.DebounceList[playerName] < remote.DebounceInterval then
			return true;
		end
		if resetDebounce == true then
			remote.DebounceList[playerName] = nil;
		else
			remote.DebounceList[playerName] = tick();
		end
		return false;
	end

	self.Remotes[remoteName] = setmetatable(remote, meta);
	remote.Remote.Parent = script;
	
	return remote;
end

export type EventRemote = {
};

function RemotesManager:NewEventRemote(remoteInstance, debounceInterval)
	local remoteName = type(remoteInstance) == "string" and remoteInstance or remoteInstance.Name;
	if self.Remotes[remoteName] then
		Debugger:Warn("Remote (",remoteName,") already exist.");
		return self.Remotes[remoteName];
	end
	remoteInstance = type(remoteInstance) == "userdata" and remoteInstance or Instance.new("RemoteEvent");
	remoteInstance.Name = remoteName;
	
	local remote = {Remote=remoteInstance; DebounceInterval=(debounceInterval or 0); DebounceList={}; Secure=false; Deprecated=false;};
	local meta = {};
	
	if RunService:IsServer() then
		remoteInstance.OnServerEvent:Connect(function(player, ...)
			local param = {...};
			
			if not remote.Secure and RemotesManager.WarnInsecure then
				local inputWarn = 0;
				loop(param, function(k,v)
					if typeof(v) == "Instance" and v:IsA("ModuleScript") then
						inputWarn = 1;
					elseif typeof(v) == "number" then
						inputWarn = 2;
					end

					if not rawequal(v, v) then
						shared.modGameLogService:Log(player.UserId.." ("..player.Name..") received sus input: "..remoteName.." = "..Debugger:Stringify(param), "Remote Logs");
					end
				end)
				
				if inputWarn == 1 then
					Debugger:StudioWarn(remoteName,"receives input as moduelscript, is remote secure? ", param);
				elseif inputWarn == 2 then
					Debugger:StudioWarn(remoteName,"receives input as number, is remote secure? ", param);
				end
			end
			
			if RemotesManager.LogRemotes then Debugger:Log(remote.Remote.Name..">> OnServerEvent. (",...,")"); end;
			RemotesManager:Record(remote.Remote.Name, "OnServerEvent", {...});
		end)
	else
		remoteInstance.OnClientEvent:Connect(function(...)
			if RemotesManager.LogRemotes then Debugger:Log(remote.Remote.Name..">> OnClientEvent. (",...,")"); end;
			RemotesManager:Record(remote.Remote.Name, "OnClientEvent", {...});
		end)
	end
	
	function meta.__index(t, k)
		if k:lower() == "fireserver" then
			return function(remoteTable, ...)
				if RemotesManager.LogRemotes then Debugger:Log(remote.Remote.Name..">> Fired Server. (",...,")"); end;
				RemotesManager:Record(remote.Remote.Name, "FireServer", {...});
				if remote.Deprecated then
					Debugger:Warn(remote.Remote.Name..">> Deprecated trace:", debug.traceback());
				end
				
				remote.Remote:FireServer(...);
			end
		elseif k:lower() == "fireclient" then
			return function(remoteTable, ...)
				if RemotesManager.LogRemotes then Debugger:Log(remote.Remote.Name..">> Fired Client. (",...,")"); end;
				RemotesManager:Record(remote.Remote.Name, "FireClient", {...});
				if remote.Deprecated then
					Debugger:Warn(remote.Remote.Name..">> Deprecated trace:", debug.traceback());
				end
				
				remote.Remote:FireClient(...);
			end
		elseif k:lower() == "fireallclients" then
			return function(remoteTable, ...)
				if RemotesManager.LogRemotes then Debugger:Log(remote.Remote.Name..">> Fired All Client. (",...,")"); end;
				RemotesManager:Record(remote.Remote.Name, "FireAllClients", {...});
				if remote.Deprecated then
					Debugger:Warn(remote.Remote.Name..">> Deprecated trace:", debug.traceback());
				end
				
				remote.Remote:FireAllClients(...);
			end
		end
		return meta[k] or remote.Remote[k];
	end;
	
	function meta:Debounce(player, resetDebounce)
		local playerName = player and player.Name or "nil";
		if remote.DebounceList[playerName] and tick()-remote.DebounceList[playerName] < remote.DebounceInterval then
			return true;
		end
		if resetDebounce == true then
			remote.DebounceList[playerName] = nil;
		else
			remote.DebounceList[playerName] = tick();
		end
		return false;
	end
	
	self.Remotes[remoteName] = setmetatable(remote, meta);
	remote.Remote.Parent = script;
	
	return remote;
end

export type FunctionRemote = {

};

function RemotesManager:NewFunctionRemote(remoteInstance, debounceInterval)
	local remoteName = type(remoteInstance) == "string" and remoteInstance or remoteInstance.Name;
	if self.Remotes[remoteName] then
		Debugger:Warn("Remote (",remoteName,") already exist.");
		return self.Remotes[remoteName];
	end
	remoteInstance = type(remoteInstance) == "userdata" and remoteInstance or Instance.new("RemoteFunction");
	remoteInstance.Name = remoteName;
	
	local remote = {Remote=remoteInstance; DebounceInterval=(debounceInterval or 0); DebounceList={}; Secure=false};
	local meta = {};
	
	function meta.__index(t, k)
		if k:lower() == "invokeserver" then
			return function(remoteTable, ...)
				if RemotesManager.LogRemotes then Debugger:Log(remoteName..">> Invoked Server. (",...,")"); end;
				RemotesManager:Record(remote.Remote.Name, "InvokeServer", {...});
				
				return remote.Remote:InvokeServer(...);
			end
		elseif k:lower() == "invokeclient" then
			return function(remoteTable, ...)
				if RemotesManager.LogRemotes then Debugger:Log(remoteName..">> Invoked Client. (",...,")"); end;
				RemotesManager:Record(remote.Remote.Name, "InvokeClient", {...});

				local p = {...};
				local r;
				local _invokeS, _invokeE = pcall(function()
					r = {remote.Remote:InvokeClient(unpack(p))};
				end)
				
				return r and unpack(r) or nil;
			end
		end
		return meta[k] or remote.Remote[k];
	end;
	
	function meta.__newindex(t, k, v)
		if k:lower() == "onserverinvoke" then
			remote.Remote.OnServerInvoke = function(player, ...)
				local param = {...};
				
				task.spawn(function()
					if not remote.Secure and RemotesManager.WarnInsecure then
						local inputWarn = 0;
						loop(param, function(k,v)
							if typeof(v) == "Instance" and v:IsA("ModuleScript") then
								inputWarn = 1;
							elseif typeof(v) == "number" then
								inputWarn = 2;
							end

							if not rawequal(v, v) then
								shared.modGameLogService:Log(player.UserId.." ("..player.Name..") received sus input: "..remoteName.." = "..Debugger:Stringify(param), "Remote Logs");
							end
						end)
						
						if inputWarn == 1 then
							Debugger:StudioWarn(remoteName,"receives input as moduelscript, is remote secure? ", param);
						elseif inputWarn == 2 then
							Debugger:StudioWarn(remoteName,"receives input as number, is remote secure? ", param);
						end
					end
				end)
				RemotesManager:Record(remote.Remote.Name, "OnServerInvoke", {...});

				return v(player, ...);
			end;
			
		elseif k:lower() == "onclientinvoke" then
			remote.Remote.OnClientInvoke = v;
			
		end
		meta[k] = v;
	end
	
	function meta:Debounce(player, resetDebounce)
		local playerName = player and player.Name or "nil";
		if remote.DebounceList[playerName] and tick()-remote.DebounceList[playerName] < remote.DebounceInterval then
			return true;
		end
		if resetDebounce == true then
			remote.DebounceList[playerName] = nil;
		else
			remote.DebounceList[playerName] = tick();
		end
		return false;
	end
	
	self.Remotes[remoteName] = setmetatable(remote, meta);
	remote.Remote.Parent = script;
	
	return remote;
end

function RemotesManager:Get(name) : EventRemote | FunctionRemote | UnreliableRemoteEvent
	if not isRemotesReady then bindWaitForRemotesReady:Wait(); end;
	
	local function get()
		return self.Remotes[name] or self.Bridges[name];
	end
	
	for a=1, 5 do
		if get() then
			break;
		else
			task.wait(1);
		end;
	end
	if get() == nil then
		error("RemotesManager>>  Remote ("..name..") does not exist after 5s.");
	end
	return get();
end

function RemotesManager.OnPlayerRemoving(player)
	for remoteName, remoteData in pairs(RemotesManager.Remotes) do
		remoteData.DebounceList[player.Name] = nil;
	end
end


--== BridgeNet
function RemotesManager:NewEventBridge(bridgeId)
	if self.Remotes[bridgeId] then
		Debugger:Warn("Bridge and remote cannot co-exist. (",bridgeId,")");
		return self.Remotes[bridgeId];
	end
	if self.Bridges[bridgeId] then
		Debugger:Warn("Bridge (",bridgeId,") already exist.");
		return self.Bridges[bridgeId];
	end
	
	local bridge = modBridgeNet.ReferenceBridge(bridgeId);
	
	local remote = {Remote=bridge;};
	local meta = {};

	function meta.__index(t, k)
		if k:lower() == "fireserver" then
			return function(remoteTable, packet)
				bridge:Fire(packet);
			end
			
		elseif k:lower() == "fireclient" then
			return function(remoteTable, ...)
				local args = {...};
				local player = table.remove(args, 1);
				
				bridge:Fire(player, args);
			end
			
		elseif k:lower() == "fireallclients" then
			return function(remoteTable, packet)
				bridge:Fire(modBridgeNet.AllPlayers(), packet);
			end

		elseif k:lower() == "fire" then
			return function(remoteTable, ...)
				RemotesManager:Record(bridgeId, "Fire", {...});
				
				local player = select(1, ...);
				bridge:Fire(player, select(2, ...));
			end
			
		elseif k:lower() == "onevent" then
			return bridge;
			
		elseif k:lower() == "onclientevent" then
			return bridge;
			
		elseif k:lower() == "onserverevent" then
			return bridge;
			
		end
		
		return meta[k];
	end;
	
	function meta.__newindex(t, k, v)
		if k:lower() == "logging" then
			rawset(bridge, k, v);
		end
	end

	self.Bridges[bridgeId] = setmetatable(remote, meta);
	
	if RunService:IsServer() then
		local bridgeTag = Instance.new("BoolValue");
		bridgeTag.Name = bridgeId;
		bridgeTag.Parent = script;
		
	end
	
	return remote;
end

function RemotesManager.Compress(packet)
	local function compress(t)
		local setkeys = {};
		local delkeys = {};
		for k, v in pairs(t) do
			if typeof(v) == "table" then
				compress(v);
			end
			if typeof(k) ~= "string" then continue end

			local ref = RemotesManager.Ref(k);
			if ref == nil then continue end;
			setkeys[ref] = v;
			delkeys[k] = true;
		end
		for k, v in pairs(setkeys) do
			t[k] = v;
		end
		for k, v in pairs(delkeys) do
			t[k] = nil;
		end
		return t;
	end
	
	return compress(packet);
end

function RemotesManager.Uncompress(packet)
	local function uncompress(t)
		local setkeys = {};
		local delkeys = {};
		for k, v in pairs(t) do
			if typeof(v) == "table" then
				uncompress(v);
			end
			if typeof(k) ~= "string" then continue end
			
			local ref = RemotesManager.DeRef(k);
			if ref == nil then continue end;
			setkeys[ref] = v;
			delkeys[k] = true;
		end
		for k, v in pairs(setkeys) do
			t[k] = v;
		end
		for k, v in pairs(delkeys) do
			t[k] = nil;
		end
		return t;
	end

	return uncompress(packet);
end


if RunService:IsClient() then
	local function loadRemote(obj)
		if obj:IsA("RemoteEvent") then
			RemotesManager:NewEventRemote(obj);
			
		elseif obj:IsA("RemoteFunction") then
			RemotesManager:NewFunctionRemote(obj);
			
		elseif obj:IsA("UnreliableRemoteEvent") then
			RemotesManager:NewUnreliableEventRemote(obj);

		elseif obj:IsA("BoolValue") then
			RemotesManager:NewEventBridge(obj.Name);
			
		end
	end
	
	repeat
		local coreRemote = script:FindFirstChild("RemoteManager");
		if coreRemote then
			loadRemote(coreRemote);
		end
		task.wait(0.2);
	until RemotesManager.Remotes.RemoteManager ~= nil;
	
	script.ChildAdded:Connect(function(obj)
		task.wait();
		loadRemote(obj);
	end);
	for _, obj in pairs(script:GetChildren()) do
		loadRemote(obj);
	end
	
else
	--==== Server Side;
	do -- Identifiers
		RemotesManager.NewRef("Key");
		RemotesManager.NewRef("Action");
		RemotesManager.NewRef("Data");
		RemotesManager.NewRef("HierarchyKey");
		RemotesManager.NewRef("Id");
		RemotesManager.NewRef("Index");
		RemotesManager.NewRef("Type");
		RemotesManager.NewRef("Arguments");
	end
	
	--== Debug;
	RemotesManager:NewEventRemote("RemoteManager");
	RemotesManager:NewEventBridge("TestRemote")
	
	--== Engine;
	RemotesManager:NewFunctionRemote("ApiRequest");
	RemotesManager:NewEventRemote("SetClientProperties");
	RemotesManager:NewFunctionRemote("GeneralUIRemote", 0.1).Secure = true;
	RemotesManager:NewFunctionRemote("Replication");
	RemotesManager:NewEventRemote("PlayAudio");
	RemotesManager:NewEventBridge("EventService");

	--== Game;
	RemotesManager:NewUnreliableEventRemote("CharacterRemote");
	RemotesManager:NewFunctionRemote("ToolHandler", 0.1);
	RemotesManager:NewEventRemote("NotifyPlayer");
	RemotesManager:NewEventRemote("DamagePacket");
	RemotesManager:NewEventRemote("ProgressMission");
	RemotesManager:NewEventRemote("BodyEquipmentsSync");
	RemotesManager:NewFunctionRemote("MissionRemote", 0.5);
	RemotesManager:NewFunctionRemote("EnterDoorRequest", 0.5).Secure = true;
	RemotesManager:NewFunctionRemote("ItemDropRemote", 0.5);
	RemotesManager:NewEventRemote("HudNotification");
	RemotesManager:NewFunctionRemote("BattlepassRemote", 1);
	
	
	--== DataControl;
	RemotesManager:NewEventBridge("PlayerDataSync");
	RemotesManager:NewFunctionRemote("PlayerDataFetch").Secure = true;
	
	RemotesManager:NewEventRemote("GoldStatSync");
	RemotesManager:NewEventRemote("MasterySync");
	RemotesManager:NewFunctionRemote("RequestPublicProfile", 0.5);
	
	--==
	RemotesManager:NewEventRemote("PlayerProperties").Secure = true;
	
	--== Gold Shop;
	RemotesManager:NewFunctionRemote("GoldShopPurchase", 0.5);
	RemotesManager:NewFunctionRemote("LimitedService", 1);
	
	
	--== Npc
	RemotesManager:NewFunctionRemote("DialogueHandler", 0.2);
	RemotesManager:NewEventRemote("NpcManager");
	RemotesManager:NewEventRemote("NpcFace");
	RemotesManager:NewEventRemote("TryHookEntity");
	
	--== Interactables;
	RemotesManager:NewEventRemote("InteractionUpdate").Secure=true;
	RemotesManager:NewEventRemote("DoorInteraction");
	RemotesManager:NewEventRemote("InteractableSync").Secure=true;
	RemotesManager:NewEventRemote("KeypadInput");
	RemotesManager:NewEventRemote("InteractableToggle").Secure=true;
	RemotesManager:NewEventRemote("ReviveInteract");
	
	--== Profile;
	RemotesManager:NewEventRemote("OnInvitationsUpdate");
	RemotesManager:NewEventRemote("RequestResetData");
	RemotesManager:NewFunctionRemote("GoldDonate", 1);
	
	--== SquadService;
	RemotesManager:NewEventRemote("GetOnlineFriends");
	RemotesManager:NewEventRemote("SquadService", 0.3);
	RemotesManager:NewEventRemote("SquadSync");
	RemotesManager:NewFunctionRemote("PlayerSearch", 5);
	
	--== Safehome
	RemotesManager:NewFunctionRemote("SafehomeRequest", 1);
	
	--== Shop
	RemotesManager:NewFunctionRemote("ShopService", 0.1);
	RemotesManager:NewFunctionRemote("MysteryChest", 1);
	
	--== GameModes;
	RemotesManager:NewFunctionRemote("GameModeLobbies", 1).Secure = true;
	RemotesManager:NewFunctionRemote("GameModeRequest", 0.1).Secure = true;
	RemotesManager:NewFunctionRemote("GameModeExit", 1);
	RemotesManager:NewEventRemote("GameModeUpdate");
	RemotesManager:NewEventRemote("GameModeHud");
	RemotesManager:NewEventRemote("GameModeAssign");
	
	--== Gameplay
	RemotesManager:NewEventRemote("CreateInfoBubble");
	RemotesManager:NewEventRemote("GenerateArcParticles");
	RemotesManager:NewEventRemote("PlayerStatusEffect");
	RemotesManager:NewEventRemote("SyncStatusEffect");
	RemotesManager:NewEventRemote("SetPlayerFace", 0.25);
	RemotesManager:NewFunctionRemote("ToggleDefaultAccessories", 0.1);
	
	RemotesManager:NewFunctionRemote("SetPoster", 0.1);
	RemotesManager:NewFunctionRemote("SetPlayerTitle", 1);
	RemotesManager:NewFunctionRemote("FastTravel", 1);
	RemotesManager:NewFunctionRemote("CharacterInteractions", 0.1);
	
	RemotesManager:NewFunctionRemote("CardGame",0.1).Secure = true;
	
	--== Tools;
	RemotesManager:NewEventBridge("ToolInputHandler");
	do -- Identifiers
		RemotesManager.NewRef("InputType");
		RemotesManager.NewRef("InputObject");
		RemotesManager.NewRef("KeyIds");
		RemotesManager.NewRef("KeyCode");
		RemotesManager.NewRef("KeyIds");
		RemotesManager.NewRef("Action");
		RemotesManager.NewRef("SiId");
		RemotesManager.NewRef("ActionIndex");
		
		RemotesManager.NewRef("PrimaryEffectMod");
	end
	
	
	RemotesManager:NewEventRemote("ToolHandlerPrimaryFire").Secure = true; -- to do: deprecate;
	
	--== Workbench;
	RemotesManager:NewFunctionRemote("DeconstructItem", 0.5);
	RemotesManager:NewFunctionRemote("TweakItem", 0.5);
	RemotesManager:NewFunctionRemote("PolishTool", 0.5);
	RemotesManager:NewFunctionRemote("BlueprintHandler", 0.1);
	
	--== Skill Tree;
	RemotesManager:NewEventRemote("SkillTree");
	RemotesManager:NewEventRemote("ThreatSenseSkill");
	
	--== Weapons;
	RemotesManager:NewEventRemote("PrimaryFire").Secure = true;
	RemotesManager:NewEventRemote("ReloadWeapon");
	RemotesManager:NewEventRemote("SimulateProjectile");
	RemotesManager:NewEventRemote("ClientProjectileHit").Secure = true;
	RemotesManager:NewFunctionRemote("ItemModAction", 0.1).Secure = true;
	
	--== Storage;
	RemotesManager:NewFunctionRemote("StorageService", 0.1);
	RemotesManager:NewFunctionRemote("StorageCombine", 0.1).Secure = true;
	RemotesManager:NewFunctionRemote("StorageRemoveItem", 0.1).Secure = true;
	RemotesManager:NewFunctionRemote("StorageSetSlot", 0.1).Secure = true;
	RemotesManager:NewFunctionRemote("StorageSplit", 0.1).Secure = true;
	RemotesManager:NewFunctionRemote("StorageSwapSlot", 0.1).Secure = true;
	RemotesManager:NewFunctionRemote("UpgradeStorage", 0.5);
	RemotesManager:NewFunctionRemote("UseStorageItem", 0.5);
	RemotesManager:NewFunctionRemote("ToggleClothing", 0.5);
	RemotesManager:NewEventRemote("StorageDestroy");
	RemotesManager:NewEventRemote("StorageSync");

	RemotesManager:NewEventRemote("StorageItemSync");
	RemotesManager:NewEventRemote("ItemActionHandler");
	
	RemotesManager:NewFunctionRemote("RenameItem", 1);
	
	--== Social
	RemotesManager:NewEventRemote("DuelRequest");
	RemotesManager:NewEventRemote("TravelRequest");
	
	--== Trading Service;
	RemotesManager:NewEventRemote("TradeRequest");
	
	
	--== Tools
	RemotesManager:NewFunctionRemote("BoomboxRemote", 1);
	RemotesManager:NewFunctionRemote("DisguiseKitRemote", 1);
	RemotesManager:NewFunctionRemote("GpsRemote", 1);
	
	RemotesManager:NewEventBridge("InstrumentRemote");
	do --Indentifiers
		RemotesManager.NewRef("StorageItemID")
		RemotesManager.NewRef("Prefabs")
		RemotesManager.NewRef("Data")
		RemotesManager.NewRef("Instrument");
		RemotesManager.NewRef("OwnerPlayer");
	end
	
	--== ChatService
	RemotesManager:NewFunctionRemote("ChatService", 0.5);
	RemotesManager:NewEventRemote("NewClientMessage");
	RemotesManager:NewFunctionRemote("SubmitMessage", 1);
	RemotesManager:NewEventRemote("SubmitChatReport");

	--== LeaderboardService
	RemotesManager:NewEventRemote("LeaderboardService");
	
	--== FactionServices
	RemotesManager:NewFunctionRemote("FactionService", 0.5).Secure = true;
	
	--== Misc
	RemotesManager:NewFunctionRemote("VoteSystem", 1).Secure = true;
	RemotesManager:NewFunctionRemote("Halloween", 1);
	RemotesManager:NewFunctionRemote("LockHydra").Secure = true;
	

	local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));
	local moddedSelf = modModEngineService:GetModule(script.Name);
	if moddedSelf then moddedSelf:Init(RemotesManager); end
end
isRemotesReady = true;
bindWaitForRemotesReady:Fire();

RemotesManager.Remote = RemotesManager:Get("RemoteManager");
local remoteTestRemote = RemotesManager:Get("TestRemote");

if RunService:IsClient() then
	RemotesManager.Remote.OnClientEvent:Connect(function(key, value)
		RemotesManager[key] = value;
	end)
	
	remoteTestRemote.OnEvent:Connect(function(packet)
		packet =  RemotesManager.Uncompress(packet);

		Debugger:Warn("TestRemote Uncompressed:",packet);
	end)

else
	-- Server;
	task.spawn(function()
		Debugger.AwaitShared("modCommandsLibrary");
		
		
		shared.modCommandsLibrary:HookChatCommand("remotes", {
			Permission = shared.modCommandsLibrary.PermissionLevel.Admin;
			Description = [[Server remotes commands:
			/remotes viewdata [sortby:Calls;MaxSize;MinSize;TotalSize]
			/remotes togglerecord
			/remotes test
			]];

			RequiredArgs = 0;
			Function = function(speaker, args)
				
				local action = args[1];
				
				if action == "viewdata" then
					
					local list = {};
					for remoteName, remoteRecord in pairs(RemotesManager.Records) do
						
						for callType, callRecords in pairs(remoteRecord) do
							table.insert(list, {
								Name=remoteName;
								CallType=callType;
								Calls=callRecords.Calls;
								MaxSize=callRecords.MaxSize;
								MinSize=callRecords.MinSize;
								TotalSize=callRecords.TotalSize;
							})
						end
					end
					
					if #list <= 0 then
						shared.Notify(speaker, "No remotes on list.", "Negative");
						return;
					end
					
					local sortBy = args[2] or "TotalSize";
					if list[1][sortBy] == nil then
						sortBy = "TotalSize";
					end
					
					table.sort(list, function(a, b)
						return a[sortBy] > b[sortBy];
					end)
					
					local rStr = "<b>Remotes Usage, sort by: ".. sortBy;
					
					for a=1, math.min(#list, 64) do
						local remoteData = list[a];
						
						rStr = rStr.."\n    - ".. remoteData.Name .." -- Calls: ".. remoteData.Calls 
							.. " | \t Type: ".. remoteData.CallType
							.. " | \t Max: ".. remoteData.MaxSize
							.. " | \t Min: ".. remoteData.MinSize
							.. " | \t Total: ".. remoteData.TotalSize
					end
					
					Debugger:Warn(rStr);
					shared.Notify(speaker, rStr, "Inform");
					
				elseif action == "togglerecord" then
					
					RemotesManager.RecordRemotes = not RemotesManager.RecordRemotes;
					shared.Notify(speaker, "Toggle Record Remotes: ".. tostring(RemotesManager.RecordRemotes), "Info");
					Debugger:Warn("Toggle Record Remotes: ".. tostring(RemotesManager.RecordRemotes));
					
				elseif action == "test" then
					
					local packet = {
						Action="test";
						Test="Example";
						Index=math.random(1, 1000);
					}
					packet = RemotesManager.Compress(packet);
					Debugger:Warn("TestRemote Compressed:",packet);
					
					remoteTestRemote:Fire(speaker, packet);
					
					shared.Notify(speaker, "Fired test", "Info");
					
				else
					shared.Notify(speaker, "Unknown action for /remotes", "Negative");

				end

				return;
			end;
		});

	end)

end


return RemotesManager;