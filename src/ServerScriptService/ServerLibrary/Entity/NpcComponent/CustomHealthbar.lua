local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local modEventSignal = require(game.ReplicatedStorage.Library.EventSignal);
local templateHealthbarGui = script:WaitForChild("HealthbarGui");

local random = Random.new();
local templateNpcStatusLink = script.Parent.Parent:WaitForChild("NpcStatus");

--== Script;
local CustomHealthbar = {};
CustomHealthbar.__index = CustomHealthbar;

function CustomHealthbar:Create(name, maxHealth, adornee)
	if self.Healths[name] then Debugger:Warn("Health bar already exist. (",name,")"); return end;
	local newHealthGui = templateHealthbarGui:Clone();
	local healthObj = {
		Name = name;
		LastDamaged = tick();
		IsDead=false;
		Health=maxHealth;
		MaxHealth=maxHealth;
		HealthGui=newHealthGui;
		BasePart=adornee;
		OnDeath = modEventSignal.new("OnCustomHealthbarDeath");
	};
	self.Healths[name] = healthObj;
	newHealthGui.Parent = adornee;
	newHealthGui.Adornee = adornee;
	self:RefreshGui(name);
	
	if adornee.Parent and adornee.Parent:FindFirstChild("NpcStatus") == nil then
		local newLink = templateNpcStatusLink:Clone();
		newLink.Parent = adornee.Parent;
		require(newLink).Initialize(self.Npc);
	end
	
	self.Npc.Garbage:Tag(function()
		healthObj.BasePart = nil;
		healthObj.OnDeath:Destroy();
	end);
	
	return self.Healths[name];
end

function CustomHealthbar:GetFromPart(bodyPart: BasePart)
	for name, healthObj in pairs(self.Healths) do
		if healthObj.BasePart == bodyPart then
			return healthObj;
		end
	end
end

function CustomHealthbar:SetGuiSize(name, x, y)
	local healthInfo = self.Healths[name];
	local healthGui = healthInfo and healthInfo.HealthGui;
	if healthGui then
		healthGui.Size = UDim2.new(x, 0, y, 0);
	end
end

function CustomHealthbar:SetOffset(name, vec)
	local healthInfo = self.Healths[name];
	local healthGui = healthInfo and healthInfo.HealthGui;
	if healthGui then
		healthGui.StudsOffsetWorldSpace = vec;
	end
end

function CustomHealthbar:RefreshGui(name)
	if self.Healths[name] == nil then Debugger:Warn("Missing health bar gui",name); return end;
	local healthInfo = self.Healths[name];
	local healthGui = healthInfo.HealthGui;
	if (healthInfo.Health > 0 and healthInfo.Health ~= healthInfo.MaxHealth) or healthGui.Enabled then
		healthGui.Enabled = true;
		local bar = healthGui.Frame.Bar;
		local lostBar = healthGui.Frame.Lostbar;
		local labelTag = healthGui.Label;
		
		labelTag.Text = math.max(math.ceil(healthInfo.Health), 0).."/"..healthInfo.MaxHealth;
		
		local newSize = UDim2.new(math.clamp(healthInfo.Health/healthInfo.MaxHealth, 0, 1), 0, 1, 0);
		bar.Size = newSize;
		task.delay(0.1, function()
			lostBar.Size = newSize;
		end)
	else
		healthGui.Enabled = false;
	end
end

function CustomHealthbar:ShowGui(name)
	if self.Healths[name] == nil then Debugger:Warn("Missing health bar gui",name); return end;
	local healthInfo = self.Healths[name];
	local healthGui = healthInfo.HealthGui;
	if healthGui then
		healthGui.Enabled = true;
		self:RefreshGui(name);
	end
end

function CustomHealthbar:HideGui(name)
	if self.Healths[name] == nil then Debugger:Warn("Missing health bar gui",name); return end;
	local healthInfo = self.Healths[name];
	local healthGui = healthInfo.HealthGui;
	if healthGui then
		healthGui.Enabled = false;
	end
end

function CustomHealthbar:SetGuiDistance(name, value)
	if self.Healths[name] == nil then Debugger:Warn("Missing health bar gui",name); return end;
	local healthInfo = self.Healths[name];
	local healthGui = healthInfo.HealthGui;
	if healthGui then
		healthGui.MaxDistance = value;
	end
end

function CustomHealthbar:ToggleLabel(name, v)
	if self.Healths[name] == nil then Debugger:Warn("Missing health bar gui",name); return end;
	local healthInfo = self.Healths[name];
	local healthGui = healthInfo.HealthGui;
	
	if healthGui then
		local label: TextLabel = healthGui.Label;
		
		label.Visible = v == true;
	end
end

-- interface: function CustomHealthbar:OnDamaged() : boolean
-- return true to isolate damage

function CustomHealthbar:TakeDamage(name, amount)
	if self.Healths[name] then
		if self.Healths[name].Health <= 0 then return end
		
		self.Healths[name].LastDamaged = tick();
		self.Healths[name].Health = self.Healths[name].Health - amount;
		
		self:RefreshGui(name)
		task.delay(2, function()
			if self.Healths[name] and not self.Healths[name].IsDead and tick()-self.Healths[name].LastDamaged > 2 then
				self:HideGui(name);
			end
		end)
		
		if self.Healths[name].Health <= 0 then
			self.Healths[name].OnDeath:Fire();
			self.Healths[name].OnDeath:Destroy();
			self.Healths[name].IsDead = true;
			self.OnDeath:Fire(name, self.Healths[name]);
		end
	else
		Debugger:Log("TakeDamage for unknown health bar",name);
	end
end

function CustomHealthbar:Destroy()
	self.OnDeath:Destroy();
	pcall(function()
		for k,v in pairs(self.Healths) do
			self.Healths[k].OnDeath:Fire();
			self.Healths[k].OnDeath:Destroy();
			self.Healths[k] = nil;
		end
	end)
end

function CustomHealthbar.new(Npc)
	local self = {
		Npc = Npc;
		Healths = {};
		OnDeath = modEventSignal.new("OnCustomHealthbarDeath");
	};
	
	setmetatable(self, CustomHealthbar);
	return self;
end

return CustomHealthbar;