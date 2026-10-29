interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

interface.turn = true
interface.level = "2"
interface.cur_level = nil
local promcode = 0
interface.edit = false

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.get_module()
	return "Elektronika IM-05"
end

function interface.get_author()
	return "Vladimir Petrenko"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local level = interface.level
	send_input(":IN.5", 0x08, 0.5)  -- LEVEL
	if (level:len() == 1) then
		send_input(":IN.3", 0x01, 0.5)  -- 'H/8'
	end
	for i = 1, level:len() do
		interface.send_pos(tonumber(level:sub(i,i)))
	end
	send_input(":IN.2", 0x02, 0.5)  -- CONFIRM
	emu.wait(0.5)
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	interface.turn = true
	send_input(":IN.5", 0x01, 0.5) -- RESET
	emu.wait(1)
	promcode = 0
	interface.cur_level = "2"
	interface.setlevel()
end

function interface.set_pos(mode)
	if mode == 0 then
		return ("") -- no sensor board
	end
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.4", 0x01, 0.5) -- MODE
	send_input(":IN.4", 0x01, 0.5) -- MODE
	send_input(":IN.4", 0x01, 0.5) -- MODE / Setup
	send_input(":IN.5", 0x02, 0.5) -- CANCEL (clear board)
	-- other pieces first, kings last
	for i = 1, 2 do
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, y)
				if (i == 2 and math.abs(p) == 1) or (i == 1 and math.abs(p) > 1) then
					if p > 0 then
						send_input(":IN.4", 0x04, 0.5) -- White
					else
						send_input(":IN.5", 0x04, 0.5) -- Black
					end
					interface.send_pos(7 - math.abs(p)) -- K F6, Q E5, R D4, B C3, N B2, P A1
					interface.send_pos(x)
					interface.send_pos(y)
					send_input(":IN.2", 0x02, 0.5) -- CONFIRM
				end
			end
		end
	end
	if mode == -1 then
		send_input(":IN.5", 0x04, 0.5) -- Black (to move)
		send_input(":IN.2", 0x02, 0.5) -- CONFIRM
	end
	send_input(":IN.4", 0x01, 0.5) -- MODE
	send_input(":IN.4", 0x01, 0.5) -- MODE / Play
	machine.video.throttled = throttled_state
end

function interface.edit_game(on)
	interface.edit = on
end

function interface.start_play(init)
	interface.turn = false
	send_input(":IN.2", 0x08, 0.5) -- ENTER
	emu.wait(0.5)
end

function interface.stop_play()
	send_input(":IN.2", 0x02, 0.5)  -- CONFIRM
end

function interface.is_selected(x, y)
	local xval = { 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71, 0x3d, 0x76 }
	local yval = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f }
	local d0 = output_value("digit4")
	local d1 = output_value("digit3")
	local d2 = output_value("digit1")
	local d3 = output_value("digit0")
	if (d2 == yval[1]) then -- promotion?
		d3 = d2
		d2 = d1
		d1 = yval[2]
	elseif (d2 == yval[8]) then
		d3 = d2
		d2 = d1
		d1 = yval[7]
	end
	return (xval[x] == d0 and yval[y] == d1) or (xval[x] == d2 and yval[y] == d3)
end

function interface.send_pos(p)
	if     (p == 1)	then send_input(":IN.0", 0x08, 0.5)
	elseif (p == 2)	then send_input(":IN.0", 0x04, 0.5)
	elseif (p == 3)	then send_input(":IN.0", 0x02, 0.5)
	elseif (p == 4)	then send_input(":IN.0", 0x01, 0.5)
	elseif (p == 5)	then send_input(":IN.3", 0x08, 0.5)
	elseif (p == 6)	then send_input(":IN.3", 0x04, 0.5)
	elseif (p == 7)	then send_input(":IN.3", 0x02, 0.5)
	elseif (p == 8)	then send_input(":IN.3", 0x01, 0.5)
	end
end

function interface.select_piece(x, y, event)
	if (event ~= "capture" and event ~= "get_castling" and event ~= "put_castling" and event ~= "en_passant") then
		if (interface.turn) then
			interface.send_pos(x)
			interface.send_pos(y)
		end
		if (event == "put") then
			if (interface.turn) then
				if (promcode ~= 0) then
					ioport.ports[":IN.1"]:field(0x08):set_value(1) -- PROMOTE on
					emu.wait(0.5)
					interface.send_pos(promcode)
					ioport.ports[":IN.1"]:field(0x08):set_value(0) -- PROMOTE off
					emu.wait(0.5)
					promcode = 0
				end
				if interface.edit then
					send_input(":IN.2", 0x02, 0.5) -- CONFIRM (enter the move, no reply)
				else
					send_input(":IN.2", 0x08, 0.5) -- ENTER
				end
			else
				promcode = 0 -- the machine's own promotion: nothing to enter
			end
			if not interface.edit then
				interface.turn = not interface.turn
			end
		end
	end
end

function interface.get_options()
	return {
		{ "string", "Level", "2" },
	}
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		local level = value:upper():match("^%s*(.-)%s*$"):gsub("%s%s+"," ") -- trim
		if (level:match("^[0-7]$") or level:match("^[0-7]%d%d$")) then
			interface.level = level
			interface.setlevel()
		end
	end
end

function interface.get_promotion(x, y)
	local digit = output_value("digit0")
	if     (digit == 0x6d) then return 'q'
	elseif (digit == 0x66) then return 'r'
	elseif (digit == 0x4f) then return 'b'
	elseif (digit == 0x5b) then return 'n'
	else return 'q'
	end
end

function interface.promote_special(piece)
	if     (piece == "q") then promcode = 5
	elseif (piece == "r") then promcode = 4
	elseif (piece == "b") then promcode = 3
	elseif (piece == "n") then promcode = 2
	else promcode = 0
	end
end

function interface.promote(x, y, piece)
end

return interface
