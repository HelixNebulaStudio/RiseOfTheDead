local Physics = {};
local PhysicsService = game:GetService("PhysicsService");

-- Default;
Physics.CollisionLayers = {
	"Players"; 
	"Debris";
	"Characters";
	"Enemies";
	"Entities";
	
	"PlayerClips";
	"EnemyClips";
	"Accessories";
	"Structure";
	"Tool";
	
	"CollisionOff";
	"RaycastIgnore";
	"Raycast";
	"DynamicPlatform";
	"EnemiesSpawn";
	
	"DefaultIgnore";
};

for a=1, #Physics.CollisionLayers do
	PhysicsService:RegisterCollisionGroup(Physics.CollisionLayers[a]);
end


--== Accessories
PhysicsService:CollisionGroupSetCollidable("Accessories", "Default", false);

--== Debris
PhysicsService:CollisionGroupSetCollidable("Debris","Debris", true);
--PhysicsService:CollisionGroupSetCollidable("Debris","Players", false);
PhysicsService:CollisionGroupSetCollidable("Debris","Characters", false);

--== Characters
PhysicsService:CollisionGroupSetCollidable("Characters","Players", false);
PhysicsService:CollisionGroupSetCollidable("Characters","Characters", false);

--== Enemies
PhysicsService:CollisionGroupSetCollidable("Enemies","PlayerClips", false);
PhysicsService:CollisionGroupSetCollidable("Characters","PlayerClips", false);

--== EnemiesSpawn
PhysicsService:CollisionGroupSetCollidable("EnemiesSpawn","PlayerClips", false);
PhysicsService:CollisionGroupSetCollidable("EnemiesSpawn","Enemies", false);
PhysicsService:CollisionGroupSetCollidable("EnemiesSpawn","EnemiesSpawn", false);


--== Players
PhysicsService:CollisionGroupSetCollidable("Players","EnemyClips", false);
PhysicsService:CollisionGroupSetCollidable("Players","Players", false);
--PhysicsService:CollisionGroupSetCollidable("Players","Debris", false);

--== Entities
PhysicsService:CollisionGroupSetCollidable("Entities","Players", true);
PhysicsService:CollisionGroupSetCollidable("Entities","Characters", true);
PhysicsService:CollisionGroupSetCollidable("Entities","Structure", true);

--== Structure
PhysicsService:CollisionGroupSetCollidable("Structure","Characters", false);

--== Tool
PhysicsService:CollisionGroupSetCollidable("Tool","Tool", false);
PhysicsService:CollisionGroupSetCollidable("Tool","Default", false);
PhysicsService:CollisionGroupSetCollidable("Tool","Players", false);
PhysicsService:CollisionGroupSetCollidable("Tool","Characters", false);

--== Raycast
PhysicsService:CollisionGroupSetCollidable("Raycast","Default", true);
PhysicsService:CollisionGroupSetCollidable("Raycast","Players", true);
PhysicsService:CollisionGroupSetCollidable("Raycast","Characters", true);
PhysicsService:CollisionGroupSetCollidable("Raycast","Entities", true);
PhysicsService:CollisionGroupSetCollidable("Raycast","Enemies", true);
PhysicsService:CollisionGroupSetCollidable("Raycast","Structure", true);
PhysicsService:CollisionGroupSetCollidable("Raycast","CollisionOff", true);
PhysicsService:CollisionGroupSetCollidable("Raycast", "RaycastIgnore", false);

--== RaycastIgnore; Set via client side;
PhysicsService:CollisionGroupSetCollidable("RaycastIgnore","Players", false);

--== CollisionOff
PhysicsService:CollisionGroupSetCollidable("CollisionOff","Default", false);
for a=1, #Physics.CollisionLayers do
	if Physics.CollisionLayers[a] ~= "Raycast" then
		PhysicsService:CollisionGroupSetCollidable("CollisionOff", Physics.CollisionLayers[a], false);
	end
end

--== TrainParts
PhysicsService:CollisionGroupSetCollidable("DefaultIgnore", "Default", false);
PhysicsService:CollisionGroupSetCollidable("DefaultIgnore", "DefaultIgnore", false);

return Physics;
