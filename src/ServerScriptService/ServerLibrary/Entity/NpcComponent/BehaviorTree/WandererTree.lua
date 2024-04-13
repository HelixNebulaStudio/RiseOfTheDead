local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modLogicTree = require(game.ReplicatedStorage.Library.LogicTree);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local worldNavLink = modBranchConfigs.NavLinks[modBranchConfigs.GetWorld()];

local EventSpawns = workspace:WaitForChild("Event");
local wandererSpots = {};

for _, obj in pairs(EventSpawns:GetChildren()) do
	if obj.Name == "Wanderer" then
		table.insert(wandererSpots, obj);
	end
end

local sleepingBagPrefab = game.ServerStorage.PrefabStorage.Objects.SleepingBag;

return function(self)
	local tree = modLogicTree.new{
    RestSequence={"And"; "NeedRest"; "Rest";};
    AmmoSequence={"And"; "NeedAmmo"; "ShopForAmmo";};
    SafehouseSelect={"Or"; "RestSequence"; "FoodSequence"; "AmmoSequence";};
    FoodSequence={"And"; "NeedFood"; "Eat";};
    Root={"Or"; "IsTalking"; "SafehouseSequence"; "TravelSequence";};
    SafehouseSequence={"And"; "IsInSafehouse"; "SafehouseSelect";};
    TravelSequence={"And"; "Travel";};
}
	
	local cache = {};
	cache.LastEat = tick();
	cache.LastRest = tick();
	cache.NeedAmmo = true;
	
	cache.EatTimer = (RunService:IsStudio() and 30 or 200);
	cache.EatDuration = (RunService:IsStudio() and cache.EatTimer/2 or 60);
	
	cache.RestTimer = (RunService:IsStudio() and 30 or 300);
	cache.RestDuration = (RunService:IsStudio() and cache.RestTimer/2 or 120);
	
	cache.NextToRestSpot = false;
	cache.NewWandererSpotIndex = 0;
	
	self.Garbage:Tag(cache);
	--self.Prefab:SetAttribute("Debug", true);
	
	local function getCurrentNavObj()
		for _, obj in pairs(wandererSpots) do
			if obj:GetAttribute("NavLocationId") == self.CurrentNav then
				return obj;
			end
		end
	end
	
	local function stopRest()
		self.AvatarFace:Set();
		self.Prefab.PrimaryPart.Anchored = false;
		if self.SleepingBag then
			self.SleepingBag.Parent = nil;
		end
		self.StopAnimation("BagSleep");
		self.Prefab.SurvivorsBackpack.Handle.Transparency = 0;
	end
	
	local function stopEat()
		self.AvatarFace:Set();
		if self.Wield.ItemId == "portablestove" then
			self.Wield.Unequip();
		end
	end
	
	tree:Hook("IsTalking", function() 
		if self.IsTalking and self.IsTalking:IsDescendantOf(workspace) then
			
			stopRest();
			stopEat();
			
			local rootPart = self.IsTalking;
			if rootPart then
				self.Movement:Face(rootPart.Position);
			end
			return modLogicTree.Status.Success;
		end
		return modLogicTree.Status.Failure;
	end)
	
	
	tree:Hook("IsInSafehouse", function() 
		if worldNavLink[self.CurrentNav] and worldNavLink[self.CurrentNav].Safehouse then
			self.Movement.DefaultWalkSpeed = 8;
			self.HuntKillCount = 0;
			self.KillRequirement = math.random(20, 40);
			
			return modLogicTree.Status.Success;
		end
		
		self.Movement.DefaultWalkSpeed = 20;
		return modLogicTree.Status.Failure;
	end)
	
	tree:Hook("NeedRest", function() 
		if tick()-cache.LastRest >= cache.RestTimer then
			return modLogicTree.Status.Success;
		end
		return modLogicTree.Status.Failure;
	end)
	
	tree:Hook("NeedFood", function() 
		if tick()-cache.LastEat >= cache.EatTimer then
			return modLogicTree.Status.Success;
		end
		return modLogicTree.Status.Failure;
	end)
	
	tree:Hook("NeedAmmo", function() 
		if cache.NeedAmmo then
			
			if self.Wield.ToolModule then
				self.Wield.PlayAnim("Empty");
			end
			
			return modLogicTree.Status.Success;
		end
		return modLogicTree.Status.Failure;
	end)
	
	tree:Hook("Rest", function() 
		if cache.StartRest == nil then
			cache.StartRest = tick();
		end
		if tick()-cache.StartRest > cache.RestDuration then
			cache.LastRest = tick();
			cache.StartRest = nil;
			
			stopRest();
			return modLogicTree.Status.Failure;
		end
		
		if self.SleepingBag == nil then
			self.SleepingBag = sleepingBagPrefab:Clone();
		end
		
		local attachmentObj = getCurrentNavObj();
		if cache.NextToRestSpot == false then
			cache.NextToShop = false;
			
			self.Movement:Move(attachmentObj.WorldPosition):OnComplete(function()
				cache.NextToRestSpot = true;
				self.RootPart.CFrame = attachmentObj.WorldCFrame;
				self.Movement:Face(attachmentObj.WorldPosition + attachmentObj.WorldCFrame.LookVector*10);
			end)
			
		else
			self.SleepingBag.Parent = workspace.Entities;
			self.SleepingBag:SetPrimaryPartCFrame(attachmentObj.WorldCFrame * CFrame.new(0, -2, 0));
			self.Prefab.PrimaryPart.Anchored = true;
			
			self.PlayAnimation("BagSleep");
			self.AvatarFace:Set("Unconscious");
			
			self.Prefab.SurvivorsBackpack.Handle.Transparency = 1;
		end
		
		return modLogicTree.Status.Success;
	end)
	
	tree:Hook("Eat", function()
		if cache.StartEat == nil then
			cache.StartEat = tick();
		end
		if tick()-cache.StartEat > cache.EatDuration then
			cache.LastEat = tick();
			cache.StartEat = nil;
			
			stopEat();
			return modLogicTree.Status.Failure;
		end
		
		if cache.NextToRestSpot == false then
			cache.NextToShop = false;
			
			local attachmentObj = getCurrentNavObj();
			if attachmentObj == nil then
				Debugger:Warn("self.CurrentNav", self.CurrentNav);
			end
			self.Movement:Move(attachmentObj.WorldPosition):OnComplete(function()
				cache.NextToRestSpot = true;
				self.RootPart.CFrame = attachmentObj.WorldCFrame;
				self.Movement:Face(attachmentObj.WorldPosition + attachmentObj.WorldCFrame.LookVector*10);
			end)
		else
			if self.Wield.ItemId ~= "portablestove" then
				self.Wield.Equip("portablestove");
			else
				self.Wield.PrimaryFireRequest(true);
			end
			
		end
		
		return modLogicTree.Status.Success;
	end)
	
	tree:Hook("ShopForAmmo", function()
		if worldNavLink[self.CurrentNav].Shop == nil then
			cache.NeedAmmo = false;
			return modLogicTree.Status.Failure;
		end
		
		local shopObj = workspace.Interactables:FindFirstChild(worldNavLink[self.CurrentNav].Shop);
		local destination = shopObj and (shopObj:FindFirstChild("Destination") and shopObj.Destination.WorldPosition or shopObj.Position);
		
		if cache.NextToShop == false then
			cache.NextToRestSpot = false;

			self.Movement:Move(destination):OnComplete(function()
				self.Movement:Face(shopObj.Position);
				cache.NextToShop = true;
			end)
			
		else
			
			self.Wield.Equip("mariner590");
			self.Wield.ToolModule.Configurations.InfiniteAmmo = nil;
			self.Wield.ToolModule.Properties.Ammo = self.Wield.ToolModule.Configurations.AmmoLimit-3;
			self.Wield.ToolModule.Properties.MaxAmmo = self.Wield.ToolModule.Configurations.MaxAmmoLimit;
			task.wait(1);
			if self.IsDead then return tree.Failure end;
			self.Wield.ReloadRequest();
			task.wait(self.Wield.ToolModule.Properties.ReloadSpeed);
			if self.IsDead then return tree.Failure end;
			self.Wield.ReloadRequest();
			task.wait(self.Wield.ToolModule.Properties.ReloadSpeed);
			if self.IsDead then return tree.Failure end;
			self.Wield.ReloadRequest();
			task.wait(self.Wield.ToolModule.Properties.ReloadSpeed);
			if self.IsDead then return tree.Failure end;
			task.wait(2);
			if self.IsDead then return tree.Failure end;
			
			self.Wield.ToolModule.Properties.Ammo = self.Wield.ToolModule.Configurations.AmmoLimit;
			self.Wield.ToolModule.Properties.MaxAmmo = self.Wield.ToolModule.Configurations.MaxAmmoLimit;
			
			self.Wield.Unequip();
			
			cache.NeedAmmo = false;
		end
		
		return modLogicTree.Status.Success;
	end)
	
	tree:Hook("Travel", function()
		self.AvatarFace:Set();
		cache.NextToRestSpot = false;
		cache.NextToShop = false;
		
		if cache.NewWandererSpot == nil then
			cache.NewWandererSpotIndex = cache.NewWandererSpotIndex +1;
			cache.NewWandererSpot = wandererSpots[math.fmod(cache.NewWandererSpotIndex, #wandererSpots)+1];
		end
		
		local spotNavId = cache.NewWandererSpot:GetAttribute("NavLocationId");
		
		self.TargetNav = spotNavId;
		
		if self.TargetNav and self.CurrentNav == self.TargetNav then
			cache.NewWandererSpot = nil;
			cache.NeedAmmo = true;
		end
		
		return self.BehaviorTree:RunTree("TravelTree");
	end)
	
	return tree;
end
