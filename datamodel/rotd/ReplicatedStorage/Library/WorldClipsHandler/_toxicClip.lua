local WorldClip = {};
WorldClip.__index = WorldClip;

local modTouchHandler = shared.require(game.ReplicatedStorage.Library.TouchHandler);
local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);

local clipTouchHandler = modTouchHandler.new("ToxicClips", 5);

WorldClip.Config = {
	Damage = nil;
	DamageRatio = 0.2;
}

function clipTouchHandler:OnHumanoidTouch(humanoid, basePart, touchPart)
	local character = humanoid.Parent;
	local healthComp: HealthComp? = modHealthComponent.getByModel(character);
	if healthComp == nil then return end;

	character = healthComp:GetModel();

	local entityClass: EntityClass = healthComp.CompOwner;
	if entityClass.StatusComp == nil then return end;

	entityClass.StatusComp:Apply("Toxic", {
		Expires = workspace:GetServerTimeNow() + 5.5;
		Duration = 5.5;
		Values = {
			DamageRatio = WorldClip.Config.DamageRatio;
		}
	});
end

function WorldClip:Load(basePart)
	basePart.Parent = script;

	clipTouchHandler:AddObject(basePart);
end

return WorldClip;