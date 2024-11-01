local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local HttpService = game:GetService("HttpService");

local DiscordWebhook = {};
DiscordWebhook.Hooks = {
    General="https://discord.com/api/webhooks/1299721433248694353/7aJbgCdff6txQHLe_dpoqJdSLd7v2_72iaW2cWDV9BSdpRbC7v30Qq23rXFBBpV323p1";
    TradeLogs="https://discord.com/api/webhooks/1299729869202133002/tCzXKMyuLDUnF8PhvYXJqHeGeeE_kj7NgEP34VfX5veRonge1j--j1bjUPylZzduUw6J";
    ChatLogs="https://discord.com/api/webhooks/1299754647812178053/tNmrXTMJMeO025kfrxWOksVl98YSW5LbVn4LsGCxS2aislD1gegnYnoSyVlu8rfVxrIf";
}

local EmbedPacket = {
    ["content"] = "",
    ["embeds"] = {{
        ["title"] = "__**Ultimate Title**__",
        ["description"] = "blah blah",
        ["type"] = "rich",
        ["color"] = tonumber(0xffffff),
        ["fields"] = {
            -- {
            --     ["name"] = "__Title__",
            --     ["value"] = "hi",
            --     ["inline"] = true
            -- },
            -- {
            --     ["name"] = "__Title__",
            --     ["value"] = "hi",
            --     ["inline"] = true
            -- }
        }
    }}
};

function DiscordWebhook.PostText(hookId, text)
    task.spawn(function()
        if workspace:GetAttribute("IsDev") then
            text = "**[DB]** "..text;
        end
        
        local s, e = pcall(function()
            local dataStr: string = HttpService:JSONEncode({
                ["content"] = text;
            });
            Debugger:StudioLog(HttpService:PostAsync(hookId, dataStr));
        end)
        if not s then
            Debugger:Warn(e);
        end
    end)
end

function DiscordWebhook.PostEmbed(hookId, dataFunc: (embedPacket: typeof(EmbedPacket.embeds[1])) -> typeof(EmbedPacket.embeds[1]))
    task.spawn(function()
        local s, e = pcall(function()
            local embedPacket = table.clone(EmbedPacket);
            dataFunc(embedPacket.embeds[1]);
            if workspace:GetAttribute("IsDev") then
                embedPacket.embeds[1].description = "**[DB]** "..embedPacket.embeds[1].description;
            end

            local dataStr: string = HttpService:JSONEncode(embedPacket);
            Debugger:StudioLog(HttpService:PostAsync(hookId, dataStr));
        end)
        if not s then
            Debugger:Warn(e);
        end
    end)
end

return DiscordWebhook;