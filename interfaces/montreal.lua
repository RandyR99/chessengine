interface = {}

interface.level = "nor4"
interface.cur_level = nil
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.get_module()
	return "Mephisto Montreal 68000"
end

function interface.get_author()
	return "Richard Lang"
end

function interface.setdigit(n)
	if     (n == 0) then send_input(":IN.3", 0x08, 0.5)
	elseif (n == 1) then send_input(":IN.1", 0x04, 0.5)
	elseif (n == 2) then send_input(":IN.1", 0x08, 0.5)
	elseif (n == 3) then send_input(":IN.2", 0x01, 0.5)
	elseif (n == 4) then send_input(":IN.2", 0x02, 0.5)
	elseif (n == 5) then send_input(":IN.2", 0x04, 0.5)
	elseif (n == 6) then send_input(":IN.2", 0x08, 0.5)
	elseif (n == 7) then send_input(":IN.3", 0x01, 0.5)
	elseif (n == 8) then send_input(":IN.3", 0x02, 0.5)
	elseif (n == 9) then send_input(":IN.3", 0x04, 0.5)
	end
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local level = interface.level
	local code = 0
	local temp = level:sub(3,3)
	if     temp=="r" then code=0x50
	elseif temp=="u" then code=0x1c
	elseif temp=="i" then code=0x30
	elseif temp=="g" then code=0x3d
	elseif temp=="t" then code=0x78
	elseif temp=="f" then code=0x71
	end

	send_input(":IN.0", 0x04, 0.5) -- LEV
	send_input(":IN.1", 0x02, 0.5) -- ENT
	while output_value("digit1")&0x7f~=code do
		send_input(":IN.0", 0x04, 0.5) -- LEV
	end

	if level:len()>3 then
		interface.setdigit(tonumber(level:sub(4,4)))
		level=level:sub(5)
		while level:len()>0 do
			temp=level:sub(1,1)
			if temp==" " or temp=="/" or temp==":" then
				send_input(":IN.1", 0x02, 0.5) -- ENT
				if output_value("digit2")&0x7f==0x39 then
					send_input(":IN.1", 0x02, 0.5) -- ENT
				end
			else
				interface.setdigit(tonumber(level:sub(1,1)))
			end
			level=level:sub(2)
		end
	end
	send_input(":IN.1", 0x02, 0.5) -- ENT
end

function interface.setup_machine()
	sb_reset_board(":board:board")
	emu.wait(1.0)

	interface.cur_level = "nor4"
	interface.setlevel()
end

function interface.set_pos(mode)
	if mode == 0 then
		send_input(":IN.0", 0x02, 0.5) -- POS
		for i=1,14 do
			send_input(":IN.1", 0x02, 0.5) -- ENT
		end
		return (":board:board")
	else
		for y=1,8 do
			for x=1,8 do
				local p=get_piece_id(x,9-y)
				if p~=0 then
					if p>0 then
						interface.setdigit(0) -- White
					else
						interface.setdigit(9) -- Black
					end
					interface.setdigit(8-math.abs(p))
					interface.setdigit(x)
					interface.setdigit(9-y)
					send_input(":IN.1", 0x02, 0.5) -- ENT
				end
			end
		end
		if mode == 1 then
			interface.setdigit(0) -- White
		else
			interface.setdigit(9) -- Black
		end
		send_input(":IN.1", 0x02, 0.5) -- ENT
		send_input(":IN.1", 0x01, 0.5) -- CL
	end
end

function interface.edit_game(on)
	if on then
		send_input(":IN.0", 0x08, 0.5) -- MEM
	else
		send_input(":IN.1", 0x01, 0.5) -- CL
	end
	emu.wait(0.5)
end

function interface.start_play(init)
	send_input(":IN.1", 0x02, 1) -- ENT
end

function interface.is_selected(x, y)
	local xval = { 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71, 0x3d, 0x76 }
	local yval = { 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f }
	local d0 = output_value("digit3") & 0x7f
	local d1 = output_value("digit2") & 0x7f
	local d2 = output_value("digit1") & 0x7f
	local d3 = output_value("digit0") & 0x7f
	return ((xval[x] == d0 and yval[y] == d1) or (xval[x] == d2 and yval[y] == d3)) and output_value("led" .. tostring(8 * (y - 1) + (x - 1))) ~= 0
end

function interface.select_piece(x, y, event)
	sb_select_piece(":board:board", 1, x, y, event)
end

function interface.get_options()
	return { { "string", "Level", "nor4"}, }
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = string.lower(value:match("^%s*(.-)%s*$"):gsub("%s%s+"," ")) -- trim
		if (level:match("^nor[0-9]$") or level:match("^tou[0-6]$") or level:match("^bli[0-7]$")
		or level:match("^beg[0-9]$") or level:match("^mat[0-9]$") or level=="inf"
		or level:match("^tou7%s%d%d/%d%d:[0-5]%d$") or level:match("^tou8%s%d%d/%d%d:[0-5]%d%s%d%d/%d%d:[0-5]%d$")
		or level:match("^tou9%s%d%d/%d%d:[0-5]%d%s%d%d:[0-5]%d$")
		or level:match("^bli8%s%d%d:[0-5]%d:[0-5]%d$") or level:match("^bli9%s%d%d:[0-5]%d:[0-5]%d%s%d%d:[0-5]%d:[0-5]%d$")) then
			interface.level = level
			interface.setlevel()
		end
	end
end

function interface.get_promotion(x, y)
	send_input(":IN.0", 0x01, 0.5)	-- INFO
	send_input(":IN.1", 0x04, 0.5)	-- 1

	local d3 = 0
	for i=0,5 do
		local d0 = output_value("digit3") & 0x7f
		local d1 = output_value("digit2") & 0x7f

		if (d0 == 0x73 and d1 == 0x50) then	-- display shows 'Pr'
			d3 = output_value("digit0") & 0x7f
			break
		end
		send_input(":IN.3", 0x08, 0.5)	-- 0
	end

	send_input(":IN.1", 0x01, 0.5)	-- CL

	if     (d3 == 0x5e) then	return "q"
	elseif (d3 == 0x31) then	return "r"
	elseif (d3 == 0x38) then	return "b"
	elseif (d3 == 0x6d) then	return "n"
	end

	return nil
end

function interface.promote(x, y, piece)
	sb_promote(":board:board", x, y, piece)
	if     (piece == "q") then	send_input(":IN.2", 0x08, 1)
	elseif (piece == "r") then	send_input(":IN.2", 0x04, 1)
	elseif (piece == "b") then	send_input(":IN.2", 0x02, 1)
	elseif (piece == "n") then	send_input(":IN.2", 0x01, 1)
	end
	if (piece == "q" or piece == "r" or piece == "b" or piece == "n") then
		send_input(":IN.1", 0x02, 1) -- ENT
	end
end

return interface
