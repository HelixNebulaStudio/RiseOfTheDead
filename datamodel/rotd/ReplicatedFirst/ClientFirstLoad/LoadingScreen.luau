local Players = game:GetService("Players");
local ReplicatedFirst = game:GetService("ReplicatedFirst");
local TweenService = game:GetService("TweenService");

local camera = workspace.CurrentCamera;
local localPlayer = Players.LocalPlayer;
local playerGui = localPlayer:WaitForChild("PlayerGui")

local LOADING_HINTS = {
	`"Buying Jerrycans for 700k" ~ Tom`;
	`Tip: Press your interact key on an inventory item to quick use them.`;
	`"Has anyone seen my can of beans?" ~ Patrick`;
	`"Arrr, like clockwork.." ~ Icarus`;
	`Lore: No one has been able to enter or exit Wrighton Dale.. Except the Rats..`;
	`Tip: Press Delete key on an inventory item to quick open delete prompt.`;
	`Tip: You can see where to get any item by check it in the shop's codex.`;
}

local WD_HEADER = "Wrighton Dale";
local WORLDS_INFO_LIBRARY = {


	--MARK: Cutscenes;
	["TheBeginning"] = {
		Images = {"rbxassetid://130814951913643"};
		HeaderTexts = WD_HEADER;
		TitleTexts = "South Bridge";
		DescTexts = "You hear the sound of thunder..";
	};
	["AwokenTheBear"] = {
		Images = {"rbxassetid://137215327484702"};
		HeaderTexts = WD_HEADER;
		TitleTexts = "Mission: Awoken The Bear";
		DescTexts = "Having second thoughts about sneaking in here..";
	};
	["VindictiveTreasure"] = {
		Images = {"rbxassetid://74882409675228"};
		HeaderTexts = WD_HEADER;
		TitleTexts = "Mission: Vindictive Treasure";
		DescTexts = "The secrets of Wrighton Dale never ceases to surprise me..";
	};
	["TheInvestigation"] = {
		Images = {"rbxassetid://131869850967869"};
		HeaderTexts = WD_HEADER;
		TitleTexts = "Mission: The Investigation";
		DescTexts = "Time to find out what is Robert truely up to..";
	};
	["DoubleCross"] = {
		Images = {"rbxassetid://112967703279702"};
		HeaderTexts = WD_HEADER;
		TitleTexts = "Mission: Double Cross";
		DescTexts = "The two big bads are about to meet..";
	};
	["BanditsRecruitment"] = {
		Images = {"rbxassetid://82343819751429"};
		HeaderTexts = WD_HEADER;
		TitleTexts = "Mission: Bandits Recruitment";
		DescTexts = "If I want something done about the bandits, I got to do it from within..";
	};
	["MedicalBreakthrough"] = {
		Images = {"rbxassetid://109489716981323"};
		HeaderTexts = WD_HEADER;
		TitleTexts = "Mission: Medical Breakthrough";
		DescTexts = "If anyone is going to figure this plague out, it's Rachel..";
	};


	--MARK: Overworlds;
	["TheWarehouse"] = {
		Images = {"rbxassetid://5954340695"};
		HeaderTexts = WD_HEADER;
		TitleTexts = "The Warehouse";
		DescTexts = "Safest place in Wrighton Dale..";
	};
	["TheUnderground"] = {
		Images = {"rbxassetid://5959082717"};
		HeaderTexts = WD_HEADER;
		TitleTexts = "The Underground";
		DescTexts = "A chill of withering echo runs down your spine..";
	};
	["TheMall"] = {
		Images = {"rbxassetid://5959095409"};
		HeaderTexts = WD_HEADER;
		TitleTexts = "The Mall";
		DescTexts = "Sense of a tyrannical force operates this area..";
	};
	["TheResidentials"] = {
		Images = {"rbxassetid://5959099674"};
		HeaderTexts = WD_HEADER;
		TitleTexts = "The Residentials";
		DescTexts = "Sounds of hope and prosperity fighting the siren of oppression..";
	};
	["TheHarbor"] = {
		Images = {"rbxassetid://7368989503"};
		HeaderTexts = WD_HEADER;
		TitleTexts = "The Harbor";
		DescTexts = "An invisible hand pulls the strings across this entire sector..";
	};


	--MARK: Raids;
	["Factory"] = {
		Images = {"rbxassetid://83891112840676"};
		HeaderTexts = WD_HEADER;
		TitleTexts = "Raid: Factory";
		DescTexts = "Someone went to great lengths to lure and board up this abandoned factory with a bunch of Zombies..";
	};
	["Office"] = {
		Images = {"rbxassetid://96259836280309"};
		HeaderTexts = WD_HEADER;
		TitleTexts = "Raid: Office";
		DescTexts = "This is not a very secure place to set up camp..";
	};
	["BanditOutpost"] = {
		Images = {"rbxassetid://88011398228757"};
		HeaderTexts = WD_HEADER;
		TitleTexts = "Raid: Bandit Outpost";
		DescTexts = "What have I gotten myself into..";
	};
	["Tombs"] = {
		Images = {"rbxassetid://74750671659386"};
		HeaderTexts = WD_HEADER;
		TitleTexts = "Raid: Tombs";
		DescTexts = "There are some sort of evil aura in here..";
	};
	["Railways"] = {
		Images = {"rbxassetid://118010878567350"};
		HeaderTexts = WD_HEADER;
		TitleTexts = "Raid: Railways";
		DescTexts = "There are some sort of evil aura in here..";
	};
	["AbandonedBunker"] = {
		Images = {"rbxassetid://106303624790264"};
		HeaderTexts = WD_HEADER;
		TitleTexts = "Raid: Abandoned Bunker";
		DescTexts = "I'm pretty sure this place didn't looked like this yesterday..";
	};


	--MARK: Coop
	["Genesis"] = {
		Images = {"rbxassetid://80837790418304"};
		HeaderTexts = WD_HEADER;
		TitleTexts = "Coop: Genesis";
		DescTexts = "I'm getting a sense of deja vu here, like I've been here in a past life..";
	};
	["SunkenShip"] = {
		Images = {"rbxassetid://129247721474357"};
		HeaderTexts = WD_HEADER;
		TitleTexts = "Coop: Sunken Ship";
		DescTexts = "What could've created such as destructive force..";
	};


	--MARK: Survival;
	["SectorF"] = {
		Images = {"rbxassetid://128153872662511"};
		HeaderTexts = WD_HEADER;
		TitleTexts = "Survival: Sector F";
		DescTexts = "Something tells me it all began here..";
	};
	["Prison"] = {
		Images = {"rbxassetid://91188047886850"};
		HeaderTexts = WD_HEADER;
		TitleTexts = "Survival: W.D. Prison";
		DescTexts = "Shame that the ones who escapes are going to find out that Wrighton Dale is the new prison..";
	};
	["SectorD"] = {
		Images = {"rbxassetid://77976475662594"};
		HeaderTexts = WD_HEADER;
		TitleTexts = "Survival: Sector D";
		DescTexts = "This facility feels like a top secret government research center..";
	};
	["Swamplands"] = {
		Images = {"rbxassetid://90652495732571"};
		HeaderTexts = WD_HEADER;
		TitleTexts = "Survival: Swamplands";
		DescTexts = "A group of people lived here, but why..";
	};

	["CommunityWaySide"] = {
		Images = {"rbxassetid://138359514045150"};
		HeaderTexts = WD_HEADER;
		TitleTexts = "Community Survival: Way Side";
		DescTexts = "Way Side by Choppygraph";
	};
	["CommunityFissionBay"] = {
		Images = {"rbxassetid://80482370239974"};
		HeaderTexts = WD_HEADER;
		TitleTexts = "Community Survival: Fission Bay";
		DescTexts = "Fission Bay by Omega_913";
	};
	["CommunityRooftops"] = {
		Images = {"rbxassetid://91819331919408"};
		HeaderTexts = WD_HEADER;
		TitleTexts = "Community Survival: Rooftops";
		DescTexts = "Rooftops by Omega_913";
	};


    --MARK: Events
	["EasterButchery"] = {
		Images = {"rbxassetid://136397911908508"};
		HeaderTexts = WD_HEADER;
		TitleTexts = "Easter: Butchery";
		DescTexts = "Bunnyman wants to know your location..";
	};
	["HalloweenBasement"] = {
		Images = {"rbxassetid://105212585938594"};
		HeaderTexts = WD_HEADER;
		TitleTexts = "Witherween: Basement";
		DescTexts = "Wanna play a game?";
	};
	["KlawsWorkshop"] = {
		Images = {"rbxassetid://81870473406162"};
		HeaderTexts = WD_HEADER;
		TitleTexts = "Winterfest: Klaw's Workshop";
		DescTexts = "This toy factory has some really strange architecture.";
	};
	["Slaughterfest"] = {
		Images = {"rbxassetid://135681954437525"};
		HeaderTexts = WD_HEADER;
		TitleTexts = "Slaughterfest: Forest";
		DescTexts = "Kill or be killed..";
	};



	["BioXResearch"] = {};
	["MainMenu"] = {};
	["Generic"] = {
		Images = {"rbxassetid://110654502874576"; "rbxassetid://118039036300880"};
	};
};


local LoadingScreen = {};

local newLoadingScreenCd = tick()-1;
function LoadingScreen.newLoadingScreen(tpScreenGui, worldName)
	if tick() < newLoadingScreenCd then return end;
	newLoadingScreenCd = tick()+1;

	local isTeleportIn = false;
	local loadingScreen, newFrame;
	if tpScreenGui == nil then
		loadingScreen = Instance.new("ScreenGui");
		loadingScreen.Name = "LoadingScreen";
		loadingScreen.DisplayOrder = 5;
		loadingScreen.IgnoreGuiInset = true;
		loadingScreen.Parent = playerGui;

		newFrame = script:WaitForChild("LoadingFrame"):Clone();
		newFrame.Parent = loadingScreen;

		task.delay(25, function() loadingScreen:Destroy(); end)
	
	else
		isTeleportIn = true;
		loadingScreen = tpScreenGui;
		loadingScreen.Parent = playerGui;
		newFrame = tpScreenGui:WaitForChild("LoadingFrame");
		loadingScreen.DisplayOrder = 6;

	end

	local WORLD_NAME = worldName or ReplicatedFirst:WaitForChild("PlaceName").Value;
	local WORLD_INFO = WORLDS_INFO_LIBRARY[WORLD_NAME];

	if WORLD_INFO == nil then
		WORLD_INFO = WORLDS_INFO_LIBRARY.Generic;
	end

	local function fadeGuiObjects(fadeIn, duration)
		local fadeTweenInfo = TweenInfo.new(duration or 1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);

		local tweens = {};

		for _, child in ipairs(newFrame:GetChildren()) do
			if child:IsA("ImageLabel") then
				local tween = TweenService:Create(
					child, 
					fadeTweenInfo, 
					{
						ImageTransparency = fadeIn and 0 or 1;
					}
				);
				table.insert(tweens, tween);

			elseif child:IsA("TextLabel") then
				local tween = TweenService:Create(
					child, 
					fadeTweenInfo, 
					{
						TextTransparency = fadeIn and 0 or 1;
					}
				);
				table.insert(tweens, tween);

			end
		end

		TweenService:Create(newFrame, TweenInfo.new(duration or 1), {
			BackgroundTransparency = fadeIn and 0 or 1;
		}):Play();

		for a=1, #tweens do
			tweens[a]:Play();
		end
	end

	local loadingImage = newFrame:WaitForChild("LoadingImage");
	local loadingImageBk1 = loadingImage:WaitForChild("LoadingImageBk1");
	local loadingImageBk2 = loadingImage:WaitForChild("LoadingImageBk2");

	loadingImage:GetPropertyChangedSignal("ImageTransparency"):Connect(function()
		loadingImageBk1.ImageTransparency = loadingImage.ImageTransparency;
		loadingImageBk2.ImageTransparency = loadingImage.ImageTransparency;
	end)

	TweenService:Create(
		loadingImage, 
		TweenInfo.new(10, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), 
		{
			Rotation = 360;
		}
	):Play();


	local thumbnailImage: ImageLabel = newFrame:WaitForChild("Thumbnail");
	if WORLD_INFO.Images then
		thumbnailImage.Image = WORLD_INFO.Images[math.random(1, #WORLD_INFO.Images)];
		TweenService:Create(
			thumbnailImage, 
			TweenInfo.new(7, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1, true), {
				Size = UDim2.new(1.1, 0, 1.1, 0);
			}
		):Play();
	end


	local textLabel: TextLabel = newFrame:WaitForChild("TextLabel");
	local textLabelBk1 = textLabel:WaitForChild("TextLabelBk1");
	local textLabelBk2 = textLabel:WaitForChild("TextLabelBk2");

	textLabel:GetPropertyChangedSignal("Text"):Connect(function()
		textLabelBk1.Text = textLabel.Text;
		textLabelBk2.Text = textLabel.Text;
	end)
	textLabel:GetPropertyChangedSignal("TextTransparency"):Connect(function()
		textLabelBk1.TextTransparency = textLabel.TextTransparency;
		textLabelBk2.TextTransparency = textLabel.TextTransparency;
	end)

	if camera.ViewportSize.Y <= 720 then
		textLabel.LineHeight = 1.4;
		textLabelBk1.LineHeight = 1.4;
		textLabelBk2.LineHeight = 1.4;
		textLabel.Size = UDim2.new(1, 0, 0.5, 0);
	end

	local loadingTextList = {};

	if WORLD_INFO.HeaderTexts then
		local headerTexts = typeof(WORLD_INFO.HeaderTexts) == "table" and WORLD_INFO.HeaderTexts or {WORLD_INFO.HeaderTexts};
		table.insert(loadingTextList, `<font size="14">{headerTexts[math.random(1, #headerTexts)]}</font>`);
	end
	if WORLD_INFO.TitleTexts then
		local titleTexts = typeof(WORLD_INFO.TitleTexts) == "table" and WORLD_INFO.TitleTexts or {WORLD_INFO.TitleTexts};
		table.insert(loadingTextList, `<font size="42">{titleTexts[math.random(1, #titleTexts)]}</font>`);
	end
	if WORLD_INFO.DescTexts then
		local descTexts = typeof(WORLD_INFO.DescTexts) == "table" and WORLD_INFO.DescTexts or {WORLD_INFO.DescTexts};
		table.insert(loadingTextList, `<font size="18">{descTexts[math.random(1, #descTexts)]}</font>`);
	end

	table.insert(loadingTextList, `\n<font size="14">{LOADING_HINTS[math.random(1, #LOADING_HINTS)]}</font>`);


	if isTeleportIn == false then
		textLabel.Text = table.concat(loadingTextList, "\n");

		fadeGuiObjects(true);
	end

	return {
		ScreenGui = loadingScreen;
		Fade = fadeGuiObjects;
	}
end

function LoadingScreen.init(tpScreenGui)
	local newLoadingScreen = LoadingScreen.newLoadingScreen(tpScreenGui);

	ReplicatedFirst:RemoveDefaultLoadingScreen();

	local addDelay = script:GetAttribute("Delay") or 0;
	task.wait(3 + addDelay);

	if not game:IsLoaded() then
		game.Loaded:Wait();
	end

	newLoadingScreen.Fade(false);
	task.wait(1.1);
	newLoadingScreen.ScreenGui:Destroy();
end

return LoadingScreen;