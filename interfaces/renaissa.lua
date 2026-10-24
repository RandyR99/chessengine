interface = {}

local module = 0
interface.opt_clear_announcements = true
interface.invert = false
interface.level = "a3"
interface.cur_level = nil

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

local function ram_block(tag, offset, len)
	local share = machine.memory.shares[tag]
	local s = ""
	for i = 0, len - 1 do
		s = s .. string.char(share:read_u8(offset + i))
	end
	return s
end

function calc_module()
    local mod = 0
    if machine.devices[":exp:analyst"] then
        mod = 6
    elseif machine.devices[":exp:maestro"] then
        mod = 19
    elseif machine.devices[":exp:maestroa"] then
        mod = 11
    elseif machine.devices[":exp:sparc"] then
        mod = 31
    end
    return mod
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local cols_idx = { a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8 }
	local x = cols_idx[interface.level:sub(1, 1)]
	local y = tonumber(interface.level:sub(2, 2))
	local maxx = 4
	local minl = -5
	if (module >= 31) then
		maxx = 8
		minl = -7
	elseif (module >= 1) then
		maxx = 7
		minl = -7
	end
	send_input(":IN.5", 0x04, 1)  -- Level
	emu.wait(0.5)

	local clevx = 0
	local clevy = 0
	for cx=1,maxx do
		for cy=1,8 do
			local led0 = output_value(tostring(cx-1) .. "." .. tostring(cy-1)) ~= 0
			local led3 = output_value(tostring(cx) .. "." .. tostring(cy)) ~= 0
			if (led0 and led3) then
				clevx = cx
				clevy = cy
				cx = maxx
				cy = 8
			end
		end
	end
	if (clevx > 0 and clevy > 0) and (clevx ~= x or clevy ~= y) then
		local dlev = (x * 8 + y) - (clevx * 8 + clevy)
		local dx = (x - clevx + maxx) % maxx
		local dy = y - clevy
		if (dlev >= minl and dlev <= 4) then
			dx = 0
			dy = dlev
		end
		for i=1,dx do
			send_input(":IN.2", 0x02, 0.6) -- Tab
		end
		for i=1,math.abs(dy) do
			if (dy > 0) then
				send_input(":IN.2", 0x04, 0.6) -- +
			else
				send_input(":IN.6", 0x01, 0.6) -- -
			end
		end
	end

	emu.wait(0.5)
	send_input(":IN.6", 0x02, 1) -- Normal
end

function interface.setup_machine()
    module = calc_module()
    
    if (module ~= 0) then
        interface.level = "e1"
    end
	sb_reset_board(":board")
	interface.invert = false
	emu.wait(8)
	send_input(":IN.7", 0x02, 1)	-- New Game
	emu.wait(1.5)

	interface.cur_level = "a3"
	interface.setlevel()
end

function setpiece(n)
	if     (n == 1) then send_input(":IN.0", 0x01, 0.5) -- K
	elseif (n == 2) then send_input(":IN.1", 0x01, 0.5) -- Q
	elseif (n == 3) then send_input(":IN.0", 0x02, 0.5) -- R
	elseif (n == 4) then send_input(":IN.1", 0x02, 0.5) -- B
	elseif (n == 5) then send_input(":IN.0", 0x04, 0.5) -- N
	elseif (n == 6) then send_input(":IN.1", 0x04, 0.5) -- P
	end
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.3", 0x04, 0.5) -- SOUND
		emu.wait(0.5)
		-- SET UP before the plugin rebuilds the board: in normal mode the machine watches the
		-- squares fill up, and "start position + one white move" makes it reverse the board
		send_input(":IN.7", 0x04, 0.5) -- SET UP
		return (":board")
	else
		send_input(":IN.3", 0x02, 0.5) -- FUNCTION
		send_input(":IN.7", 0x02, 0.5) -- NEW GAME
		local piece=7
		for y=1,8 do
			for x=1,8 do
				local p=get_piece_id(x,9-y)
				if p~=0 then
					if p*piece<0 then
						send_input(":IN.2", 0x02, 0.5) -- TAB/COLOR
					end
					setpiece(math.abs(p))
					sb_press_square(":board", 0.5, x, 9-y)
					piece=p
				end
			end
		end
		if mode*piece<0 then
			send_input(":IN.2", 0x02, 0.5) -- TAB/COLOR
		end
		send_input(":IN.3", 0x04, 0.5) -- SOUND
		emu.wait(0.5)
		send_input(":IN.6", 0x02, 0.5) -- NORMAL
	end
end

function interface.edit_game(on)
	if on then
		send_input(":IN.6", 0x04, 1) -- Analysis
	else
		send_input(":IN.6", 0x02, 1) -- Normal
	end
	emu.wait(0.5)
end

function interface.start_play(init)
	if (init) then
		sb_rotate_board(":board")
		interface.invert = true
	end
	send_input(":IN.5", 0x02, 1)	-- Play
end

function interface.stop_play()
	send_input(":IN.5", 0x02, 1)	-- Play
end

function getdigit(n)
	local map = { 13, 15, 18, 12, 17, 14, 16 }
	local digit = 0x00
	for i=1,7 do
		digit = digit | (output_value("s" .. (8-n) .. "." .. map[i]) << (i-1))
	end
	return digit
end

function interface.is_selected(x, y)
	local xval = { 0x77, 0x7c, 0x58, 0x5e, 0x79, 0x71, 0x3d, 0x74 }
	local yval = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f }
	local d1 = getdigit(1)
	local d2 = getdigit(2)
	local d3 = getdigit(3)
	local d4 = getdigit(4)
	if (d1 == 0x04 and interface.opt_clear_announcements) then
		emu.wait(1.5)
		send_input(":IN.6", 0x02, 1) -- Normal
		return false
	end
	if (d2 == 0x3f and d3 == 0x40 and d4 == 0x3f) then
		if (d1 == 0x40) then
			d1 = 0x79
			d3 = 0x58
		else
			d1 = 0x79
			d3 = 0x3d
		end
		if (output_value("9.1") ~= 0) then
			d2 = 0x7f
			d4 = 0x7f
		else
			d2 = 0x06
			d4 = 0x06
		end
	end
	return (xval[x] == d1 and yval[y] == d2) or (xval[x] == d3 and yval[y] == d4)
end

function interface.select_piece(x, y, event)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	sb_select_piece(":board", 1, x, y, event)
end

function interface.get_options()
	if (module ~= 0) then
		return { { "string", "Level", "e1"}, { "check", "Clear announcements", "1"}, }
	else
		return { { "string", "Level", "a3"}, { "check", "Clear announcements", "1"}, }
	end
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		local level = value:match("^%s*(.-)%s*$"):gsub("%s%s+"," "):lower() -- trim
		local tmp = "[a-d][1-8]"
		if (module >= 31) then
			tmp = "[a-h][1-8]"
		elseif (module >= 1) then
			tmp = "[a-g][1-8]"
		end
		if (level:match(tmp)) then
			interface.level = level
			interface.setlevel()
		end
	end
	if (name == "clear announcements") then
		interface.opt_clear_announcements = tonumber(value) == 1
	end
end

function getpiece()
	local piece = 0x00
	for i=1,7 do
		if (output_value("s" .. (i+8) .. ".12") ~= 0) then
			piece = piece | (1 << (i-1))
		end
	end
	return piece
end

function interface.get_promotion(x, y)
	local piece = getpiece()
	if     (piece == 0x3e) then return 'q'
	elseif (piece == 0x3f) then return 'r'
	elseif (piece == 0x36) then return 'b'
	elseif (piece == 0x7c) then return 'n'
	end
	return nil
end

function interface.promote_special(piece)
	if     (piece == "q") then send_input(":IN.1", 0x01, 1)
	elseif (piece == "r") then send_input(":IN.0", 0x02, 1)
	elseif (piece == "b") then send_input(":IN.1", 0x02, 1)
	elseif (piece == "n") then send_input(":IN.0", 0x04, 1)
	end
end

function interface.promote(x, y, piece)
	if interface.invert then
		x = 9 - x
		y = 9 - y
	end
	sb_promote(":board", x, y, piece)
end

function interface.show_info(on)
    if on then
        local ddram = ram_block(":nvram", 0x0b3f, 0x10)
        if digit_ascii(ddram:byte(1)) ~= " " and digit_ascii(ddram:byte(1)) ~= "-" and digit_ascii(ddram:byte(1)) ~= "P" then
            interface.score = digit_ascii(ddram:byte(11)) .. digit_ascii(ddram:byte(12)) .. digit_ascii(ddram:byte(14)) .. digit_ascii(ddram:byte(15)):gsub(" ", "")
            interface.depth = digit_ascii(ddram:byte(0)) .. digit_ascii(ddram:byte(1)):gsub(" ", "")
            interface.pv = digit_ascii(ddram:byte(3)) .. digit_ascii(ddram:byte(4)) .. digit_ascii(ddram:byte(6)) .. digit_ascii(ddram:byte(7))
        end
        return "info score cp " .. interface.score .. " depth " .. interface.depth .. " pv " .. interface.pv
    end
end


return interface
