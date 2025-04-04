local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local HealthComponent = {};
HealthComponent.__index = HealthComponent;

function HealthComponent.new(ownerClass)
    local self = {
        OwnerClass = ownerClass;
        IsDead = false;

        CurHealth = 100;
        MaxHealth = 100;
		KillHealth = 0;

		LastDamagedBy = nil;
    };

    setmetatable(self, HealthComponent);
    return self;
end

-- Get health component of the model.
function HealthComponent.getFromModel(model: Model)
	assert(typeof(model) == "Instance", `Invalid model type: {typeof(model)}`);
	
	if model:IsA("Accessory") then
		model = model.Parent;
	end
		
	while model:GetAttribute("EntityParent") do 
		model = model.Parent :: Model; 
	end 
	
	if RunService:IsServer() then
		local player: Player = game.Players:GetPlayerFromCharacter(model);
		local playerClass: PlayerClass = player and shared.modPlayers.Get(player);

		if playerClass then
			return playerClass.HealthComp;
		end

		local npcStatus = model:FindFirstChild("NpcStatus");
		if npcStatus then
			npcStatus = require(npcStatus);
			
			local npcClass: NpcClass = npcStatus:GetNpcClass();
			return npcClass.HealthComp;			
		end

		while model:GetAttribute("DestructibleParent") do
			model = model.Parent :: Model;
		end

		local destructibleModule = model:FindFirstChild("Destructible");
		if destructibleModule then
			local destructible: Destructible = require(destructibleModule);

			return destructible.HealthComp;
		end

	end	

	return;
end

function HealthComponent:Destroy()
	-- self.LastDamageCharacterClass = nil;
end

function HealthComponent:TakeDamage(damageData: DamageData)
    Debugger:Warn("Unimplemented TakeDamage.");	
end

function HealthComponent:CanTakeDamageFrom(attackerCharacter: CharacterClass)
    Debugger:Warn("Unimplemented CanTakeDamageFrom.");
end

return HealthComponent;