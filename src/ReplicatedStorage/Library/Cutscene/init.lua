local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Cutscene = {};
Cutscene.__index = Cutscene;
Cutscene.Scenes = {};
Cutscene.Status = {Playing=1; Paused=2; Ended=3;};
Cutscene.QualityLevel = 10;
Cutscene.Script = script;
Cutscene.ActiveCutscenes = {};

local RunService = game:GetService("RunService");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local remotes = game.ReplicatedStorage:WaitForChild("Remotes");
local remotePlayClientScene = remotes:WaitForChild("Cutscene"):WaitForChild("PlayClientScene");
local remoteContinueScene = remotes:WaitForChild("Cutscene"):WaitForChild("ContinueScene");
local remoteClientReady = remotes:WaitForChild("Cutscene"):WaitForChild("ClientReady");
local bindPlayServerScene = remotes:WaitForChild("Cutscene"):WaitForChild("PlayServerScene");

local CutsceneSequence = {};

--== Script;
function Cutscene.load(src)
	src.Parent = script;
	Cutscene.Scenes[src.Name] = {Name=src.Name; File=src;};
end

for _, scene in pairs(script:GetChildren()) do
	if scene.ClassName == "ModuleScript" then
		Cutscene.load(scene);
	end
end
script.ChildAdded:Connect(function(child)
	if child:IsA("ModuleScript") then
		Cutscene.load(child);
	end
end)

function CutsceneSequence.new(cutscene)
	local sequenceMeta = setmetatable({}, Cutscene);
	sequenceMeta.__index = sequenceMeta;
	
	local sequence = setmetatable({}, sequenceMeta);
	sequence.InitialScene = "Start"

	function sequenceMeta:GetCutscene() return cutscene; end;
	function sequenceMeta:GetPlayers()
		local players = {};
		for a=1, #cutscene.Players do table.insert(players, cutscene.Players[a]); end;
		return players;
	end;
	function sequenceMeta:AddPlayer(player)
		if table.find(cutscene.Players, player) == nil then
			table.insert(cutscene.Players, player);
		end
	end
	
	function sequenceMeta:Initialize(sceneFunc)
		if RunService:IsServer() then
			sequence[sequence.InitialScene] = sceneFunc;
		end
	end
	
	function sequenceMeta:NewScene(sceneName, sceneFunc)
		if RunService:IsServer() then
			sequence[sceneName] = function()
				if modBranchConfigs.IsWorld("MainMenu") then return end;
				if #cutscene.Players <= 0 then Debugger:Warn("No players in cutscene:",cutscene); return end;
				local completed = {};
				local allComplete = false;
				
				cutscene:ForEachPlayer(function(player)
					completed[player.Name] = false;
					local success, failedErr = pcall(function()
						local invoked = false;
						task.spawn(function()
							remotePlayClientScene:InvokeClient(player, cutscene.Name, sceneName);
							invoked = true;
						end)
						for a=1, 5, 0.1 do
							if not invoked then
								task.wait(0.1);
							else
								break;
							end
						end
						if not invoked then
							error(`Client ({player.Name}) failed to respond.`);
						end
					end)
					if not success then Debugger:Warn(`{cutscene.Name}:{sceneName} failed:`,failedErr) end;
					completed[player.Name] = true;
	
					local c = true;
					for playerName, completed in pairs(completed) do
						if not completed then c = false; break; end;
					end
					allComplete = c;

				end)
				
				for a=0, 5, 0.5 do
					if allComplete then break; end
					task.wait(0.5);
				end
			end;
		else
			sequence[sceneName] = sceneFunc;
		end
	end
	
	function sequenceMeta:NewServerScene(sceneName, sceneFunc)
		if RunService:IsServer() then
			sequence[sceneName] = sceneFunc;
		else
			--sequence[sceneName] = function() remotePlayServerScene:InvokeServer(cutscene.Name, sceneName); end;
		end
	end
	
	function sequenceMeta:NextScene(sceneName)
		if cutscene.Status == Cutscene.Status.Paused then return end;
		if sequence[sceneName] then
			sequence[sceneName]();
		else
			cutscene.Status = Cutscene.Status.Ended;
			Debugger:Warn("CutsceneSequence>>  Next scene(",sceneName,") does not exist.");
		end
	end
	
	function sequenceMeta:Pause(timeout)
		if RunService:IsServer() then
			local completed = {};
			local allComplete = false;
			
			local function check()
				if allComplete == true then return end;
				local c = true;
				for playerName, completed in pairs(completed) do
					if not completed then c = false; break; end;
				end
				allComplete = c;
			end
			cutscene:ForEachPlayer(function(player)
				completed[player.Name] = false;
				remoteContinueScene:FireClient(player);
			end)
			local continueConnection = remoteContinueScene.OnServerEvent:Connect(function(player)
				if completed[player.Name] ~= nil then
					completed[player.Name] = true;
				end
				
				check();
			end)

			for a=1, timeout, 0.2 do
				task.wait(0.2);
				
				cutscene:ForEachPlayer(function(player)
					if completed[player.Name] ~= true then
						remoteContinueScene:FireClient(player);
					end
				end)
				check();
				
				if allComplete then break; end;
			end
			
			continueConnection:Disconnect();
			cutscene:ForEachPlayer(function(player)
				remoteContinueScene:FireClient(player, true);
			end)
		end
	end
	
	return sequence;
end

function Cutscene.New(cutsceneName)
	local library = Cutscene.Scenes[cutsceneName];
	if library == nil then Debugger:Warn("Cutscene.New (",cutsceneName,") does not exist."); return end;
	
	local cutscene = {
		Name=library.Name;
		File=library.File;
		Sequence=nil;
	};
	if cutscene.Sequence == nil then
		local cutsceneSequence = Debugger:Require(cutscene.File)(CutsceneSequence.new(cutscene));
		if cutsceneSequence == nil then
			Debugger:Warn("Cutscene(",cutsceneName,") didn't load.");
			return
		end;
		
		cutscene.Sequence = cutsceneSequence;
		cutscene.Status = Cutscene.Status.Paused;
		cutscene.Players = {};
		cutscene.Play = function(self, sceneName)
			sceneName = sceneName or self.Sequence.InitialScene;
			if sceneName and self.Sequence[sceneName] then
				cutscene.Status = Cutscene.Status.Playing;
				task.spawn(self.Sequence[sceneName]);
			else
				Debugger:Warn("Cutscene(",cutsceneName,") does not have scene(",sceneName,").");
			end
		end;
		cutscene.ForEachPlayer = function(self, func)
			for a=#self.Players, 1, -1 do
				local player = game.Players:FindFirstChild(self.Players[a].Name)
				if player then
					task.spawn(func, player);
				else
					Debugger:Log("Player (",self.Players[a].Name,") disconnected, removing from Cutscene.");
					table.remove(self.Players, a);
				end
			end
		end
	end 
	return cutscene;
end

if RunService:IsClient() then
	local activeCutscenes = {};
	function remotePlayClientScene.OnClientInvoke(cutsceneName, sceneName)
		if RunService:IsStudio() then
			Debugger:Warn("[Studio]","Play Cutscene ( "..cutsceneName..": "..sceneName.." )")
		end
		local modData = require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);

		local cutsceneObj = activeCutscenes[cutsceneName];
		if cutsceneObj == nil then
			cutsceneObj = Cutscene.New(cutsceneName);
			activeCutscenes[cutsceneName] = cutsceneObj;
		end

		local cutsceneSequence = cutsceneObj and cutsceneObj.Sequence;
		if cutsceneSequence and cutsceneSequence[sceneName] then
			cutsceneObj.Status = Cutscene.Status.Playing;

			cutsceneSequence.modData = modData;
			
			local modInterface = modData:GetInterfaceModule();
			while modInterface == nil do
				modInterface = modData:GetInterfaceModule();
				task.wait();
			end
			
			cutsceneSequence.modInterface = modInterface;

			cutsceneSequence[sceneName]();
		else
			Debugger:Warn("Cutscene>> Scene(",sceneName,") does not exist for (",cutsceneName,").");
		end
	end
	
	task.spawn(function()
		repeat
			remoteClientReady:FireServer();
			task.wait(1);
		until game.Players.LocalPlayer:GetAttribute("CutsceneReady") == true;
		Debugger:Log("Loaded Cutscene engine.");
	end)
	
else
	function Cutscene:WaitForReady(players)
		local timelapsed = 1;
		repeat
			local notready = false;
			for a=1, #players do
				if players[a]:GetAttribute("CutsceneReady") ~= true then
					notready = true;
					break;
				end
			end
			
			if notready then
				task.wait(1)
				
				if timelapsed%5 == 0 then
					local names = {};
					for a=1, #players do
						if players[a]:GetAttribute("CutsceneReady") ~= true then
							table.insert(names, players[a].Name)
						end
					end
					
					Debugger:Log("Waiting for (",table.concat(names, ", "),") for cutscene ready.")
				end
			else
				break;
			end
			
			timelapsed = timelapsed +1;
		until timelapsed >= 20;
	end
	
	function Cutscene:Init()
		remoteClientReady.OnServerEvent:Connect(function(player)
			if player:GetAttribute("CutsceneReady") ~= true then
				player:SetAttribute("CutsceneReady", true)
				Debugger:Log(player.Name," is cutscene ready.")
			end
		end)

		function bindPlayServerScene.OnInvoke(players, cutsceneName, sceneName)
			Debugger:Log("bind Play Cutscene ( ",(cutsceneName or "NULL")," ) for ", players);
			
			task.wait();
			local cutscene = Cutscene.New(cutsceneName);
			if cutscene and cutscene.Sequence then
				cutscene.Players = players or {};
				cutscene.Status = Cutscene.Status.Playing;
				
				Cutscene:WaitForReady(players)
				cutscene:Play(sceneName);
				
			else
				Debugger:Warn("PlayServerScene.OnInvoke Cutscene (",cutsceneName,") does not exist.");
				
			end
		end
	end
	
	function Cutscene:PlayCutscene(players, cutsceneName, sceneName)
		Debugger:Log("Play Cutscene ( ",(cutsceneName or "NULL")," ) for ", players);
	
		local cutscene = Cutscene.New(cutsceneName);
		if cutscene and cutscene.Sequence then
			cutscene.Players = players or {};
			cutscene.Status = Cutscene.Status.Playing;
			
			Cutscene:WaitForReady(players)
			cutscene:Play(sceneName);
		else
			Debugger:Warn("PlayCutscene (",cutsceneName,") does not exist.");
		end
	end	
	
end

local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));
local moddedSelf = modModEngineService:GetModule(script.Name);
if moddedSelf then moddedSelf:Init(Cutscene); end

return Cutscene;