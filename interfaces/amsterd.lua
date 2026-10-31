interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

interface.level = "2"
interface.cur_level = nil

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.get_module()
	return "Mephisto Amsterdam"
end

function interface.get_author()
	return "Richard Lang"
end

function interface.setdigit(n)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if     (n == 0) then send_input(":KEY.1", 0x80, 0.5)
	elseif (n == 1) then send_input(":KEY.1", 0x01, 0.5)
	elseif (n == 2) then send_input(":KEY.1", 0x02, 0.5)
	elseif (n == 3) then send_input(":KEY.1", 0x04, 0.5)
	elseif (n == 4) then send_input(":KEY.1", 0x08, 0.5)
	elseif (n == 5) then send_input(":KEY.1", 0x10, 0.5)
	elseif (n == 6) then send_input(":KEY.1", 0x20, 0.5)
	elseif (n == 7) then send_input(":KEY.0", 0x40, 0.5)
	elseif (n == 8) then send_input(":KEY.0", 0x80, 0.5)
	elseif (n == 9) then send_input(":KEY.1", 0x40, 0.5)
	end
	machine.video.throttled = throttled_state
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	interface.cur_level = interface.level
	local level = interface.level
	send_input(":KEY.0", 0x04, 0.5) -- LEV
	for i = 1, level:len() do
		local n = level:sub(i, i)
		if (n == " " or n == ":") then
			send_input(":KEY.0", 0x20, 0.5) -- ENT
		else
			interface.setdigit(tonumber(n))
		end
	end
	send_input(":KEY.0", 0x20, 0.5) -- ENT
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	sb_reset_board(":board:board")
	emu.wait(1)
	interface.cur_level = "2"
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
				local p = get_piece_id(x ,9 - y)
				if p ~= 0 then
					if p > 0 then
						interface.setdigit(0) -- White
					else
						interface.setdigit(9) -- Black
					end
					interface.setdigit(8 - math.abs(p))
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
		send_input(":KEY.0", 0x10, 0.5) -- CL
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game(on)
	if on then
		send_input(":KEY.0", 0x08, 0.5) -- MEM
	else
		send_input(":KEY.0", 0x10, 0.5) -- CL
	end
	emu.wait(0.5)
end

function interface.start_play(init)
	send_input(":KEY.0", 0x20, 1) -- ENT
end

function interface.is_selected(x, y)
	return output_value("led" .. (y - 1) * 8 + (x - 1)) ~= 0
end

function interface.select_piece(x, y, event)
	sb_select_piece(":board:board", 1, x, y, event)
end

function interface.get_options()
	return {
		{ "string", "Level", "2" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = value:match("^%s*(.-)%s*$"):gsub("%s%s+", " ") -- trim
		if (string.match(level, "^[0-69]$") or string.match(level, "^[78]%s%d%d:[0-5]%d:[0-5]%d$")) then
			interface.level = level
			interface.setlevel()
		end
	end
end

function interface.get_promotion(x, y)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":KEY.0", 0x01, 0.5) -- INFO
	send_input(":KEY.1", 0x01, 0.5) -- 1
	local d3 = 0
	for i = 0, 5 do
		local d0 = output_value("digit3") & 0x7f
		local d1 = output_value("digit2") & 0x7f
		if (d0 == 0x73 and d1 == 0x50) then -- display shows 'Pr'
			d3 = output_value("digit0") & 0x7f
			break
		end
		send_input(":KEY.1", 0x80, 0.5) -- 0
	end
	send_input(":KEY.0", 0x10, 0.5) -- CLR
	machine.video.throttled = throttled_state
	if     (d3 == 0x5e) then return "q"
	elseif (d3 == 0x31) then return "r"
	elseif (d3 == 0x38) then return "b"
	elseif (d3 == 0x6d) then return "n"
	end
	return nil
end

function interface.promote(x, y, piece)
	sb_promote(":board:board", x, y, piece)
	if     (piece == "q") then send_input(":KEY.1", 0x20, 1)
	elseif (piece == "r") then send_input(":KEY.1", 0x10, 1)
	elseif (piece == "b") then send_input(":KEY.1", 0x08, 1)
	elseif (piece == "n") then send_input(":KEY.1", 0x04, 1)
	end
	if (piece == "q" or piece == "r" or piece == "b" or piece == "n") then
		send_input(":KEY.0", 0x20, 1)
	end
end

-- the search information the INFO key shows is kept as text in RAM (found by the " SUM" in it): the main line
-- 0x3c bytes before it ("E7E5E2E4D7D6" up to 8 moves, "_" after the last), the evaluation in pawns for Mephisto
-- 0x1c before (" 0" "28": the point is bit 6 of the units digit; dallas/roma show at most "-9.99"), then after it the depth "M 03" (+0x0c), the move
-- searched "A 01" "E7E5" and the selective depth "S 12" (+0x18; amsterdg has no move there: +0x14); manual H.1-H.6
local ram_ranges = { amsterd = { 0xffc000, 0xffffff }, dallas16 = { 0xffc000, 0xffffff }, roma16 = { 0xffc000, 0xffffff },
	dallas32 = { 0x010000, 0x01ffff }, roma32 = { 0x010000, 0x01ffff },
	amsterdg = { 0x01c000, 0x01ffff }, dallas16g = { 0x01c000, 0x01ffff }, roma16g = { 0x01c000, 0x01ffff } } -- Glasgow hardware
local info_text = nil -- address of " SUM"
local stale = nil     -- the texts as the previous search left them

local function find_info_text()
	local sp = machine.devices[":maincpu"].spaces["program"]
	local r = ram_ranges[machine.system.name]
	if r == nil then
		return nil
	end
	for a = r[1], r[2] - 0x20 do
		if sp:read_u8(a) == 0x20 and sp:read_u8(a + 1) == 0x53 and sp:read_u8(a + 2) == 0x55 and sp:read_u8(a + 3) == 0x4d
			and sp:read_u8(a + 0x0c) == 0x4d then
			return a
		end
	end
	return nil
end

local function ram_text(offset, len)
	local sp = machine.devices[":maincpu"].spaces["program"]
	local t = ""
	for a = info_text + offset, info_text + offset + len - 1 do
		t = t .. string.char(sp:read_u8(a))
	end
	return t
end

function interface.show_info(on)
	if info_text == nil then
		info_text = find_info_text()
		if info_text == nil then
			return nil
		end
	end
	local texts = ram_text(-0x3c, 0x24) .. ram_text(0x0c, 0x10)
	if not on then
		stale = texts
		return nil
	end
	if texts == stale then
		return nil -- nothing from this search yet
	end
	stale = nil
	local info = {}
	local pv = {}
	local line = ram_text(-0x3c, 0x20)
	for k = 1, 29, 4 do
		local move = ""
		for c = k, k + 3 do
			-- dallas/roma add 0x40 to characters of the first move (display attribute: "G8F6" = 87 78 86 36)
			local ch = line:byte(c)
			local want = (c - k) % 2 == 0 and "[A-H]" or "[1-8]"
			if not string.char(ch):match(want) and ch >= 0x40 then
				ch = ch - 0x40
			end
			move = move .. string.char(ch)
		end
		move = move:lower()
		if not move:match("^[a-h][1-8][a-h][1-8]$") then
			break
		end
		pv[#pv + 1] = move
	end
	if #pv > 0 then
		info.pv = pv
	end
	local score = ram_text(-0x1c, 4)
	local sign, units, hundredths = score:sub(1, 1), score:byte(2), score:sub(3, 4)
	if units and units & 0x40 ~= 0 and hundredths:match("^%d%d$") and (sign == " " or sign == "-" or sign:match("%d")) then
		local pawns = (units & 0xbf) - 0x30
		if pawns >= 0 and pawns <= 9 then
			local cp = (tonumber(sign) or 0) * 1000 + pawns * 100 + tonumber(hundredths)
			info.score = sign == "-" and -cp or cp
		end
	end
	info.depth = tonumber(ram_text(0x0c, 4):match("^M ?(%d+)$"))
	info.seldepth = tonumber(ram_text(0x14, 8):match("^S ?(%d+)") or ram_text(0x14, 8):match("^....S ?(%d+)"))
	return info
end
interface.info_every = 1 -- show_info only reads RAM

return interface

