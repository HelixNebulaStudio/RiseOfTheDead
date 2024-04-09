local modLibraryManager = require(game.ReplicatedStorage.Library.LibraryManager);
local library = modLibraryManager.new();

local thumbnailString = "http://www.roblox.com/Thumbs/Asset.ashx?format=png&width=150&height=150&assetId=";

library:Add{
	Id="nodyes";
	Name="Nodding Yes";
	LayoutOrder=1;
	AnimationId="rbxassetid://3275424185";
	Looped=false;
	Unlocked=true;
};

library:Add{
	Id="nodno";
	Name="Nodding No";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://3275433209";
	Looped=false;
	Unlocked=true;
};

library:Add{
	Id="shrug2";
	Name="Shrug 2";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://16659928811"; --3261531578
	Looped=false;
	Unlocked=true;
	Thumbnail=thumbnailString.."3576968026";
};

library:Add{
	Id="clapping";
	Name="Clapping";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://3261558526";
	Looped=true;
	Unlocked=true;
};

library:Add{
	Id="crossedarm";
	Name="Crossed Arm";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://6885373092";
	Looped=true;
	Unlocked=true;
};

library:Add{
	Id="handout";
	Name="Hand out";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://6418497950";
	Looped=true;
	Unlocked=true;
};

library:Add{
	Id="wave";
	Name="Wave";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://507770239";
	Looped=false;
	Unlocked=true;
	Thumbnail=thumbnailString.."3576686446";
	-- Rbx;
};

library:Add{
	Id="cheer";
	Name="Cheer";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://507770677";
	Looped=true;
	Unlocked=true;
	-- Rbx;
};

library:Add{
	Id="laugh";
	Name="Laugh";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://507770818";
	Looped=false;
	Unlocked=true;
	-- Rbx;
};

library:Add{
	Id="point";
	Name="Point";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://507770453";
	Looped=false;
	Unlocked=true;
	Thumbnail=thumbnailString.."3576823880";
	-- Rbx;
};

library:Add{
	Id="Idle";
	Name="Idle";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://2157846793";
	Looped=true;
	Unlocked=false;
	-- Rbx;
};

library:Add{
	Id="dance";
	Name="Default Dance 1";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://507772104";
	Looped=true;
	Unlocked=true;
	-- Rbx;
};

library:Add{
	Id="dance2";
	Name="Default Dance 2";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://507776879";
	Looped=true;
	Unlocked=true;
	-- Rbx;
};

library:Add{
	Id="dance3";
	Name="Default Dance 3";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://507777623";
	Looped=true;
	Unlocked=true;
	-- Rbx;
};

library:Add{
	Id="dance4";
	Name="The Mechanical";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://3641511003";
	Looped=true;
	Unlocked=true;
};

library:Add{
	Id="sittingonedge";
	Name="Sitting";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://3274848554";
	Looped=true;
	Unlocked=true;
};

library:Add{
	Id="sitting2";
	Name="Sitting 2";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://3641533487";
	Looped=true;
	Unlocked=true;
};

library:Add{
	Id="sleeping";
	Name="Sleeping";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://3275568427";
	Looped=true;
	Unlocked=true;
};

library:Add{
	Id="sleeping2";
	Name="Sleeping 2";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://3641341316";
	Looped=true;
	Unlocked=true;
};

library:Add{
	Id="sittingonground";
	Name="Sitting On Ground";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://3275586488";
	Looped=true;
	Unlocked=true;
};

library:Add{
	Id="sitting3";
	Name="Slavic Squat";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://3641602269";
	Looped=true;
	Unlocked=true;
};

library:Add{
	Id="leanforward";
	Name="Lean Forwards";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://16952747017";
	Looped=true;
	Unlocked=true;
};

library:Add{
	Id="leanback";
	Name="Lean Backwards";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://3275612620";
	Looped=true;
	Unlocked=true;
};

library:Add{
	Id="panic";
	Name="Panic";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://4927208372";
	Looped=true;
	Unlocked=true;
};

library:Add{
	Id="t";
	Name="T";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://3338010159";
	Looped=false;
	Unlocked=true;
	Thumbnail=thumbnailString.."3576719440";
	-- Rbx;
};

library:Add{
	Id="toprock";
	Name="Top Rock";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://3361276673";
	Looped=false;
	Unlocked=true;
	Thumbnail=thumbnailString.."3570535774";
	-- Rbx;
};

library:Add{
	Id="robot";
	Name="Robot";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://3338025566";
	Looped=false;
	Unlocked=true;
	Thumbnail=thumbnailString.."3576721660";
	-- Rbx;
};

library:Add{
	Id="shy";
	Name="Shy";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://3337978742";
	Looped=false;
	Unlocked=true;
	Thumbnail=thumbnailString.."3576717965";
	-- Rbx;
};

library:Add{
	Id="tilt";
	Name="Tilt";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://3334538554";
	Looped=false;
	Unlocked=true;
	Thumbnail=thumbnailString.."3360692915";
	-- Rbx;
};

library:Add{
	Id="shrug";
	Name="Shrug";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://3334392772";
	Looped=false;
	Unlocked=true;
	Thumbnail=thumbnailString.."3576968026";
	-- Rbx;
};

library:Add{
	Id="hello";
	Name="Hello";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://3344650532";
	Looped=false;
	Unlocked=true;
	Thumbnail=thumbnailString.."3576686446";
	-- Rbx;
};

library:Add{
	Id="stadium";
	Name="Stadium";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://3338055167";
	Looped=true;
	Unlocked=true;
	Thumbnail=thumbnailString.."3360686498";
	-- Rbx;
};

library:Add{
	Id="salute";
	Name="Salute";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://3333474484";
	Looped=false;
	Unlocked=true;
	Thumbnail=thumbnailString.."3360689775";
	-- Rbx;
};

library:Add{
	Id="surrender";
	Name="Surrender";
	LayoutOrder=library.Size+2;
	AnimationId="rbxassetid://4905193674";
	Looped=true;
	Unlocked=true;
};

library:Add{
	Id="aroundtown";
	Name="Around Town";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://3303391864";
	Looped=true;
	Unlocked=true;
	Thumbnail=thumbnailString.."3576747102";
	-- Rbx;
};

library:Add{
	Id="celebrate";
	Name="Celebrate";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://3338097973";
	Looped=true;
	Unlocked=true;
	Thumbnail=thumbnailString.."3994127840";
	-- Rbx;
};

library:Add{
	Id="point2";
	Name="Point 2";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://3344585679";
	Looped=false;
	Unlocked=true;
	Thumbnail=thumbnailString.."3576823880";
	-- Rbx;
};

library:Add{
	Id="injured";
	Name="Injured";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://3720684640";
	Looped=true;
	Unlocked=true;
};

library:Add{
	Id="scared";
	Name="Scared";
	LayoutOrder=library.Size+1;
	AnimationId="rbxassetid://3720752373";
	Looped=true;
	Unlocked=true;
};

library:Add{
	Id="scaredpeek";
	Name="Scared Peek";
	LayoutOrder=library.Size+2;
	AnimationId="rbxassetid://3720798293";
	Looped=true;
	Unlocked=true;
};

library:Add{
	Id="hypedance";
	Name="Hype Dance";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://3695333486";
	Looped=true;
	Unlocked=true;
	-- Rbx;
};

library:Add{
	Id="zombie";
	Name="Zombie";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://4210116953";
	Looped=true;
	Unlocked=true;
	Thumbnail=thumbnailString.."4212496830";
	-- Rbx;
};

library:Add{
	Id="jacks";
	Name="Jumping Jacks";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://3338066331";
	Looped=true;
	Unlocked=true;
	Thumbnail=thumbnailString.."3570649048";
	-- Rbx;
};

library:Add{
	Id="chacha";
	Name="Cha Cha";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://3695322025";
	Looped=true;
	Unlocked=true;
	-- Rbx;
};

library:Add{
	Id="airguitar";
	Name="Air Guitar";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://3695300085";
	Looped=true;
	Unlocked=true;
	-- Rbx;
};

library:Add{
	Id="heismanpose";
	Name="Heisman Pose";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://3695263073";
	Looped=true;
	Unlocked=true;
	-- Rbx;
};

library:Add{
	Id="superheroreveal";
	Name="Superhero Reveal";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://3695373233";
	Looped=true;
	Unlocked=true;
};

--library:Add{
--	Id="layingdead";
--	Name="Laying Dead";
--	LayoutOrder=library.Size;
--	AnimationId="rbxassetid://4644365025";
--	Looped=true;
--	Unlocked=true;
--};

library:Add{
	Id="cower";
	Name="Cower";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://4940563117";
	Looped=false;
	Unlocked=true;
	-- Rbx;
};

library:Add{
	Id="confused";
	Name="Confused";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://4940561610";
	Looped=false;
	Unlocked=true;
	-- Rbx;
};

library:Add{
	Id="dizzy";
	Name="Dizzy";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://3361426436";
	Looped=false;
	Unlocked=true;
	-- Rbx;
};

library:Add{
	Id="getout";
	Name="Get Out";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://3333272779";
	Looped=false;
	Unlocked=true;
	-- Rbx;
};


library:Add{
	Id="fancyfeet";
	Name="Fancy Feet";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://3333432454";
	Looped=false;
	Unlocked=true;
	-- Rbx;
};

library:Add{
	Id="dolphinedance";
	Name="Dolphin Dance";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://5918726674";
	Looped=false;
	Unlocked=true;
	Thumbnail=thumbnailString.."5938365243";
	-- Rbx;
};

library:Add{
	Id="bored";
	Name="Bored";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://5230599789";
	Looped=false;
	Unlocked=true;
	Thumbnail=thumbnailString.."5230661597";
	-- Rbx;
};

library:Add{
	Id="sneaky";
	Name="Sneaky";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://3334424322";
	Looped=false;
	Unlocked=true;
	Thumbnail=thumbnailString.."3576754235";
	-- Rbx;
};

library:Add{
	Id="breakdance";
	Name="Break Dance";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://5915648917";
	Looped=false;
	Unlocked=true;
	Thumbnail=thumbnailString.."5915773992";
	-- Rbx;
};

library:Add{
	Id="beckon";
	Name="Beckon";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://5230598276";
	Looped=false;
	Unlocked=true;
	Thumbnail=thumbnailString.."5230615437";
	-- Rbx;
};

library:Add{
	Id="y";
	Name="Y";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://4349285876";
	Looped=false;
	Unlocked=true;
	Thumbnail=thumbnailString.."4391211308";
	-- Rbx;
};


library:Add{
	Id="FixingWire";
	Name="Fixing Wire";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://7453395758";
	Looped=false;
	Unlocked=true;
	
	-- Interaction;
};


library:Add{
	Id="InspectCrate";
	Name="Inspect Crate";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://8904730107";
	Looped=false;
	Unlocked=true;
	
	-- Interaction;
};


library:Add{
	Id="OpenDoor";
	Name="Open Door";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://7453785412";
	Looped=false;
	Unlocked=true;
	
	-- Interaction;
};

library:Add{
	Id="CloseDoor";
	Name="Close Door";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://7454008924";
	Looped=false;
	Unlocked=true;
	
	-- Interaction;
};

library:Add{
	Id="DOpenDoor";
	Name="Open Double Door";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://7454184767";
	Looped=false;
	Unlocked=true;
	
	-- Interaction;
};

library:Add{
	Id="DCloseDoor";
	Name="Close Double Door";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://7454200705";
	Looped=false;
	Unlocked=true;
	
	-- Interaction;
};

library:Add{
	Id="PullLever";
	Name="Pull Lever";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://7453932498";
	Looped=false;
	Unlocked=true;
	
	-- Interaction;
};

library:Add{
	Id="UnpullLever";
	Name="Unpull Lever";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://7453985015";
	Looped=false;
	Unlocked=true;
	
	-- Interaction;
};

library:Add{
	Id="Press";
	Name="Button Press";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://7454343107";
	Looped=false;
	Unlocked=true;
	
	-- Interaction;
};

library:Add{
	Id="OpenStorage";
	Name="Open Storage";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://7455442251";
	Looped=false;
	Unlocked=true;
	
	-- Interaction;
};

library:Add{
	Id="Unconscious";
	Name="Unconscious";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://4644365025";
	Looped=true;
	Unlocked=true;
	
	-- Interaction;
};

library:Add{
	Id="climbincrate";
	Name="Climb In Crate";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://9721327802";
	Looped=true;
	Unlocked=false;

	-- Interaction;
};

library:Add{
	Id="useterminal";
	Name="Use Terminal";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://9730558323";
	Looped=true;
	Unlocked=true;

	-- Interaction;
};

library:Add{
	Id="getshot";
	Name="Got Shot";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://4906948499";
	Looped=true;
	Unlocked=true;

	-- Interaction;
};

library:Add{
	Id="injured2";
	Name="Injured 2";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://9759548068";
	Looped=true;
	Unlocked=true;

	-- Interaction;
};


library:Add{
	Id="pickupcharacter";
	Name="Pick Up Character";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://9760603153"; 
	Looped=true;
	Unlocked=false;

	-- Interaction;
};

library:Add{
	Id="carriedinjured";
	Name="Carried Injured";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://9760633863";
	Looped=true;
	Unlocked=true;

	-- Interaction;
};

library:Add{
	Id="carryinginjured";
	Name="Carrying Injured";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://9769398259";
	Looped=true;
	Unlocked=true;

	-- Interaction;
};

library:Add{
	Id="feelingcold";
	Name="Cold";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://10372090247";
	Looped=false;
	Unlocked=true;
};

library:Add{
	Id="foldbackhands";
	Name="Fold Back Hands";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://11577750009";
	Looped=true;
	Unlocked=true;
};

library:Add{
	Id="leanonfencing";
	Name="Lean on Fencing";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://11750548090";
	Looped=true;
	Unlocked=true;
};

library:Add{
	Id="shoveling";
	Name="Shoveling";
	LayoutOrder=library.Size;
	AnimationId="rbxassetid://11820239674";
	Looped=true;
	Unlocked=false;

	-- Interaction;
};

for id, lib in pairs(library:GetAll()) do
	local new = Instance.new("Animation");
	new.AnimationId = lib.AnimationId;
	new.Name = lib.Id;
	new.Parent = script;
	library:Set(id, "Animation", new);
end

return library;