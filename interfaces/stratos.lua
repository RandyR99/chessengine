interface = {}

-- read len bytes of a memory share (battery RAM) as a string
local function ram_block(tag, offset, len)
	local share = machine.memory.shares[tag]
	local s = ""
	for i = 0, len - 1 do
		s = s .. string.char(share:read_u8(offset + i))
	end
	return s
end

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

interface.invert = false
interface.new_game_pending = false
interface.level = "a1"
interface.cur_level = nil
interface.pv_depth = 0
interface.pv = ""
interface.score = "0"
interface.depth = "1"
interface.last_pv = ""

function interface.get_module()
	if machine.system.name == "stratos" then
		return "SciSys Stratos"
	elseif machine.system.name == "stratosa" then
		return "SciSys Stratos v2"
	elseif machine.system.name == "tking" then
		return "SciSys Turbo King"
	elseif machine.system.name == "tkinga" then
		return "SciSys Turbo King v2"
	elseif machine.system.name == "tkingb" then
		return "SciSys Turbo King v3"
	else
		return machine.system.description
	end
end

function interface.get_author()
	return "Julio Kaplan & Craig Barnes"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local cols_idx = { a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8 }
	local x = cols_idx[interface.level:sub(1,1)]
	local y = tonumber(interface.level:sub(2,2))
	send_input(":IN.0", 0x02, 1) -- Level
	emu.wait(0.5)
	local invert = interface.invert
	interface.invert = false
	local clevx = 0
	local clevy = 0
	for cx = 1, 8 do
		for cy = 1, 8 do
			if (interface.is_selected(cx, cy)) then
				clevx = cx
				clevy = cy
				cx = 8
				cy = 8
			end
		end
	end
	if (clevx > 0 and clevy > 0) and (clevx ~= x or clevy ~= y) then
		local dlev = (x * 8 + y) - (clevx * 8 + clevy)
		local dx = (x - clevx + 8) % 8
		local dy = y - clevy
		if (dlev >= -7 and dlev <= 4) then
			dx = 0
			dy = dlev
		end
		for i = 1, dx do
			send_input(":IN.4", 0x02, 1) -- Tab
		end
		for i = 1, math.abs(dy) do
			if (dy > 0) then
				send_input(":IN.5", 0x01, 1) -- +
			else
				send_input(":IN.4", 0x04, 1) -- -
			end
		end
	end
	interface.invert = invert
	emu.wait(0.5)
	send_input(":IN.7", 0x04, 1) -- Normal
	emu.wait(0.5)
	machine.video.throttled = throttled_state
	interface.select_info_display()
end

-- the battery RAM is saved without a STOP when MAME quits, and a stale or empty one leaves
-- the machine unresponsive: force a cold boot (driver notes: hold PLAY while powering on)
function interface.cold_boot()
	emu.wait(1)
	send_input(":IN.1", 0x02, 1) -- Stop
	local play = machine.ioport.ports[":IN.4"]:field(0x01)
	play:set_value(1) -- hold Play
	send_input(":RESET", 0x01, 1) -- Go
	emu.wait(2)
	play:set_value(0)
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	interface.cold_boot()
	sb_reset_board(":board")
	interface.invert = false
	emu.wait(3)
	send_input(":IN.1", 0x04, 1)	-- New Game
	emu.wait(1)
	machine.video.throttled = throttled_state
	interface.cur_level = "a1"
	interface.setlevel()
end

function setpiece(n)
	if     (n == 1) then send_input(":IN.3", 0x04, 1) -- K
	elseif (n == 2) then send_input(":IN.3", 0x01, 1) -- Q
	elseif (n == 3) then send_input(":IN.2", 0x01, 1) -- R
	elseif (n == 4) then send_input(":IN.2", 0x04, 1) -- B
	elseif (n == 5) then send_input(":IN.3", 0x02, 1) -- N
	elseif (n == 6) then send_input(":IN.2", 0x02, 1) -- P
	end
end

local function is_start_position()
	local back = {3, 5, 4, 2, 1, 4, 5, 3}
	for x = 1, 8 do
		if get_piece_id(x, 1) ~= back[x] or get_piece_id(x, 2) ~= 6 or
		   get_piece_id(x, 7) ~= -6 or get_piece_id(x, 8) ~= -back[x] then
			return false
		end
		for y = 3, 6 do
			if get_piece_id(x, y) ~= 0 then
				return false
			end
		end
	end
	return true
end

-- a short NORMAL press is sometimes missed and the machine stays in setup mode
-- (the last square stays lit): repeat until the board leds are off
local function leave_setup()
	for i = 1, 5 do
		send_input(":IN.7", 0x04, 1) -- NORMAL
		emu.wait(0.5)
		local lit = false
		for x = 1, 8 do
			for y = 1, 8 do
				if interface.is_selected(x, y) then -- the machine's own board leds (corona differs)
					lit = true
				end
			end
		end
		if not lit then
			return
		end
	end
end

-- short key presses during setup get dropped: all presses here last 1 s
function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.0", 0x01, 1) -- SET UP
		emu.wait(0.5)
		send_input(":IN.1", 0x01, 1) -- SOUND
		emu.wait(0.5)
		send_input(":IN.5", 0x02, 1) -- FUNCTION
		send_input(":IN.1", 0x04, 1) -- NEW GAME
		return (":board")
	elseif mode == 1 and is_start_position() then
		-- a set-up start position is taken as a new game by some versions (they then play white
		-- from the reversed board): use New Game, and let Play rotate as in a new game
		send_input(":IN.1", 0x01, 1) -- SOUND
		emu.wait(0.5)
		leave_setup()
		send_input(":IN.1", 0x04, 1) -- NEW GAME
		emu.wait(1)
		interface.new_game_pending = true
	else
		local piece = 7
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if p * piece < 0 then
						send_input(":IN.4", 0x02, 1) -- TAB/COLOR
					end
					setpiece(math.abs(p))
					sb_press_square(":board", 1, x, 9 - y)
					piece = p
				end
			end
		end
		if mode * piece < 0 then
			send_input(":IN.4", 0x02, 1) -- TAB/COLOR
		end
		emu.wait(0.5)
		send_input(":IN.1", 0x01, 1) -- SOUND
		emu.wait(0.5)
		leave_setup()
	end
end

function interface.edit_game(on)
	if on then
		send_input(":IN.7", 0x02, 1) -- Analysis
	else
		send_input(":IN.7", 0x04, 1) -- Normal
	end
	emu.wait(0.5)
end

function interface.start_play(init)
	if (init or interface.new_game_pending) then
		interface.new_game_pending = false
		sb_rotate_board(":board")
		interface.invert = true
	end
	interface.select_info_display()
	send_input(":IN.4", 0x01, 1)	-- Play
end

function interface.is_selected(x, y)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	local xval0 = output_value("4." .. (x - 1)) ~= 0
	local xval1 = output_value("5." .. (x - 1)) ~= 0
	local yval0 = output_value("2." .. (y - 1)) ~= 0
	local yval1 = output_value("3." .. (y - 1)) ~= 0
	return (xval0 or xval1) and (yval0 or yval1)
end

function interface.select_piece(x, y, event)
	interface.new_game_pending = false -- the player moves first: no board rotation
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	sb_select_piece(":board", 1, x, y, event)
end

function interface.get_options()
	return {
		{ "string", "Level", "a1" },
	}
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		interface.level = value:lower():match("^%s*(.-)%s*$"):gsub("%s%s+"," ") -- trim
		interface.setlevel()
	end
end

function interface.get_promotion(x, y)
	if     (output_value("0.6") ~= 0 or output_value("1.6") ~= 0) then return 'q'
	elseif (output_value("0.5") ~= 0 or output_value("1.5") ~= 0) then return 'r'
	elseif (output_value("0.4") ~= 0 or output_value("1.4") ~= 0) then return 'b'
	elseif (output_value("0.3") ~= 0 or output_value("1.3") ~= 0) then return 'n'
	end
	return nil
end

function interface.promote_special(piece)
	if interface.get_promotion(x, y) ~= nil then
		return
	end
	if     (piece=="q") then send_input(":IN.3", 0x01, 1)
	elseif (piece=="r") then send_input(":IN.2", 0x01, 1)
	elseif (piece=="b") then send_input(":IN.2", 0x04, 1)
	elseif (piece=="n") then send_input(":IN.3", 0x02, 1)
	end
end

function interface.promote(x, y, piece)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	sb_promote(":board", x, y, piece)
end

function interface.select_info_display()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.7", 0x04, 1) -- Normal
	send_input(":IN.5", 0x02, 0.75) -- Function
	send_input(":IN.6", 0x02, 0.75) -- info
	send_input(":IN.5", 0x02, 0.75) -- Function
	send_input(":IN.6", 0x02, 0.75) -- info
	machine.video.throttled = throttled_state
end

function interface.show_info(on, color)
	if on == true then
		local info = interface.read_digit(1)
		if (info:sub(2,2)) ~= "P" then
			if (info:sub(2,3)) == "nf" then
				interface.pv = interface.read_digit(2)
				interface.depth = info:sub(4,5)
				interface.pv_depth = 1
			elseif (info:sub(2,3)) == "5c" then
				interface.score = interface.read_7_7_segment() .. interface.read_digit(2)
				if color == "B" then
				    if tonumber(interface.score) ~= nil then
				        interface.score = tonumber(interface.score) * (-1)
				    end
				end
			elseif tonumber(interface.read_7_7_segment()) == (interface.pv_depth + 1) then
				interface.pv_depth = interface.pv_depth + 1
				interface.pv = interface.pv .. " " .. interface.read_digit(2)
			end
			if interface.pv == "____" then
				interface.pv = "book"
			end
			if string.match(interface.last_pv, "^" .. interface.pv) == nil then
				interface.last_pv = interface.pv
			end
			return "info score cp " .. interface.score .. " depth " .. interface.depth .. " pv " .. interface.last_pv
		end
	end
end

function interface.read_7_7_segment()
	local digit = {
		[43] = "+",
		[49] = "1",
		[50] = "2",
		[51] = "3",
		[52] = "4",
		[53] = "5",
		[54] = "6",
		[55] = "7",
		[56] = "8",
		[57] = "9",
		[59] = "-"
	}
	local ddram = ram_block(":nvram.u6", 0x0962, 0x2)
	return digit[ddram:byte(1)]
end

function interface.read_digit(line)
	local digit = {
		[1] = " ",
		[7] = "1",
		[8] = "7",
		[9] = "_",
		[18] = "i",
		[17] = " ",
		[21] = ":",
		[29] = "u",
		[57] = "l",
		[58] = "C",
		[62] = "g",
		[64] = "0",
		[65] = "-",
		[80] = "3",
		[81] = "r",
		[85] = "n",
		[89] = "c",
		[92] = "2",
		[93] = "o",
		[95] = "d",
		[103] = "4",
		[110] = "5",
		[111] = "y",
		[114] = "f",
		[116] = "P",
		[117] = "h",
		[120] = "a",
		[121] = "t",
		[122] = "e",
		[125] = "b",
		[126] = "6",
		[128] = "8",
		[112] = "9"
	}
	local info2 = ""
	local ddram = ram_block(":nvram.u6", 0x095d, 0x10)
	local info = digit[ddram:byte(1) + 1] .. digit[ddram:byte(2) + 1] .. digit[ddram:byte(3) + 1] .. digit[ddram:byte(4) + 1] .. digit[ddram:byte(5) + 1]
	ddram = ram_block(":nvram.u6", 0x0963, 0x10)
	info2 = digit[ddram:byte(2) + 1] .. digit[ddram:byte(3) + 1] .. digit[ddram:byte(4) + 1] .. digit[ddram:byte(5) + 1]
	if line == 1 then
		return info
	elseif line == 2 then
		return info2
	end
	return info
end

return interface
