local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local MailObject = {};
MailObject.Enum = {
	PurchasedPerksCollection=1;
	Referral=2;
	Gift=3;
	LevelPerksReward=4;
	ReferralComplete=5;
	TweakPoints=6;
	LoadLegacySave=99;
}

--== Script;
function MailObject.new(mailType, mailData)
	return {Type=mailType; Data=mailData;};
end

return MailObject;