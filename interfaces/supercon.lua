interface = {}

interface.level = 2
interface.cur_level = nil

function interface.get_module()
	return "Novag Super Constellation"
end

function interface.get_author()
	return "David Kittinger"
end

function interface.setlevel()
	if (interface.cur_level == nil or interface.cur_level == interface.level) then
		return
	end
	interface.cur_level = interface.level
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	repeat
		send_input(":IN.6", 0x02, 0.5) -- Set Level
		local cur_level = 0
		for y = 0, 7 do
			if output:get_indexed_value("1.", y) ~= 0 then
				cur_level = cur_level + 1
			end
		end
	until cur_level == interface.level
	send_input(":IN.7", 0x01, 1) -- Go
	machine.video.throttled = throttled_state
end

function interface.setup_machine()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	sb_reset_board(":board")
	send_input(":IN.0", 0x01, 1) -- New Game
	emu.wait(5)
	machine.video.throttled = throttled_state
	interface.cur_level = 2
	interface.setlevel()
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	send_input(":IN.6", 0x02, 1) -- Set Level
	local d0 = output:get_value("0.2")
	if d0 == 0 then
		send_input(":IN.2", 0x02, 1) -- Depth Search
	end
	send_input(":IN.7", 0x01, 1) -- Go
	machine.video.throttled = throttled_state
end

function setpiece(n)
	if     (n == 1) then send_input(":IN.0", 0x02, 0.5) -- K
	elseif (n == 2) then send_input(":IN.1", 0x02, 0.5) -- Q
	elseif (n == 3) then send_input(":IN.4", 0x02, 0.5) -- R
	elseif (n == 4) then send_input(":IN.2", 0x02, 0.5) -- B
	elseif (n == 5) then send_input(":IN.3", 0x02, 0.5) -- N
	elseif (n == 6) then send_input(":IN.5", 0x02, 0.5) -- P
	end
end

function interface.set_pos(mode)
	local throttled_state = machine.video.throttled
	machine.video.throttled = false
	if mode == 0 then
		send_input(":IN.2", 0x02, 0.5) -- Sound
		send_input(":IN.1", 0x01, 0.5) -- Verify/Setup
		send_input(":IN.1", 0x01, 0.5) -- Verify/Setup
		send_input(":IN.3", 0x01, 0.5) -- Clear Board
		machine.video.throttled = throttled_state
		return (":board")
	else
		local piece = 7
		for y = 1, 8 do
			for x = 1, 8 do
				local p = get_piece_id(x, 9 - y)
				if p ~= 0 then
					if p * piece < 0 then
						send_input(":IN.2", 0x01, 0.5) -- Change Color
					end
					if math.abs(p) ~= math.abs(piece) then
						setpiece(math.abs(p))
					end
					sb_press_square(":board", 0.5, x, 9 - y)
					piece = p
				end
			end
		end
		send_input(":IN.7", 0x01, 0.5) -- GO
		if mode == -1 then
			send_input(":IN.2", 0x01, 0.5) -- Change Color
		end
		send_input(":IN.2", 0x02, 0.5) -- Sound
	end
	machine.video.throttled = throttled_state
end

function interface.edit_game()
	send_input(":IN.0", 0x02, 1) -- MultiMove
	emu.wait(1)
end

function interface.start_play(init)
	send_input(":IN.7", 0x01, 1) -- Go
end

function interface.is_selected(x, y)
	return (output:get_indexed_value("1.", (8 - y)) ~= 0) and (output:get_indexed_value("2.", (x - 1)) ~= 0)
end

function interface.select_piece(x, y, event)
	sb_select_piece(":board", 1, x, y, event)
end

function interface.get_options()
	return {
		{ "spin", "Level", "2", "1", "8" },
	}
end

function interface.set_option(name, value)
	if (name == "level") then
		local level = tonumber(value)
		if (level < 1 or level > 8) then
			return
		end
		interface.level = level
		interface.setlevel()
	end
end

function interface.get_promotion_led()
	if     (output:get_value("0.1") ~= 0) then return 'q'
	elseif (output:get_value("0.4") ~= 0) then return 'r'
	elseif (output:get_value("0.2") ~= 0) then return 'b'
	elseif (output:get_value("0.3") ~= 0) then return 'n'
	end
	return nil
end

function interface.get_promotion(x, y)
	for i = 1, 5 do
		local p = interface.get_promotion_led()
		if (p ~= nil) then
			return p
		end
		emu.wait(0.25)
	end
	return nil
end

function interface.promote(x, y, piece)
	sb_promote(":board", x, y, piece)
	emu.wait(1)
	if     (piece == "q") then send_input(":IN.1", 0x02, 1)
	elseif (piece == "r") then send_input(":IN.4", 0x02, 1)
	elseif (piece == "b") then send_input(":IN.2", 0x02, 1)
	elseif (piece == "n") then send_input(":IN.3", 0x02, 1)
	end
end

function interface.show_pv_after_move_player()
  send_input(":IN.3", 0x100, 0.5)        -- LV
  interface.score=0
  interface.depth=0
end
 
   
function interface.befor_move_from_engine()
  send_input(":IN.3", 0x100, 0.5)        -- LV
  local d1 = output:get_value("digit1")
  if d1 == 0 then interface.depth =  tonumber(interface.digit_string(d0),16) end
  send_input(":IN.5", 0x100, 0.5)  -- RE
  local d0 = output:get_value("digit0")
  d1 = output:get_value("digit1")
  local d2 = output:get_value("digit2")
  local d3 = output:get_value("digit3")
  local dotO = output:get_value("2.7")
  local dotU = output:get_value("3.7")
  if d3 ~=0 and d2 ~=0 and d1 ~=0 and d0 ~=0 and dotO== 0 then
    interface.hex=interface.digit_string(d3) .. interface.digit_string(d2) .. interface.digit_string(d1) ..  interface.digit_string(d0)
    interface.score = tonumber(interface.digit_string(d3) .. interface.digit_string(d2) .. interface.digit_string(d1) ..  interface.digit_string(d0),16)/256
    interface.score =tostring(round( interface.score )*10)
    interface.score =interface.score:gsub("%.","")
    local dotU = output:get_value("3.7") -- punkt unten
    if dotU==1 then
      interface.score="-" .. interface.score:gsub("%.","")
      interface.hex="-" .. interface.hex
    end
  end
end
   
function interface.show_info(ply)
  if ply==true then
    local d0 = output:get_value("digit0")
    local d1 = output:get_value("digit1")
    local d2 = output:get_value("digit2")
    local d3 = output:get_value("digit3")
    local dotO = output:get_value("2.7") -- punkt oben
    emu.wait(0.1)
    if d1 == 0 then interface.depth =  tonumber(interface.digit_string(d0),16)
    elseif d3 ~=0 and d2 ~=0 and d1 ~=0 and d0 ~=0 and dotO== 0 then
      interface.hex=interface.digit_string(d3) .. interface.digit_string(d2) .. interface.digit_string(d1) ..  interface.digit_string(d0)
      interface.score = tonumber(interface.digit_string(d3) .. interface.digit_string(d2) .. interface.digit_string(d1) ..  interface.digit_string(d0),16)/256
      interface.score =tostring(round( interface.score )*10)
      interface.score =interface.score:gsub("%.","")
      local dotU = output:get_value("3.7") -- punkt unten
      if dotU==1 then
        interface.score="-" .. interface.score:gsub("%.","")
        interface.hex="-" .. interface.hex
      end
    end
    if interface.depth==0 then  interface.score="book" end
  end
  return ("info score cp " ..  (interface.score) .. " depth " .. tostring(interface.depth) .. " hex " .. tostring(interface.hex))
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
