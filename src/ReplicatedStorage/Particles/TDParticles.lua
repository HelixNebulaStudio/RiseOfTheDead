local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== 
local TDParticles = {};
--==
local Debris = game:GetService("Debris");
local TweenService = game:GetService("TweenService");


function TDParticles:Emit(packet)
	local particleType = packet.Type;
	
	if particleType == "Shockwave" then
		
		assert(packet.Origin, "Missing origin");
		assert(packet.TweenInfo, "Missing tweenInfo");
		
		local newWave: MeshPart = script.Shockwave:Clone();
		Debugger.Expire(newWave, packet.Lifespan or 1);
		newWave.Size = packet.StartSize or Vector3.new(2,0.2,2);
		newWave.CFrame = packet.Origin;
		
		newWave.Color = packet.WaveColor or newWave.Color;
		newWave.Material = packet.WaveMaterial or newWave.Material;
		newWave.TextureID = packet.WaveTextureID or newWave.TextureID;
		
		newWave.Parent = workspace.Debris;

		TweenService:Create(newWave, packet.TweenInfo, {
			Size=packet.EndSize or Vector3.new(4, 0.2, 4);
			Transparency=1;
		}):Play();
	end
	
end

return TDParticles;
