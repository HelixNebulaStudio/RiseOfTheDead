local WorldClip = {};
WorldClip.__index = WorldClip;

local modTouchHandler = shared.require(game.ReplicatedStorage.Library.TouchHandler);
local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);

local clipTouchHandler = modTouchHandler.new("EnvFireClips", 1);

WorldClip.Config = {
	Damage = nil;
	Duration = 5;
}

function clipTouchHandler:OnHumanoidTouch(humanoid, basePart, touchPart)
	local character = humanoid.Parent;
	local healthComp: HealthComp? = modHealthComponent.getByModel(character);
	if healthComp == nil then return end;

	character = healthComp:GetModel();

	local entityClass: EntityClass = healthComp.CompOwner;
	local statusComp: StatusComp = entityClass and entityClass.StatusComp;
	if statusComp == nil then return end;

	local fireDuration = WorldClip.Config.Duration;

	local statusClass: StatusClassInstance = statusComp:GetOrDefault("LiquidFlame");
	if statusClass == nil then
		statusComp:Apply("LiquidFlame", {
			Expires = workspace:GetServerTimeNow() + fireDuration;
			Duration = fireDuration;
			Values = {
				TargetPart = touchPart;
				Damage = 2;
				Stacks = 1;
			}
		});

	else
		statusClass.Expires = workspace:GetServerTimeNow() + fireDuration;
		statusClass.Duration = fireDuration;
		statusClass.Values.Stacks += 1;

	end
end

function WorldClip:Load(basePart)
	basePart.Parent = script;

	clipTouchHandler:AddObject(basePart);
end

return WorldClip;