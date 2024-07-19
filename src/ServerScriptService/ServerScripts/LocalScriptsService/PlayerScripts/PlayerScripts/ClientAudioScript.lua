return function()
	--== Variables;
	local SoundService = game:GetService("SoundService");
	local RunService = game:GetService("RunService");
	
	local modConfigurations = require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("Configurations"));
	local modAudio = require(game.ReplicatedStorage.Library:WaitForChild("Audio"));
	local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
	
	local remotePlayAudio = modRemotesManager:Get("PlayAudio"); --game.ReplicatedStorage.Remotes.;
	
	local random = Random.new();
	
	--== Script;
	remotePlayAudio.OnClientEvent:Connect(function(audio, audioParent, pitch, volume)
		if audio == nil then return end;
		if audioParent == nil then return end;
		
		local newSound = audio:Clone();
		newSound.Parent = audioParent;
		newSound:Play();
		newSound.PlaybackSpeed = pitch or newSound.PlaybackSpeed;
		newSound.Volume = volume or newSound.Volume;
		
		newSound.Ended:Connect(function() task.wait(); newSound:Destroy() end);
	end)
	
	if modConfigurations.SpecialEvent.Halloween then
		while wait(random:NextNumber(60, 180)) do
			local soundName = "FarThunder"..random:NextInteger(1, 2);
			
			modAudio.Preload(soundName, 5);
			local sound = modAudio.Play(soundName);
			if sound then
				sound.Volume = 0.6;
			end
			
			spawn(function()
				wait(random:NextNumber(0.2, 0.4));
				game.Lighting.Ambient = Color3.fromRGB(121, 136, 181);
				wait(0.05);
				game.Lighting.Ambient = Color3.fromRGB(25, 25, 25);
				wait(random:NextNumber(0.05, 0.1));
				game.Lighting.Ambient = Color3.fromRGB(121, 136, 181);
				wait(0.05);
				game.Lighting.Ambient = Color3.fromRGB(25, 25, 25);
				if random:NextInteger(1, 2) == 1 then
					wait(random:NextNumber(0.05, 0.1));
					game.Lighting.Ambient = Color3.fromRGB(121, 136, 181);
					wait(0.05);
					game.Lighting.Ambient = Color3.fromRGB(25, 25, 25);
				end
			end)
		end
	end
end