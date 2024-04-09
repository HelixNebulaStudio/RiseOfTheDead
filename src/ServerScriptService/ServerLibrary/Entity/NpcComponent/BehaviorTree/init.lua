local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Script;

local Component = {};
Component.__index = Component;

function Component.new(Npc)
	local self = {
		Npc = Npc;
		Trees = {};
		
		Thread = nil;
		Running = false;
	};
	
	setmetatable(self, Component);
	return self;
end

function Component:StopTree()
	--Debugger:Log("think", self.ThinkThread and coroutine.status(self.ThinkThread) or "nil");
	self.Running = false;
	
	for key, logicTree in pairs(self.Trees) do
		logicTree.Disabled = true;
	end
	--if self.Thread and coroutine.status(self.Thread) ~= "dead" then
	--	local stopThinkS, stopThinkE = pcall(function() coroutine.close(self.Thread) end);

	--	self.Thread = nil;

	--	if not stopThinkS then
	--		Debugger:Warn("thinkthread ",self.Name," failed ", stopThinkE); 
	--	end
	--end;
end

function Component:RunTree(treeObj, isRoot)
	if self.Disabled then return end;
	
	if isRoot then
		if self.Running then return end;
		
		self.Thread = coroutine.running();
		self.Running = true;
		
	end
	
	local treeSrc = nil;
	local treeName = treeObj;
	
	if typeof(treeObj) == "Instance" then
		treeSrc = treeObj;
		treeName = treeObj.Name;
	end
	
	local tl = tick();
	if self.Trees[treeName] == nil then
		local treeFunc = treeSrc or script:FindFirstChild(treeName);
		
		self.Trees[treeName] = require(treeFunc)(self.Npc);
		self.Trees[treeName].Name = treeName;
	end
	
	local status = self.Trees[treeName]:Process();
	
	if isRoot then
		self.State = self.Trees[treeName].State;
		self.Status = self.Trees[treeName].Status;
		
		if self.Npc.Prefab:GetAttribute("Debug") == true then
			Debugger:Log(self.Npc.Name,"Behavior:",self.State.." = "..self.Trees[treeName].Status,", Time:",string.format("%.3f", (tick()-tl)), "s");
		end
	end
	
	if isRoot then
		self.Running = false;
	end
	
	return status;
end

return Component;