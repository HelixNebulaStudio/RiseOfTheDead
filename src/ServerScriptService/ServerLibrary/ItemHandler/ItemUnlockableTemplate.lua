local Handler = require(script.Parent).new(script);

Handler.Use = Handler.ItemUnlockable;

return Handler;
