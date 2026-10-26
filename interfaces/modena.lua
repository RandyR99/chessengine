interface = {}

interface.level = "a2"
interface.cur_level = nil
interface.depth = "0"
interface.score = "0.00"
interface.pv = ""

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.get_module()
	if machine.system.name == "modena" then
		return "Mephisto Modena"
	elseif machine.system.name == "modenaa" then
		return "Mephisto Modena v2"
	elseif machine.system.name == "modenab" then
		return "Mephisto Modena v3"
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
	local cols_idx = { a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8 }
	local x = cols_idx[interface.level:sub(1,1)]
	if (x > 5) then
		return
	end
	local y = interface.level:sub(2,2)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":KEY", 0x10, 1)  -- LEVEL
	emu.wait(0.5)
	sb_press_square(":board", 1, x, y)
	emu.wait(0.5)
	send_input(":KEY", 0x80, 1) -- CLEAR
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	emu.wait(1)
	ioport.ports[":KEY"]:field(0x80):set_value(1)
	ioport.ports[":KEY"]:field(0x40):set_value(1)
	emu.wait(0.5)
	ioport.ports[":KEY"]:field(0x40):set_value(0)
	ioport.ports[":KEY"]:field(0x80):set_value(0)
	emu.wait(2)
	machine.video.throttled = throttled_state
	interface.cur_level = "a2"
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":KEY", 0x08, 0.5) -- POS
		send_input(":KEY", 0x40, 0.5) -- ENT
		send_input(":KEY", 0x40, 0.5) -- ENT
		machine.video.throttled = throttled_state
		return (":board")
	else
		local piece = 7
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if math.abs(p) ~= math.abs(piece) then
						send_input(":KEY", 0x01 << (6 - math.abs(p)), 0.5)
					end
					sb_press_square(":board", 0.5, x, 9 - y)
					if p < 0 then
						sb_press_square(":board", 0.5, x, 9 - y)
					end
					piece = p
				end
			end
		end
		send_input(":KEY", 0x80, 0.5) -- CL
		if mode == -1 then
			send_input(":KEY", 0x40, 0.5) -- ENT
		end
		send_input(":KEY", 0x80, 0.5) -- CL
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game(on)
	if on then
		send_input(":KEY", 0x04, 0.5) -- MEMORY
	else
		send_input(":KEY", 0x80, 0.5) -- CLEAR
	end
	emu.wait(0.5)
end

local function display_state()
	return output_value("digit3") .. " " .. output_value("digit2") .. " " .. output_value("digit1") .. " " .. output_value("digit0")
end

function interface.start_play(init)
	-- the Modena starts thinking on its own once the player's move is on the board (book replies are instant);
	-- ENTER would then make it move at once. While it thinks the clock blinks, a pending move blinks too:
	-- press CLEAR + ENTER only when the display stays steady
	local first = display_state()
	for i = 1, 12 do
		emu.wait(0.1)
		if display_state() ~= first then
			return
		end
	end
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":KEY", 0x80, 1) -- CLEAR
	send_input(":KEY", 0x40, 1) -- ENTER
	machine.video.throttled = throttled_state
end

-- the machine's move as shown on the display (e.g. 'E2E4'), nil if the display shows something else
local function display_move()
	local xvals = { 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71, 0x3d, 0x76 }
	local yvals = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f }
	local d = { output_value("digit3") & 0x7f, output_value("digit2") & 0x7f, output_value("digit1") & 0x7f, output_value("digit0") & 0x7f }
	local fx, fy, tx, ty
	for i = 1, 8 do
		if d[1] == xvals[i] then fx = i end
		if d[2] == yvals[i] then fy = i end
		if d[3] == xvals[i] then tx = i end
		if d[4] == yvals[i] then ty = i end
	end
	if fx and fy and tx and ty then
		return fx, fy, tx, ty
	end
	return nil
end

function interface.is_selected(x, y)
	-- the display keeps showing the previous move while the machine thinks: its from-square is empty now
	local fx, fy, tx, ty = display_move()
	if fx and get_piece_id(fx, fy) ~= 0 then
		return (x == fx and y == fy) or (x == tx and y == ty)
	end
	return output_value("1." .. (x - 1)) ~= 0 and output_value("2." .. (y - 1)) ~= 0
end

function interface.select_piece(x, y, event)
	sb_select_piece(":board", 1, x, y, event)
	-- the 6502 scans the button board slowly: back-to-back presses (the machine's own move) get lost
	emu.wait(1)
end

function interface.get_options()
	return {
		{ "string", "Level", "a2" },
	}
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		interface.level = value:lower():match("^%s*(.-)%s*$"):gsub("%s%s+"," ") -- trim
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
	local d0 = output_value("digit3") & 0x7f
	local d1 = output_value("digit2") & 0x7f
	local d3 = output_value("digit0") & 0x7f
	if (d0 == 0x73 and d1 == 0x50) then	-- display shows 'Pr'
		if     (d3 == 0x5e) then return "q"
		elseif (d3 == 0x31) then return "r"
		elseif (d3 == 0x38) then return "b"
		elseif (d3 == 0x6d) then return "n"
		end
	end
	return nil
end

function interface.promote(x, y, piece)
	sb_promote(":board", x, y, piece)
	if     (piece == "q") then send_input(":KEY", 0x10, 1)
	elseif (piece == "r") then send_input(":KEY", 0x08, 1)
	elseif (piece == "b") then send_input(":KEY", 0x04, 1)
	elseif (piece == "n") then send_input(":KEY", 0x02, 1)
	elseif (piece == "Q" or piece == "R" or piece == "B" or piece == "N") then
		sb_press_square(":board", 1, x, y)
	end
end

-- show_info disabled: it presses CLEAR/INFO/ENTER while the machine thinks; the INFO display (main line)
-- was then taken for the machine's move and the machine ignored the board presses (stalls, reversed moves).
-- To be redone in the show_info revisit.
--[[
function interface.show_info(on)
	if on then
		local throttled_state = machine.video.throttled
		machine.video.throttled = false
		send_input(":KEY", 0x80, 0.3) -- CLEAR
		send_input(":KEY", 0x02, 0.3) -- INFO
		local d1 = output_value("digit3") & 0x7f
		local d2 = output_value("digit2") & 0x7f
		local d3 = output_value("digit1") & 0x7f
		local d4 = output_value("digit0") & 0x7f
		interface.pv = digit_ascii(d1) .. digit_ascii(d2) ..digit_ascii(d3) .. digit_ascii(d4)
		send_input(":KEY", 0x02, 0.3) -- INFO
		d1 = output_value("digit3") & 0x7f
		d2 = output_value("digit2") & 0x7f
		d3 = output_value("digit1") & 0x7f
		d4 = output_value("digit0") & 0x7f
		interface.score = digit_ascii(d1) .. digit_ascii(d2) .. digit_ascii(d3) .. digit_ascii(d4):gsub(" ","")
		send_input(":KEY", 0x40, 0.3) -- ENTER
		d2 = output_value("digit2") & 0x7f
		d3 = output_value("digit1") & 0x7f
		d4 = output_value("digit0") & 0x7f
		interface.depth = digit_ascii(d2) .. digit_ascii(d3) .. digit_ascii(d4):gsub(" ","")
		machine.video.throttled = throttled_state
		return "info score cp " .. interface.score .. " depth " .. interface.depth .. " pv " .. interface.pv
	end
end

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
	return " "
end
--]]

return interface
