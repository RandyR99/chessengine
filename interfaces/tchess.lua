interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

interface.turn = true
interface.color = "B"
interface.last_get = nil
interface.level = 1
interface.cur_level = nil
interface.edit = false

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.get_module()
	return "Tryom Electronic Chess"
end

function interface.get_author()
	return "David B. Goodrich"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.1", 0x01, 0.5) -- RST
	interface.send_pos2(interface.level)
	send_input(":IN.1", 0x08, 0.5) -- C
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	interface.turn = true
	interface.color = "B"
	interface.last_get = nil
	emu.wait(1)
	send_input(":IN.1", 0x01, 0.5) -- RST
	send_input(":IN.3", 0x02, 0.5) -- 1
	send_input(":IN.1", 0x02, 0.5) -- A
	send_input(":IN.4", 0x02, 0.5) -- 5 (random book)
	machine.video.throttled = throttled_state
	interface.cur_level = 1
	interface.setlevel()
end

local function enter_piece(p)
	-- Enter Position mode: White K Q B N R P = A B C D E F, Black = 1 2 3 4 5 6
	local keys = {
		{ ":IN.1", 0x02 }, { ":IN.1", 0x04 }, { ":IN.1", 0x08 }, { ":IN.1", 0x10 }, { ":IN.2", 0x02 }, { ":IN.2", 0x04 },
		{ ":IN.3", 0x02 }, { ":IN.3", 0x04 }, { ":IN.3", 0x08 }, { ":IN.3", 0x10 }, { ":IN.4", 0x02 }, { ":IN.4", 0x04 } }
	local idx = ({ 1, 2, 5, 3, 4, 6 })[math.abs(p)] -- plugin piece ids K Q R B N P -> key order K Q B N R P
	if p < 0 then
		idx = idx + 6
	end
	send_input(keys[idx][1], keys[idx][2], 0.5)
end

function interface.set_pos(mode)
	if mode == 0 then
		return ("") -- no sensor board
	end
	-- keypad setup (manual p.5): RST, level, B (blank board), then EP, piece, square, XMV for each piece
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.1", 0x01, 0.5) -- RST
	interface.send_pos2(interface.level)
	send_input(":IN.1", 0x04, 0.5) -- B (blank board)
	for y = 1, 8 do
		for x = 1, 8 do
			local p = get_piece_id(x, y)
			if p ~= 0 then
				send_input(":IN.0", 0x08, 0.5) -- EP
				enter_piece(p)
				interface.send_pos(x, y)
				send_input(":IN.0", 0x02, 0.5) -- XMV
			end
		end
	end
	if mode == -1 then
		-- after a setup White is to move: WSD (computer plays White) lets Black move next
		send_input(":IN.2", 0x01, 0.5) -- WSD
	end
	machine.video.throttled = throttled_state
	interface.turn = true
	interface.last_get = nil
	if mode == 1 then
		interface.color = "B"
	else
		interface.color = "W"
	end
end

function interface.edit_game(on)
	interface.edit = on
end

function interface.start_play()
	interface.turn = false
	if interface.color == "B" then
		interface.color = "W"
		send_input(":IN.2", 0x01, 0.5) -- WSD
	else
		interface.color = "B"
		send_input(":IN.3", 0x01, 0.5) -- BSD
	end
	send_input(":IN.0", 0x10, 0.5) -- PLY
	emu.wait(0.5)
end

function interface.stop_play()
end

function interface.is_selected(x, y)
	local xval = { 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71, 0x3d, 0x76 } -- A to H
	local yval = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f } -- 1 to 8
	local d0 = output_value("digit0")
	local d1 = output_value("digit1")
	local d2 = output_value("digit2")
	local d3 = output_value("digit3")
	local d4 = output_value("digit4")
	local d5 = output_value("digit5")
	if (d0 == 0x3f and d1 == 0x40 and d2 == 0x3f and d3 == 0x3f) then -- "0-00", computer castles queenside
		return (x == 5 or x == 3) and (y == 8)
	end
	if (d0 == 0x3f and d1 == 0x40 and d2 == 0x3f and d3 == 0x00) then -- "0-0 ", computer castles kingside
		return (x == 5 or x == 7) and (y == 8)
	end
	return (xval[x] == d2 and yval[y] == d3) or (xval[x] == d4 and yval[y] == d5)
end

function interface.send_pos1(p)  -- "A" to "H" keys
	if     (p == 1)	then send_input(":IN.1", 0x02, 0.5)
	elseif (p == 2)	then send_input(":IN.1", 0x04, 0.5)
	elseif (p == 3)	then send_input(":IN.1", 0x08, 0.5)
	elseif (p == 4)	then send_input(":IN.1", 0x10, 0.5)
	elseif (p == 5)	then send_input(":IN.2", 0x02, 0.5)
	elseif (p == 6)	then send_input(":IN.2", 0x04, 0.5)
	elseif (p == 7)	then send_input(":IN.2", 0x08, 0.5)
	elseif (p == 8)	then send_input(":IN.2", 0x10, 0.5)
	end
end

function interface.send_pos2(p)  -- "1" to "8" keys
	if     (p == 1)	then send_input(":IN.3", 0x02, 0.5)
	elseif (p == 2)	then send_input(":IN.3", 0x04, 0.5)
	elseif (p == 3)	then send_input(":IN.3", 0x08, 0.5)
	elseif (p == 4)	then send_input(":IN.3", 0x10, 0.5)
	elseif (p == 5)	then send_input(":IN.4", 0x02, 0.5)
	elseif (p == 6)	then send_input(":IN.4", 0x04, 0.5)
	elseif (p == 7)	then send_input(":IN.4", 0x08, 0.5)
	elseif (p == 8)	then send_input(":IN.4", 0x10, 0.5)
	end
end

function interface.send_pos(x, y)
	interface.send_pos1(x)
	interface.send_pos2(y)
end

function interface.move_play()
	if interface.edit then
		send_input(":IN.0", 0x02, 0.5) -- XMV
		if interface.color == "B" then
			interface.color = "W"
		else
			interface.color = "B"
		end
	else
		send_input(":IN.0", 0x10, 0.5) -- PLY
	end
end

function interface.select_piece(x, y, event)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if (event == "get" and interface.turn) then
		interface.last_get = {x = x, y = y}
	elseif (event == "put" and interface.turn) then
		local move_type = get_move_type(interface.last_get.x, interface.last_get.y, x, y)
		if (move_type == "castling") then
			interface.send_pos(interface.last_get.x, interface.last_get.y)
			interface.send_pos(x, y)
			send_input(":IN.0", 0x02, 0.5) -- XMV
			if (x == 7) then
				interface.send_pos(8, y)
				interface.send_pos(6, y)
				send_input(":IN.0", 0x02, 0.5) -- XMV
			elseif (x == 3) then
				interface.send_pos(1, y)
				interface.send_pos(4, y)
				send_input(":IN.0", 0x02, 0.5) -- XMV
			end
			interface.move_play()
		elseif (move_type == "en_passant") then
			interface.send_pos(interface.last_get.x, interface.last_get.y)
			interface.send_pos(x, interface.last_get.y)
			send_input(":IN.0", 0x02, 0.5) -- XMV
			interface.send_pos(x, interface.last_get.y)
			interface.send_pos(x, y)
			interface.move_play()
		elseif (move_type == "promotion" or move_type == "capture_promotion") then
			interface.send_pos(interface.last_get.x, interface.last_get.y)
			interface.send_pos(x, y)
			send_input(":IN.0", 0x02, 0.5) -- XMV
		else
			interface.send_pos(interface.last_get.x, interface.last_get.y)
			interface.send_pos(x, y)
			interface.move_play()
		end
		interface.last_get = nil
	end
	if (event == "put" and interface.edit == false) then
		interface.turn = not interface.turn
	end
	machine.video.throttled = throttled_state
end

function interface.get_options()
	return {
		{ "spin", "Level", "1", "1", "8" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 1 or level > 8) then
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
	if (piece == "q" or piece == "r" or piece == "b" or piece == "n") then
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		send_input(":IN.0", 0x08, 0.5) -- EP
		if get_piece_id(x, y) > 0 then
			if     (piece == "q") then send_input(":IN.1", 0x04, 0.5)
			elseif (piece == "r") then send_input(":IN.2", 0x02, 0.5)
			elseif (piece == "b") then send_input(":IN.1", 0x08, 0.5)
			elseif (piece == "n") then send_input(":IN.1", 0x10, 0.5)
			end
		else
			if     (piece == "q") then send_input(":IN.3", 0x04, 0.5)
			elseif (piece == "r") then send_input(":IN.4", 0x02, 0.5)
			elseif (piece == "b") then send_input(":IN.3", 0x08, 0.5)
			elseif (piece == "n") then send_input(":IN.3", 0x10, 0.5)
			end
		end
		interface.send_pos(x, y)
		interface.move_play()
		machine.video.throttled = throttled_state
	end
end

return interface
