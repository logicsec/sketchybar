local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local brew = sbar.add("item", "widgets.brew", 42, {
    position = "right",
    background = {
        height = 22,
        color = { alpha = 0 },
        border_width = 0,
        drawing = true,
    },
    icon = { 
        string = icons.brew,
        color = colors.green 
    },
    label = {
        string = "0",
        font = {
            family = settings.font.numbers,
            style = settings.font.style_map["Bold"],
        },
        align = "right",
        padding_right = 0,
    },
    update_freq = 5,
    padding_right = settings.paddings + 6
})

local mail = sbar.add("item", "widgets.mail", 42, {
    position = "right",
    background = {
        height = 22,
        color = { alpha = 0 },
        border_width = 0,
        drawing = true,
    },
    icon = { 
        string = icons.mail,
        color = colors.green 
    },
    label = {
        string = "0",
        font = {
            family = settings.font.numbers,
            style = settings.font.style_map["Bold"],
        },
        align = "right",
        padding_right = 0,
    },
    update_freq = 5,
    padding_right = settings.paddings
})

local messages = sbar.add("item", "widgets.messages", 42, {
    position = "right",
    background = {
        height = 22,
        color = { alpha = 0 },
        border_width = 0,
        drawing = true,
    },
    icon = { 
        string = icons.messages,
        color = colors.green 
    },
    label = {
        string = "0",
        font = {
            family = settings.font.numbers,
            style = settings.font.style_map["Bold"],
        },
        align = "right",
        padding_right = 0,
    },
    update_freq = 5,
    padding_right = settings.paddings
})

sbar.add("bracket", "widgets.notifications.bracket", { brew.name, mail.name, messages.name }, {
    background = { color = colors.bg1 }
})

sbar.add("item", "widgets.notifications.padding", {
    position = "right",
    width = settings.group_paddings
})

-- Function to update brew count
local function update_brew_count()
    sbar.exec("brew outdated | wc -l | tr -d ' '", function(count)
        local brew_count = tonumber(count) or 0
        local color
        local label_padding

        -- Color logic based on outdated package count
        if brew_count >= 30 then
            color = colors.red
            label_padding = 1
        elseif brew_count >= 10 then
            color = colors.yellow
            label_padding = 1
        elseif brew_count >= 1 then
            color = colors.blue
            label_padding = 1
        else
            color = colors.green
            label_padding = 0
        end

        brew:set({
            label = {
                string = tostring(brew_count)
            },
            icon = {
                color = color
            }
        })
    end)
end

-- Function to update mail count
local function update_mail_count()
    sbar.exec([[
        osascript -e 'tell application "Mail" to count of (messages of inbox whose read status is false)'
    ]], function(count)
        local mail_count = tonumber(count) or 0
        local color
        local label_padding

        -- Color logic based on unread email count
        if mail_count >= 30 then
            color = colors.red
            label_padding = 1
        elseif mail_count >= 10 then
            color = colors.yellow
            label_padding = 1
        elseif mail_count >= 1 then
            color = colors.blue
            label_padding = 1
        else
            color = colors.green
            label_padding = 0
        end

        mail:set({
            label = {
                string = tostring(mail_count)
            },
            icon = {
                color = color
            }
        })
    end)
end

-- Function to update messages count
local function update_messages_count()
    local db_path = os.getenv("HOME") .. "/Library/Messages/chat.db"
    local cmd = string.format("sqlite3 %s \"SELECT COUNT(*) FROM message JOIN chat_message_join ON chat_message_join.message_id = message.ROWID JOIN chat ON chat.ROWID = chat_message_join.chat_id WHERE message.is_from_me = 0 AND message.is_read = 0\"", db_path)

    sbar.exec(cmd, function(count)
        local message_count = tonumber(count) or 0
        local icon_color, label_color, label_padding

        -- Color logic based on unread count
        if message_count >= 30 then
            icon_color = colors.red
            label_color = colors.white
            label_padding = 1
        elseif message_count >= 10 then
            icon_color = colors.yellow
            label_color = colors.white
            label_padding = 1
        elseif message_count >= 1 then
            icon_color = colors.blue
            label_color = colors.white
            label_padding = 1
        else
            icon_color = colors.green
            label_color = colors.white
            label_padding = 0
        end

        messages:set({
            label = {
                string = tostring(message_count)
            },
            icon = {
                color = icon_color
            }
        })
    end)
end

-- Subscribe to update events
sbar.subscribe("brew_update", update_brew_count)
sbar.subscribe("mail_check", update_mail_count)
sbar.subscribe("messages_check", update_messages_count)

-- Add these new event subscriptions
brew:subscribe({ "forced", "routine", "system_woke" }, update_brew_count)
mail:subscribe({ "forced", "routine", "system_woke" }, update_mail_count)
messages:subscribe({ "forced", "routine", "system_woke" }, update_messages_count)

brew:subscribe("mouse.clicked", function(env)
    if env.modifier == "cmd" then  -- Command + Click to upgrade
        sbar.exec("brew upgrade", function()
            update_brew_count()  -- Update the count after upgrade
            sbar.exec([[
                osascript -e 'display notification "All packages have been upgraded" with title "Brew Upgrade Complete"'
            ]])
        end)
    else  -- Normal click just updates the list
        sbar.exec("brew update", function()
            update_brew_count()
            sbar.exec([[
                osascript -e 'display notification "Brew package list has been updated" with title "Brew Update Complete"'
            ]])
        end)
    end
end)

mail:subscribe("mouse.clicked", function(env)
    sbar.exec("open -a Mail")
end)

messages:subscribe("mouse.clicked", function(env)
    sbar.exec("open -a Messages")
end)

-- Initial count fetch
update_brew_count()
update_mail_count()
update_messages_count()
