local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
-- Settings;

-- Variables;
local RunService = game:GetService("RunService");
local SoundService = game:GetService("SoundService");

local modLazyLoader = require(game.ReplicatedStorage.Library.LazyLoader);

local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));
local moddedSelf = modModEngineService:GetModule(script.Name);

local Library = {};
local lazyLoader = modLazyLoader.new(script);

local proxySound = Instance.new("Sound");

--==
if RunService:IsServer() then
	local serverAudio = script:WaitForChild("ServerAudio");

	if serverAudio then
		local soundFiles = serverAudio:GetChildren();
		for a=1, #soundFiles do
			if soundFiles[a]:IsA("Sound") then
				if moddedSelf then
					moddedSelf.OnAudioLoad(soundFiles[a]);
				end
				Library[soundFiles[a].Name] = soundFiles[a];
			end
		end
	end

	lazyLoader:ConnectOnServerRequested(function(player, key)
		local audioInstance = Library[key];
		if audioInstance == nil then return end;

		local new = audioInstance:Clone();
		new.Parent = player.PlayerGui;
		Debugger.Expire(new, 5);

		return new;
	end)
end
if RunService:IsClient() then
	lazyLoader:ConnectOnClientLoad(function(key: string, sound: Sound)
		local new = sound:Clone();
		new.Parent = script.ClientAudio;
		Library[key] = new;
	end)
end


if moddedSelf then
	moddedSelf:Init(Library);
end


function Get(id)
	local audioInstance = Library[id];
	if audioInstance ~= nil then
		return audioInstance;
	end
	return;
end

function Play(id, parent, looped, pitch, volume) : Sound
	if id == nil then return proxySound; end;
	local audioInstance = Library[id];
	
	if typeof(id) == "Instance" and id:IsA("Sound") then
		audioInstance = id;
	end
	
	if audioInstance == nil then
		Debugger:Warn("Audio missing (",id,").");
		if RunService:IsClient() then
			lazyLoader:Request(id);
		end
		return proxySound;
	end

	if parent == nil then
		if RunService:IsClient() then
			local _loop = audioInstance.Looped;
			audioInstance.Looped = true;
			SoundService:PlayLocalSound(audioInstance);
			audioInstance.Looped = false;
		else
			--PlayReplicated(id, parent);
		end
		return audioInstance;
	else
		local n;
		if typeof(parent) == "Vector3" then
			n = Instance.new("Attachment");
			n.Parent = workspace.Terrain;
			n.WorldPosition = parent;
			
			parent = n;
		end
		
		local newSound = audioInstance:Clone();
		newSound.Parent = parent;
		newSound.PlaybackSpeed = pitch or newSound.PlaybackSpeed;
		newSound.Volume = volume or newSound.Volume;
		if looped == true then newSound.Looped = true; end
		newSound:Play();
		newSound.Ended:Connect(function()
			game.Debris:AddItem(newSound, 0.1);
			if n then
				game.Debris:AddItem(n, 0.1);
			end
		end);
		return newSound;
	end

end

function PlayReplicated(id, parent, looped, pitch, volume)
	if RunService:IsServer() then error("Audio>>  Failed to play audio from server. Use Play() instead."); return end;
	local audioInstance = Library[id];
	if audioInstance ~= nil then
		if parent == nil then
			SoundService:PlayLocalSound(audioInstance);
			return audioInstance;
		else
			local newSound = audioInstance:Clone();
			newSound.Parent = parent;
			newSound.PlaybackSpeed = pitch or newSound.PlaybackSpeed;
			newSound.Volume = volume or newSound.Volume;
			if looped ~= nil and looped then newSound.Looped = true; end
			newSound:Play();
			
			newSound.Ended:Connect(function() RunService.Stepped:Wait(); newSound:Destroy() end);
			return newSound;
		end
	end
	return;
end

function Load(child, soundGroupName)
	if child:IsA("Sound") then 
		warn("Importing new audio file(",child,").");
		child.Parent = script;
		
		soundGroupName = soundGroupName or child:GetAttribute("SoundGroupId");
		
		if soundGroupName == nil then
			if child.TimeLength < 60 then
				soundGroupName = "Effects";
			else
				soundGroupName = "BackgroundMusic";
			end
		end
		
		child.SoundGroup = SoundService:FindFirstChild(soundGroupName) or SoundService.BackgroundMusic;
		
		Library[child.Name] = child;
	end
end

function Preload(key)
	if RunService:IsClient() then
		lazyLoader:Request(key);
	end
end

script.ChildAdded:Connect(Load)

return {
	Play = Play;
	PlayReplicated = PlayReplicated;
	Get = Get;
	Preload = Preload;
	Library = Library;
	Load = Load;
	ModdedSelf = moddedSelf;
	Script = script;
};