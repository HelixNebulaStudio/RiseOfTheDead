local Door = require(game.ReplicatedStorage.Library.Doors).new(script.Parent);
Door.Public = true;
Door.CanBreakIn = false;

return Door;
