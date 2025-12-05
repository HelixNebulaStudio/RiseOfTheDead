local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClass);
--==

local toolPackage = {
	ItemId=script.Name;
	Class="Melee";
	HandlerType="MeleeTool";

	Animations={
		Core={Id=16798872611;};
		PrimaryAttack={Id=78050388072797;};
		SlamAttack={Id=16805205137; Markers={"SlamImpact"};};
		SpinAttack={Id=16805046629; Markers={"SpinStart"; "SpinEnd";}};
	};
	Audio={
		Load={Id=2304904662; Pitch=1; Volume=0.4;};
		PrimaryHit={Id=9141019032; Pitch=1; Volume=1;};
		PrimarySwing={Id=158037267; Pitch=0.8; Volume=0.6;};
	};
	
	Configurations={
		Category = "Blunt";
		Type="Sword";

		EquipLoadTime=1.25;
		Damage=10;

		PrimaryAttackSpeed=0.5;
		PrimaryAttackAnimationSpeed=1.1;
		HitRange=20;

		WaistRotation=math.rad(0);

		StaminaCost = 18;
		StaminaDeficiencyPenalty = 0.8;
	};
	Properties={};
};

function toolPackage.OnMarkerEvent(handler: ToolHandlerInstance, animId: string, animTrack: AnimationTrack, paramString: string)
	local toolModel = handler.MainToolModel;
	local handle = toolModel.PrimaryPart;
	local impactPointAtt = handle.ImpactPoint;
	
	if paramString == "SlamImpact" then
		local modAoeHighlight = shared.require(game.ReplicatedStorage.Particles.AoeHighlight);
		local modParticleSprinkler = shared.require(game.ReplicatedStorage.Particles.ParticleSprinkler);
		local modTDParticles = shared.require(game.ReplicatedStorage.Particles.TDParticles);
		
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

function toolPackage.newClass()
	return modEquipmentClass.new(toolPackage);
end

return toolPackage;