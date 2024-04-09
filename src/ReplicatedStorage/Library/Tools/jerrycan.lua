local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");
local CollectionService = game:GetService("CollectionService");

local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
local modProjectile = require(game.ReplicatedStorage.Library.Projectile);

local function spread(maxSpreadAngle)
	local deflection = math.random(0, 100)/100^2 * math.rad(maxSpreadAngle);
	local cf = CFrame.lookAt(Vector3.new(), Vector3.new(0, -1, 0))
	cf = cf*CFrame.Angles(0, 0, math.random(0, 100)/100 *2*math.pi);
	cf = cf*CFrame.Angles(deflection, 0, 0);
	return cf.lookVector;
end

if RunService:IsServer() then
	modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
	modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
	
end
	
return function()
	local Tool = {};
	Tool.IsActive = false;

	function Tool:OnEquip()
		self.Fuel = self.StorageItem:GetValues("Fuel") or 100;
	end
	
	function Tool:OnUnequip()
		self.StorageItem:SetValues("Fuel", (self.Fuel or 100));
	end
	
	function Tool:OnPrimaryFire(isActive)
		self.IsActive = isActive;
		
		local prefab = self.Prefabs[1];
		local emitter = prefab:FindFirstChild("gasolineParticle", true);
		
		self.Fuel = self.StorageItem:GetValues("Fuel") or 100;
		
		if emitter then
			if self.IsActive then
				if self.Fuel > 0 then
					emitter.Enabled = true;

					local attachPoint = emitter.Parent;
					repeat
						
						local origin = CFrame.new(attachPoint.WorldPosition+Vector3.new(0, 1, 0));
						
						local projectileObject = modProjectile.Fire("Gasoline", origin, Vector3.new(0, -1, 0), nil, self.Player);
						
						local spreadLookVec = spread(90);

						modProjectile.ServerSimulate(projectileObject, origin.p, spreadLookVec * 20);
						
						self.Fuel = self.Fuel - 5;
						self.StorageItem:SetValues("Fuel", self.Fuel):Sync("Fuel");
						
						wait(0.5);
					until not self.IsActive or self.Fuel <= 0 or not prefab:IsDescendantOf(workspace);
				end
			end
			emitter.Enabled = false;
		end
		
	end
	
	return Tool;
end;