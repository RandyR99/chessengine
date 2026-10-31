interface = {}

interface.level = "NORMAL 0:10"
interface.cur_level = nil
interface.ignore_late_go = true -- replies on its own once the player's move is on the board
interface.levelnum = 1
interface.score = "0.00"
interface.depth = "0"
interface.pv = ""

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

-- Helper function to read a specific range of characters from DDRAM
local function read_lcd_range(start_idx, end_idx)
    local dev = machine.devices[':display:hd44780']
    if not dev then return "" end
    
    local state_item = dev.items["0/m_ddram"]
    if not state_item then return "" end
    
    local wrapped_mem = emu.item(state_item)
    local str = ""
    for i = start_idx, end_idx do
        str = str .. string.char(wrapped_mem:read(i))
    end
    return str
end

function interface.get_module()
	if machine.system.name == "polgar" then
		return "Mephisto Polgar"
	elseif machine.system.name == "polgara" then
		return "Mephisto Polgar v2"
	elseif machine.system.name == "polgar101" then
		return "Mephisto Polgar v10.1"
	elseif machine.system.name == "polgar10" then
		return "Mephisto Polgar v10.0"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Ed Schröder"
end

function setdigits(n, r, s)
	send_input(":KEY", 0x40, 0.25) -- ENT
	for i = 1, n do
		if (n == 3 and i == 2) then
			r = r + 1
			s = s + 1
		end
		
		-- Updated to use helper function for single-character lookup matching the exact offset loop logic
		while (read_lcd_range(0x40 + r + i - 1, 0x40 + r + i - 1) ~= interface.level:sub(s + i - 1, s + i - 1)) do
			if     (i == 1) then send_input(":KEY", 0x01, 0.25) -- TRN
			elseif (i == 2) then send_input(":KEY", 0x02, 0.25) -- INFO
			elseif (i == 3) then send_input(":KEY", 0x04, 0.25) -- MEM
			elseif (i == 4) then send_input(":KEY", 0x08, 0.25) -- POS
			end
		end
	end
	send_input(":KEY", 0x80, 0.25) -- CL
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level or interface.levelnum == 0) then
		return
	end
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":KEY", 0x10, 0.5) -- LEV
	emu.wait(0.5)
	
	-- Updated to use helper function (reads 16 bytes starting at 0x40)
	local ddram = read_lcd_range(0x40, 0x4F)
	
	local temp = string.upper(ddram:sub(1,5))
	local n = 0
	if     (temp == " NORM" or temp == "NORMA") then n = 1
	elseif (temp == "TURN " or temp == "TOUR ") then n = 2
	elseif (temp == "BLITZ") then n = 3
	elseif (temp == "RECHE" or string.match(temp,"PLY[%-%s]D")) then n = 4
	elseif (temp == "MATT " or temp == "MATE ") then n = 5
	elseif (string.match(temp,"ELO[%-%s]T")) then n = 6
	elseif (string.match(temp,"ELO[%-%s]A")) then n = 7
	elseif (string.match(temp,"-- %u%u")) then n = 8
	else
		send_input(":KEY", 0x80, 0.5) -- CL
		return
	end
	interface.cur_level = interface.level
	n = (interface.levelnum - n + 8) % 8
	for i = 1, n do
		send_input(":KEY", 0x10, 0.25) -- LEV
	end
	local s = 0
	if (interface.levelnum == 1) then
		s = string.find(interface.level,"%d:[0-5]%d")
		setdigits(3,12,s)
	elseif (interface.levelnum == 2) then
		s = string.find(interface.level,"%d%d")
		setdigits(2,5,s)
		s = string.find(interface.level,"%d:[0-5]%d",s+1)
		setdigits(3,12,s)
	elseif (interface.levelnum == 3) then
		s = string.find(interface.level,"%d:[0-5]%d")
		setdigits(3,7,s)
		s = string.find(interface.level,"%d:[0-5]%d",s+1)
		setdigits(3,12,s)
	elseif (interface.levelnum == 4) then
		s = string.find(interface.level,"%d%d")
		setdigits(2,12,s)
	elseif (interface.levelnum == 5) then
		s = string.find(interface.level,"[1-8]")
		setdigits(1,8,s)
	elseif (interface.levelnum == 6) then
		s = string.find(interface.level,"%d%d%d%d")
		setdigits(4,12,s)
	elseif (interface.levelnum == 7) then
		s = string.find(interface.level,"%d%d%d%d")
		setdigits(4,12,s)
	elseif (interface.levelnum == 8) then
		-- nothing to do
	end
	send_input(":KEY", 0x80, 0.5) -- CL
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	sb_reset_board(":board:board")
	emu.wait(1)
	interface.cur_level = ""
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":KEY", 0x08, 0.5) -- POS
		send_input(":KEY", 0x40, 0.5) -- ENT
		machine.video.throttled = throttled_state
		return (":board:board")
	else
		local piece = 3
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if math.abs(p) ~= math.abs(piece) then
						send_input(":KEY", 0x01 << (6 - math.abs(p)), 0.5)
					end
					if p * piece < 0 then
						send_input(":KEY", 0x01 << (6 - math.abs(p)), 0.5)
					end
					sb_press_square(":board:board", 0.5, x, 9 - y)
					piece = p
				end
			end
		end
		if mode * piece < 0 then
			send_input(":KEY", 0x01 << (6 - math.abs(piece)), 0.5)
		end
		send_input(":KEY", 0x80, 0.5) -- CL
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game(on)
	if on then
		send_input(":KEY", 0x04, 0.5) -- MEM
	else
		send_input(":KEY", 0x80, 0.5) -- CL
	end
	emu.wait(0.5)
end

function interface.start_play(init)
	send_input(":KEY", 0x40, 1)
end

-- the machine's move as shown in the upper LCD row (' E4-D3'), nil if it shows something else
local function display_move()
	local row = read_lcd_range(0x00, 0x0f)
	local f, r1, t, r2 = row:match("^ ([A-H])([1-8])[-x:]([A-H])([1-8])%s*$")
	if f then
		return f:byte() - 64, tonumber(r1), t:byte() - 64, tonumber(r2)
	end
	return nil
end

function interface.is_selected(x, y)
	-- the 10 MHz versions light the captured pawn instead of the from-square for their own en passant; the display shows the move
	local fx, fy, tx, ty = display_move()
	if fx and get_piece_id(fx, fy) ~= 0 then -- an empty from-square = the move is already made (or the player's move is still shown)
		return (x == fx and y == fy) or (x == tx and y == ty)
	end
	return output_value("led" .. ((y - 1) * 8 + (x - 1))) ~= 0
end

function interface.select_piece(x, y, event)
	sb_select_piece(":board:board", 1, x, y, event)
end

function interface.get_options()
	return {
		{ "string", "Level", "NORMAL 0:10" },
	}
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		value=value:match("^%s*(.-)%s*$"):gsub("%s%s+"," ") -- trim
		local temp = string.upper(value)
		interface.levelnum = 0
		if ((string.match(temp,"NORMAL%s+%d:[0-5]%d")) or (string.match(temp,"NORMAL%s+TIME%s+%d:[0-5]%d"))) then
			interface.levelnum = 1
		elseif ((string.match(temp,"TURN%s+%d%d%s+IN%s+%d:[0-5]%d")) or (string.match(temp,"TOUR%s+%d%d%s+IN%s+%d:[0-5]%d"))) then
			interface.levelnum = 2
		elseif (string.match(temp,"BLITZ%s+%d:[0-5]%d%s+%d:[0-5]%d")) then
			interface.levelnum = 3
		elseif ((string.match(temp,"RECHENTIEFE%s+%d%d?")) or (string.match(temp,"PLY[%-%s]DEPTH%s+%d%d?"))) then
			if (string.match(temp," %d%d") == nil) then
				local s = string.find(temp," %d")
				value = value:sub(1,s) .. "0" .. value:sub(s+1,s+1)
			end
			interface.levelnum = 4
		elseif ((string.match(temp,"MATT%s+IN%s+[1-8]")) or (string.match(temp,"MATE%s+IN%s+[1-8]"))) then
			interface.levelnum = 5
		elseif ((string.match(temp,"ELO[%-%s]TURNIER%s+%d%d%d%d")) or (string.match(temp,"ELO[%-%s]TOUR%s+%d%d%d%d"))) then
			interface.levelnum = 6
		elseif ((string.match(temp,"ELO[%-%s]AKTIV%s+%d%d%d%d")) or (string.match(temp,"ELO[%-%s]ACTIVE%s+%d%d%d%d"))) then
			interface.levelnum = 7
		elseif ((string.match(temp,"ANALYSE")) or (string.match(temp,"INFINITE")) or (string.match(temp,"UNBEGRENZT")) or (string.match(temp,"UNENDLICH"))) then
			interface.levelnum = 8
		end
		if (interface.levelnum ~= 0) then
			interface.level = value
			interface.setlevel()
		end
	end
end

function interface.get_promotion(x, y)
	-- Updated to use helper function (reads 0x80 total bytes starting from 0x00, mapping index 0x00 to 0x7F)
	local ddram = read_lcd_range(0x00, 0x7F)
	if     (ddram:sub(65,81):find('\x04') or ddram:sub(65,81):find('\x0c')) then return 'q'
	elseif (ddram:sub(65,81):find('\x03') or ddram:sub(65,81):find('\x0b')) then return 'r'
	elseif (ddram:sub(65,81):find('\x02') or ddram:sub(65,81):find('\x0a')) then return 'b'
	elseif (ddram:sub(65,81):find('\x01') or ddram:sub(65,81):find('\x09')) then return 'n'
	end
	return nil
end

function interface.promote(x, y, piece)
	sb_promote(":board:board", x, y, piece)
	emu.wait(1)
	if     (piece == "q") then send_input(":KEY", 0x10, 1)
	elseif (piece == "r") then send_input(":KEY", 0x08, 1)
	elseif (piece == "b") then send_input(":KEY", 0x04, 1)
	elseif (piece == "n") then send_input(":KEY", 0x02, 1)
	end
end

-- the main line in RAM like on mega4 (same list of square pairs, at 0x013e) and the evaluation as text after it,
-- read without key presses
local mega4 = load_interface("mega4")
mega4.pv_ram = 0x013e
mega4.score_ram = nil
mega4.score_text_ram = 0x0148 -- the evaluation for the machine as text ("-8.95")
mega4.depth_ram = nil -- not found
interface.show_info = mega4.show_info
interface.info_every = 1 -- show_info only reads RAM

return interface

