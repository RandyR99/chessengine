interface = {}

interface.invert = false
interface.level = "c2"
interface.cur_level = nil
interface.ignore_late_go = true -- replies on its own once the player's move is on the board
interface.score = "0.00"
interface.depth = "0"
interface.pv = ""

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.get_module()
	if machine.system.name == "smondial" then
		return "Mephisto Super Mondial"
	elseif machine.system.name == "smondialab" then
		return "Mephisto Super Mondial v2"
	elseif machine.system.name == "smondialb" then
		return "Mephisto Super Mondial v3"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Frans Morsch"
end

function interface.setdigit(n)
	if     (n == 1) then send_input(":KEY.0", 0x01, 0.5)
	elseif (n == 2) then send_input(":KEY.1", 0x01, 0.5)
	elseif (n == 3) then send_input(":KEY.2", 0x01, 0.5)
	elseif (n == 4) then send_input(":KEY.3", 0x01, 0.5)
	elseif (n == 5) then send_input(":KEY.0", 0x02, 0.5)
	elseif (n == 6) then send_input(":KEY.1", 0x02, 0.5)
	elseif (n == 7) then send_input(":KEY.2", 0x02, 0.5)
	elseif (n == 8) then send_input(":KEY.3", 0x02, 0.5)
	end
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local cols_idx = { a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8 }
	local x = cols_idx[interface.level:sub(1,1)]
	if (x > 5) then
		return
	end
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local y = interface.level:sub(2,2)
	send_input(":KEY.1", 0x08, 0.5) -- LEV
	emu.wait(0.5)
	sb_press_square(":board", 1, x, y)
	emu.wait(0.5)
	send_input(":KEY.0", 0x08, 0.5) -- CL
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	interface.invert = false
	emu.wait(1)
	send_input(":KEY.3", 0x08, 0.5) -- RES
	emu.wait(1)
	machine.video.throttled = throttled_state
	interface.cur_level = "c2"
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":KEY.1", 0x04, 0.5) -- POS
		send_input(":KEY.2", 0x08, 0.5) -- ENT
		send_input(":KEY.2", 0x08, 0.5) -- ENT
		machine.video.throttled = throttled_state
		return (":board")
	else
		local piece = 7
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if p * piece < 0 then
						if p < 0 then
							interface.setdigit(7) -- Black
						else
							interface.setdigit(8) -- White
						end
					end
					if math.abs(p) ~= math.abs(piece) then
						interface.setdigit(7 - math.abs(p))
					end
					sb_press_square(":board", 0.5, x, 9 - y)
					piece = p
				end
			end
		end
		if mode == 1 then
			interface.setdigit(8) -- White
		else
			interface.setdigit(7) -- Black
		end
		send_input(":KEY.0", 0x08, 0.5) -- CL
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game(on)
	if on then
		send_input(":KEY.2", 0x04, 0.5) -- MEM
	else
		send_input(":KEY.0", 0x08, 0.5) -- CL
	end
	emu.wait(0.5)
end

function interface.start_play(init)
	if (init) then
		sb_rotate_board(":board")
		interface.invert = true
	end
	send_input(":KEY.2", 0x08, 1) -- ENT
end

function interface.is_selected(x, y)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	if (output_value("digit1") & 0x80 ~= 0 and output_value("digit5") & 0x80 ~= 0) then
		return false
	end
	local xval = output_value((x - 1) .. ".5") ~= 0
	local yval = output_value((y - 1) .. ".3") ~= 0
	return xval and yval
end

function interface.select_piece(x, y, event)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	sb_select_piece(":board", 1, x, y, event)
end

function interface.get_options()
	return {
		{ "string", "Level", "c2" },
	}
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		interface.level = value:lower():match("^%s*(.-)%s*$"):gsub("%s%s+"," ") -- trim
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
	local d0 = output_value("digit0") & 0x7f
	local d1 = output_value("digit1") & 0x7f
	local d4 = output_value("digit4") & 0x7f
	local d5 = output_value("digit5") & 0x7f
	local d3 = nil
	if (d0 == 0x73 and d1 == 0x50) then	-- UPper display shows 'Pr'
		d3 = output_value("digit3") & 0x7f
	end
	if (d4 == 0x73 and d5 == 0x50) then	-- lower display shows 'Pr'
		d3 = output_value("digit7") & 0x7f
	end
	if	   (d3 == 0x5e) then return "q"
	elseif (d3 == 0x31) then return "r"
	elseif (d3 == 0x38) then return "b"
	elseif (d3 == 0x6d) then return "n"
	end
	return nil
end

function interface.promote(x, y, piece)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	sb_promote(":board", x, y, piece)
	if	   (piece == "q") then send_input(":KEY.0", 0x02, 1)
	elseif (piece == "r") then send_input(":KEY.3", 0x01, 1)
	elseif (piece == "b") then send_input(":KEY.2", 0x01, 1)
	elseif (piece == "n") then send_input(":KEY.1", 0x01, 1)
	elseif (piece == "Q" or piece == "R" or piece == "B" or piece == "N") then
		sb_press_square(":board", 1, x, y)
	end
end

-- show_info disabled (as on montec, same display code): its INFO press can land just after the machine shows its move
-- (before the move LEDs light) and hide it. To be redone in the show_info revisit.
--[[
function interface.show_info(on)
	if on then
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		send_input(":KEY.3", 0x04, 0.2) -- INFO
		emu.wait(0.3)
		local d1 = output_value("digit0")
		local d2 = output_value("digit1")
		local d3 = output_value("digit2")
		local d4 = output_value("digit3")
		local d5 = output_value("digit4")
		local d6 = output_value("digit5")
		local d7 = output_value("digit6")
		local d8 = output_value("digit7")
		interface.pv = digit_ascii(d1) .. digit_ascii(d2) .. digit_ascii(d3) .. digit_ascii(d4)
		send_input(":KEY.0", 0x01, 0.2) -- 1
		emu.wait(0.3)
		d1 = output_value("digit2")
		d2 = output_value("digit3")
		d3 = output_value("digit4")
		d4 = output_value("digit5")
		d5 = output_value("digit6")
		d6 = output_value("digit7")
		interface.depth = digit_ascii(d1) .. digit_ascii(d2)
		interface.score = digit_ascii(d3) .. digit_ascii(d4) .. digit_ascii(d5) .. digit_ascii(d6)
		send_input(":KEY.0", 0x08, 0.2) -- CLEAR
		emu.wait(0.3)
		machine.video.throttled = throttled_state
		return "info score cp " .. interface.score .. " depth " .. interface.depth .. " pv " .. interface.pv
	end
end
]]

function digit_ascii(digit)
	if     digit == 0   then return " "
	elseif digit == 64  then return "-"
	elseif digit == 8   then return "_"
	elseif digit == 63  then return "0"
	elseif digit == 6   then return "1"
	elseif digit == 91  then return "2"
	elseif digit == 79  then return "3"
	elseif digit == 102 then return "4"
	elseif digit == 109 then return "5"
	elseif digit == 125 then return "6"
	elseif digit == 7   then return "7"
	elseif digit == 127 then return "8"
	elseif digit == 111 then return "9"
	elseif digit == 119 then return "a"
	elseif digit == 124 then return "b"
	elseif digit == 57  then return "c"
	elseif digit == 94  then return "d"
	elseif digit == 121 then return "e"
	elseif digit == 113 then return "f"
	elseif digit == 61  then return "g"
	elseif digit == 118 then return "h"
	end
end

return interface
