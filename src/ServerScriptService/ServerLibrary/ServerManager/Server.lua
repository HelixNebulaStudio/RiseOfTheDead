local ServerManager;
local Server = {};

--== Services;
local HttpService = game:GetService("HttpService");
local Players = game:GetService("Players");

function Server.new(data)
	data = data or {};
	
	local meta = {};
	meta.__index = meta;
	meta.ClassName = "Server";
	
	function meta:UpdatePlayers()
		self.Players = {};
		if self.Closing then return end;
		for _, player in pairs(game.Players:GetPlayers()) do
			self.Players[player.Name] = player.UserId;
		end
	end
	
	function meta:FindPlayer(tag)
		if self.Players[tag] then return self.Players[tag] end;
		for name, userId in pairs(self.Players) do
			if userId == tag then return userId end;
		end
	end
	
	function meta:LoopPlayers(callback)
		local c=0;
		for playerName, userId in pairs(self.Players) do
			if callback then
				local r = callback(playerName, userId);
				if r ~= nil then break; end;
			end
			c=c+1;
		end
		return c;
	end
	
	function meta:Upload()
		self.LastUpdated = os.time();
		ServerManager.UpdateServer(self);
		ServerManager.Database:SetAsync(self.Id, HttpService:JSONEncode(self));
		--ServerManager.Binds.Update:Fire(self);
	end
	
	function meta:Destroy()
		self.Closing = true;
		ServerManager.DestroyServer(self);
		ServerManager.Database:RemoveAsync(self.Id);
		--ServerManager.Binds.Destroy:Fire(self);
	end
	
	local server = setmetatable({}, meta);
	server.Id = data.Id or (game.JobId and #game.JobId > 0 and game.JobId) or "test:"..HttpService:GenerateGUID(false);
	server.WorldName = data.WorldName or "";
	server.Version = data.Version or ServerManager.VersionId;
	server.AccessCode = data.AccessCode or nil;
	server.Players = data.Players or {};
	server.LastUpdated = data.LastUpdated or os.time();
	server.Linked = data.Linked or {};
	server.Closing = data.Closing or false;
	server.ShadowServer = data.ShadowServer or false;
	server.UpTime = data.UpTime or os.time();
	
	return server;
end

return function(serverManager)
	ServerManager = serverManager;
	return Server;
end;
