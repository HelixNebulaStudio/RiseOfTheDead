local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local localplayer = game.Players.LocalPlayer;

local modData = require(localplayer:WaitForChild("DataModule"));
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modCharacter = modData:GetModCharacter();

local prefabModel = script:WaitForChild("Prefab").Value; 
local humanoid = prefabModel:WaitForChild("Zombie");
local rootPart = prefabModel:WaitForChild("HumanoidRootPart");

local Tracks = {};

local random = Random.new();
--== Script;
local parentChangeSignal;
parentChangeSignal = prefabModel:GetPropertyChangedSignal("Parent"):Connect(function()
	if prefabModel.Parent ~= nil then return end
	parentChangeSignal:Disconnect();
	script:Destroy();
end)

local function screenShake()
	local distance = localplayer:DistanceFromCharacter(rootPart.Position);
	modCharacter.CameraShakeAndZoom(math.clamp((128-distance)/128, 0, 1)*4, 0, 0.5, nil, false);
end

local lastStep = tick()-1;
local foundTrack = nil;
repeat
	local tracks = humanoid:GetPlayingAnimationTracks();
	for a=1, #tracks do
		if Tracks[tracks[a]] == nil then
			
			Tracks[tracks[a]] = tracks[a]:GetMarkerReachedSignal("Step"):Connect(function(paramString)
				if humanoid.Health <= 0 then return end;
				if tick()-lastStep <= 0.15 then return end;
				lastStep = tick();
				
				if paramString == "1" then
					foundTrack = tracks[a];
					if prefabModel:FindFirstChild("RightFoot") then
						modAudio.Play("HeavyThump", prefabModel.RightLeg).PlaybackSpeed = random:NextNumber(1.2, 1.4);
					end
					screenShake();
					
				elseif paramString == "2" then
					foundTrack = tracks[a];
					if prefabModel:FindFirstChild("LeftFoot") then
						modAudio.Play("HeavyThump", prefabModel.LeftLeg).PlaybackSpeed = random:NextNumber(1.2, 1.4);
					end
					screenShake();
				end
			end)
		end
	end
until foundTrack ~= nil or not wait(1);

for track, connection in pairs(Tracks) do
	if track ~= foundTrack then
		Tracks[track]:Disconnect();
		Tracks[track] = nil;
	end
end