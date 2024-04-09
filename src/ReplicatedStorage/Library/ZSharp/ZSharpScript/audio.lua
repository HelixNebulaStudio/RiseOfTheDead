local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local modAudio = require(game.ReplicatedStorage.Library.Audio);


--
local ZSharp = {};

function ZSharp.Load(zSS, zEnv)
	local AudioMeta = {};
	AudioMeta.__index = AudioMeta;
	AudioMeta.__metatable = "The metatable is locked";
	
	AudioMeta.hintPlay = "Plays an Sound.";
	AudioMeta.descPlay = [[Plays an Audio.
		<b>Audio:Play</b>(soundName: <i>string</i>): <i>ZSound</i>
	]];

	AudioMeta.hintNew = "Creates a new Sound by name.";
	AudioMeta.descNew = [[Creates a new Sound by name.
		<b>Audio:New</b>(soundName: <i>string</i>): <i>ZSound</i>
	]];

	AudioMeta.hintFind = "Find an Sound by name match.";
	AudioMeta.descFind = [[Finds an Audio.
		<b>Audio:Find</b>(pattern: <i>string</i>): <i>{string}</i>
	]];
	
	local Audio = {};
	setmetatable(Audio, AudioMeta);
	
	function Audio:Play(soundName: string)
		local sound = modAudio.Play(soundName, workspace); 
		local newZSound = zEnv.new("ZSound", sound);
		return newZSound;
	end

	function Audio:New(soundName: string)
		local sound = modAudio.Get(soundName); 
		if sound == nil then return; end
		
		local newSound = sound:Clone();
		newSound.Parent = workspace;
		
		local newZSound = zEnv.new("ZSound", sound);
		return newZSound;
	end
	
	function Audio:Find(pattern: string)
		local r = {};
		
		for _, obj in pairs(modAudio.Script:GetChildren()) do
			if string.match(obj.Name, pattern) then
				table.insert(r, obj.Name);
			end
		end
		
		return r;
	end
	
	
	zEnv.Audio = Audio;
end

return ZSharp;