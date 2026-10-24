interface = {}

interface.level = "a3"
interface.cur_level = nil

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.get_module()
	return "Mephisto Mirage"
end

function interface.get_author()
	return "Thomas Nitsche & Elmar Henne"
end

function interface.setdigit(n)
	if     (n == 0)	then send_input(":IN.1", 0x10, 0.5)
	elseif (n == 1)	then send_input(":IN.0", 0x02, 0.5)
	elseif (n == 2)	then send_input(":IN.0", 0x08, 0.5)
	elseif (n == 3)	then send_input(":IN.0", 0x20, 0.5)
	elseif (n == 4)	then send_input(":IN.0", 0x80, 0.5)
	elseif (n == 5)	then send_input(":IN.1", 0x02, 0.5)
	elseif (n == 6)	then send_input(":IN.1", 0x08, 0.5)
	elseif (n == 7)	then send_input(":IN.1", 0x20, 0.5)
	elseif (n == 8)	then send_input(":IN.1", 0x80, 0.5)
	elseif (n == 9)	then send_input(":IN.1", 0x04, 0.5)
	end
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local level = interface.level
	local cols_idx = { a = 1, b = 2, c = 3, d = 4, e = 5, f = 6, g = 7, h = 8 }
	send_input(":IN.0", 0x40, 0.5) -- LEV
	for i = 1, level:len() do
		local c = level:sub(i,i)
		if (c:match("[a-h]")) then
			interface.send_pos(cols_idx[c])
		elseif (c:match("[1-8]")) then
			interface.send_pos(tonumber(c))
		elseif (c == "0") then
			send_input(":IN.1", 0x10, 0.5) -- 0
		elseif (c == "9") then
			send_input(":IN.1", 0x04, 0.5) -- 9
		elseif (c == " ") then
			send_input(":IN.0", 0x04, 0.5) -- ENT
		end
	end
	send_input(":IN.0", 0x04, 0.5) -- ENT
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	sb_reset_board(":board:board")
	if (ioport.ports[":FAKE"]:read() == 0x01) then
		send_input(":FAKE", 0x01, 0.5) -- Magnet Off
	end
	interface.turn = true
	emu.wait(1)
	interface.cur_level = "a3"
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.1", 0x01, 0.5) -- LIST
		send_input(":IN.1", 0x40, 0.5) -- REV
		machine.video.throttled = throttled_state
		return (":board:board")
	else
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if p > 0 then
						interface.setdigit(0) -- White
					else
						interface.setdigit(9) -- Black
					end
					interface.setdigit(8 - math.abs(p))
					interface.setdigit(x)
					interface.setdigit(9 - y)
					send_input(":IN.0", 0x04, 0.5) -- ENT
				end
			end
		end
		if mode == 1 then
			interface.setdigit(0) -- White
		else
			interface.setdigit(9) -- Black
		end
		send_input(":IN.0", 0x04, 0.5) -- ENT
		send_input(":IN.0", 0x01, 0.5) -- CL
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game(on)
	interface.edit = on
	if (on and (ioport.ports[":FAKE"]:read() == 0x01)) then
		send_input(":FAKE", 0x01, 0.5) -- Magnet Off
		send_input(":IN.0", 0x01, 0.5) -- CL
		emu.wait(0.5)
	end
end

function interface.start_play(init)
	interface.turn = false
	send_input(":IN.0", 0x10, 0.5) -- STA
end

function interface.stop_play()
	send_input(":IN.0", 0x04, 0.5) -- ENT
end

function interface.is_selected(x, y)
	local xval = { 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71, 0x3d, 0x76 }
	local yval = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f }
	local d0 = output_value("digit3") & 0x7f
	local d1 = output_value("digit2") & 0x7f
	local d2 = output_value("digit1") & 0x7f
	local d3 = output_value("digit0") & 0x7f
	return (xval[x] == d0 and yval[y] == d1) or (xval[x] == d2 and yval[y] == d3)
end

function interface.send_pos(p)
	if     (p == 1)	then send_input(":IN.0", 0x02, 0.5)
	elseif (p == 2)	then send_input(":IN.0", 0x08, 0.5)
	elseif (p == 3)	then send_input(":IN.0", 0x20, 0.5)
	elseif (p == 4)	then send_input(":IN.0", 0x80, 0.5)
	elseif (p == 5)	then send_input(":IN.1", 0x02, 0.5)
	elseif (p == 6)	then send_input(":IN.1", 0x08, 0.5)
	elseif (p == 7)	then send_input(":IN.1", 0x20, 0.5)
	elseif (p == 8)	then send_input(":IN.1", 0x80, 0.5)
	end
end

function interface.select_piece(x, y, event)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if (ioport.ports[":FAKE"]:read() == 0x01) then
		if (event == "en_passant") then
			sb_remove_piece(":board:board", x, y)
		else
			sb_select_piece(":board:board", 1, x, y, event)
		end
		machine.video.throttled = throttled_state
		return
	end
	if (event ~= "capture" and event ~= "get_castling" and event ~= "put_castling" and event ~= "en_passant") then
		if (interface.turn) then
			interface.send_pos(x)
			interface.send_pos(y)
		end
		if (event == "put") then
			if interface.edit == true then
				send_input(":IN.0", 0x04, 0.5) -- ENT
			else
				if (interface.turn) then
					send_input(":IN.0", 0x10, 1) -- STA
				end
				interface.turn = not interface.turn
			end
		end
	end
	sb_move_piece(":board:board", x, y)
	machine.video.throttled = throttled_state
end

function interface.get_options()
	return {
		{ "string", "Level", "a3" },
	}
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		local level = value:match("^%s*(.-)%s*$"):gsub("%s%s+"," "):lower() -- trim
		if (level:match("^[a-d][1-7]$") or level:match("^[ef][1-8]$") or level:match("^[gh][2-8]$") or level:match("^[a-d]8%s%d%d:?%d%d?$")) then
			interface.level = level
			interface.setlevel()
		end
	end
end

function interface.get_promotion(x, y)
	return 'q'	-- engine always promotes to Queen
end

function interface.promote(x, y, piece)
	promotion_error(piece)
	sb_promote(":board:board", x, y, 'q')	-- TODO
end

return interface
