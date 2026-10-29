interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

interface.turn = true
interface.next = false
interface.invert = false
interface.edit = false
interface.stm = 1
interface.level = 1
interface.cur_level = nil

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.get_module()
	if machine.system.name == "cc7" then
		return "Fidelity Chess Challenger 7"
	elseif machine.system.name == "cc7a" then
		return "Fidelity Chess Challenger 7 v2"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Ron Nelson"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	-- LV steps through the levels, digit3 shows the level number
	local lcd_num = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07 }
	for i = 1, 20 do
		send_input(":IN.3", 0x02, 0.5) -- LV
		emu.wait(0.2)
		if (output_value("digit3") == lcd_num[interface.level]) then
			break
		end
	end
	send_input(":IN.1", 0x01, 0.5) -- CL
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	interface.turn = true
	interface.next = false
	interface.invert = false
	interface.stm = 1
	send_input(":IN.3", 0x01, 1) -- RE
	emu.wait(1)
	machine.video.throttled = throttled_state
	interface.cur_level = 1
	interface.setlevel()
end

function interface.set_pos(mode)
	if (mode == 0) then
		return ""
	end
	-- the machine plays from the bottom: with Black to move the board is turned and the colors swapped
	interface.invert = (mode == -1)
	interface.stm = mode
	send_input(":IN.1", 0x02, 0.5) -- PB
	send_input(":IN.0", 0x02, 0.5) -- PV
	local ram = machine.devices[":maincpu"].spaces["program"]
	local fig = { 0xff, 0xfe, 0xfd, 0xfc, 0xfb, 0xfa, 0x00, 0x06, 0x05, 0x04, 0x03, 0x02, 0x01 }
	for x = 1, 8 do
		for y = 1, 8 do
			local z
			if (interface.invert) then
				z = -get_piece_id(9 - x, 9 - y)
			else
				z = get_piece_id(x, y)
			end
			ram:write_u8(0x3000 + 16 * (y - 1) + x - 1, fig[z + 7])
		end
	end
	send_input(":IN.1", 0x02, 0.5) -- PB
end

function interface.edit_game(on)
	-- history moves are only tracked, then the final position is set up
	interface.edit = on
	if (not on) then
		local stm = interface.stm
		interface.setup_machine()
		interface.set_pos(stm)
	end
end

function interface.start_play(init)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if (init) then
		interface.turn = false
		interface.next = true
		send_input(":IN.2", 0x01, 0.5) -- CB
	elseif (interface.next) then
		local col
		if (output_value("digit0") == 0x5e) then
			col = 4 -- d2d4
		else
			col = 5 -- e2e4
		end
		interface.setup_machine()
		interface.turn = false
		interface.send_pos(col)
		interface.send_pos(2)
		interface.send_pos(col)
		interface.send_pos(4)
		send_input(":IN.0", 0x01, 1) -- EN
	else
		-- DM + PB: the machine moves for the side to move
		interface.turn = false
		send_input(":IN.2", 0x02, 0.5) -- DM
		send_input(":IN.1", 0x02, 0.5) -- PB
	end
	machine.video.throttled = throttled_state
end

function interface.stop_play()
end

function interface.is_selected(x, y)
	if (interface.invert) then
		x = 9 - x
		y = 9 - y
	end
	local xval = { 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71, 0x6f, 0x76 }
	local yval = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f }
	local d0 = output_value("digit0")
	local d1 = output_value("digit1")
	local d2 = output_value("digit2")
	local d3 = output_value("digit3")
	return (xval[x] == d0 and yval[y] == d1) or (xval[x] == d2 and yval[y] == d3)
end

function interface.send_pos(p)
	if     (p == 1)	then send_input(":IN.3", 0x04, 0.5)
	elseif (p == 2)	then send_input(":IN.2", 0x04, 0.5)
	elseif (p == 3)	then send_input(":IN.1", 0x04, 0.5)
	elseif (p == 4)	then send_input(":IN.0", 0x04, 0.5)
	elseif (p == 5)	then send_input(":IN.3", 0x08, 0.5)
	elseif (p == 6)	then send_input(":IN.2", 0x08, 0.5)
	elseif (p == 7)	then send_input(":IN.1", 0x08, 0.5)
	elseif (p == 8)	then send_input(":IN.0", 0x08, 0.5)
	end
end

function interface.select_piece(x, y, event)
	if (event ~= "capture" and event ~= "get_castling" and event ~= "put_castling" and event ~= "en_passant") then
		if (interface.turn and not interface.edit) then
			if (interface.invert) then
				x = 9 - x
				y = 9 - y
			end
			interface.send_pos(x)
			interface.send_pos(y)
		end
		if (event == "put") then
			if (interface.turn and not interface.edit) then
				interface.next = false
				send_input(":IN.0", 0x01, 1) -- EN
			end
			interface.turn = not interface.turn
			interface.stm = -interface.stm
		end
	end
end

function interface.get_options()
	return {
		{ "spin", "Level", "1", "1", "7" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 1 or level > 7) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
	return 'q'	-- engine always promotes to Queen
end

function interface.promote(x, y, piece)
	promotion_error(piece)
end

return interface
