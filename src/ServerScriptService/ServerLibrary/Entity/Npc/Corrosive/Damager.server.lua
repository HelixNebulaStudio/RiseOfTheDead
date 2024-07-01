local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local remotes = game.ReplicatedStorage.Remotes;
local remoteCameraShakeAndZoom = remotes.CameraShakeAndZoom;
local modPlayers = require(game.ReplicatedStorage.Library.Players);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);

local victims = {};
local damage, rate = 2, 0.1;

local function Damage(player)
	if victims[player] == nil or tick()-victims[player] >= rate then
		victims[player] = tick();
		local humanoid = player.Character and player.Character:FindFirstChild("Humanoid");
		if humanoid and humanoid.Name == "Humanoid" and humanoid:IsA("Humanoid") then
			
			local classPlayer = modPlayers.Get(player);
			
			if classPlayer then
				local gasProtection = classPlayer:GetBodyEquipment("GasProtection");
				if gasProtection then
					damage = damage * (1-gasProtection);
				end
				
				classPlayer:TakeDamagePackage(modDamagable.NewDamageSource{
					Damage=2;
					OriginPosition=classPlayer:GetCFrame().Position;
				});
			end

		end
		remoteCameraShakeAndZoom:FireClient(player, 5, 0, 0.3, 2, false);
	end
end

local function GetPlayerOfPart(part)
	local humanoid = part.Parent and part.Parent:FindFirstChildOfClass("Humanoid");
	if humanoid and humanoid.Name == "Humanoid" then
		local name = part.Parent.Name;
		local player = game.Players:FindFirstChild(name);
		return player;
	end
end

script.Parent.Touched:Connect(function(part)
	local player = GetPlayerOfPart(part);
	if player then
		Damage(player);
	end
end)

while wait(0.1) do
	local objs = script.Parent:GetTouchingParts()
	
	local function isTouching(player)
		for a=1, #objs do
			if GetPlayerOfPart(objs[a]) == player then
				return true;
			end 
		end
		return false;
	end
	
	for player, t in pairs(victims) do
		if isTouching(player) then
			Damage(player);
		end
	end
end