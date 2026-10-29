interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

interface.level = "a2"
interface.cur_level = nil
interface.score = "0.00"
interface.depth = "1"
interface.pv = ""

function interface.get_module()
	if machine.system.name == "sgalaxy" then
		return "CXG Sphinx Galaxy v2.03"
	elseif machine.system.name == "sgalaxya" then
		return "CXG Sphinx Galaxy v2.00"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Frans Morsch"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local cols_idx = { a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8 }
	local x = cols_idx[interface.level:sub(1, 1)]
	local y = interface.level:sub(2, 2)
	send_input(":IN.1", 0x20, 0.5)  -- Level
	sb_press_square(":board", 0.5, x, y)
	send_input(":IN.1", 0x20, 0.5)  -- Level
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	sb_reset_board(":board")
	emu.wait(1)
	interface.cur_level = "a2"
	interface.setlevel()
end

function setpiece(n)
	if     (n == 1) then send_input(":IN.0", 0x01, 0.6) -- K
	elseif (n == 2) then send_input(":IN.0", 0x02, 0.6) -- Q
	elseif (n == 3) then send_input(":IN.0", 0x04, 0.6) -- R
	elseif (n == 4) then send_input(":IN.0", 0x08, 0.6) -- B
	elseif (n == 5) then send_input(":IN.0", 0x80, 0.6) -- N
	elseif (n == 6) then send_input(":IN.0", 0x40, 0.6) -- P
	end
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.1", 0x02, 0.5) -- Enter Position
		send_input(":IN.1", 0x08, 0.5) -- Library/Clearboard
		sb_clear_board(":board")
		machine.video.throttled = throttled_state
		return ("")
	else
		local piece = 7
		local z
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if p * piece < 0 then
						send_input(":IN.1", 0x04, 0.6) -- Sound/Color
					end
					emu.wait(0.5)
					if math.abs(p) ~= math.abs(piece) then
						setpiece(math.abs(p))
					end
					if p > 0 then
						z = 6 - p
					else
						z = 12 + p
					end
					send_input(":board:SPAWN", 0x01 << z, 0.09)
					sb_select_piece(":board", 1, x, 9 - y, "put")
					piece = p
				end
			end
		end
		if mode * piece < 0 then
			send_input(":IN.1", 0x04, 0.5) -- Sound/Color
		end
		send_input(":IN.1", 0x02, 0.5) -- Enter Position
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game()
	send_input(":IN.1", 0x10, 0.5) -- MultiMove
	emu.wait(0.5)
end

function interface.start_play(init)
	send_input(":IN.0", 0x10, 1) -- Move
end

function interface.is_selected(x, y)
	local xval = output_value(tostring(x - 1) .. ".4") ~= 0
	local yval = output_value(tostring(y - 1) .. ".5") ~= 0
	return xval and yval
end

--function interface.is_selected(x, y)
--	return output_value((y - 1) .. "." .. (x - 1)) ~= 0
--end

function interface.select_piece(x, y, event)
	sb_select_piece(":board", 0.5, x, y, event)
end

function interface.get_options()
	return {
		{ "string", "Level", "a2" },
	}
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		local level = value:lower():match("^%s*(.-)%s*$"):gsub("%s%s+"," ") -- trim
		if (level:match("^[a-g][1-8]$")) then
			interface.level = level
			interface.setlevel()
		end
	end
end

function interface.get_promotion(x, y)
	local new_type = nil
	if     (output_value("4.6") ~= 0) then new_type = 'q'
	elseif (output_value("3.6") ~= 0) then new_type = 'r'
	elseif (output_value("2.6") ~= 0) then new_type = 'b'
	elseif (output_value("1.6") ~= 0) then new_type = 'n'
	end
	if (new_type ~= nil) then
		interface.select_piece(x, y, "")
	end
	return new_type
end

function interface.promote(x, y, piece)
	sb_promote(":board", x, y, piece)
	emu.wait(0.5)
	if     (piece == "q") then send_input(":IN.0", 0x02, 1)
	elseif (piece == "r") then send_input(":IN.0", 0x04, 1)
	elseif (piece == "b") then send_input(":IN.0", 0x08, 1)
	elseif (piece == "n") then send_input(":IN.0", 0x80, 1)
	end
end

-- show_info disabled: on the default level the machine finishes its move right when INFO is pressed (every ~10 s);
-- it then takes its move as played without lighting the LEDs -> the plugin never sees it (sgalaxyb fen_wl/fen_start ~2/3).
-- To be redone in the show_info revisit (read score, depth and best move from RAM).
--[[
function interface.show_info(on, color)
	if on then
		local dot1 = output_value("s0.16")
		local dot2 = output_value("s1.16")
		if dot1 == 1 and dot2 == 1 then
			send_input(":IN.1", 0x40, 0.15)
		end
		local d1 = output_value("digit0")
		local d2 = output_value("digit1")
		local d3 = output_value("digit2")
		local d4 = output_value("digit3")
		local d5 = output_value("digit4")
		local d6 = output_value("digit5")
		local d7 = output_value("digit6")
		local d8 = output_value("digit7")
		interface.score = digit_ascii(d5) .. digit_ascii(d6) .. digit_ascii(d7) .. digit_ascii(d8)
		if color == "B" then
		    if tonumber(interface.score) ~= nil then
		        interface.score = tonumber(interface.score) * (-1)
    		end
    	end
		if digit_ascii(d1) ~= "-" then
			interface.pv = digit_ascii(d1) .. digit_ascii(d2) .. digit_ascii(d3) .. digit_ascii(d4)
		end
		return "info score cp " .. interface.score .. " depth " .. interface.depth .. " pv " .. interface.pv
	end
end
--]]

function digit_ascii(digit)
	if     digit == nil then return("0")
	elseif digit == 63  then return("0")
	elseif digit == 6   then return("1")
	elseif digit == 91  then return("2")
	elseif digit == 79  then return("3")
	elseif digit == 102 then return("4")
	elseif digit == 109 then return("5")
	elseif digit == 125 then return("6")
	elseif digit == 7   then return("7")
	elseif digit == 127 then return("8")
	elseif digit == 111 then return("9")
	elseif digit == 119 then return("a")
	elseif digit == 124 then return("b")
	elseif digit == 57  then return("c")
	elseif digit == 94  then return("d")
	elseif digit == 121 then return("e")
	elseif digit == 113 then return("f")
	elseif digit == 61  then return("g")
	elseif digit == 118 then return("h")
	elseif digit == 0   then return(" ")
	elseif digit == 28  then return("Nr.")
	elseif digit == 64  then return("-")
	elseif digit == 115 then return("P")
	elseif digit == 55  then return("N")
	else
		return (" hex" .. tostring(digit) .. " ")
	end
end

return interface
