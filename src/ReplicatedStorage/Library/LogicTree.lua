--!strict
local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local LogicTree = {};
LogicTree.__index = LogicTree;
LogicTree.ClassName = "LogicTree";

LogicTree.Status = {
	Success = "Success";
	Failure = "Failure";
	Running = "Running";
	None = "None";
}
LogicTree.Success = LogicTree.Status.Success;
LogicTree.Failure = LogicTree.Status.Failure;
LogicTree.Running = LogicTree.Status.Running;
export type LogicTreeStatus = string;


--== Node;
local Node = {};
Node.__index = Node;
Node.Count = 1;

type NodeObject = {
	Name: string;
	Children: {[number]: any?};
	Index: number;
	Status: LogicTreeStatus;

	Type: any;
	Function: ((node: any?) -> LogicTreeStatus)?
}
export type Node = typeof(setmetatable({} :: NodeObject, Node));

function Node.new(nodeName: string?) : Node
	local self = {
		Name = nodeName or ("Node#"..Node.Count);
		Children = {};
		Index = 1;
		Status = LogicTree.Status.None;
	};
	
	Node.Count = Node.Count+1;
	setmetatable(self, Node);
	
	return self;
end

function Node:SetType(nodeType)
	if nodeType == nil then error("LogicTree>>  Missing node type.") end;
	if LogicTree.Types[nodeType] == nil then error("LogicTree>>  Invalid node type. ".. nodeType) end;
	self.Type = LogicTree.Types[nodeType];
end

--LogicTree.Node = Node;


LogicTree.Types = {};
LogicTree.Types.Process = function(tree: LogicTree, node: Node)
	if tree.Disabled == true then
		return tree.Failure;
	end;
	
	node.Status = tree.Running;
	return node.Type(tree, node);
end;

LogicTree.Types.And = function(tree: LogicTree, parentNode: Node)
	local childNode = parentNode.Children[parentNode.Index];
	local status = LogicTree.Types.Process(tree, childNode);
	
	if status == LogicTree.Status.Success then
		parentNode.Index += 1;
		
		if parentNode.Index > #parentNode.Children then
			parentNode.Index = 1;
			parentNode.Status = LogicTree.Status.Success;
			
		else
			LogicTree.Types.Process(tree, parentNode);
			
		end
		
	elseif status == LogicTree.Status.Failure then
		parentNode.Index = 1;
		parentNode.Status = LogicTree.Status.Failure;
		
	else
		Debugger:Warn(tree.Name, parentNode.Name, "Missing return status [And]", status);
		
	end
	
	return parentNode.Status;
end;

LogicTree.Types.Or = function(tree: LogicTree, parentNode: Node)
	local childNode = parentNode.Children[parentNode.Index];
	local status = LogicTree.Types.Process(tree, childNode);
	
	if status == LogicTree.Status.Failure then
		parentNode.Index += 1;
		
		if parentNode.Index > #parentNode.Children then
			parentNode.Index = 1;
			parentNode.Status = LogicTree.Status.Failure;
			
		else
			LogicTree.Types.Process(tree, parentNode);
			
		end
		
	elseif status == LogicTree.Status.Success then
		parentNode.Index = 1;
		parentNode.Status = LogicTree.Status.Success;

	else
		Debugger:Warn(tree.Name, parentNode.Name, "Missing return status [Or]", status);
		
	end
	
	return parentNode.Status;
end;

LogicTree.Types.IfElse = function(tree: LogicTree, parentNode: Node)
	local childNode = parentNode.Children[parentNode.Index];
	local status = LogicTree.Types.Process(tree, childNode);
	
	if parentNode.Index == 1 then
		if status == LogicTree.Status.Success then
			parentNode.Index = 2;
		else
			parentNode.Index = 3;
		end
		
	else
		parentNode.Index = 1;
		parentNode.Status = status;
		
	end
	
	return parentNode.Status;
end;

LogicTree.Types.Not = function(tree: LogicTree, parentNode: Node)
	local childNode = parentNode.Children[1];
	local status = LogicTree.Types.Process(tree, childNode);
	
	if status == LogicTree.Status.Success then
		parentNode.Status = LogicTree.Status.Failure;
	elseif status == LogicTree.Status.Failure then
		parentNode.Status = LogicTree.Status.Success;
	else
		Debugger:Warn(tree.Name, parentNode.Name, "Missing return status [Not]", status);
	end
	
	return parentNode.Status;
end;

LogicTree.Types.Leaf = function(tree: LogicTree, node: Node)
	local status = nil;
	
	if node.Function then
		local s, e = pcall(function()
			if not tree.Disabled then
				status = node.Function(node);
			end
		end);

		if not s then
			Debugger:Warn(e);
			Debugger:Warn("Node (",node.Name,") failed to run.");
		end

	else
		Debugger:Warn(tree.Name, node.Name, "Missing node function.");

	end
	
	if status == nil then
		status = tree.Failure;
	end
	node.Status = status
	
	tree.State = node.Name;
	tree.Status = node.Status;
	
	return node.Status;
end;

type LogicTreeObject = {
	Name: string?;
	Root: Node;
	Nodes: {[string]: Node};
	Cache: {};
	Disabled: boolean;
	
	State: string?;
	Status: string?;
};
export type LogicTree = typeof (setmetatable({} :: LogicTreeObject, LogicTree));

-- MARK: LogicTree.new
function LogicTree.new(treeTable: {[string]: {string}}) : LogicTree
	local self = {
		Name = nil;
		Root = Node.new("Root");
		Nodes = {};
		Cache = {};
		Disabled = false;
	};
	setmetatable(self, LogicTree);
	
	-- Init;
	local function load(parentNode: Node, rawNode)
		if #rawNode < 2 then Debugger:Warn("Invalid Behavior Tree"); return end;
		for a=2, #rawNode do
			local nodeName = rawNode[a];
			
			local newNode = self:NewNode(nodeName);
			parentNode:SetType(rawNode[1]);
			table.insert(parentNode.Children, newNode);
			
			if treeTable[nodeName] then
				load(newNode, treeTable[nodeName]);
			else
				newNode:SetType("Leaf");
			end
		end
	end
	if treeTable.Root == nil then
		Debugger:Warn("Missing root node for tree");
	end
	load(self.Root, treeTable.Root);
	
	return self;
end

function LogicTree:NewNode(name: string) : Node
	if self.Nodes[name] then return self.Nodes[name]; end;
	self.Nodes[name] = Node.new(name);
	return self.Nodes[name];
end

function LogicTree:Process()
	return LogicTree.Types.Process(self, self.Root);
end

function LogicTree:Hook(nodeName: string, func)
	local node = self.Nodes[nodeName];
	if node == nil then Debugger:Warn("Logic tree does not contain node ("..nodeName..") to hook function to."); return end;
	node.Function = func;
end

function LogicTree:Call(nodeName: string, ...)
	local node = self.Nodes[nodeName];
	if node == nil then Debugger:Warn("Logic tree does not contain node ("..nodeName..") to call."); return end;
	return node.Function(...);
end

return LogicTree;








--[[ 
Example:

local tree = LogicTree.new{
	Root={"Or"; "EnterBuildingTree"};
	EnterBuildingTree={"And"; "EnterDoor"};
	EnterDoor={"And"; "WalkToDoor"; "DoorLogic"; "WalkThroughDoor"; "CloseDoor"};
	
	DoorLogic={"Or"; "CivilBehavior"; "SmashDoor";};
	CivilBehavior={"And"; "KnowHowToOpenDoor"; "TryOpenDoor"};
	TryOpenDoor={"Or"; "OpenDoor"; "UnlockAndOpenDoor"; "SmashDoor"};
	KnowHowToOpenDoor={"Inverter"; "IsZombie"};
	UnlockAndOpenDoor={"And"; "UnlockDoor"; "OpenDoor"};
};

local doorLocked = true;
tree:Hook("IsZombie", function() return LogicTree.Status.Failure; end)
tree:Hook("UnlockDoor", function() doorLocked = false; return LogicTree.Status.Success; end)
tree:Hook("OpenDoor", function() return doorLocked and LogicTree.Status.Failure or LogicTree.Status.Success; end)

task.spawn(function()
	print("Tree", tree);
	while true do
		wait(1);
		tree:Process();
		Debugger:Log("State:",tree.State, "Status:", tree.Status);
	end
end)
]]