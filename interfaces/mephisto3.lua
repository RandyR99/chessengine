interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

interface.level = 3
interface.cur_level = nil
interface.score = "0.00"
interface.depth = "0"
interface.pv = ""

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.get_module()
	if machine.system.name == "mephisto3" then
		return "Mephisto III"
	elseif machine.system.name == "mephisto3a" then
		return "Mephisto III v2"
	elseif machine.system.name == "mephisto3b" then
		return "Mephisto III v3"
	elseif machine.system.name == "mephisto3c" then
		return "Mephisto III v4"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Thomas Nitsche & Elmar Henne"
end

function interface.setdigit(n)
	if     (n == 0)	then send_input(":IN.3", 0x01, 0.5)
	elseif (n == 1)	then send_input(":IN.0", 0x02, 0.5)
	elseif (n == 2)	then send_input(":IN.0", 0x08, 0.5)
	elseif (n == 3)	then send_input(":IN.1", 0x02, 0.5)
	elseif (n == 4)	then send_input(":IN.1", 0x08, 0.5)
	elseif (n == 5)	then send_input(":IN.2", 0x02, 0.5)
	elseif (n == 6)	then send_input(":IN.2", 0x08, 0.5)
	elseif (n == 7)	then send_input(":IN.3", 0x02, 0.5)
	elseif (n == 8)	then send_input(":IN.3", 0x08, 0.5)
	elseif (n == 9)	then send_input(":IN.2", 0x04, 0.5)
	end
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.1", 0x04, 0.5) -- LEV
	local n = tonumber(interface.level)
	interface.setdigit(n)
	send_input(":IN.0", 0x04, 0.5) -- ENT
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	send_input(":RESET", 0x01, 0.5) -- RES
	emu.wait(1)
	send_input(":IN.0", 0x01, 0.5) -- CL
	machine.video.throttled = throttled_state
	interface.cur_level = 3
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.2", 0x01, 0.5) -- POS
		for i = 1, 14 do
			send_input(":IN.0", 0x04, 0.5) -- ENT
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
	interface.editing = on
	if on then
		send_input(":IN.3", 0x04, 0.5) -- MEM
	else
		send_input(":IN.0", 0x01, 0.5) -- CL
	end
	emu.wait(0.5)
end

function interface.start_play(init)
	send_input(":IN.0", 0x04, 0.5) -- ENT
end

function interface.is_selected(x, y)
	return output_value((y - 1) .. "." .. (x - 1)) ~= 0
end

function interface.select_piece(x, y, event)
	if (event == "get_castling" or event == "en_passant" or event == "capture") then
		emu.wait(1)
	elseif interface.editing then
		emu.wait(1) -- a fast history replay loses board presses in MEM mode
	end
	sb_select_piece(":board", 1, x, y, event)
end

function interface.get_options()
	return {
		{ "spin", "Level", "3", "0", "9" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 0 or level > 9) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.1", 0x01, 0.5)	-- INFO
	send_input(":IN.0", 0x02, 0.5)	-- 1
	send_input(":IN.3", 0x01, 0.5)	-- 0
	local d0 = 0
	local d3 = output_value("digit3") & 0x7f
	local d2 = output_value("digit2") & 0x7f
	if (d3 == 0x73 and d2 == 0x50) then	-- display shows 'Pr'
		d0 = output_value("digit0") & 0x7f
	end
	send_input(":IN.1", 0x01, 0.5)	-- INFO
	machine.video.throttled = throttled_state
	if     (d0 == 0x5e) then return "q"
	elseif (d0 == 0x31) then return "r"
	elseif (d0 == 0x38) then return "b"
	elseif (d0 == 0x6d) then return "n"
	end
	return nil
end

function interface.promote(x, y, piece)
	sb_promote(":board", x, y, piece)
	if     (piece == "q") then send_input(":IN.2", 0x08, 0.5)
	elseif (piece == "r") then send_input(":IN.2", 0x02, 0.5)
	elseif (piece == "b") then send_input(":IN.1", 0x08, 0.5)
	elseif (piece == "n") then send_input(":IN.1", 0x02, 0.5)
	end
	if (piece == "q" or piece == "r" or piece == "b" or piece == "n") then
		send_input(":IN.0", 0x04, 0.5) -- ENT
	end
end

function interface.show_info(on)
	if on then
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		send_input(":IN.1", 0x01, 0.2) -- Info
		emu.wait(0.1)
		local d1 = output_value("digit3") & 0x7f
		local d2 = output_value("digit2") & 0x7f
		local d3 = output_value("digit1") & 0x7f
		local d4 = output_value("digit0") & 0x7f
		interface.pv = digit_ascii(d1) .. digit_ascii(d2) .. digit_ascii(d3) .. digit_ascii(d4)
		send_input(":IN.0", 0x02, 0.2) -- 1
		emu.wait(0.1)
		d1 = output_value("digit3") & 0x7f
		d2 = output_value("digit2") & 0x7f
		d3 = output_value("digit1") & 0x7f
		d4 = output_value("digit0") & 0x7f
		interface.score = (digit_ascii(d1) .. digit_ascii(d2) .. digit_ascii(d3) .. digit_ascii(d4)):gsub(" ","")
		send_input(":IN.1", 0x02, 0.2) -- 3
		emu.wait(0.1)
		d1 = output_value("digit1") & 0x7f
		d2 = output_value("digit0") & 0x7f
		interface.depth = digit_ascii(d1) .. digit_ascii(d2)
		send_input(":IN.0", 0x01, 0.2) -- CL
		machine.video.throttled = throttled_state
		return "info score cp " .. interface.score .. " depth " .. interface.depth .. " pv " .. interface.pv
	end
end
-- off: show_info presses keys while the machine searches, and a press can land just as the move appears and hide it
-- (as on montec/mm4); to come back once the info can be read from RAM without key presses
interface.show_info = nil

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
	return " " -- unknown segment pattern (a nil here broke the info line and stopped the plugin)
end

return interface
