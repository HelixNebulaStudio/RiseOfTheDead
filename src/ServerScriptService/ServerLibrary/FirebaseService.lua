--== Configuration;
local defaultDatabase = "https://rise-of-the-dead.firebaseio.com/";
local authenticationToken = "00";

--== Variables;
local HttpService = game:GetService("HttpService");
local DataStoreService = game:GetService("DataStoreService");

local FirebaseService = {};
--== Script;
function FirebaseService:GetFirebase(name, database)
	database = database or defaultDatabase;
	local databaseName = database..HttpService:UrlEncode(name);
	local authentication = ".json?auth="..authenticationToken;

	local Firebase = {
		Datastore = DataStoreService:GetDataStore(name);
		UseDatabase = true;
	};
	
	function Firebase:UseDatabase(value)
		self.UseDatabase = value;
	end
	
	function Firebase:GetAsync(directory)
		local data = nil;
		
		--== Firebase Get;
		local getTick = tick();
		local tries = 0; repeat until pcall(function() tries = tries +1;
			data = HttpService:GetAsync(databaseName..HttpService:UrlEncode(directory and "/"..directory or "")..authentication, true);
		end) or tries > 2;
		if type(data) == "string" then
			if data:sub(1,1) == '"' then
				return data:sub(2, data:len()-1);
			elseif data:len() <= 0 then
				return nil;
			end
		end
		return tonumber(data) or data ~= "null" and data or nil;
	end
	
	function Firebase:SetAsync(directory, value, header)
		if not self.UseDatabase then return end
		if value == "[]" then self:RemoveAsync(directory); return end;
		
		--== Firebase Set;
		header = header or {["X-HTTP-Method-Override"]="PUT"};
		local replyJson = "";
		if type(value) == "string" and value:len() >= 1 and value:sub(1,1) ~= "{" and value:sub(1,1) ~= "[" then
			value = '"'..value..'"';
		end
		local success, errorMessage = pcall(function()
		replyJson = HttpService:PostAsync(databaseName..HttpService:UrlEncode(directory and "/"..directory or "")..authentication, value,
			Enum.HttpContentType.ApplicationUrlEncoded, false, header);
		end);
		if not success then
			warn("FirebaseService>> [ERROR] "..errorMessage);
			pcall(function()
				replyJson = HttpService:JSONDecode(replyJson or "[]");
			end)
		end
	end
	
	function Firebase:RemoveAsync(directory)
		self:SetAsync(directory, "", {["X-HTTP-Method-Override"]="DELETE"});
	end
	
	function Firebase:IncrementAsync(directory, delta)
		delta = delta or 1;
		local data = self:GetAsync(directory) or 0;
		if data then
			data = data+delta;
			self:SetAsync(directory, data);
		end
		return data;
	end
	
	function Firebase:UpdateAsync(directory, callback)
		local data = self:GetAsync(directory);
		local callbackData = callback(data);
		if callbackData then
			self:SetAsync(directory, callbackData);
		end
	end
	
	function Firebase:Destroy()
		if not self.UseDatabase then return end
		header = header or {["X-HTTP-Method-Override"]="DELETE"};
		local replyJson = "";
		local success, errorMessage = pcall(function()
		replyJson = HttpService:PostAsync(database..authentication, "",
			Enum.HttpContentType.ApplicationUrlEncoded, false, header);
		end);
		if not success then
			warn("FirebaseService>> [ERROR] "..errorMessage);
		end
	end
	
	return Firebase;
end

return FirebaseService;