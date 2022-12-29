local last_priv_msg_name = {}

local S = minetest.get_translator("chatplus")
local storage = minetest.get_mod_storage()

--- MOD CONFIGURATION ---
local msg_chat_color_text = "#ffff88"
local msg_chat_color_name = "#ffff00"

local colors = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e"}

local color_table = {}
color_table["1"] = "#0000aa" -- Dark Blue
color_table["2"] = "#00aa00" -- Dark Green
color_table["3"] = "#00aaaa" -- Dark Aqua
color_table["4"] = "#aa0000" -- Dark Red
color_table["5"] = "#aa00aa" -- Dark Purple
color_table["6"] = "#ffaa00" -- Gold
color_table["7"] = "#aaaaaa" -- Gray
color_table["8"] = "#555555" -- Dark Gray
color_table["9"] = "#5555ff" -- Blue
color_table["a"] = "#55ff55" -- Green
color_table["b"] = "#55ffff" -- Aqua
color_table["c"] = "#ff5555" -- Red
color_table["d"] = "#ff55ff" -- Light Purple
color_table["e"] = "#ffff55" -- Yellow

local color_description_string = "Colors: " ..
	minetest.colorize(color_table["1"], "1 ") ..
	minetest.colorize(color_table["2"], "2 ") ..
	minetest.colorize(color_table["3"], "3 ") ..
	minetest.colorize(color_table["4"], "4 ") ..
	minetest.colorize(color_table["5"], "5 ") ..
	minetest.colorize(color_table["6"], "6 ") ..
	minetest.colorize(color_table["7"], "7 ") ..
	minetest.colorize(color_table["8"], "8 ") ..
	minetest.colorize(color_table["9"], "9 ") ..
	minetest.colorize(color_table["a"], "a ") ..
	minetest.colorize(color_table["b"], "b ") ..
	minetest.colorize(color_table["c"], "c ") ..
	minetest.colorize(color_table["d"], "d ") ..
	minetest.colorize(color_table["e"], "e ")

if minetest.get_modpath("chatplus_discord") then
	minetest.register_on_chat_message(
		function(name, message)
			if minetest.check_player_privs(name, "shout") == true then
				minetest.chat_send_all(minetest.colorize(color_table[storage:get_string(name)], name .. ": ") .. message)
				minetest.log("action", "CHAT: <" .. name .. "> " .. message)
				discord.send(('**%s**: %s'):format(name, message))
				return true
			else
				return false
			end
		end
	)
else
	minetest.register_on_chat_message(
		function(name, message)
			if minetest.check_player_privs(name, "shout") == true then
				minetest.chat_send_all(minetest.colorize(color_table[storage:get_string(name)], name .. ": ") .. message)
				minetest.log("action", "CHAT: <" .. name .. "> " .. message)
				return true
			else
				return false
			end
		end
	)
end

minetest.register_chatcommand("namecolor", {
	description = S("Change the color of your name"),
	func = function(name, param)

		local valid_color = false

		for k in pairs(color_table) do
			if param == k then
				valid_color = true
				break;
			end
		end

		if valid_color then
			storage:set_string(name, param)
			minetest.chat_send_player(name, S("Color of your name changed. (").. minetest.colorize(color_table[storage:get_string(name)], name) .. ")")
		else
			minetest.chat_send_player(name, "Usage: " .. minetest.colorize("#00ff00", "/namecolor ") .. minetest.colorize("#ffff00", "<color>") )
			minetest.chat_send_player(name, color_description_string )
		end

	end
})

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()

	if not storage:contains(name) or storage:get_string(name) == "0" then
		storage:set_string(name, colors[math.random(1, 14)])
	end
end)

local function private_message(name, param)
	local to, msg = string.match(param, "([%a%d_-]+) (.+)")
	if to == nil or msg == nil then
		minetest.chat_send_player(name, "Usage: " .. minetest.colorize("#00ff00", "/msg ") .. minetest.colorize("#ffff00", "<name> <message>") )
	else
		if minetest.get_player_by_name(to) then
			minetest.chat_send_player(name, minetest.colorize(msg_chat_color_name, S("To ") .. to .. ": ") .. minetest.colorize(msg_chat_color_text, msg) )
			minetest.chat_send_player(to, minetest.colorize(msg_chat_color_name, S("From ") .. name .. ": ") .. minetest.colorize(msg_chat_color_text, msg) )
			minetest.log("action", "MSG: from <" .. name .. "> to <" .. to .. "> " .. msg)
			minetest.sound_play("chatplus_incoming_msg", {to_player = to})
			last_priv_msg_name[name] = to
		else
			minetest.chat_send_player(name, "Player " .. minetest.colorize(msg_chat_color_name, to) .. " isn't online.")
		end
	end
end

minetest.register_chatcommand("m", {
	description = S("Send a private message to the same person you sent your last message to."),
	func = function(name, param)
		if last_priv_msg_name[name] == nil then
			minetest.chat_send_player(name, "Use " .. minetest.colorize(msg_chat_color_name, "/msg") .. " before this command!")
		elseif minetest.get_player_by_name(last_priv_msg_name[name]) ~= nil then
			private_message(name, last_priv_msg_name[name] .. " " .. param)
		else
			minetest.chat_send_player(name, "Player " .. minetest.colorize(msg_chat_color_name, last_priv_msg_name[name]) .. " isn't online anymore." )
		end
	end
})

minetest.unregister_chatcommand("msg")
minetest.register_chatcommand("msg", {func = private_message})

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	last_priv_msg_name[name] = nil
end)
