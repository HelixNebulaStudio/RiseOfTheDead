local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);

--== Script;
local Component = {};
Component.ClassName = "NpcComponent";
Component.__index = Component;

function Component.onRequire()
	remoteNpcComponent = modRemotesManager:Get("NpcComponent");
end

function Component.new(npcClass: NpcClass)
	local self = {
		NpcClass = npcClass;
	};
	
	setmetatable(self, Component);

	local properties = npcClass.Properties;
	properties.OnChanged:Connect(function(k, v, nv) 
		if k ~= "EnemyTargetData" then return end;
		if v == nil then return end;

		local lastV = v;
		while not npcClass.HealthComp.IsDead and properties.EnemyTargetData == lastV do
			self();
			task.wait(9);
		end
	end)
	
	return self;
end

function Component:Setup()
	self();
end

function Component:__call()
	local npcClass: NpcClass = self.NpcClass;

	if npcClass.Properties.ThreatSenseHidden == true then return end;
	if workspace:GetAttribute("ModifiersBlackout") then return end; -- Survival;

	local enemyTargetData = npcClass.Properties.EnemyTargetData;
	if enemyTargetData == nil then return end;

	local playerClass: PlayerClass = enemyTargetData.HealthComp.CompOwner;
	if playerClass.ClassName ~= "PlayerClass" then return end;
	if not playerClass.HealthComp:CanTakeDamageFrom(npcClass) then return end;

	local player = playerClass:GetInstance();
	if player == nil then return end;

	task.spawn(function()
		local profile = shared.modProfile:Get(player);
		if profile == nil then return end

		local skillData = profile.SkillTree:GetSkill(player, "thrsen");
		if skillData.Points <= 0 then
			return;
		end

		local skillLvl, skillStat = profile.SkillTree:CalStats(skillData.Library, skillData.Points);
		local distance = skillStat.Amount.Value;
		
		if playerClass:DistanceFrom(npcClass:GetCFrame().Position) > distance then
			return;
		end
		
		remoteNpcComponent:FireClient(player, "ThreatSense", "threatsense", npcClass.Character);
	end)
end


return Component;