interface = load_interface("mm4")

interface.level = 1
interface.cur_level = nil

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.get_module()
	if machine.system.name == "mm2" then
		return "Mephisto MM II"
	elseif machine.system.name == "mm2a" then
		return "Mephisto MM II v2"
	elseif machine.system.name == "mm2b" then
		return "Mephisto MM II v3"
	elseif machine.system.name == "mm2c" then
		return "Mephisto MM II v4"
	elseif machine.system.name == "mm2d" then
		return "Mephisto MM II v5"
	elseif machine.system.name == "mm2e" then
		return "Mephisto MM II v6"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Ulf Rathsman"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":KEY.0", 0x10, 1) -- LEV
	local n = tonumber(interface.level)
	interface.setdigit(n)
	send_input(":KEY.0", 0x20, 1) -- ENT
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	sb_reset_board(":board:board")
	emu.wait(1)
	interface.cur_level = 1
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":KEY.0", 0x02, 0.5) -- POS
		send_input(":KEY.0", 0x20, 0.5) -- ENT
		machine.video.throttled = throttled_state
		return (":board:board")
	else
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
		send_input(":KEY.0", 0x20, 0.5) -- ENT
		if mode == 1 then
			interface.setdigit(0) -- White
		else
			interface.setdigit(9) -- Black
		end
		send_input(":KEY.0", 0x01, 0.5) -- CL
	end
	machine.video.throttled = throttled_state
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

local led_selected = interface.is_selected

function interface.is_selected(x, y)
	-- the LEDs also light the square of a pawn captured en passant, the display shows only the move
	local fx, fy, tx, ty = display_move()
	if fx and get_piece_id(fx, fy) ~= 0 then -- an empty from-square = the previous move still shown
		return (x == fx and y == fy) or (x == tx and y == ty)
	end
	return led_selected(x, y)
end

function interface.edit_game(on)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if on then
		send_input(":KEY.0", 0x01, 0.5) -- CL
		send_input(":KEY.0", 0x10, 0.5) -- LEV
		send_input(":KEY.0", 0x04, 0.5) -- MEM
		send_input(":KEY.0", 0x20, 0.5) -- ENT
	else
		send_input(":KEY.0", 0x20, 0.5) -- ENT
	end
	emu.wait(0.5)
	machine.video.throttled = throttled_state
end

function interface.get_options()
	return {
		{ "spin", "Level", "1", "1", "10" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 1 or level > 10) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
	local d3 = output_value("digit0") & 0x7f
	local d2 = output_value("digit1") & 0x7f
	local d1 = output_value("digit2") & 0x7f
	local d0 = output_value("digit3") & 0x7f
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
	if     (piece == "q" or piece == "Q") then send_input(":KEY.1", 0x01, 1)
	elseif (piece == "r" or piece == "R") then send_input(":KEY.1", 0x80, 1)
	elseif (piece == "b" or piece == "B") then send_input(":KEY.1", 0x40, 1)
	elseif (piece == "n" or piece == "N") then send_input(":KEY.1", 0x20, 1)
	end
end

return interface
