interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

interface.turn = true
interface.level = "00"
interface.cur_level = nil
interface.set = false
interface.edit = false
-- The Delta-1 has no side to move, only a computer color: ENTER without a move
-- makes it move for that color, an entered move is the other color's. Track both
-- and press Change Color when they don't fit.
interface.stm = "W"	-- side to move
interface.comp = "B"	-- computer color (black after New Game and after EP)

function interface.get_module()
	return "Chess Champion Delta-1"
end

function interface.get_author()
	return "David Lindsay"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local s = "000000"
	local level = s:sub(1,6-interface.level:len()) .. interface.level
	send_input(":IN.0", 0x02, 0.5) -- Time Set
	emu.wait(0.5)
	for i = 1, 6 do
		local n = tonumber(level:sub(i,i))
		if n == 0 then
			send_input(":IN.3", 0x02, 0.5)
		elseif n <= 4 then
			send_input(":IN.1", 0x01 << (n - 1), 0.5)
		elseif n <= 8 then
			send_input(":IN.2", 0x01 << (n - 5), 0.5)
		elseif n == 9 then
			send_input(":IN.3", 0x01, 0.5)
		end
	end
	send_input(":IN.4", 0x08, 0.5) -- Enter
	emu.wait(0.5)
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	interface.turn = true
	interface.set = false
	interface.stm = "W"
	interface.comp = "B"
	send_input(":RESET", 0x01, 0.5) -- New Game
	emu.wait(1)
	machine.video.throttled = throttled_state
	interface.cur_level = "00"
	interface.setlevel()
end

-- write the plugin's board into the board RAM at 0x2040 (a1..h1, a2..h8; white 1..6 = P N B R Q K, black negative)
local function other(color)
	return color == "W" and "B" or "W"
end

local function change_color()
	send_input(":IN.4", 0x04, 1) -- Change Color
	interface.comp = other(interface.comp)
end

local function write_board()
	local ram = machine.devices[":maincpu"].spaces["program"]
	local fig = {0xff, 0xfe, 0xfd, 0xfc, 0xfb, 0xfa, 0x00, 0x06, 0x05, 0x04, 0x03, 0x02, 0x01}
	for x = 1, 8 do
		for y = 1, 8 do
			ram:write_u8(0x2040 + 8 * (y - 1) + x - 1, fig[get_piece_id(x, y) + 7])
		end
	end
end

function interface.set_pos(mode)
	if mode == 0 then
		return ("")
	else
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		send_input(":IN.4", 0x02, 0.5) -- EP
		write_board()
		send_input(":IN.4", 0x08, 0.5) -- Enter
		interface.comp = "B"
		interface.stm = mode == 1 and "W" or "B"
		interface.set = true
		machine.video.throttled = throttled_state
	end
end

-- no multi move key: skip the moves, then write the final position
function interface.edit_game(on)
	interface.edit = on
	if not on then
		send_input(":IN.4", 0x02, 0.5) -- EP
		write_board()
		send_input(":IN.4", 0x08, 0.5) -- Enter
		interface.comp = "B"
	end
end

function interface.start_play(init)
	if interface.comp ~= interface.stm then
		change_color()
	end
	interface.turn = false
	send_input(":IN.4", 0x08, 0.5) -- Enter
	emu.wait(0.25)
end

function interface.stop_play()
end


local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.is_selected_int(x, y)
	local xval = { 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71, 0x3d, 0x76 }
	local yval = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f }
	local d0 = output_value("digit3")
	local d1 = output_value("digit2")
	local d2 = output_value("digit1")
	local d3 = output_value("digit0")
	return (xval[x] == d0 and yval[y] == d1) or (xval[x] == d2 and yval[y] == d3)
end

function interface.is_selected(x, y)
	if (interface.is_selected_int(x, y)) then
		emu.wait(0.4)
		return interface.is_selected_int(x, y)
	end
	return false
end

function interface.send_pos(p)
	if	   (p == 1) then send_input(":IN.1", 0x01, 0.5)
	elseif (p == 2)	then send_input(":IN.1", 0x02, 0.5)
	elseif (p == 3)	then send_input(":IN.1", 0x04, 0.5)
	elseif (p == 4)	then send_input(":IN.1", 0x08, 0.5)
	elseif (p == 5)	then send_input(":IN.2", 0x01, 0.5)
	elseif (p == 6)	then send_input(":IN.2", 0x02, 0.5)
	elseif (p == 7)	then send_input(":IN.2", 0x04, 0.5)
	elseif (p == 8)	then send_input(":IN.2", 0x08, 0.5)
	end
end

function interface.select_piece(x, y, event)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if event == "put" then
		interface.stm = other(interface.stm)
	end
	if (not interface.edit and event ~= "capture" and event ~= "get_castling" and event ~= "put_castling" and event ~= "en_passant") then
		if (interface.turn) then
			if event == "get" and interface.comp == interface.stm then
				change_color()
			end
			interface.send_pos(x)
			interface.send_pos(y)
		end
		if (event == "put") then
			if (interface.turn) then
				send_input(":IN.4", 0x08, 0.5) -- Enter
				emu.wait(1)
			end
			interface.turn = not interface.turn
		end
	end
	machine.video.throttled = throttled_state
end

function interface.get_options()
	return {
		{ "string", "Level", "00" },
	}
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		interface.level = value
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
	return 'q'	-- engine always promotes to Queen
end

function interface.promote(x, y, piece)
	promotion_error(piece)
	-- TODO
end

return interface
