local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RedeemService = {}
RedeemService.__index = RedeemService;

local MemoryStoreService = game:GetService("MemoryStoreService");

local modLibraryManager = require(game.ReplicatedStorage.Library.LibraryManager);
local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);

RedeemService.MemStore = MemoryStoreService:GetSortedMap("RedeemCodes");
RedeemService.ClaimCache = MemoryStoreService:GetSortedMap("ClaimCache");

local oneDaySec = 86400;
local oneMonthSec = 2592000;
--==

modRewardsLibrary:Add{
	Id="Halloween2021";
	Hidden=true;
	Rewards={
		{Index=1; ItemId="skinhalloweenpixelart"; Chance=1;};
	};
	IgnoreScan=true;
};


modRewardsLibrary:Add{
	Id="Offline";
	Hidden=true;
	Rewards={
		{Index=1; ItemId="skinoffline"; Chance=1;};
	};
	IgnoreScan=true;
};


-- Clear Claim Cache: 
-- game:GetService("MemoryStoreService"):GetSortedMap("ClaimCache"):RemoveAsync("16170943:Halloween2021");
-- /setredeemcode Halloween2021 2021
-- /listredeemcodes

function RedeemService:Redeem(player, redeemCode)
	local rPacket = {};
	rPacket.Claimed = false;
	rPacket.Skip = true;
	
	local s, e = pcall(function()
		
		self.ClaimCache:UpdateAsync(tostring(player.UserId)..":"..redeemCode, function(val)
			if val == true then return val end;
			
			rPacket.Skip = false;
			return true;
		end, oneMonthSec)
		
		if not rPacket.Skip then
			self.MemStore:UpdateAsync(redeemCode, function(val)
				if val < 0 then return val end;
				
				val = val -1;
				rPacket.Claimed = true;
				
				return val;
			end, self:GetTimeLeft(redeemCode))
		end
		
	end)
	
	if not s then
		Debugger:Warn(e);
	end
	
	return rPacket;
end

function RedeemService:GetCodeCount(redeemCode)
	local amount = 0;
	
	local s, e = pcall(function()
		amount = self.MemStore:GetAsync(redeemCode);
	end)
	
	if not s then
		Debugger:Warn(e);
	end
	
	return amount;
end

function RedeemService:GetRedeemCodes()
	local list = {};
	
	local s, e = pcall(function()
		list = self.MemStore:GetRangeAsync(Enum.SortDirection.Ascending, 200);
	end)
	if not s then
		Debugger:Warn(e);
	end
	
	return list;
end

function RedeemService:GetTimeLeft(redeemCode)
	local expireTime;
	
	local s, e = pcall(function()
		expireTime = self.MemStore:GetAsync(redeemCode.."Expire") or os.time() + oneMonthSec;
	end)
	if not s then
		Debugger:Warn(e);
	end
	
	return expireTime-os.time();
end

function RedeemService:SetCode(redeemCode, amount, sec)
	local s, e = pcall(function()
		
		self.MemStore:SetAsync(redeemCode.."Expire", os.time() + (sec or oneDaySec*3), oneMonthSec);
		self.MemStore:UpdateAsync(redeemCode, function(oldValue)
			return (amount or 100);
		end, self:GetTimeLeft(redeemCode))
	end)
	
	if not s then
		Debugger:Warn(e);
	end
	
	return s;
end

return RedeemService;
