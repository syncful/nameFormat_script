local DiscordBotToken = "YOUR_TOKEN_HERE"
local GuildID = "YOUR_SERVER_ID"
local NameBypassRoleID = "YOUR_NAMEBYPASS_ROLE"

-- DO NOT EDIT, UNLESS YOU KNOW WHAT YOU'RE DOING --

function GetDiscordUser(source)
    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        if string.find(id, "discord:") then
            return string.gsub(id, "discord:", "")
        end
    end
    return nil
end

function GetDiscordMember(discordID, callback)
    local url = ("https://discord.com/api/guilds/%s/members/%s"):format(GuildID, discordID)
    local headers = {
        ["Authorization"] = "Bot " .. DiscordBotToken,
        ["Content-Type"] = "application/json"
    }

    PerformHttpRequest(url, function(errorCode, resultData, resultHeaders)
        if errorCode == 200 then
            local data = json.decode(resultData)
            callback(true, data)
        else
            callback(false, nil)
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

    GetDiscordMember(discordID, function(success, data)
        if not success then
            deferrals.done("Failed to verify your Discord information. Try again later.")
            return
        end

        local hasNameBypassRole = false
        for _, role in pairs(data.roles or {}) do
            if role == NameBypassRoleID then
                hasNameBypassRole = true
                break
            end
        end

        if hasNameBypassRole then
            deferrals.done()
            return
        end

        local discordNick = data.nick or GetPlayerName(source)
        if discordNick ~= playerName then
            deferrals.done("You've been denied access to the server because your name format is incorrect.")
        else
            deferrals.done()
        end
    end)
end)
