local module = {};

module.List = {
	"Tip: You can pin and unpin a mission by right clicking it from the missions menu.";
	"Tip: If you are lagging, lower your graphic settings in Roblox settings, it can reduce/disable bullet holes!";
	"Tip: You can slide by running and crouching at the same time!";
	"Tip: If you want to get past a horde of zombies, just jump on their heads!";
	"Tip: Your F2 key doesn't work and you want to access the settings? Use /settings";
	"Tip: You can travel to a friend from the social menu, even if you haven't unlocked the area yet, but be careful!";
	"Tip: Have feedback? Found a bug? Open the report menu by pressing F3 or type in chat /report";
	"Tip: You can customize your auto pick up in the settings to select what you want to pick up.";
	"Fun Fact: Rise Of The Dead (Legacy) started development back in 2014.";
	"Fun Fact: Each safehouse has an easter egg hidden somewhere.";
	"Fun Fact: Pathoroth used to be an extreme boss in W.D. Mall.";
	"Fun Fact: R.A.T. members, also known as shop keepers, have their own tunnels for transporting goods.";
	"Fun Fact: R.A.T. members, also known as shop keepers, have their own tunnels for transporting goods.";
};

function module.Get()
	local seed = workspace:GetAttribute("DayOfYear") or 0;
	local random = Random.new(seed);
	return module.List[random:NextInteger(1, #module.List)];
end

return module;
