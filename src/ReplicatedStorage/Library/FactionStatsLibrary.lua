local modLibraryManager = require(game.ReplicatedStorage.Library.LibraryManager);
local library = modLibraryManager.new();

library:Add{
	Id="Coop";
	Icon="rbxassetid://4466529123";
	Name="Coop";
	Description="Coop";
	Buff=true;
};

return library;