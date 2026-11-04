interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board
interface.setup_underpromotion = true -- the player's underpromotion goes in through the position setup

interface.turn = true
interface.level = 1
interface.cur_level = nil
interface.edit = false

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.get_module()
	return "Intelligent Chess"
end

function interface.get_author()
	return "Mike Johnson, David Levy & Kevin O'Connell"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local level = interface.level
	local dval = { 0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x67 }
	local l0 = 0x38
	local l2 = 0x00
	local l3 = dval[level % 10 + 1]
	if (level > 9) then
		l2 = 0x06
	end
	repeat
		send_input(":X1", 0x04, 0.5)	-- LEVEL
		local d0 = output_value("digit0")
		local d2 = output_value("digit2")
		local d3 = output_value("digit3")
	until (d0 == l0 and d2 == l2 and d3 == l3)
	send_input(":X2", 0x08, 0.5)		-- ENTER
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	interface.turn = true
	-- MAME's 6522 reset leaves an asserted VIA IRQ stuck (CPU loops in its IRQ handler);
	-- disabling all VIA interrupts (IER = 0x7f) first releases the line
	machine.devices[":maincpu"].spaces["program"]:write_u8(0x280e, 0x7f)
	send_input(":RESET", 0x01, 0.5)	-- RESET
	emu.wait(0.5)
	send_input(":X2", 0x04, 0.5)		-- NEW GAME
	emu.wait(0.5)
	machine.video.throttled = throttled_state
	interface.cur_level = 1
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":X4", 0x08, 0.5) -- PLACE
		send_input(":X2", 0x04, 0.5) -- C.BOARD
		machine.video.throttled = throttled_state
		return ("")
	else
		local piece = 7
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if p * piece < 0 then
						if p > 0 then
							send_input(":X3", 0x02, 0.5) -- White
						else
							send_input(":X4", 0x02, 0.5) -- Black
						end
					end
					interface.send_pos(7 - math.abs(p))
					interface.send_pos(x)
					interface.send_pos(9 - y)
					piece = p
				end
			end
		end
		if mode == 1 then
			send_input(":X3", 0x02, 0.5) -- White
		else
			send_input(":X4", 0x02, 0.5) -- Black
		end
		send_input(":X2", 0x08, 0.5) -- ENTER
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game(on)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local mode = 0x3d
	if on then
		mode = 0x79
	end
	repeat
		send_input(":X3", 0x04, 0.5) -- MODUS
	until output_value("digit0") == mode
	send_input(":X2", 0x08, 0.5) -- ENTER
	interface.edit = on
	interface.turn = false
	machine.video.throttled = throttled_state
end

function interface.start_play(init)
	send_input(":X2", 0x08, 0.5)	-- ENTER
	interface.turn = false
end

function interface.stop_play()
end

function interface.is_selected(x, y)
	if (x == 1 and y == 1) then
		computing = false
		for i = 1, 4 do
			if (output_value("digit0") == 0) then
				computing = true
				return false
			elseif (i < 4) then
				emu.wait(0.25)
			end
		end
	elseif (computing) then
		return false
	end
	local xval = { 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71, 0x3d, 0x76 }
	local yval = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f }
	local d0 = output_value("digit0")
	local d1 = output_value("digit1")
	local d2 = output_value("digit2")
	local d3 = output_value("digit3")
	return ((xval[x] == d0 and yval[y] == d1) or (xval[x] == d2 and yval[y] == d3))
end

function interface.send_pos(p)
	if     (p == 1)	then send_input(":X1", 0x01, 0.5)
	elseif (p == 2)	then send_input(":X2", 0x01, 0.5)
	elseif (p == 3)	then send_input(":X3", 0x01, 0.5)
	elseif (p == 4)	then send_input(":X4", 0x01, 0.5)
	elseif (p == 5)	then send_input(":X1", 0x02, 0.5)
	elseif (p == 6)	then send_input(":X2", 0x02, 0.5)
	elseif (p == 7)	then send_input(":X3", 0x02, 0.5)
	elseif (p == 8)	then send_input(":X4", 0x02, 0.5)
	end
end

function interface.select_piece(x, y, event)
	if (event ~= "capture" and event ~= "get_castling" and event ~= "put_castling" and event ~= "en_passant") then
		if (interface.turn or interface.edit) then
			interface.send_pos(x)
			interface.send_pos(y)
		end
		if (event == "put") then
			if (interface.turn or interface.edit) then
				send_input(":X2", 0x08, 0.5) -- ENTER
			end
			interface.turn = not interface.turn
		end
	end
end

function interface.get_options()
	return {
		{ "spin", "Level", "1", "1", "13" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 1 or level > 13) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
end

-- the machine underpromotes when that is better. It flashes the pawn for about 8 s, then puts the
-- new piece on the target square: VRAM 0x1800 = a8, low 3 bits = piece, bit 3 = white. Checking the
-- color skips a captured piece that is still shown there.
function interface.get_promotion(x, y)
	local pieces = { [2] = 'n', [3] = 'b', [4] = 'r', [5] = 'q' }
	local color = (y == 8) and 8 or 0
	local program = machine.devices[":maincpu"].spaces["program"]
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local piece = nil
	for i = 1, 80 do
		local square = program:read_u8(0x1800 + (8 - y) * 8 + x - 1)
		if ((square & 8) == color) then
			piece = pieces[square & 7]
		end
		if (piece ~= nil) then
			break
		end
		emu.wait(0.25)
	end
	machine.video.throttled = throttled_state
	return piece or 'q'
end

function interface.promote(x, y, piece)
	promotion_error(piece)
	-- nothing to press: a queen is assumed
end

return interface
