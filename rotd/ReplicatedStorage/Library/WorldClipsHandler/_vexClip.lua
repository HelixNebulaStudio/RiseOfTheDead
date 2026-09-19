local WorldClip = {};
WorldClip.__index = WorldClip;

local CollectionService = game:GetService("CollectionService");

local modTouchHandler = shared.require(game.ReplicatedStorage.Library.TouchHandler);
local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);

local clipTouchHandler = modTouchHandler.new("VexClips", 2);

clipTouchHandler.WhitelistFunc = function()
	return CollectionService:GetTagged("PlayerRootParts");
end

WorldClip.Config = {
	Damage = nil;
	DamageRatio = 0.1;
}

function clipTouchHandler:OnHumanoidTouch(humanoid, basePart, touchPart)
	local character = humanoid.Parent;
	local healthComp: HealthComp? = modHealthComponent.getByModel(character);
	if healthComp == nil then return end;

	character = healthComp:GetModel();

	local entityClass: EntityClass = healthComp.CompOwner;
	if entityClass.StatusComp == nil then return end;

	entityClass.StatusComp:Apply("VexBile", {
		Expires = workspace:GetServerTimeNow() + 2.5;
		Duration = 2.5;
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