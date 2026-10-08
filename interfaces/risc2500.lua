interface = {}

interface.level = "010 sec/move"
interface.cur_level = nil
interface.levelnum = 1
interface.style = "normal"
interface.cur_style = nil
interface.stylenum = 3

function setdigits(n)
	local dram = emu.item(machine.devices[':ram'].items['0/m_pointer'])
	send_input(":IN.1", 0x80, 0.2) -- Enter
	for i=1,n do
		if (n == 7 and (i == 3 or i == 5)) then
			-- skip char
		else
			local k = tonumber(interface.level:sub(i,i)) - (dram:read(0xeb1+i)-0x30)
			if (n == 7 and i == 6) then
				if (k > 3) then
					k = k - 6
				elseif (k < -3) then
					k = k + 6
				end
			else
				if (k > 5) then
					k = k - 10
				elseif (k < -5) then
					k = k + 10
				end
			end
			for j=1,math.abs(k) do
				if (k > 0) then
					send_input(":IN.3", 0x80, 0.2) -- Up
				else
					send_input(":IN.2", 0x80, 0.2) -- Down
				end
			end
			if (i < n) then
				send_input(":IN.6", 0x40, 0.2) -- Right
			end
		end
	end
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level or interface.levelnum == 0) then
		return
	end
	send_input(":IN.4", 0x80, 0.2) -- Menu
	send_input(":IN.2", 0x80, 0.2) -- Down
	send_input(":IN.2", 0x80, 0.2) -- Down
	send_input(":IN.1", 0x80, 0.2) -- Enter
	send_input(":IN.1", 0x80, 0.2) -- Enter
	local dram = emu.item(machine.devices[':ram'].items['0/m_pointer'])
	local s = ""
	local b = 0
	local i = 1
	repeat
		b = dram:read(0xec1 + i)
		if (b ~= 0x00) then
			s = s .. string.char(b)
			i = i + 1
		end
	until (b == 0x00)
	local curnum = 0
	if     (string.match(s,"sec/move") or string.match(s,"Sek/Zug")) then curnum = 1
	elseif (string.match(s,"moves/hrs") or string.match(s,"Z.ge/Std")) then curnum = 2
	elseif (string.match(s,"min/game") or string.match(s,"Min/Partie")) then curnum = 3
	elseif (string.match(s,"ply") or string.match(s,"Halbzug")) then curnum = 4
	elseif (string.match(s,"mate") or string.match(s,"Matt")) then curnum = 5
	elseif (string.match(s,"analysis") or string.match(s,"Analyse")) then curnum = 6
	end
	if (curnum == 0) then
		send_input(":IN.4", 0x80, 0.2) -- Menu
		return
	end
	interface.cur_level = interface.level
	local k = interface.levelnum - curnum
	if (k > 3) then
		k = k - 6
	elseif (k < -3) then
		k = k + 6
	end
	for i=1,math.abs(k) do
		if (k > 0) then
			send_input(":IN.2", 0x80, 0.2) -- Down
		else
			send_input(":IN.3", 0x80, 0.2) -- Up
		end
	end
	if     (interface.levelnum == 1) then setdigits(3)
	elseif (interface.levelnum == 2) then setdigits(7)
	elseif (interface.levelnum == 3) then setdigits(2)
	elseif (interface.levelnum == 4) then setdigits(2)
	elseif (interface.levelnum == 5) then setdigits(2)
	elseif (interface.levelnum == 6) then -- nothing to do
	end
	send_input(":IN.1", 0x80, 0.2) -- Enter
	send_input(":IN.4", 0x80, 0.2) -- Menu
end

function interface.setstyle()
	if (interface.cur_style == nil or interface.cur_style == interface.style or interface.stylenum == 0) then
		return
	end
	send_input(":IN.4", 0x80, 0.2) -- Menu
	send_input(":IN.2", 0x80, 0.2) -- Down
	send_input(":IN.1", 0x80, 0.2) -- Enter
	send_input(":IN.2", 0x80, 0.2) -- Down
	send_input(":IN.2", 0x80, 0.2) -- Down
	send_input(":IN.1", 0x80, 0.2) -- Enter
	local dram = emu.item(machine.devices[':ram'].items['0/m_pointer'])
	local s = ""
	local b = 0
	local i = 1
	repeat
		b = dram:read(0xec1 + i)
		if (b ~= 0x00) then
			s = s .. string.char(b)
			i = i + 1
		end
	until (b == 0x00)
	local curnum = 0
	if     (string.match(s,"defensive") or string.match(s,"Defensive")) then curnum = 1
	elseif (string.match(s,"solid") or string.match(s,"Solid")) then curnum = 2
	elseif (string.match(s,"normal") or string.match(s,"Normal")) then curnum = 3
	elseif (string.match(s,"active") or string.match(s,"Aktiv")) then curnum = 4
	elseif (string.match(s,"offensive") or string.match(s,"Offensiv")) then curnum = 5
	end
	if (curnum == 0) then
		send_input(":IN.4", 0x80, 0.2) -- Menu
		return
	end
	interface.cur_style = interface.style
	local k = interface.stylenum - curnum
	if (k > 2) then
		k = k - 5
	elseif (k < -2) then
		k = k + 5
	end
	for i=1,math.abs(k) do
		if (k > 0) then
			send_input(":IN.2", 0x80, 0.2) -- Down
		else
			send_input(":IN.3", 0x80, 0.2) -- Up
		end
	end
	send_input(":IN.1", 0x80, 0.2) -- Enter
	send_input(":IN.4", 0x80, 0.2) -- Menu
end

function interface.setup_machine()
	sb_reset_board(":board")
	emu.wait(10) -- boot time

	interface.cur_level = ""
	interface.setlevel()
	emu.wait(0.25)
	interface.cur_style = ""
	interface.setstyle()
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.4", 0x80, 0.2) -- Menu
		send_input(":IN.2", 0x80, 0.2) -- Down
		send_input(":IN.2", 0x80, 0.2) -- Down
		send_input(":IN.2", 0x80, 0.2) -- Down
		send_input(":IN.1", 0x80, 0.2) -- Enter
		send_input(":IN.2", 0x80, 0.2) -- Down
		send_input(":IN.1", 0x80, 0.2) -- Enter
		send_input(":IN.6", 0x80, 0.2) -- New Game
		send_input(":IN.1", 0x80, 0.2) -- Enter
		return (":board")
	else
		local piece=7
		for y=1,8 do
			for x=1,8 do
				local p=get_piece_id(x,9-y)
				if p~=0 then
					if p*piece<0 then
						send_input(":IN.5", 0x80, 0.2) -- Play
					end
					if math.abs(p)~=math.abs(piece) then
						send_input(":IN." .. (6-math.abs(p)), 0x40, 0.5)
					end
					sb_press_square(":board", 0.5, x, 9-y)
					piece=p
				end
			end
		end
		if mode*piece<0 then
			send_input(":IN.5", 0x80, 0.2) -- Play
		end
		send_input(":IN.1", 0x80, 0.2) -- Enter
		send_input(":IN.4", 0x80, 0.2) -- Menu
	end
end

function interface.edit_game(on)
	send_input(":IN.4", 0x80, 0.2) -- Menu
	send_input(":IN.2", 0x80, 0.2) -- Down
	send_input(":IN.1", 0x80, 0.2) -- Enter
	send_input(":IN.1", 0x80, 0.2) -- Enter
	local dram = emu.item(machine.devices[':ram'].items['0/m_pointer'])
	local s = ""
	local b = 0
	for i=1,2 do
		b = dram:read(0xec1 + i)
		if (b ~= 0x00) then
			s = s .. string.upper(string.char(b))
		end
	end
	if on then
		if (s == "NO") then
			send_input(":IN.2", 0x80, 0.2) -- Down
		elseif (s == "AU") then
			send_input(":IN.3", 0x80, 0.2) -- UP
		end
	else
		if (s == "2 ") then
			send_input(":IN.3", 0x80, 0.2) -- Up
		elseif (s == "AU") then
			send_input(":IN.2", 0x80, 0.2) -- Down
		end
	end
	send_input(":IN.1", 0x80, 0.2) -- Enter
	send_input(":IN.4", 0x80, 0.2) -- Menu
end

function interface.start_play(init)
	send_input(":IN.5", 0x80, 1)
end

function interface.is_selected(x, y)
	local xval = output:get_indexed_value("0.", x - 1) ~= 0
	local yval = output:get_indexed_value("1.", y - 1) ~= 0
	return xval and yval
end

function interface.select_piece(x, y, event)
	sb_select_piece(":board", 1, x, y, event)
end

function interface.get_options()
	return { { "string", "Level", "10 sec/move"}, { "combo", "Style", "normal", "defensive\tsolid\tnormal\tactive\toffensive"}, }
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		value=value:match("^%s*(.-)%s*$"):gsub("%s%s+"," ") -- trim
		local temp = value:upper():gsub("\xdc", "U"):gsub("\xfc", "U"):gsub("ü", "U"):gsub("Ü", "U")
		interface.levelnum = 0
		if ((string.match(temp,"%d%d?%d?%s+SEC/MOVE")) or (string.match(temp,"%d%d?%d?%s+SE[KC]/ZUG"))) then
			if (temp:sub(3,3) == " ") then
				value = "0" .. value
			elseif (temp:sub(2,2) == " ") then
				value = "00" .. value
			end
			interface.levelnum = 1
		elseif ((string.match(temp,"%d%d?/%d:[0-5]%d%s+MOVES/HRS")) or (string.match(temp,"%d%d?/%d:[0-5]%d%s+ZUGE/STD"))) then
			if (temp:sub(2,2) == "/") then
				value = "0" .. value
			end
			interface.levelnum = 2
		elseif ((string.match(temp,"%d%d?%s+MIN/GAME")) or (string.match(temp,"%d%d?%s+MIN/PARTIE"))) then
			if (temp:sub(2,2) == " ") then
				value = "0" .. value
			end
			interface.levelnum = 3
		elseif ((string.match(temp,"%d%d?%s+PLY")) or (string.match(temp,"%d%d?%s+HALBZUG"))) then
			if (temp:sub(2,2) == " ") then
				value = "0" .. value
			end
			interface.levelnum = 4
		elseif ((string.match(temp,"%d%d?%s+MATE")) or (string.match(temp,"%d%d?%s+MATT"))) then
			if (temp:sub(2,2) == " ") then
				value = "0" .. value
			end
			interface.levelnum = 5
		elseif ((string.match(temp,"ANALYSIS")) or (string.match(temp,"ANALYSE"))) then
			interface.levelnum = 6
		end
		if (interface.levelnum ~= 0) then
			interface.level = value
			interface.setlevel()
		end
	elseif (name == "style" and value ~= "") then
		local temp = string.upper(value)
		interface.stylenum = 0
		if (temp == "DEFENSIVE") then
			interface.stylenum = 1
		elseif (temp == "SOLID") then
			interface.stylenum = 2
		elseif (temp == "NORMAL") then
			interface.stylenum = 3
		elseif (temp == "ACTIVE") then
			interface.stylenum = 4
		elseif (temp == "OFFENSIVE") then
			interface.stylenum = 5
		end
		if (interface.stylenum ~= 0) then
			interface.style = value
			interface.setstyle()
		end
	end
end

function interface.get_promotion(x, y)
	local dram = emu.item(machine.devices[':ram'].items['0/m_pointer'])
	local adr = 0x0f75
	local p
	repeat
		adr = adr + 1
		p = dram:read(adr)
	until (p >= 0x08 and p <= 0x0b) or p == 0x00
	if     p == 0x08 then return 'q'
	elseif p == 0x09 then return 'r'
	elseif p == 0x0a then return 'b'
	elseif p == 0x0b then return 'n'
	end
	return nil
end

function interface.promote(x, y, piece)
	sb_promote(":board", x, y, piece)
	if     (piece == "q") then	send_input(":IN.4", 0x40, 1)
	elseif (piece == "r") then	send_input(":IN.3", 0x40, 1)
	elseif (piece == "b") then	send_input(":IN.2", 0x40, 1)
	elseif (piece == "n") then	send_input(":IN.1", 0x40, 1)
	end
end

function interface.show_pv_after_move_player()
    if (read_pv():match("Thinking")) or (read_pv():match("Your Move")) then
        send_input(":IN.2", 0x80, 0.2) -- Down
    end
end

function interface.show_pv_after_move_emu()
    if (read_pv():match("Thinking")) or (read_pv():match("Your Move")) then
        send_input(":IN.2", 0x80, 0.2) -- Down
    end
end

function interface.show_info(on)
    if on == true then
        local pv = read_pv()
        local info = read_depth()
        if info:sub(1,1) == "p" or info:sub(1,1) == "b" then
            local depth = info:sub(3,4)
            local seldepth = info:sub(6,7)
            local score = info:sub(8,12)
            score = score:gsub(" ", "")
            pv = pv:gsub("-", "")
            pv = pv:gsub("x", "")
            return "info score cp " .. score .. " depth " .. depth .. " seldepth " .. seldepth .. " pv " .. pv
        end
    end
end

function read_display()
    local dram = emu.item(machine.devices[':ram'].items['0/m_pointer'])
    local s = ""
    local b = 0
    local i = 1
    repeat
        b = dram:read(0x0ec0 + i)
        if (b ~= 0x00) then
            s = s .. string.char(b)
            i = i + 1
        end
    until (b == 0x00)
    return s
end

function read_depth()
    local dram = emu.item(machine.devices[':ram'].items['0/m_pointer'])
    local s = ""
    local b = 0
    local i = 1
    repeat
        b = dram:read(0x0f3b + i)
        if (b ~= 0x00) then
            s = s .. string.char(b)
            i = i + 1
        end
    until (i == 13) or (b == 0x00)
    return s
end

function read_pv()
    local dram = emu.item(machine.devices[':ram'].items['0/m_pointer'])
    local s = ""
    local b = 0
    local i = 1
    repeat
        b = dram:read(0x0f75 + i)
        if (b ~= 0x00) then
            if b == (0x08) then
                s = s .. "q"
            elseif b == (0x0b) then
                s = s .. "n"
            elseif b == (0x0a) then
                s = s .. "b"
            elseif b == (0x09) then
                s = s .. "r"
            else
                s = s .. string.char(b)
            end
            i = i + 1
        end
    until (i == 31) or (b == 0x00)
    return s
end

return interface
