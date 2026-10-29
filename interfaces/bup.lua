interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

interface.level = "bl 2"
interface.cur_level = nil

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.get_module()
	if machine.system.name == "bup" then
		return "Mephisto Blitz & Problem"
	elseif machine.system.name == "bupa" then
		return "Mephisto Blitz & Problem v2"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Ulf Rathsman"
end

function interface.setdigit(n)
	if     (n == 1) then  send_input(":KEY.0", 0x01, 0.5)
	elseif (n == 2) then  send_input(":KEY.0", 0x02, 0.5)
	elseif (n == 3) then  send_input(":KEY.0", 0x04, 0.5)
	elseif (n == 4) then  send_input(":KEY.0", 0x08, 0.5)
	elseif (n == 5) then  send_input(":KEY.0", 0x10, 0.5)
	elseif (n == 6) then  send_input(":KEY.0", 0x20, 0.5)
	end
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local l0 = 0x7c -- 'b'
	local l1 = 0x38 -- 'l'
	if (interface.level:sub(1, 2) == "pl") then
		l0 = 0x73 -- 'p'
	end
	repeat
		send_input(":KEY.1", 0x40, 1) -- LEV
		local d0 = output_value("digit3") & 0x7f
		local d1 = output_value("digit2") & 0x7f
	until (d0 == l0 and d1 == l1)
	local n = tonumber(interface.level:sub(4))
	if (n == 1) then
		send_input(":KEY.0", 0x01, 1)
	elseif (n == 2) then
		send_input(":KEY.0", 0x02, 1)
	elseif (n == 3) then
		send_input(":KEY.0", 0x04, 1)
	elseif (n == 4) then
		send_input(":KEY.0", 0x08, 1)
	elseif (n == 5) then
		send_input(":KEY.0", 0x10, 1)
	elseif (n == 6) then
		send_input(":KEY.0", 0x20, 1)
	end
	send_input(":KEY.1", 0x02, 1) -- ENT
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board:board")
	emu.wait(1)
	while (output_value("led101") == 0) do
		machine:soft_reset()
		emu.wait(1)
	end
	send_input(":KEY.1", 0x01, 1) -- CL
	emu.wait(1)
	machine.video.throttled = throttled_state
	interface.cur_level = "bl 2"
	interface.setlevel()
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":KEY.1", 0x20, 0.5) -- POS
		send_input(":KEY.1", 0x01, 0.5) -- CL
		return (":board:board")
	else
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					interface.setdigit(7 - math.abs(p))
					if p < 0 then
						interface.setdigit(7 - math.abs(p))
					end
					sb_press_square(":board:board", 0.5, x, 9 - y)
				end
			end
		end
		send_input(":KEY.1", 0x01, 0.5) -- CL
		if mode == 1 then
			send_input(":KEY.0", 0x40, 0.5) -- White
		else
			send_input(":KEY.0", 0x80, 0.5) -- Black
		end
		send_input(":KEY.1", 0x02, 0.5) -- ENT
		machine.video.throttled = throttled_state
	end
end

function interface.edit_game(on)
	if on then
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		send_input(":KEY.1", 0x01, 0.5) -- CL
		send_input(":KEY.1", 0x40, 0.5) -- LEV
		send_input(":KEY.1", 0x10, 0.5) ---MON
		send_input(":KEY.1", 0x02, 0.5) -- ENT
		machine.video.throttled = throttled_state
	end
	emu.wait(0.5)
end

function interface.start_play(init)
	if (output_value("led100") ~= 0) then
		send_input(":KEY.0", 0x80, 1) -- BLACK
	elseif (output_value("led101") ~= 0) then
		send_input(":KEY.0", 0x40, 1) -- WHITE
	end
	send_input(":KEY.1", 0x02, 1) -- ENT
end

local xval = { 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71, 0x3d, 0x76 }
local yval = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f }

-- the machine's move as shown on the display (e.g. 'E4d3'), nil if the display shows something else
local function display_move()
	local d = { output_value("digit3") & 0x7f, output_value("digit2") & 0x7f, output_value("digit1") & 0x7f, output_value("digit0") & 0x7f }
	local fx, fy, tx, ty
	for i = 1, 8 do
		if d[1] == xval[i] then fx = i end
		if d[2] == yval[i] then fy = i end
		if d[3] == xval[i] then tx = i end
		if d[4] == yval[i] then ty = i end
	end
	if fx and fy and tx and ty then
		return fx, fy, tx, ty
	end
	return nil
end

function interface.is_selected(x, y)
	-- the LEDs also light the square of a pawn captured en passant, the display shows only the move
	local fx, fy, tx, ty = display_move()
	if fx and get_piece_id(fx, fy) ~= 0 then -- an empty from-square = the previous move still shown
		return (x == fx and y == fy) or (x == tx and y == ty)
	end
	return output_value("led" .. (8 * (y - 1) + (x - 1))) ~= 0
end

function interface.select_piece(x, y, event)
	local d0 = output_value("digit3") & 0x7f
	local d1 = output_value("digit2") & 0x7f
	local d2 = output_value("digit1") & 0x7f
	local d3 = output_value("digit0") & 0x7f
	if ((d0 == 0x31 and d1 == 0x30 and d2 == 0x37 and d3 == 0x79) or (d0 == 0x77 and d1 == 0x06 and d2 == 0x77 and d3 == 0x06)) then -- 'TIME' or 'A1A1'
		send_input(":KEY.1", 0x01, 0.3) -- CL
	end
	sb_select_piece(":board:board", 1, x, y, event)
end

function interface.get_options()
	return {
		{ "string", "Level", "bl 2" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		value = value:gsub("_", " ")
		local level = string.lower(value:match("^%s*(.-)%s*$"):gsub("%s%s+", " ")) -- trim
		if (string.match(level, "^[1-6]$")) then
			level = "bl " .. level
		end
		if (string.match(level, "^[bp]l [1-6]$")) then
			interface.level = level
			interface.setlevel()
		end
	end
end

function interface.get_promotion(x, y)
	local d0 = output_value("digit3") & 0x7f
	local d1 = output_value("digit2") & 0x7f
	local d3 = output_value("digit0") & 0x7f
	if (d0 == 0x73 and d1 == 0x50) then -- display shows 'Pr'
		if     (d3 == 0x5e) then return "q"
		elseif (d3 == 0x31) then return "r"
		elseif (d3 == 0x38) then return "b"
		elseif (d3 == 0x6d) then return "n"
		end
	end
	return nil
end

function interface.promote(x, y, piece)
	sb_promote(":board:board", x, y, piece)
	if     (piece == "q" or piece == "Q") then send_input(":KEY.0", 0x10, 1)
	elseif (piece == "r" or piece == "R") then send_input(":KEY.0", 0x08, 1)
	elseif (piece == "b" or piece == "B") then send_input(":KEY.0", 0x04, 1)
	elseif (piece == "n" or piece == "N") then send_input(":KEY.0", 0x02, 1)
	end
end

return interface
