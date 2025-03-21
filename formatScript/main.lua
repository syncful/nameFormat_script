-- CUSTOMIZABLE SECTION --

local DiscordBotToken = "TOKEN_HERE"
local GuildID = "SERVER_ID"
local RequiredRoleID = "WHITELIST_ROLES"
local NameBypassRoleID = "NAMEBYPASS_ROLES"

-- DO NOT EDIT THIS --

function GetDiscordUser(source)
    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        if string.find(id, "discord:") then
            return string.gsub(id, "discord:", "")
        end
    end
    return nil
end

function IsPlayerWhitelisted(discordID, callback)
    local url = ("https://discord.com/api/guilds/%s/members/%s"):format(GuildID, discordID)
    local headers = {
        ["Authorization"] = "Bot " .. DiscordBotToken,
        ["Content-Type"] = "application/json"
    }

    PerformHttpRequest(url, function(errorCode, resultData, resultHeaders)
        if errorCode == 200 then
            local data = json.decode(resultData)
            local isWhitelisted = false
            local hasNameBypassRole = false

            for _, role in pairs(data.roles) do
                if role == RequiredRoleID then
                    isWhitelisted = true
                end
                if role == NameBypassRoleID then
                    hasNameBypassRole = true
                end
            end

            callback(isWhitelisted, hasNameBypassRole)
        else
            callback(false, false)
        end
    end, "GET", "", headers)
end

AddEventHandler("playerConnecting", function(playerName, setKickReason, deferrals)
    local source = source
    deferrals.defer()
    Wait(0)

    local discordID = GetDiscordUser(source)
    if not discordID then
        deferrals.done("You must have Discord linked to join this server.")
        return
    end

    IsPlayerWhitelisted(discordID, function(whitelisted, hasNameBypassRole)
        if not whitelisted then
            deferrals.done("Failed to connect to the server due to you not being whitelisted, contact your CoC.")
            return
        end

        if hasNameBypassRole then
            deferrals.done()
            return
        end

        local url = ("https://discord.com/api/guilds/%s/members/%s"):format(GuildID, discordID)
        local headers = {
            ["Authorization"] = "Bot " .. DiscordBotToken,
            ["Content-Type"] = "application/json"
        }

        PerformHttpRequest(url, function(errorCode, resultData, resultHeaders)
            if errorCode == 200 then
                local data = json.decode(resultData)
                local discordNick = data.nick or GetPlayerName(source)

                if discordNick ~= playerName then
                    deferrals.done("You've been denied access to the server. Your name format is incorrect.")
                else
                    deferrals.done()
                end
            else
                deferrals.done("Failed to verify your Discord information. Try again later.")
            end
        end, "GET", "", headers)
    end)
end)