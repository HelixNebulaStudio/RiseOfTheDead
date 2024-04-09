local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modFacesLibrary = require(game.ReplicatedStorage.Library.FacesLibrary);
local remoteNpcFace = modRemotesManager:Get("NpcFace");
local random = Random.new();

local Component = {};
Component.__index = Component;
Component.DefaultFace = modFacesLibrary:Find("Happy").Texture;

--== Script;
function Component:SetRandom(...)
	self:Set(modFacesLibrary:GetRandom(), ...);
end

function Component:Set(id, players, isDialog)
	self.Face = self.Face or (self.Npc.Head:FindFirstChild("face") or nil);
	if self.Face == nil then return end;
	if self.Default == nil then self.Default = self.Face.Texture; end
	
	local faceLib = modFacesLibrary:Find(id);
	
	if players then
		players = type(players) ~= "table" and {players} or players;
		
		if id == nil then
			id = self.Default or self.DefaultFace;
		elseif faceLib then
			id = faceLib.Texture;
		end
		
		for a=1, #players do
			remoteNpcFace:FireClient(players[a], self.Face, id);
		end
	else
		
		if id == nil then
			self.Face.Texture = self.Default or self.DefaultFace;
		elseif faceLib then
			self.Face.Texture = faceLib.Texture;
		else
			self.Face.Texture = id;
		end
	end
	if isDialog ~= true then self.CurrentFace = self.Face.Texture; end;
end

function Component:DialogSet(id, players)
	self.Face = self.Face or (self.Npc.Head:FindFirstChild("face") or nil);
	
	if id then
		self:Set(id, players, true);
		
	elseif self.CurrentFace then
		self:Set(self.CurrentFace, players, true);
		
	else
		self:Set(nil, players, true);
		
	end
end

function Component.new(Npc)
	local self = {
		Npc = Npc;
	};
	
	setmetatable(self, Component);
	return self;
end

return Component;