interface = {}

interface.level = "a2"
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
	if machine.system.name == "mega4" then
		return "Mephisto Mega IV"
	elseif machine.system.name == "mega4a" then
		return "Mephisto Mega IV v2"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Ed Schröder"
end

function interface.setdigit(n)
	if     (n == 1) then send_input(":KEY.0", 0x01, 0.9)
	elseif (n == 2) then send_input(":KEY.1", 0x01, 0.9)
	elseif (n == 3) then send_input(":KEY.2", 0x01, 0.9)
	elseif (n == 4) then send_input(":KEY.3", 0x01, 0.9)
	elseif (n == 5) then send_input(":KEY.0", 0x02, 0.9)
	elseif (n == 6) then send_input(":KEY.1", 0x02, 0.9)
	elseif (n == 7) then send_input(":KEY.2", 0x02, 0.9)
	elseif (n == 8) then send_input(":KEY.3", 0x02, 0.9)
	end
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local cols_idx = { a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8 }
	local x = cols_idx[interface.level:sub(1,1)]
	if (x > 6) then
		return
	end
	local y = interface.level:sub(2,2)
	send_input(":KEY.1", 0x08, 1)  -- LEVEL
	emu.wait(0.5)
	sb_press_square(":board", 1, x, y)
	emu.wait(0.5)
	send_input(":KEY.0", 0x08, 1) -- CLEAR
end

function interface.setup_machine()
	sb_reset_board(":board")
	emu.wait(1)
	send_input(":KEY.3", 0x08, 1) -- RESET
	emu.wait(1)
	interface.cur_level = "a2"
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":KEY.1", 0x04, 0.9) -- POS
		send_input(":KEY.2", 0x08, 0.9) -- ENT
		send_input(":KEY.2", 0x08, 0.9) -- ENT
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
		send_input(":KEY.0", 0x08, 0.9) -- CL
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game(on)
	if on then
		send_input(":KEY.2", 0x04, 0.9) -- MEM
	else
		send_input(":KEY.0", 0x08, 0.9) -- CL (the original pressed KEY.2 0x08 = ENT)
	end
	emu.wait(0.5)
end

function interface.start_play(init)
	send_input(":KEY.2", 0x08, 1) -- ENTER
end

function interface.is_selected(x, y)
	-- no clock check here (unlike smondial): this program shows the clocks while its move waits on the board
	local xval = output_value((x - 1) .. ".5") ~= 0
	local yval = output_value((y - 1) .. ".3") ~= 0
	return xval and yval
end

function interface.select_piece(x, y, event)
	sb_select_piece(":board", 1, x, y, event)
end

function interface.get_options()
	return {
		{ "string", "Level", "a2" },
	}
end

function interface.set_option(name, value)
    if (name == "level" and value ~= "") then
        interface.level = value
        interface.setlevel()
    end
end

function interface.get_promotion(x, y)
	local d0 = output_value("digit0") & 0x7f
	local d1 = output_value("digit1") & 0x7f
	local d4 = output_value("digit4") & 0x7f
	local d5 = output_value("digit5") & 0x7f
	local d3 = nil
	if (d0 == 0x73 and d1 == 0x33) then	-- UPper display shows 'Pr'
		d3 = output_value("digit3") & 0x7f
	end
	if (d4 == 0x73 and d5 == 0x33) then	-- lower display shows 'Pr'
		d3 = output_value("digit7") & 0x7f
	end
	if     (d3 == 0x5e) then return "q"
	elseif (d3 == 0x31) then return "r"
	elseif (d3 == 0x38) then return "b"
	elseif (d3 == 0x6d) then return "n"
	end
	return nil
end

function interface.promote(x, y, piece)
	sb_promote(":board", x, y, piece)
	if     (piece == "q") then send_input(":KEY.0", 0x02, 1)
	elseif (piece == "r") then send_input(":KEY.3", 0x01, 1)
	elseif (piece == "b") then send_input(":KEY.2", 0x01, 1)
	elseif (piece == "n") then send_input(":KEY.1", 0x01, 1)
	end
end

-- the search keeps its main line in RAM at interface.pv_ram (0x018a; polgar 0x013e; found by RAM dumps during the
-- search): pairs of squares
-- (file * 10 + rank, file 0 = a), ended by an invalid pair. Read without key presses (an INFO press could land just
-- after the machine shows its move and hide it); the evaluation and depth weren't found in RAM
local stale = nil -- RAM as the previous search (or game) left it
local first = true
interface.pv_ram = 0x018a

function interface.show_info(on)
	local sp = machine.devices[":maincpu"].spaces["program"]
	local raw = ""
	for a = interface.pv_ram, interface.pv_ram + 0x0f do
		raw = raw .. string.char(sp:read_u8(a))
	end
	if not on or first then
		first = false -- battery RAM still holds the last search before this session's first player turn
		stale = raw
		return nil
	end
	if raw == stale then
		return nil -- nothing from this search yet
	end
	stale = nil
	local function square(v)
		local file, rank = v // 10, v % 10
		if file <= 7 and rank >= 1 and rank <= 8 then
			return string.char(0x61 + file) .. rank
		end
	end
	local pv = {}
	for k = 1, #raw - 1, 2 do
		local from, to = square(raw:byte(k)), square(raw:byte(k + 1))
		if not from or not to or from == to then
			break
		end
		pv[#pv + 1] = from .. to
	end
	if #pv == 0 then
		return nil
	end
	return { pv = pv }
end
interface.info_every = 1 -- show_info only reads RAM

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
