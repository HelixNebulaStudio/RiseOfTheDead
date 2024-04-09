local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local FactionUser = {};
FactionUser.__index = FactionUser;
FactionUser.ClassType = "FactionUser";

function FactionUser.new(userId)
	local self = {
		UserId=tostring(userId);
		Tag="";
		Name="";
		Role="Member";
		LastActive=-1;
		
		IsInFaction=false;
		
		SuccessfulMissions={This=0; Total=0;};
		ScoreContribution={This=0; Total=0;};
		TopMissions={};
	};

	setmetatable(self, FactionUser);
	return self;
end

function FactionUser:OnDeserialize(rawData)
	if rawData == nil then return end;
	
	self.IsInFaction = rawData.Tag and #rawData.Tag > 2 or false;
end;

function FactionUser:SetFaction(tag)
	if tag == nil then
		self.Tag = nil;

	else
		if self.Tag ~= tag then
			self.SuccessfulMissions.This = 0;
			self.ScoreContribution.This = 0;
		end
		self.Tag = tag;

	end
end

function FactionUser:SetRole(roleKey)
	if roleKey == "__new" then -- roleKey == "Owner" or
		roleKey = "Member";
	end
	self.Role=roleKey;
end

function FactionUser:AddMissionScore(score)
	self.SuccessfulMissions.This = self.SuccessfulMissions.This +1;
	self.SuccessfulMissions.Total = self.SuccessfulMissions.Total +1;

	self.ScoreContribution.This = self.ScoreContribution.This + score;
	self.ScoreContribution.Total = self.ScoreContribution.Total + score;
end

return FactionUser;
