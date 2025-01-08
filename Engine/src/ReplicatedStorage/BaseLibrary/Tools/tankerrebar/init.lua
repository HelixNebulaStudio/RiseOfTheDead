local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local toolPackage = {
	Type="Melee";
	Animations={
		Core={Id=16798872611;};
		SlamAttack={Id=16805205137; Markers={"SlamImpact"};};
		SpinAttack={Id=16805046629; Markers={"SpinStart"; "SpinEnd";}};
	};
	Audio={
		PrimaryHit={Id=4844105915; Pitch=1.4; Volume=1;};
		PrimarySwing={Id=4601593953; Pitch=1.4; Volume=1;};
	};
};

--==
local modMeleeProperties = require(game.ReplicatedStorage.Library.Tools.MeleeProperties);

function toolPackage.NewToolLib(handler)
	local Tool = {};
	Tool.Class = "Melee";
	
	Tool.Configurations = {
		Type="Sword";
		EquipLoadTime=1.25;
		BaseDamage=5;

		PrimaryAttackSpeed=0.5;
		PrimaryAttackAnimationSpeed=1.1;

		HitRange=20;

		WaistRotation=math.rad(0);

		StaminaCost = 18;
		StaminaDeficiencyPenalty = 0.8;

	};

	Tool.Properties = {
		Attacking=false;
	}

	function Tool:OnMarkerEvent(wieldData: {any}, trackData: {any}, paramString: string)
		local toolModel = wieldData.Instances[1];
		local handle = toolModel.PrimaryPart;
		local impactPointAtt = handle.ImpactPoint;
		
		
		if paramString == "SlamImpact" then
			
			local modAoeHighlight = require(game.ReplicatedStorage.Particles.AoeHighlight);
			local modParticleSprinkler = require(game.ReplicatedStorage.Particles.ParticleSprinkler);
			local modTDParticles = require(game.ReplicatedStorage.Particles.TDParticles);
			
			local groundCf = modAoeHighlight:Ray(impactPointAtt.WorldPosition + Vector3.yAxis*2, Vector3.yAxis*-4);
			if groundCf then

				local particlePacket = {
					Type=1;
					Origin=groundCf;
					SpreadRange={Min=-0.5; Max=0.5};
					Velocity=Vector3.new(0, 1, 0);
					SizeRange={Min=0.3; Max=1};
					Material=Enum.Material.Slate;
					DespawnTime=3;
					Speed=30;
					Color = Color3.fromRGB(65, 46, 33);
					
					MinSpawnCount=6;
					MaxSpawnCount=8;
				};
				modParticleSprinkler:Emit(particlePacket);

				local shockWavePacket = {
					Type="Shockwave";

					TweenInfo=TweenInfo.new(1, Enum.EasingStyle.Cubic);
					Origin=CFrame.new(groundCf.Position);
					
					StartSize=Vector3.new(4, 0.5, 4);
					EndSize=Vector3.new(18, 1, 18);
				};
				modTDParticles:Emit(shockWavePacket);
			end
			
		end
	end
	
	Tool.__index = Tool;
	setmetatable(Tool, handler);
	return modMeleeProperties.new(Tool);
end

return toolPackage;