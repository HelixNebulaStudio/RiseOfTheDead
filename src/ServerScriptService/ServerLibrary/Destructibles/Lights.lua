local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Lighting = game:GetService("Lighting");
local CollectionService = game:GetService("CollectionService");

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);

--== Scripts;
modOnGameEvents:ConnectEvent("OnNightTimeStart", function()
	local repairLights = CollectionService:GetTagged("DestroyedLights");
	for a=1, #repairLights do
		local modDestructible = require(repairLights[a]);
		modDestructible:Repair();
	end
end)

return function(Destructible)
	Destructible.Enabled = true;
	Destructible.MaxHealth = 100;
	Destructible.Health = Destructible.MaxHealth;
	Destructible.CustomDestroy = true;
	
	--self.Prefab
	function Destructible.OnDamaged(damage, player, storageItem, hitPart)
		local self = Destructible;
		if self.Destroyed then return end;
		
		if hitPart == nil then return end;
		if hitPart.Material == Enum.Material.Neon then
			hitPart.Material = Enum.Material.SmoothPlastic;
			local sound = modAudio.Play("GlassSmash", hitPart);
			sound.RollOffMaxDistance = 256;
			sound.RollOffMinDistance = 64;
		end
		
		local disableLightSource = true;
		for _, obj in pairs(self.Prefab:GetChildren()) do
			if obj:IsA("BasePart") and obj.Material == Enum.Material.Neon then disableLightSource = false; break; end;
		end
		
		if disableLightSource then
			self.Destroyed = true;
			
			delay(130, function() self:Repair(); end)
			
			self.Prefab:SetAttribute("IsDestroyed", true);
			
			local lightObjects = {};
			if self.Prefab:FindFirstChild("_lightSource") then
				for _, obj in pairs(self.Prefab:GetDescendants()) do
					if obj:IsA("Light") then
						table.insert(lightObjects, obj);
					end
				end
			end

			self.DestroyedTime = tick();
			CollectionService:AddTag(self.Script, "DestroyedLights");
			
			local function toggleOn()
				hitPart.Material = Enum.Material.Neon;
				for a=1, #lightObjects do
					lightObjects[a].Enabled = true;
				end
			end
			local function toggleOff()
				hitPart.Material = Enum.Material.SmoothPlastic;
				for a=1, #lightObjects do
					lightObjects[a].Enabled = false;
				end
			end
			
			if self.Prefab:GetAttribute("IsPowered") == true then
				wait(0.2);
				toggleOn();
				for a=1, 2 do
					wait(0.1);
					toggleOn();
					wait(0.1);
					toggleOff();
				end
			else
				toggleOff();
			end
		end
	end
	
	function Destructible:Repair()
		if tick()-self.DestroyedTime <= 120 then return end;
		
		if self.Prefab:GetAttribute("IsPowered") == true then
			for _, obj in pairs(self.Prefab:GetDescendants()) do
				if obj:IsA("Light") then
					obj.Enabled = true;
					
				elseif obj:IsA("BasePart") then
					obj.Material = Enum.Material.Neon;
					
				end
			end
		end
		
		self.Destroyed = false;
		self.Prefab:SetAttribute("IsDestroyed", false);
		self.DestroyedTime = nil;
		CollectionService:RemoveTag(self.Script, "DestroyedLights");
	end
end
