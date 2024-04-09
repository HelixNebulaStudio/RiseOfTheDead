local modLibraryManager = require(game.ReplicatedStorage.Library.LibraryManager);
local TitleStyle = {
	Basic = {
		TextColor3 = Color3.fromRGB(130, 130, 130);
		TextStrokeColor3 = Color3.fromRGB(50, 50, 50);
	};
	
	--== Medal Tiers
	Bronze = {
		TextColor3 = Color3.fromRGB(159, 94, 64);
		TextStrokeColor3 = Color3.fromRGB(67, 44, 33);
	};
	Silver = {
		TextColor3 = Color3.fromRGB(230, 230, 230);
		TextStrokeColor3 = Color3.fromRGB(124, 124, 124);
	};
	Gold = {
		TextColor3 = Color3.fromRGB(208, 159, 43);
		TextStrokeColor3 = Color3.fromRGB(126, 87, 48);
	};
	Diamond = {
		TextColor3 = Color3.fromRGB(52, 201, 255);
		TextStrokeColor3 = Color3.fromRGB(98, 108, 112);
	};
	Nebula = {
		TextColor3 = Color3.fromRGB(155, 55, 255);
		TextStrokeColor3 = Color3.fromRGB(40, 30, 50);
	};
	Bloodmetal = {
		TextColor3 = Color3.fromRGB(255, 72, 0);
		TextStrokeColor3 = Color3.fromRGB(30, 0, 0);
	};
	
	--== Group Tiers
	Founder = {
		TextColor3 = Color3.fromRGB(255, 149, 0);
		TextStrokeColor3 = Color3.fromRGB(30, 0, 0);
	};
	Moderator = {
		TextColor3 = Color3.fromRGB(245, 88, 88);
		TextStrokeColor3 = Color3.fromRGB(30, 0, 0);
	};
	Staff = {
		TextColor3 = Color3.fromRGB(206, 107, 225);
		TextStrokeColor3 = Color3.fromRGB(30, 0, 0);
	};
	Helper = {
		TextColor3 = Color3.fromRGB(98, 190, 155);
		TextStrokeColor3 = Color3.fromRGB(30, 0, 0);
	};
	GameTester = {
		TextColor3 = Color3.fromRGB(98, 190, 155);
		TextStrokeColor3 = Color3.fromRGB(16, 31, 25);
	};
	
};

local UnlockMethods = {
	Achievement = "Achievement";
	Rank = "Rank";
};

local library = modLibraryManager.new();

--== Rank Titles;
library:Add{
	Id="rank255";
	Title="Founder";
	Unlock=UnlockMethods.Rank;
	UnlockValue=255;
	TitleStyle=TitleStyle.Founder;
};

library:Add{
	Id="rank220";
	Title="Moderator";
	Unlock=UnlockMethods.Rank;
	UnlockValue=220;
	TitleStyle=TitleStyle.Moderator;
};

library:Add{
	Id="rank205";
	Title="Programmer";
	Unlock=UnlockMethods.Rank;
	UnlockValue=205;
	TitleStyle=TitleStyle.Staff;
};

library:Add{
	Id="rank204";
	Title="Artist";
	Unlock=UnlockMethods.Rank;
	UnlockValue=204;
	TitleStyle=TitleStyle.Staff;
};

library:Add{
	Id="rank203";
	Title="Sound Designer";
	Unlock=UnlockMethods.Rank;
	UnlockValue=203;
	TitleStyle=TitleStyle.Staff;
};

library:Add{
	Id="rank202";
	Title="Builder";
	Unlock=UnlockMethods.Rank;
	UnlockValue=202;
	TitleStyle=TitleStyle.Staff;
};

library:Add{
	Id="rank201";
	Title="Story Designer";
	Unlock=UnlockMethods.Rank;
	UnlockValue=201;
	TitleStyle=TitleStyle.Staff;
};

library:Add{
	Id="rank200";
	Title="Animator";
	Unlock=UnlockMethods.Rank;
	UnlockValue=200;
	TitleStyle=TitleStyle.Staff;
};

library:Add{
	Id="rank101";
	Title="Game Tester";
	Unlock=UnlockMethods.Rank;
	UnlockValue=101;
	TitleStyle=TitleStyle.GameTester;
};

--== Achievement Titles;
library:Add{
	Id="whami";
	Title="Where.. am I?";
	Unlock=UnlockMethods.Achievement;
	TitleStyle=TitleStyle.Basic;
};

library:Add{
	Id="premem";
	Title="Premium Member";
	Unlock=UnlockMethods.Achievement;
	TitleStyle=TitleStyle.Gold;
};

library:Add{
	Id="theeng";
	Title="The Engineer";
	Unlock=UnlockMethods.Achievement;
	TitleStyle=TitleStyle.Silver;
};

library:Add{
	Id="thetra";
	Title="The Trader";
	Unlock=UnlockMethods.Achievement;
	TitleStyle=TitleStyle.Gold;
};

library:Add{
	Id="titoup";
	Title="Time To Upgrade";
	Unlock=UnlockMethods.Achievement;
	TitleStyle=TitleStyle.Bronze;
};

library:Add{
	Id="gromem";
	Title="Group Member";
	Unlock=UnlockMethods.Achievement;
	TitleStyle=TitleStyle.Bronze;
};

library:Add{
	Id="fimyst";
	Title="Fits My Style";
	Unlock=UnlockMethods.Achievement;
	TitleStyle=TitleStyle.Bronze;
};

library:Add{
	Id="thedec";
	Title="The Deconstructor";
	Unlock=UnlockMethods.Achievement;
	TitleStyle=TitleStyle.Gold;
};

library:Add{
	Id="maawe";
	Title="Mastered A Weapon";
	Unlock=UnlockMethods.Achievement;
	TitleStyle=TitleStyle.Bronze;
};

library:Add{
	Id="dammas";
	Title="Damage Master";
	Unlock=UnlockMethods.Achievement;
	TitleStyle=TitleStyle.Diamond;
};

library:Add{
	Id="thedef";
	Title="The Defender";
	Unlock=UnlockMethods.Achievement;
	TitleStyle=TitleStyle.Bronze;
};

library:Add{
	Id="zomhun";
	Title="Zombie Hunter";
	Unlock=UnlockMethods.Achievement;
	TitleStyle=TitleStyle.Silver;
};

library:Add{
	Id="zomext";
	Title="Zombie Exterminator";
	Unlock=UnlockMethods.Achievement;
	TitleStyle=TitleStyle.Gold;
};

library:Add{
	Id="zomann";
	Title="Zombie Annihilator";
	Unlock=UnlockMethods.Achievement;
	TitleStyle=TitleStyle.Diamond;
};

library:Add{
	Id="viptra";
	Title="VIP Traveler";
	Unlock=UnlockMethods.Achievement;
	TitleStyle=TitleStyle.Silver;
};

library:Add{
	Id="nekron";
	Title="Nekronomical";
	Unlock=UnlockMethods.Achievement;
	TitleStyle=TitleStyle.Diamond;
};

library:Add{
	Id="2022film";
	Title="Nebula Awards 2022";
	Unlock=UnlockMethods.Achievement;
	TitleStyle=TitleStyle.Nebula;
};

library:Add{
	Id="faction";
	Title="Faction Leader";
	Unlock=UnlockMethods.Achievement;
	TitleStyle=TitleStyle.Diamond;
};

library:Add{
	Id="merchant";
	Title="The Merchant";
	Unlock=UnlockMethods.Achievement;
	TitleStyle=TitleStyle.Diamond;
};

library:Add{
	Id="2023film";
	Title="Nebula Awards 2023";
	Unlock=UnlockMethods.Achievement;
	TitleStyle=TitleStyle.Nebula;
};

library:Add{
	Id="bpseason1";
	Title="Apocalypse Origins";
	Unlock=UnlockMethods.Achievement;
	TitleStyle=TitleStyle.Bloodmetal;
	BpLevels=true;
};

library:Add{
	Id="bphalloween1";
	Title="Slaughter Fest 2023";
	Unlock=UnlockMethods.Achievement;
	TitleStyle=TitleStyle.Bloodmetal;
	BpLevels=true;
};


return library;