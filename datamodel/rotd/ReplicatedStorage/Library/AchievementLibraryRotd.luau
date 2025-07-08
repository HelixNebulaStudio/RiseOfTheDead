local library = shared.require(game.ReplicatedStorage.Library.AchievementLibrary);

local Tiers = {
	None={};
	Bronze={Perks=10;};
	Silver={Perks=25;};
	Gold={Perks=50;};
	Diamond={Perks=100;};
	Bloodmetal={Perks=100;};
	Nebula={};
}

library:Add{
	Id="whami"; -- Where... am I?
	Tier=Tiers.None;
	BadgeId=478975214;
	Announce="Achievement Unlocked: Joining the game for the first time.";
};

library:Add{
	Id="premem"; -- Premium Member?
	Tier=Tiers.Gold;
	BadgeId=479110154;
	Announce="Achievement Unlocked: Acquiring Premium Member!";
};

library:Add{
	Id="maawe"; -- Master a weapon
	Tier=Tiers.Bronze;
	BadgeId=2124505969;
	Announce="Achievement Unlocked: Reaching weapon level 20!";
};

library:Add{
	Id="dammas"; -- Damage Master
	Tier=Tiers.Diamond;
	BadgeId=2124505986;
	Announce="$PlayerName Achievement Unlocked: Maxing out a damage mod!";
	PublicAnnounce=true;
};

-- Zombile Kills;
library:Add{
	Id="thedef"; -- The defender
	Tier=Tiers.Bronze;
	BadgeId=2124506791;
	Announce="Achievement Unlocked: Killed 1'000 zombies!";
};

library:Add{
	Id="zomhun"; -- Zombie hunter
	Tier=Tiers.Silver;
	BadgeId=2124506792;
	Announce="Achievement Unlocked: Killed 10'000 zombies!";
};

library:Add{
	Id="zomext"; -- Zombie exterminator
	Tier=Tiers.Gold;
	BadgeId=2124506793;
	Announce="Achievement Unlocked: Killed 100'000 zombies!";
};

library:Add{
	Id="zomann"; -- Zomie ann
	Tier=Tiers.Diamond;
	BadgeId=2124506794;
	Announce="$PlayerName Achievement Unlocked: Killed 1 million zombies!";
	PublicAnnounce=true;
};
-- Zombile Kills;

library:Add{
	Id="thetra"; -- The Trader
	Tier=Tiers.Gold;
	BadgeId=2124512282;
	Announce="Achievement Unlocked: Acquired Gold for the first time.";
};

library:Add{
	Id="theeng"; -- The Engineer
	Tier=Tiers.Silver;
	BadgeId=2124512281;
	Announce="Achievement Unlocked: Unlocked the ability to use the workbench anywhere.";
};

library:Add{
	Id="titoup"; -- Time To Upgrade
	Tier=Tiers.Bronze;
	BadgeId=2124513957;
	Announce="Achievement Unlocked: Upgrading your equipment for the first time.";
};

library:Add{
	Id="gromem"; -- Group Member
	Tier=Tiers.Bronze;
	BadgeId=2124513958;
	Announce="Achievement Unlocked: Joined the Helix Nebula Studio group.";
};

library:Add{
	Id="fimyst"; -- Fits My Style
	Tier=Tiers.Bronze;
	BadgeId=2124513960;
	Announce="Achievement Unlocked: Customized your equipment for the first time.";
};

library:Add{
	Id="thedec"; -- The Deconstructor
	Tier=Tiers.Gold;
	BadgeId=2124513965;
	Announce="Achievement Unlocked: Deconstruct a fully upgraded mod and claimed it.";
};

library:Add{
	Id="viptra"; -- vip travel
	Tier=Tiers.Silver;
	BadgeId=2124753015;
	Announce="Achievement Unlocked: Unlocked the ability to fast travel for 75% off.";
};

library:Add{
	Id="nekron"; -- Nekronomical
	Tier=Tiers.Diamond;
	BadgeId=2124753016;
	Announce="$PlayerName Achievement Unlocked: Acquiring Nekronomical by tweaking your weapons.";
	PublicAnnounce=true;
};

library:Add{
	Id="2022film"; -- Nebula Film Contest
	Tier=Tiers.Nebula;
	BadgeId=2125028614;
	Announce="$PlayerName Achievement Unlocked: Participant of the 2022 Nebula Film Contest.";
	PublicAnnounce=true;
	Hidden=true;
};

library:Add{
	Id="faction"; -- Faction Leader
	Tier=Tiers.Diamond;
	BadgeId=2126995475;
	Announce="$PlayerName Achievement Unlocked: Creating your own faction.";
	PublicAnnounce=true;
};

library:Add{
	Id="merchant"; -- The Merchant
	Tier=Tiers.Diamond;
	BadgeId=2146888057;
	Announce="$PlayerName Achievement Unlocked: Completing 100 trades.";
	PublicAnnounce=true;
}

library:Add{
	Id="2023film"; -- Nebula Film Contest
	Tier=Tiers.Nebula;
	BadgeId=2141830445;
	Announce="$PlayerName Achievement Unlocked: Participant of the 2023 Nebula Film Contest.";
	PublicAnnounce=true;
	Hidden=true;
};

library:Add{
	Id="bpseason1"; -- Bp season 1
	Tier=Tiers.Bloodmetal;
	BadgeId=2147850756;
	Announce="$PlayerName Completed: Apocalypse Origins Event Pass.";
	Hidden=true;
}

library:Add{
	Id="bphalloween1"; -- Bp halloween 1
	Tier=Tiers.Bloodmetal;
	BadgeId=2152862689;
	Announce="$PlayerName Completed: Slaughter Fest 2023 Event Pass.";
	Hidden=true;
}

library:Add{
	Id="bp5years"; -- Bp 5 years
	Tier=Tiers.Bloodmetal;
	BadgeId=531879295475986;
	Announce="$PlayerName Completed: 5 Years Anniversary Event Pass.";
	Hidden=true;
}

library:Add{
	Id="dbtinker"; -- dbtinker
	Tier=Tiers.Gold;
	BadgeId=3689379645649221;
	Announce="Achievement Unlocked: Unlocked development branch commands.";
	Hidden=true;
}

library:Add{
	Id="slaughterfest2024";
	Tier=Tiers.Bloodmetal;
	BadgeId=3813260452618296;
	Announce="$PlayerName Unlocked: Slaughterfest 2024";
	Hidden=true;
}

library:Add{
	Id="frostivus2024";
	Tier=Tiers.Bloodmetal;
	BadgeId=198525199497730;
	Announce="$PlayerName Completed: Frostivus 2024 Event Pass.";
	Hidden=true;
}

library.Tiers = Tiers;
return library;