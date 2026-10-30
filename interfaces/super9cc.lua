interface = {}
interface.info_every = 1 -- show_info only reads the display
interface.ignore_late_go = true -- replies on its own once the player's move is on the board

interface.opt_clear_announcements = true
interface.level = "a1"
interface.cur_level = nil
interface.score = 0
interface.depth = 0
interface.hex = ""
local turn  = 0
local check = 3

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

function interface.get_module()
	return "Fidelity Super Sensory 9"
end

function interface.get_author()
	return "Dan & Kathe Spracklen"
end

function interface.setdigit(n,d)
	local lcd_num = { 0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x67 }
	local led = 3 - n
	for i = 1, 40 do
		if (output_value("digit" .. led) == lcd_num[d + 1]) then
			break
		end
		send_input(":IN." .. tostring(3 - n), 0x100, 0.5)  -- TM / RV / spk
	end
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	local level = interface.level
	local cols_idx = { a=1, b=2, c=3, d=4, e=5, f=6, g=7, h=8 }
	local x = cols_idx[interface.level:sub(1,1)]
	local y = interface.level:sub(2,2)
	send_input(":IN.8", 0x08, 1)  -- LV
	sb_press_square(":board", 0.5, x, y)
	local num = level:sub(4)
	if (num ~= "" and num:len() <= 2) then
		if (num:len() == 1) then
			num = "0" .. num
		end
		for i = 1, 2 do
			interface.setdigit(i + 1, num:sub(i,i))
		end
	else
		local k = 1
		while (num ~= "") do
			local d = num:sub(1,1)
			if (d == " ") then
				sb_press_square(":board", 0.5, x, y)
				k = 1
			elseif (d == "/") then
				sb_press_square(":board", 0.5, x, y)
				k = 2
			elseif (d ~= ":") then
				interface.setdigit(k,d)
				k = k + 1
			end
			num = num:sub(2)
		end
	end
	emu.wait(0.5)
	send_input(":IN.8", 0x40, 1) -- CL
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	sb_reset_board(":board")
	emu.wait(1)
	interface.cur_level = "a1"
	interface.setlevel()
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.0", 0x100, 0.5) -- SPK
		sb_press_square(":board", 0.5, 8, 8) -- Voice off
		send_input(":IN.8", 0x40, 0.5) -- CL
		send_input(":IN.8", 0x80, 0.5) -- RE
		sb_press_square(":board", 0.5, 4, 7) -- Clear board
		send_input(":IN.8", 0x40, 0.5) -- CL
		send_input(":IN.8", 0x20, 0.5) -- PB
		machine.video.throttled = throttled_state
		return (":board")
	else
		local piece = 7
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if math.abs(p) ~= math.abs(piece) then
						send_input(":IN.8", 0x40 >> math.abs(p), 0.5)
					end
					sb_press_square(":board", 0.5, x, 9 - y)
					if p < 0 then
						sb_press_square(":board", 0.5, x, 9 - y)
					end
					piece = p
				end
			end
		end
		send_input(":IN.8", 0x40, 0.5) -- CL
		if mode == -1 then
			send_input(":IN.8", 0x80, 0.5) -- RE
			sb_press_square(":board", 0.5, 4, 5) -- Change color
			send_input(":IN.8", 0x40, 0.5) -- CL
		end
		send_input(":IN.0", 0x100, 0.5) -- SPK
		sb_press_square(":board", 0.5, 7, 8) -- Voice on
		send_input(":IN.8", 0x40, 0.5) -- CL
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game(on)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if on then
		send_input(":IN.0", 0x100, 0.5) -- SPK
		sb_press_square(":board", 0.5, 8, 8) -- Voice off
		send_input(":IN.8", 0x40, 0.5) -- CL
	end
	send_input(":IN.8", 0x80, 0.5) -- RE
	sb_press_square(":board", 0.5, 5, 6) -- Monitor mode
	send_input(":IN.8", 0x40, 0.5) -- CL
	if not on then
		send_input(":IN.0", 0x100, 0.5) -- SPK
		sb_press_square(":board", 0.5, 7, 8) -- Voice on
		send_input(":IN.8", 0x40, 0.5) -- CL
	end
	emu.wait(0.5)
	machine.video.throttled = throttled_state
end

function interface.start_play(init)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if (check==1) then
		check=3
	else
		check=1
	end
	send_input(":IN.8", 0x02, 1) -- DM
	send_input(":IN.8", 0x01, 1) -- RV
	machine.video.throttled = throttled_state
end

function interface.clear_announcements()
	if (output_value("0.8") ~= 0 and output_value("1.8") ~= 0 and output_value("2.8") ~= 0 and output_value("3.8") ~= 0 and
	    output_value("4.8") ~= 0 and output_value("5.8") ~= 0 and output_value("6.8") ~= 0 and output_value("7.8") ~= 0) then
		send_input(":IN.8", 0x40, 1) -- CL
	end
end

function interface.is_selected(x, y)
	if (interface.opt_clear_announcements and x == 1 and y == 1) then
		interface.clear_announcements()
	end
	return output_value(tostring(x - 1) .. "." .. tostring(y - 1 + 8)) ~= 0
end

function interface.select_piece(x, y, event)
	if (event ~= "capture") then
		if (event ~= "en_passant" and event ~= "get_castling" and event ~= "put_castling") then
			turn = turn + 1
			if turn > 3 then
				turn = 0
			end
			if turn == check then
				emu.wait(4)
			end
		end
	end
	sb_select_piece(":board", 1, x, y, event)
end

function interface.get_options()
	return {
		{ "string", "Level", "a1" },
		{ "check", "Clear announcements", "1" },
	}
end

function interface.set_option(name, value)
	if (name == "level" and value ~= "") then
		local level = value:lower():match("^%s*(.-)%s*$"):gsub("%s%s+"," ") -- trim
		if (level:match("^a[1-8]$") or level:match("^b[1-7]$")
		or  level:match("^b[4-6]%s%d%d?$")
		or  level:match("^b[72]%s%d:%d%d$") or level:match("^b2%s%d:%d%d%s%d:%d%d$")
		or  level:match("^b3%s%d:%d%d/%d%d$") or level:match("^b3%s%d:%d%d/%d%d%s%d:%d%d/%d%d$") or level:match("^b3%s%d:%d%d/%d%d%s%d:%d%d/%d%d%s%d:%d%d$")) then
			interface.level = level
			interface.setlevel()
		end
	end
	if (name == "clear announcements") then
		interface.opt_clear_announcements = tonumber(value) == 1
	end
end

function interface.test_promotion(x, y)
	local function board_led(x, y)
		for i = 1, 5 do
			if (output_value(tostring(x - 1) .. "." .. tostring(y - 1 + 8)) ~= 0) then
				send_input(":IN.8", 0x40, 0.5) -- CL
				send_input(":IN.0", 0x100, 0.5) -- SPK
				sb_press_square(":board", 0.5, 7, 8) -- Voice on
				send_input(":IN.8", 0x40, 0.5) -- CL
				return true
			end
			emu.wait(0.1)
		end
		return false
	end
	if (interface.opt_clear_announcements) then
		interface.clear_announcements()
	end
	send_input(":IN.0", 0x100, 0.5) -- SPK
	sb_press_square(":board", 0.5, 8, 8) -- Voice off
	send_input(":IN.8", 0x40, 0.5) -- CL
	send_input(":IN.8", 0x10, 0.5) -- PV
	send_input(":IN.8", 0x10, 0.5)
	if board_led(x, y) then
		return "Q"
	end
	send_input(":IN.8", 0x02, 0.5)
	if board_led(x, y) then
		return "N"
	end
	send_input(":IN.8", 0x04, 0.5)
	if board_led(x, y) then
		return "B"
	end
	send_input(":IN.8", 0x08, 0.5)
	if board_led(x, y) then
		return "R"
	end
	send_input(":IN.8", 0x40, 0.5) -- CL
	send_input(":IN.0", 0x100, 0.5) -- SPK
	sb_press_square(":board", 0.5, 7, 8) -- Voice on
	send_input(":IN.8", 0x40, 0.5) -- CL
	return "Q"
end

function interface.get_promotion(x, y)
	return nil
end

function interface.promote(x, y, piece)
	sb_promote(":board", x, y, piece)
	emu.wait(1)
	if     (piece == "q") then send_input(":IN.8", 0x10, 1)
	elseif (piece == "r") then send_input(":IN.8", 0x08, 1)
	elseif (piece == "b") then send_input(":IN.8", 0x04, 1)
	elseif (piece == "n") then send_input(":IN.8", 0x02, 1)
	end
end

function interface.show_pv_after_move_player()
  send_input(":IN.3", 0x100, 0.5)        -- LV
  interface.score=0
  interface.depth=0
end
 
   
function interface.befor_move_from_engine()
  send_input(":IN.3", 0x100, 0.5)        -- LV
  local d1 = output_value("digit1")
  if d1 == 0 then interface.depth =  tonumber(interface.digit_string(d0),16) end
  send_input(":IN.5", 0x100, 0.5)  -- RE
  local d0 = output_value("digit0")
  d1 = output_value("digit1")
  local d2 = output_value("digit2")
  local d3 = output_value("digit3")
  local dotO = output_value("2.7")
  local dotU = output_value("3.7")
  if d3 ~=0 and d2 ~=0 and d1 ~=0 and d0 ~=0 and dotO== 0 then
    interface.hex=interface.digit_string(d3) .. interface.digit_string(d2) .. interface.digit_string(d1) ..  interface.digit_string(d0)
    interface.score = tonumber(interface.digit_string(d3) .. interface.digit_string(d2) .. interface.digit_string(d1) ..  interface.digit_string(d0),16)/256
    interface.score =tostring(round( interface.score )*10)
    interface.score =interface.score:gsub("%.","")
    local dotU = output_value("3.7") -- punkt unten
    if dotU==1 then
      interface.score="-" .. interface.score:gsub("%.","")
      interface.hex="-" .. interface.hex
    end
  end
end
   
-- while it thinks the display shows the search depth (hex, last digit; the first digit counts the moves searched);
-- the hex score page the old code expected never appeared (12 minutes of thinking in a queen-down position)
function interface.show_info(on)
  if on ~= true then
    return nil
  end
  if output_value("digit1") == 0 then
    local depth = tonumber(interface.digit_string(output_value("digit0")), 16)
    if depth and depth > 0 then
      return { depth = depth }
    end
  end
  return nil
end

function round(num)
  local numDecimalPlaces=2
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end


function interface.digit_string(d)
     if d==nil then
        return("0")
    end
    if d==63 then
        return("0")
    elseif d==6 then
        return("1")
    elseif d==91 then
        return("2")
    elseif d==79 then
        return("3")
    elseif d==102 then
        return("4")
    elseif d==109 then
        return("5")
    elseif d==125 then
        return("6")
    elseif d==7 then
        return("7")
    elseif d==127 then
        return("8")
    elseif d==103 then
        return("9")
    elseif d==119 then
        return("a")
    elseif d==124 then
        return("b")
    elseif d==57 then
        return("c")
    elseif d==94 then
        return("d")
    elseif d==121 then
        return("e")
    elseif d==113 then
        return("f")
    elseif d==61 then
        return("g")
    elseif d==118 then
        return("h")
    elseif d==0 then
        return(" ")
    elseif d==28 then
        return("Nr.")
    elseif d==64 then
        return("-")
    elseif d==115 then
        return("P")
    elseif d==55 then
        return("N")
    else
        return (" hex" .. tostring(d) .. " ")
    end
end

return interface
