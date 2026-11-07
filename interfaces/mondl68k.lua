interface = {}

interface.level = "2"
interface.cur_level = nil
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.get_module()
	return "Mephisto Mondial 68000 XL"
end

function interface.get_author()
	return "Richard Lang"
end

function interface.setdigit(n)
	if	   (n == 1) then send_input(":IN.0", 0x01, 0.5)
	elseif (n == 2) then send_input(":IN.1", 0x01, 0.5)
	elseif (n == 3) then send_input(":IN.2", 0x01, 0.5)
	elseif (n == 4) then send_input(":IN.3", 0x01, 0.5)
	elseif (n == 5) then send_input(":IN.0", 0x02, 0.5)
	elseif (n == 6) then send_input(":IN.1", 0x02, 0.5)
	elseif (n == 7) then send_input(":IN.2", 0x02, 0.5)
	elseif (n == 8) then send_input(":IN.3", 0x02, 0.5)
	elseif (n == 9) then send_input(":IN.0", 0x04, 0.5)
	elseif (n == 0) then send_input(":IN.1", 0x04, 0.5)
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
	send_input(":IN.0", 0x08, 0.5) -- LEV
	emu.wait(0.5)
	for i = 1, level:len() do
		local n = level:sub(i,i)
		if (n == " " or n == ":") then
			send_input(":IN.3", 0x08, 0.5) -- ENT
		else
			interface.setdigit(tonumber(n))
		end
	end
	send_input(":IN.3", 0x08, 0.5) -- ENT
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	emu.wait(2)
	machine.video.throttled = throttled_state
	interface.cur_level = "2"
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.3", 0x04, 0.5) -- POS
		for i = 1, 14 do
			send_input(":IN.3", 0x08, 0.5) -- ENT
		end
		machine.video.throttled = throttled_state
		return (":board")
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
					send_input(":IN.3", 0x08, 0.5) -- ENT
				end
			end
		end
		if mode == 1 then
			interface.setdigit(0) -- White
		else
			interface.setdigit(9) -- Black
		end
		send_input(":IN.3", 0x08, 0.5) -- ENT
		send_input(":IN.2", 0x08, 0.5) -- CL
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game(on)
	if on then
		send_input(":IN.1", 0x08, 0.5) -- MEM
	else
		send_input(":IN.2", 0x08, 0.5) -- CL
	end
	emu.wait(0.5)
end

function interface.start_play(init)
	send_input(":IN.3", 0x08, 1) -- ENT
	emu.wait(1)
end

function interface.is_selected(x, y)
	local xval = output_value("0." .. (x - 1)) ~= 0
	local yval = output_value("1." .. (y - 1)) ~= 0
	return xval and yval
end

function interface.select_piece(x, y, event)
	sb_select_piece(":board", 1, x, y, event)
end

function interface.get_options()
	return {
		{ "string", "Level", "2" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = value:match("^%s*(.-)%s*$"):gsub("%s%s+"," ") -- trim
		local hms = "%s%d%d:[0-5]%d:[0-5]%d"
		if (level:match("^7" .. hms .. "$")) then
			level = level .. level:sub(2,level:len()) -- same time for both
		end
		if (level:match("^[0-69]$") or level:match("^7" .. hms .. hms .. "$") or level:match("^8" .. hms .. "$")) then
			interface.level = level
			interface.setlevel()
		end
	end
end

function interface.get_promotion(x, y)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_select_piece(":board", 0.5, x, y, "")
	send_input(":IN.2", 0x04, 0.5) -- INFO
	send_input(":IN.0", 0x01, 0.5) -- 1
	send_input(":IN.1", 0x04, 0.5) -- 0
	local d0 = output_value("digit0") & 0x7f
	local d1 = output_value("digit1") & 0x7f
	local d3 = output_value("digit3") & 0x7f
	local piece = nil
	if (d0 == 0x73 and d1 == 0x50) then	-- display shows 'Pr'
		if	   (d3 == 0x5e) then piece = "q"
		elseif (d3 == 0x31) then piece = "r"
		elseif (d3 == 0x38) then piece = "b"
		elseif (d3 == 0x6d) then piece = "n"
		end
	end
	send_input(":IN.2", 0x08, 0.5) -- CL
	machine.video.throttled = throttled_state
	return piece
end

function interface.promote(x, y, piece)
	sb_promote(":board", x, y, piece)
	-- player promotion: display shows 'Pr -', piece key + ENT (a square press clears the choice)
	if	   (piece == "q") then send_input(":IN.1", 0x02, 1)
	elseif (piece == "r") then send_input(":IN.0", 0x02, 1)
	elseif (piece == "b") then send_input(":IN.3", 0x01, 1)
	elseif (piece == "n") then send_input(":IN.2", 0x01, 1)
	else
		sb_press_square(":board", 0.5, x, y)
		return
	end
	send_input(":IN.3", 0x08, 1) -- ENT
end

-- the Lang program keeps its search information as text in RAM, as the Amsterdam does: amsterd.lua reads it
local amsterdam = load_interface("amsterd")
interface.show_info = amsterdam.show_info
interface.info_every = amsterdam.info_every

return interface
