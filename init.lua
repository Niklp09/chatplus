chatplus = {}
chatplus.modpath = minetest.get_modpath("chatplus")
chatplus.last_priv_msg_name = {}

local S = minetest.get_translator("chatplus")
local storage = minetest.get_mod_storage()

--- MOD CONFIGURATION ---
local mod_chat_color_text = "#ff5d37"
local mod_chat_color_name = "#ff3404"

local msg_chat_color_text = "#ffff88"
local msg_chat_color_name = "#ffff00"

colors = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e"}

color_table = {}
color_table["0"] = "#000000" -- Black
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

color_escapes_table = {}
for k, v in pairs(color_table) do
	color_escapes_table[k] = minetest.get_color_escape_sequence(v)
end

color_description_string = "Colors: " ..
	minetest.colorize(color_table["0"], "0 ") ..
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

local function get_players_by_str(str)
	if minetest.get_player_by_name(str) ~= nil then
		return str
	end
	local names = {}
	local count = 0
	for k , player in pairs(minetest.get_connected_players()) do
		if player:get_player_name():lower():find(str:lower()) ~= nil then
			table.insert(names, player:get_player_name())
			count = count + 1
		end
	end
	if count == 0 then
		return nil
	end
	if count == 1 then
		for k, player_name in pairs(names) do
			return player_name
		end
	end
	return names
end

function escape_colors_message(message)
	local ret_message = message
	for k, v in pairs(color_escapes_table) do
  		ret_message = ret_message:gsub("%%"..k, v)
	end
	return ret_message
end

if minetest.get_modpath("chatplus_discord") then
	minetest.register_on_chat_message(
		function(name, message)
			minetest.chat_send_all(minetest.colorize(color_table[storage:get_string(name)], name .. ": ") .. escape_colors_message(message))
			discord.send(('**%s**: %s'):format(name, message))
			return true
		end
	)
else
	minetest.register_on_chat_message(
		function(name, message)
			minetest.chat_send_all(minetest.colorize(color_table[storage:get_string(name)], name .. ": ") .. escape_colors_message(message))
			return true
		end
	)
end

minetest.register_chatcommand("namecolor", {
	description = S("Change the color of your name"),
	func = function(name, param)

		local valid_color = false

		for k, v in pairs(color_table) do
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

minetest.register_on_joinplayer(
	function(ObjectRef, last_login)

		local name = ObjectRef:get_player_name()

		if not storage:contains(name) then
			storage:set_string(name, colors[math.random(1, 16)])
		end

	end
)

local function private_message(name, param)
	local to, msg = string.match(param, "([%a%d_-]+) (.+)")
	if to == nil or msg == nil then
		minetest.chat_send_player(name, "Usage: " .. minetest.colorize("#00ff00", "/msg ") .. minetest.colorize("#ffff00", "<name> <message>") )
	else
		local names = get_players_by_str(to)
		if type(names) == "string" then
			minetest.chat_send_player(name, minetest.colorize(msg_chat_color_name, S("To ") .. names .. ": ") .. minetest.colorize(msg_chat_color_text, msg) )
			minetest.chat_send_player(names, minetest.colorize(msg_chat_color_name, S("From ") .. name .. ": ") .. minetest.colorize(msg_chat_color_text, msg) )
			minetest.sound_play("chatplus_incoming_msg", {to_player = names})
			chatplus.last_priv_msg_name[name] = names
		elseif names == nil then
			minetest.chat_send_player(name, "Player " .. minetest.colorize(msg_chat_color_name, to) .. " isn't online.")
		else
			minetest.chat_send_player(name, "No message send!  Multiple players could be meant: " .. minetest.colorize(msg_chat_color_name, table.concat(names, ", ")))
		end
	end
end

minetest.register_chatcommand("m", {
	description = S("Send a private message to the same person you sent your last message to."),
	func = function(name, param)
		if chatplus.last_priv_msg_name[name] == nil then
			minetest.chat_send_player(name, "Use " .. minetest.colorize(msg_chat_color_name, "/msg") .. " before this command!")
		elseif minetest.get_player_by_name(chatplus.last_priv_msg_name[name]) ~= nil then
			private_message(name, chatplus.last_priv_msg_name[name] .. " " .. param)
		else
			minetest.chat_send_player(name, "Player " .. minetest.colorize(msg_chat_color_name, chatplus.last_priv_msg_name[name]) .. " isn't online anymore." )
		end
	end
})

minetest.unregister_chatcommand("msg")
minetest.register_chatcommand("msg", {func = private_message})

minetest.register_on_leaveplayer(
	function(ObjectRef, timed_out)
		local name = ObjectRef:get_player_name()
		chatplus.last_priv_msg_name[name] = nil
	end
)