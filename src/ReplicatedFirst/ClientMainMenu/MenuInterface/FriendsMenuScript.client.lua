--== Configuration;

--== Variables;
local player = game.Players.LocalPlayer;
local friendsMenuFrame = script.Parent:WaitForChild("MenuFrame"):WaitForChild("FriendsFrame");
local friendsListFrame = friendsMenuFrame:WaitForChild("BackgroundFrame"):WaitForChild("listFrame"):WaitForChild("list");
local friendsFrameCopy = script:WaitForChild("FriendFrame"):Clone();
--local searchbar = friendsMenuFrame:WaitForChild("BackgroundFrame"):WaitForChild("SearchFrame"):WaitForChild("SearchFriend");

local modFriendsListInterface = require(game.StarterGui:WaitForChild("FriendsListInterface"));
modFriendsListInterface.MenuInterface = script.Parent;

local interface = modFriendsListInterface.new(friendsListFrame, friendsFrameCopy, nil); --{Searchbar=searchbar;}
--== Script;
function UpdateFriendsList()
	interface:Update();
end

friendsMenuFrame:GetPropertyChangedSignal("Visible"):Connect(UpdateFriendsList)

while wait(5) do
	if friendsMenuFrame.Visible then
		interface:Update();
	end
end