interface = {}
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

interface.level = 3
interface.cur_level = nil

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

-- show_info reads the search information from RAM, without key presses (an INFO press could land just as the move
-- appears and hide it). The program keeps the INFO pages as character codes (0-9 digits, 0x0a-0x11 a-h, 0x24 '-',
-- bit 7 = point; segments through the ROM table at 0x7f4b) and the search fills them as it goes: the main line at
-- 0x8314 (4 moves of 4 characters), the evaluation for the machine at 0x8328 (sign, pawns with point, 2 digits), the
-- depth at 0x837a and the selective depth at 0x837e (2 digits each). Found by read taps on the INFO keys.
local stale = nil
local first = true

function interface.show_info(on)
	local sp = machine.devices[":maincpu"].spaces["program"]
	local raw = {}
	for a = 0x8314, 0x832b do
		raw[#raw + 1] = sp:read_u8(a) & 0x7f
	end
	for a = 0x837a, 0x837f do
		raw[#raw + 1] = sp:read_u8(a) & 0x7f
	end
	local key = ""
	for _, c in ipairs(raw) do
		key = key .. string.char(c)
	end
	if not on or first then
		first = false -- battery RAM still holds the last search before this session's first player turn
		stale = key
		return nil
	end
	if key == stale then
		return nil -- nothing from this search yet
	end
	stale = nil
	local function char(c)
		if c <= 9 then
			return tostring(c)
		elseif c >= 0x0a and c <= 0x11 then
			return string.char(0x61 + c - 0x0a)
		end
	end
	local info = {}
	local pv = {}
	for k = 1, 13, 4 do
		local m = (char(raw[k]) or "?") .. (char(raw[k + 1]) or "?") .. (char(raw[k + 2]) or "?") .. (char(raw[k + 3]) or "?")
		if not m:match("^[a-h][1-8][a-h][1-8]$") then
			break
		end
		pv[#pv + 1] = m
	end
	if #pv > 0 then
		info.pv = pv
	end
	local function number(a, b)
		if a <= 9 and b <= 9 then
			return a * 10 + b
		end
	end
	local depth, seldepth = number(raw[25], raw[26]), number(raw[29], raw[30])
	local sign, pawns, d1, d2 = raw[21], raw[22], raw[23], raw[24]
	if pawns <= 9 and d1 <= 9 and d2 <= 9 then
		local cp = pawns * 100 + d1 * 10 + d2
		-- each search starts with ' 0.00' until its first iteration has a value
		if cp ~= 0 or (depth or 0) > 1 then
			info.score = sign == 0x24 and -cp or cp
		end
	end
	if depth and depth > 0 then
		info.depth = depth
		if seldepth and seldepth >= depth then
			info.seldepth = seldepth
		end
	end
	if not info.pv and not info.score then
		return nil
	end
	return info
end

interface.info_every = 1 -- show_info only reads RAM

return interface
