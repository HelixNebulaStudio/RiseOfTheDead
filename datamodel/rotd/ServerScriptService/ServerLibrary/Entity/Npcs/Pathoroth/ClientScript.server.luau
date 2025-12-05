local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local characterTag = script:WaitForChild("Character");
repeat task.wait(0.1) until characterTag.Value ~= nil;

local character = characterTag.Value;
if not workspace:IsAncestorOf(character) then return end;

local localplayer = game.Players.LocalPlayer;
local modData = shared.require(localplayer:WaitForChild("DataModule") :: ModuleScript);
local modCharacter = modData:GetModCharacter();
--==

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local humanoid = character:WaitForChild("Zombie");
local rootPart = character:WaitForChild("HumanoidRootPart");


local Tracks = {};
local function screenShake()
	local distance = localplayer:DistanceFromCharacter(rootPart.Position);
	modCharacter.CameraShakeAndZoom(math.clamp((128-distance)/128, 0, 1)*8, 0, 0.5, nil, false);
end

local lastStep = tick()-1;
local foundTrack = nil;
repeat
	local tracks = humanoid:GetPlayingAnimationTracks();
	for a=1, #tracks do
		if Tracks[tracks[a]] == nil then
			
			Tracks[tracks[a]] = tracks[a]:GetMarkerReachedSignal("Step"):Connect(function(paramString)
				if tick()-lastStep <= 0.15 then return end;
				lastStep = tick();
				
				if paramString == "1" then
					foundTrack = tracks[a];
					if character:FindFirstChild("RightHand") then
						modAudio.Play("HeavyThump", character.RightHand.PrimaryPart).PlaybackSpeed = math.random(65, 100)/100;
					end
					screenShake();
				elseif paramString == "2" then
					foundTrack = tracks[a];
					if character:FindFirstChild("LeftHand") then
						modAudio.Play("HeavyThump", character.LeftHand.PrimaryPart).PlaybackSpeed = math.random(65, 100)/100;
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