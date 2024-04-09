local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Sfc = {}

local participantIds = {
	606654358;
	2355763916;
	1300846062;
	192387436;
	1253853586;
	1050764620;
	1483780739;
	731589841;
	303772850;
	215878810;
	1501025243;
	1371102364;
	958383634;
	1443555842;
	411816244;
	470115058;
	727994959;
	509692137;
	86976526;
	10139379;
	86841665;
	430432281;
	852639741;
	1034419038;
	115051350;
	568019124;
	120596148;
	441142315;
	1135992932;
	568638188;
	371716368;
	32911077;
	99661429;
	87044430;
	632673385;
	117392244;
	572465429;
	57646149;
	899668195;
	37338367;
	882457532;
	679635342;
	2228867938;
	1539057250;
	1435641047;
	1431874104;
	439750975;
	158138984;
}



function Sfc.Player(player, profile)
	local playerId = player.UserId;
	local playerSave = profile:GetActiveSave();
	
	local isParticipant = table.find(participantIds, playerId) == nil;
	Debugger:Log(player, "isParticipant:", isParticipant);
	if isParticipant then return end;
	playerSave:AwardAchievement("2022film", true);
end

return Sfc;
