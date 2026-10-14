interface = {}

local function led_on(name)
	local led = machine.devices[":"]:output(name)
	return led ~= nil and led:get() ~= 0
end

interface.level = "010 sec/move"
interface.cur_level = nil
interface.levelnum = 1
interface.style = "normal"
interface.cur_style = nil
interface.stylenum = 3


function interface.get_module()
	if machine.system.name == "tascr30" then
		return "Tasc R30 (The King 2.50)"
	elseif machine.system.name == "tascr30a" then
		return "Tasc R30 (The King 2.20)"
	elseif machine.system.name == "tascr30b" then
		return "Tasc R30 (The King 2.23)"
	elseif machine.system.name == "tascr30g" then
		return "Tasc R30 (Gideon 3.1)"
	else
		return machine.system.description
	end
end

function interface.get_author()
	if machine.system.name == "tascr30g" then
		return "Ed Schröder"
	else
		return "Johan de Koning"
	end
end

local function setdigits(n)
	local dram = machine.devices[':lcd:lcdc'].spaces['display']
	send_input(":IN.3", 0x20, 0.3) -- Enter
	emu.wait(0.25)
	for i = 1, n do
		if (n == 7 and (i == 3 or i == 5)) then
			-- skip char
		else
			local k = tonumber(interface.level:sub(i,i)) - (dram:read_u8(0x119+i)-0x10)
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
			for j = 1, math.abs(k) do
				if (k > 0) then
					send_input(":IN.2", 0x40, 0.5) -- up
				else
					send_input(":IN.3", 0x40, 0.5) -- down
				end
			end
			if (i < n) then
				send_input(":IN.1", 0x40, 0.5) -- right
			end
		end
	end
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level or interface.levelnum == 0) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.2", 0x20, 0.3) -- Menu
	emu.wait(0.25)
	send_input(":IN.1", 0x40, 0.3) -- right
	emu.wait(0.25)
	send_input(":IN.3", 0x40, 0.3) -- down
	emu.wait(0.25)
	send_input(":IN.1", 0x40, 0.3) -- right
	emu.wait(0.25)
	if (interface.levelnum == 1) then
		send_input(":IN.2", 0x40, 0.3) -- up
		emu.wait(0.25)
		setdigits(3)
	elseif (interface.levelnum == 2) then
		setdigits(7)
	elseif (interface.levelnum == 3) then
		send_input(":IN.3", 0x40, 0.3) -- down
		emu.wait(0.25)
		setdigits(2)
	elseif (interface.levelnum == 4) then
		send_input(":IN.3", 0x40, 0.3) -- down
		emu.wait(0.25)
		send_input(":IN.3", 0x40, 0.3) -- down
		emu.wait(0.25)
		setdigits(2)
	elseif (interface.levelnum == 5) then
		send_input(":IN.3", 0x40, 0.3) -- down
		emu.wait(0.25)
		send_input(":IN.3", 0x40, 0.3) -- down
		emu.wait(0.25)
		send_input(":IN.3", 0x40, 0.3) -- down
		emu.wait(0.25)
		setdigits(2)
	elseif (interface.levelnum == 6) then
		send_input(":IN.2", 0x40, 0.3) -- up
		emu.wait(0.25)
		send_input(":IN.2", 0x40, 0.3) -- up
		emu.wait(0.25)
	end
	send_input(":IN.3", 0x20, 0.3) -- Enter
	emu.wait(0.25)
	send_input(":IN.2", 0x20, 0.3) -- Menu
	emu.wait(0.25)
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":smartboard:board")
	emu.wait(6)
	send_input(":IN.2", 0x20, 0.3) -- Menu
	emu.wait(0.25)
	send_input(":IN.3", 0x40, 0.3) -- down
	emu.wait(0.25)
	send_input(":IN.3", 0x40, 0.3) -- down
	emu.wait(0.25)
	send_input(":IN.3", 0x40, 0.3) -- down
	emu.wait(0.25)
	send_input(":IN.1", 0x40, 0.3) -- right
	emu.wait(0.25)
	send_input(":IN.3", 0x40, 0.3) -- down
	emu.wait(0.25)
	send_input(":IN.1", 0x40, 0.3) -- right
	emu.wait(0.25)
	send_input(":IN.3", 0x40, 0.3) -- down
	emu.wait(0.25)
	send_input(":IN.3", 0x20, 0.3) -- Enter
	emu.wait(0.25)
	send_input(":IN.2", 0x20, 0.3) -- Menu
	emu.wait(0.25)
	interface.cur_level = ""
	interface.setlevel()
	local drei = 0
	repeat
		if drei == 3 or drei == 9 then
			send_input(":IN.3", 0x20, 0.3) -- Enter
			emu.wait(0.25)
		elseif drei == 6 or drei == 12 then
			send_input(":IN.1", 0x40, 0.3) -- right
			emu.wait(0.25)
			drei = 0
		end
		send_input(":IN.0", 0x40, 0.3) -- left
		emu.wait(0.25)
		drei = drei + 1
	until (digit_char(0) .. digit_char(1)) == "--"
    send_input(":IN.0", 0x40, 0.3) -- left
    send_input(":IN.0", 0x40, 0.3) -- left
    send_input(":IN.1", 0x40, 0.3) -- right
    send_input(":IN.1", 0x40, 0.3) -- right
	machine.video.throttled = throttled_state
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.2", 0x20, 0.2) -- Menu
		send_input(":IN.1", 0x40, 0.2) -- right
		send_input(":IN.3", 0x40, 0.2) -- down
		send_input(":IN.3", 0x40, 0.2) -- down
		send_input(":IN.3", 0x40, 0.2) -- down
		send_input(":IN.3", 0x20, 0.2) -- Enter
		machine.video.throttled = throttled_state
		return (":smartboard:board")
	else
		if mode == -1 then
			send_input(":IN.0", 0x20, 0.2)	-- Play
		end
		send_input(":IN.3", 0x20, 0.2) -- Enter
		send_input(":IN.2", 0x20, 0.2) -- Menu
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game(on)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.2", 0x20, 0.2) -- Menu
	send_input(":IN.1", 0x40, 0.2) -- right
	send_input(":IN.1", 0x40, 0.2) -- right
	if on == false then
		send_input(":IN.3", 0x40, 0.2) -- down
	end
	send_input(":IN.3", 0x20, 0.2) -- Enter
	send_input(":IN.2", 0x20, 0.2) -- Menu
	machine.video.throttled = throttled_state
end

function interface.start_play(init)
	send_input(":IN.0", 0x20, 0.5) -- PLAY
end

function interface.is_selected(x, y)
	return led_on("sb30_led_" .. tostring(8 - y) .. "." .. tostring(8 - x))
end

function interface.select_piece(x, y, event)
	sb_select_piece(":smartboard:board", 1, x, y, event)
end

function interface.ponder(value)
    if tonumber(value) == 0 then
        send_input(":IN.2", 0x20, 0.3) -- Menu
        emu.wait(0.25)
        send_input(":IN.3", 0x40, 0.3) -- down
        emu.wait(0.25)
        send_input(":IN.3", 0x40, 0.3) -- down
        emu.wait(0.25)
        send_input(":IN.1", 0x40, 0.3) -- right
        emu.wait(0.25)
        send_input(":IN.1", 0x40, 0.3) -- right
        emu.wait(0.25)
        send_input(":IN.3", 0x20, 0.3) -- Enter
        emu.wait(0.25)
        send_input(":IN.2", 0x20, 0.3) -- Menu
    else
        send_input(":IN.2", 0x20, 0.3) -- Menu
        emu.wait(0.25)
        send_input(":IN.3", 0x40, 0.3) -- down
        emu.wait(0.25)
        send_input(":IN.3", 0x40, 0.3) -- down
        emu.wait(0.25)
        send_input(":IN.1", 0x40, 0.3) -- right
        emu.wait(0.25)
        send_input(":IN.1", 0x40, 0.3) -- right
        emu.wait(0.25)
        send_input(":IN.3", 0x40, 0.3) -- down
        emu.wait(0.25)
        send_input(":IN.3", 0x20, 0.3) -- Enter
        emu.wait(0.25)
        send_input(":IN.2", 0x20, 0.3) -- Menu
    end
    emu.wait(0.25)
end

function interface.hash(value)
    if tonumber(value) == 1 then
        send_input(":IN.2", 0x20, 0.3) -- Menu
        emu.wait(0.25)
        send_input(":IN.3", 0x40, 0.3) -- down
        emu.wait(0.25)
        send_input(":IN.3", 0x40, 0.3) -- down
        emu.wait(0.25)
        send_input(":IN.1", 0x40, 0.3) -- right
        emu.wait(0.25)
        send_input(":IN.3", 0x40, 0.3) -- down
        emu.wait(0.25)
        send_input(":IN.1", 0x40, 0.3) -- right
        emu.wait(0.25)
        send_input(":IN.3", 0x40, 0.3) -- down
        emu.wait(0.25)
        send_input(":IN.3", 0x20, 0.3) -- Enter
        emu.wait(0.25)
        send_input(":IN.2", 0x20, 0.3) -- Menu
    else
        send_input(":IN.2", 0x20, 0.3) -- Menu
        emu.wait(0.25)
        send_input(":IN.3", 0x40, 0.3) -- down
        emu.wait(0.25)
        send_input(":IN.3", 0x40, 0.3) -- down
        emu.wait(0.25)
        send_input(":IN.1", 0x40, 0.3) -- right
        emu.wait(0.25)
        send_input(":IN.3", 0x40, 0.3) -- down
        emu.wait(0.25)
        send_input(":IN.1", 0x40, 0.3) -- right
        emu.wait(0.25)
        send_input(":IN.3", 0x20, 0.3) -- Enter
        emu.wait(0.25)
        send_input(":IN.2", 0x20, 0.3) -- Menu
    end
    emu.wait(0.25)
end

function interface.strength(value)
    send_input(":IN.2", 0x20, 0.3) -- Menu
    emu.wait(0.25)
    send_input(":IN.3", 0x40, 0.3) -- Down
    emu.wait(0.25)
    send_input(":IN.3", 0x40, 0.3) -- Down
    emu.wait(0.25)
    send_input(":IN.1", 0x40, 0.3) -- Right
    emu.wait(0.25)
    send_input(":IN.2", 0x40, 0.3) -- Up
    emu.wait(0.25)
    send_input(":IN.2", 0x40, 0.3) -- Up
    emu.wait(0.25)
    send_input(":IN.1", 0x40, 0.3) -- Right
    emu.wait(0.25)
    if tonumber(value) == 2 then
        send_input(":IN.3", 0x40, 0.3) -- Down
    elseif tonumber(value) == 3 then
        send_input(":IN.3", 0x40, 0.3) -- Down
        emu.wait(0.25)
        send_input(":IN.3", 0x40, 0.3) -- Down
    elseif tonumber(value) == 4 then
        send_input(":IN.3", 0x40, 0.3) -- Down
        emu.wait(0.25)
        send_input(":IN.3", 0x40, 0.3) -- Down
        emu.wait(0.25)
        send_input(":IN.3", 0x40, 0.3) -- Down
    end
    emu.wait(0.25)
    send_input(":IN.3", 0x20, 0.3) -- Enter
    emu.wait(0.25)
    send_input(":IN.2", 0x20, 0.3) -- Menu
    emu.wait(0.25)
end

function interface.style(value)
    send_input(":IN.2", 0x20, 0.3) -- Menu
    emu.wait(0.25)
    send_input(":IN.3", 0x40, 0.3) -- Down
    send_input(":IN.3", 0x40, 0.3) -- Down
    emu.wait(0.25)
    send_input(":IN.1", 0x40, 0.3) -- Right
    emu.wait(0.25)
    send_input(":IN.2", 0x40, 0.3) -- Up
    emu.wait(0.25)
    send_input(":IN.1", 0x40, 0.3) -- Right
    emu.wait(0.25)
    if tonumber(value) == 1 then
        send_input(":IN.2", 0x40, 0.3) -- Up
    elseif tonumber(value) == 3 then
        send_input(":IN.3", 0x40, 0.3) -- Down
    elseif tonumber(value) == 4 then
        send_input(":IN.3", 0x40, 0.3) -- Down
        emu.wait(0.25)
        send_input(":IN.3", 0x40, 0.3) -- Down
    elseif tonumber(value) == 5 then
        send_input(":IN.3", 0x40, 0.3) -- Down
        emu.wait(0.25)
        send_input(":IN.3", 0x40, 0.3) -- Down
        emu.wait(0.25)
        send_input(":IN.3", 0x40, 0.3) -- Down
    end
    emu.wait(0.25)
    send_input(":IN.3", 0x20, 0.3) -- Enter
    emu.wait(0.25)
    send_input(":IN.2", 0x20, 0.3) -- Menu
    emu.wait(0.25)
end

function interface.book(value)
    send_input(":IN.2", 0x20, 0.3) -- Menu
    emu.wait(0.25)
    send_input(":IN.3", 0x40, 0.3) -- Down
    emu.wait(0.25)
    send_input(":IN.3", 0x40, 0.3) -- Down
    emu.wait(0.25)
    send_input(":IN.1", 0x40, 0.3) -- Right
    emu.wait(0.25)
    send_input(":IN.3", 0x40, 0.3) -- Down
    emu.wait(0.25)
    send_input(":IN.3", 0x40, 0.3) -- Down
    emu.wait(0.25)
    send_input(":IN.3", 0x40, 0.3) -- Down
    emu.wait(0.25)
    send_input(":IN.1", 0x40, 0.3) -- Right
    emu.wait(0.25)
    if tonumber(value) == 1 then
        send_input(":IN.3", 0x40, 0.3) -- Down
    elseif tonumber(value) == 2 then
        send_input(":IN.3", 0x40, 0.3) -- Down
        emu.wait(0.25)
        send_input(":IN.3", 0x40, 0.3) -- Down
    end
    emu.wait(0.25)
    send_input(":IN.3", 0x20, 0.3) -- Enter
    emu.wait(0.25)
    send_input(":IN.2", 0x20, 0.3) -- Menu
    emu.wait(0.25)
end

function interface.bookstyle(value)
    send_input(":IN.2", 0x20, 0.3) -- Menu
    emu.wait(0.25)
    send_input(":IN.3", 0x40, 0.3) -- Down
    emu.wait(0.25)
    send_input(":IN.3", 0x40, 0.3) -- Down
    emu.wait(0.25)
    send_input(":IN.1", 0x40, 0.3) -- Right
    emu.wait(0.25)
    send_input(":IN.3", 0x40, 0.3) -- Down
    emu.wait(0.25)
    send_input(":IN.3", 0x40, 0.3) -- Down
    emu.wait(0.25)
    send_input(":IN.3", 0x40, 0.3) -- Down
    emu.wait(0.25)
    send_input(":IN.3", 0x40, 0.3) -- Down
    emu.wait(0.25)
    send_input(":IN.1", 0x40, 0.3) -- Right
    emu.wait(0.25)
    if tonumber(value) == 1 then
        send_input(":IN.3", 0x40, 0.3) -- Down
    end
    emu.wait(0.25)
    send_input(":IN.3", 0x20, 0.3) -- Enter
    emu.wait(0.25)
    send_input(":IN.2", 0x20, 0.3) -- Menu
    emu.wait(0.25)
end

function interface.get_options()
	return {
		{"string", "Level", "010 sec/move"},
        {"check", "Ponder", "1"},
        {"combo", "Style", "normal", "defensive\tsolid\tnormal\tactive\toffensive"},
        {"check", "Hash", "1"},
        {"combo", "Strength", "expert", "expert\tstrong\tmoderate\tnovice"},
        {"combo", "Book", "aegon", "normal\taegon\toff"},
        {"combo", "Book Style", "random", "random\ttournament"}
	}
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
		elseif ((string.match(temp,"INFINITE")) or (string.match(temp,"UNENDLICH"))) then
			interface.levelnum = 6
		end
		if (interface.levelnum ~= 0) then
			interface.level = value
			interface.setlevel()
		end
    elseif (name == "ponder" and value ~= "") then
        interface.ponder(value)
    elseif (name == "style" and value ~= "") then
        if (value == "defensive") then
            value = 1
        elseif (value == "solid") then
            value = 2
        elseif (value == "normal") then
            value = 3
        elseif (value == "active") then
            value = 4
        elseif (value == "offensive") then
            value = 5
        end
        interface.style(value)
    elseif (name == "hash" and value ~= "") then
        interface.hash(value)
    elseif (name == "strength" and value ~= "") then
        if (value == "expert") then
            value = 1
        elseif (value == "strong") then
            value = 2
        elseif (value == "moderate") then
            value = 3
        elseif (value == "novice") then
            value = 4
        else
            value = -1
        end
        if value ~= -1 then interface.strength(value) end
    elseif (name == "book" and value ~= "") then
        if (value == "normal") then
            value = 1
        elseif (value == "aegon") then
            value = 2
        elseif (value == "off") then
            value = 3
        else
            value = -1
        end
        if value ~= -1 then interface.book(value) end
    elseif (name == "book style" and value ~= "") then
        if (value == "random") then
            value = 1
        elseif (value == "tournament") then
            value = 2
        else
            value = -1
        end
        if value ~= -1 then interface.bookstyle(value) end
    end
	if digit_char(0) .. digit_char(1) == "  " then
		send_input(":IN.3", 0x20, 0.3) -- Enter
		emu.wait(0.25)
	end
end

function interface.get_promotion(x, y)
	local dram = machine.devices[':lcd:lcdc'].spaces['display']
	local addr = 0x133
	local byte = 0
	repeat
		addr = addr - 1
		byte = dram:read_u8(addr)
	until (byte ~= 0x80 and byte ~= 0xf2 and byte ~= 0xf3)
	if     (byte == 0xed) then return 'q'
	elseif (byte == 0xee) then return 'r'
	elseif (byte == 0xef) then return 'b'
	elseif (byte == 0xf0) then return 'n'
	end
end

function interface.promote(x, y, piece)
	sb_promote(":smartboard:board", x, y, piece)
	local right = -1
	if     (piece == "q") then right = 0
	elseif (piece == "r") then right = 1
	elseif (piece == "b") then right = 2
	elseif (piece == "n") then right = 3
	end
	if (right ~= -1) then
		for i = 1, right do
			send_input(":IN.1", 0x40, 0.3) -- RIGHT
			emu.wait(0.25)
		end
		send_input(":IN.3", 0x20, 0.3) -- ENTER
		emu.wait(0.25)
	end
end

function interface.show_info(on)
	if on then
		local depth = " depth " .. digit_char(0) .. digit_char(1)
		local score = " score cp " .. digit_char(7) .. digit_char(8) .. digit_char(10) .. digit_char(11)
		local pv = " pv " .. (digit_char(48) .. digit_char(49) .. digit_char(51) .. digit_char(52)):gsub(" ", "")
		return "info" .. score .. depth .. pv
	end
end

function digit_char(n)
	local ddram = machine.devices[':lcd:lcdc'].spaces['display']
	local addr = 0x000
	addr = addr + n
	local byte = ddram:read_u8(addr)
	if     byte == 0x10 then return "0"
	elseif byte == 0x11 then return "1"
	elseif byte == 0x12 then return "2"
	elseif byte == 0x13 then return "3"
	elseif byte == 0x14 then return "4"
	elseif byte == 0x15 then return "5"
	elseif byte == 0x16 then return "6"
	elseif byte == 0x17 then return "7"
	elseif byte == 0x18 then return "8"
	elseif byte == 0x19 then return "9"
	elseif byte == 0x00 then return " "
	elseif byte == 0x0f then return "/"
	elseif byte == 0x0b then return "+"
	elseif byte == 0x0e then return "."
	elseif byte == 0x41 then return "a"
	elseif byte == 0x42 then return "b"
	elseif byte == 0x43 then return "c"
	elseif byte == 0x44 then return "d"
	elseif byte == 0x45 then return "e"
	elseif byte == 0x46 then return "f"
	elseif byte == 0x47 then return "g"
	elseif byte == 0x48 then return "h"
	elseif byte == 0x6F then return string.char(200)
	elseif byte == 0x70 then return string.char(199)
	elseif byte == 0x6e then return string.char(201)
	elseif byte == 0x6c then return string.char(203)
	elseif byte == 0x6d then return string.char(202)
	elseif byte == 0x58 then return "x"
	elseif byte == 0x2f then return "O"
	elseif byte == 0x0d then return "-"
	elseif byte == 0x73 then return "M"
	end
	return " byte: " .. byte .. " " -- noch nicht definiertes Zeichen
end

return interface

