interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

interface.level = "le 1"
interface.cur_level = nil

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.get_module()
	if machine.system.name == "mm4" then
		return "Mephisto MM IV"
	elseif machine.system.name == "mm4a" then
		return "Mephisto MM IV v2"
	elseif machine.system.name == "mm4b" then
		return "Mephisto MM IV v3"
	elseif machine.system.name == "mm4tk" then
		return "Mephisto MM IV Turbokit"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Ed Schröder"
end

function interface.setdigit(n)
	if     (n == 0) then  send_input(":KEY.0", 0x40, 0.5)
	elseif (n == 1) then  send_input(":KEY.1", 0x08, 0.5)
	elseif (n == 2) then  send_input(":KEY.1", 0x20, 0.5)
	elseif (n == 3) then  send_input(":KEY.1", 0x40, 0.5)
	elseif (n == 4) then  send_input(":KEY.1", 0x80, 0.5)
	elseif (n == 5) then  send_input(":KEY.1", 0x01, 0.5)
	elseif (n == 6) then  send_input(":KEY.1", 0x02, 0.5)
	elseif (n == 7) then  send_input(":KEY.1", 0x04, 0.5)
	elseif (n == 8) then  send_input(":KEY.1", 0x10, 0.5)
	elseif (n == 9) then  send_input(":KEY.0", 0x80, 0.5)
	end
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":KEY.0", 0x10, 1) -- LEV
	if (interface.level:sub(1,2) == "bl") then
		send_input(":KEY.0", 0x10, 1) -- LEV
	end
	local n = tonumber(interface.level:sub(4))
	interface.setdigit(n)
	send_input(":KEY.0", 0x20, 1) -- ENT
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	ioport.ports[":RESET"]:field(0x01):set_value(1) -- Res 1
	ioport.ports[":RESET"]:field(0x02):set_value(1) -- Res 2
	emu.wait(0.3)
	ioport.ports[":RESET"]:field(0x01):set_value(0) -- RES 1
	ioport.ports[":RESET"]:field(0x02):set_value(0) -- RES 2
	emu.wait(0.5)
	sb_reset_board(":board:board")
	emu.wait(1)
	machine.video.throttled = throttled_state
	interface.cur_level = "le 1"
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":KEY.0", 0x02, 0.5) -- POS
		for i = 1, 14 do
			send_input(":KEY.0", 0x20, 0.5) -- ENT
		end
		machine.video.throttled = throttled_state
		return (":board:board")
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
					interface.setdigit(7 - math.abs(p))
					interface.setdigit(x)
					interface.setdigit(9 - y)
					send_input(":KEY.0", 0x20, 0.5) -- ENT
				end
			end
		end
		if mode == 1 then
			interface.setdigit(0) -- White
		else
			interface.setdigit(9) -- Black
		end
		send_input(":KEY.0", 0x20, 0.5) -- ENT
		send_input(":KEY.0", 0x01, 0.5) -- CL
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game(on)
	if on then
		send_input(":KEY.0", 0x04, 0.5) -- MEM
	else
		send_input(":KEY.0", 0x01, 0.5) -- CL
	end
	emu.wait(0.5)
end

function interface.start_play(init)
	send_input(":KEY.0", 0x20, 1) -- ENT
end

function interface.is_selected(x, y)
	if x == 6 and (y == 8 or y == 1) then
		if output_value("led" .. ((y - 1) * 8 + (7 - 1))) ~= 0 and output_value("led" .. ((y - 1) * 8 + (8 - 1))) ~= 0 then
			return 0
		end
	end
	if x == 1 and (y == 8 or y == 1) then
		if output_value("led" .. ((y - 1) * 8 + (3 - 1))) ~= 0 and output_value("led" .. ((y - 1) * 8 + (5 - 1))) ~= 0 then
			return 0
		end
	end
	return output_value("led" .. ((y - 1) * 8 + (x - 1))) ~= 0
end

function interface.select_piece(x, y, event)
	local d0 = output_value("digit3") & 0x7f
	local d1 = output_value("digit2") & 0x7f
	local d2 = output_value("digit1") & 0x7f
	local d3 = output_value("digit0") & 0x7f
	if ((d0 == 0x31 and d1 == 0x30 and d2 == 0x37 and d3 == 0x79) or (d0 == 0x77 and d1 == 0x06 and d2 == 0x77 and d3 == 0x06)) then -- 'TIME' or 'A1A1'
		send_input(":KEY.0", 0x01, 1) -- CL
	end
	sb_select_piece(":board:board", 1, x, y, event)
end

function interface.get_options()
	return {
		{ "string", "Level", "le 1" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = string.lower(value:match("^%s*(.-)%s*$"):gsub("%s%s+", " ")) -- trim
		if (string.match(level, "^[0-9]$")) then
			level = "le " .. level
		end
		if (string.match(level, "^le [0-9]$") or string.match(level, "^bl [1-8]$")) then
			interface.level = level
			interface.setlevel()
		end
	end
end

function interface.get_promotion(x, y)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":KEY.0", 0x08, 0.5) -- INFO
	send_input(":KEY.1", 0x08, 0.5) -- 1
	local d3 = 0
	for i = 0, 5 do
		local d0 = output_value("digit3") & 0x7f
		local d1 = output_value("digit2") & 0x7f
		if (d0 == 0x73 and d1 == 0x50) then -- display shows 'Pr'
			d3 = output_value("digit0") & 0x7f
			break
		end
		send_input(":KEY.0", 0x40, 0.5) -- 0
	end
	send_input(":KEY.0", 0x08, 0.5) -- INFO
	machine.video.throttled = throttled_state
	if     (d3 == 0x5e) then return "q"
	elseif (d3 == 0x31) then return "r"
	elseif (d3 == 0x38) then return "b"
	elseif (d3 == 0x6d) then return "n"
	end
	return nil
end

function interface.promote(x, y, piece)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_promote(":board:board", x, y, piece)
	if     (piece == "q") then send_input(":KEY.1", 0x01, 1)
	elseif (piece == "r") then send_input(":KEY.1", 0x80, 1)
	elseif (piece == "b") then send_input(":KEY.1", 0x40, 1)
	elseif (piece == "n") then send_input(":KEY.1", 0x20, 1)
	end
	if (piece == "q" or piece == "r" or piece == "b" or piece == "n") then
		send_input(":KEY.0", 0x20, 1)
	end
	machine.video.throttled = throttled_state
end

-- the search keeps what the INFO pages show in RAM (found with read taps on the info keys): at interface.info_ram
-- (0x013e; rebel5: 0x0174) the first move of the main line (file * 10 + rank, file 0 = a), 10 bytes after it the
-- evaluation in pawns for Mephisto as display digits ("-8.91": 0x40 0xff 0x6f 0x06, bit 7 = point). Read without key presses (a press could land just
-- as the move appears and hide it); no search depth found
local segment_char = { [0x00] = "", [0x40] = "-", [0x3f] = "0", [0x06] = "1", [0x5b] = "2", [0x4f] = "3", [0x66] = "4",
	[0x6d] = "5", [0x7d] = "6", [0x07] = "7", [0x7f] = "8", [0x6f] = "9" }
local stale = nil -- RAM as the previous search (or game) left it
local first = true
interface.info_ram = 0x013e

function interface.show_info(on)
	local sp = machine.devices[":maincpu"].spaces["program"]
	local raw = ""
	local base = interface.info_ram
	for a = base, base + 0x0d do
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
	local info = {}
	local text = ""
	for a = base + 0x0a, base + 0x0d do
		local b = sp:read_u8(a)
		local c = segment_char[b & 0x7f]
		if c == nil then
			text = nil
			break
		end
		text = text .. c .. ((b & 0x80 ~= 0) and "." or "")
	end
	local pawns = text and tonumber(text:match("^%-?%d+%.%d%d$"))
	if pawns then
		info.score = math.floor(pawns * 100 + (pawns < 0 and -0.5 or 0.5))
	end
	local function square(v)
		local file, rank = v // 10, v % 10
		if file <= 7 and rank >= 1 and rank <= 8 then
			return string.char(0x61 + file) .. rank
		end
	end
	local from, to = square(sp:read_u8(base)), square(sp:read_u8(base + 1))
	if from and to and from ~= to then
		info.pv = { from .. to }
	end
	return info
end
interface.info_every = 1 -- show_info only reads RAM

return interface
