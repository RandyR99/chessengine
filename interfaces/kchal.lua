interface = {}

local function output_value(name)
	local out = machine.devices[":"]:output(name)
	return out ~= nil and out:get() or 0
end

interface.level = 6
interface.cur_level = nil
interface.prom = false
local pv1 = ""
local pv2 = ""
local pv3 = ""
local l_pv = ""
local score = ""
local counter = 0

-- the machine switches itself off after a few idle minutes: the LCD is then blank
-- and the CPU is in standby (PC stands still); the LCD alone also blanks in play
local function On()
	for i = 0, 23 do
		if output_value("s0." .. i) ~= 0 or output_value("s1." .. i) ~= 0 then
			return
		end
	end
	local state = machine.devices[":maincpu"].state["PC"]
	local pc = state.value
	for t = 1, 8 do
		emu.wait(0.05)
		if state.value ~= pc then
			return
		end
	end
	send_input(":IN.1", 0x01, 0.5) -- ON/OFF
	emu.wait(1)
end

function interface.get_author()
    return "G.Horvath"
end

function getdigit(n, ascii)
    local segments = {
        {"s0.0", "s0.21", "s1.21", "s1.22", "s0.22", "s1.0", "s0.23"},
        {"s0.4", "s0.19", "s1.19", "s1.20", "s0.20", "s1.3", "s0.3"},
        {"s0.5", "s0.16", "s1.16", "s1.17", "s0.17", "s1.5", "s0.18"},
        {"s0.9", "s0.14", "s1.14", "s1.15", "s0.15", "s1.8", "s0.8"},
        {"s0.11", "s0.12", "s1.12", "s1.13", "s0.13", "s1.10", "s0.10"}
    }
    local digit = 0x00
    for i = 1, 7 do
        if (output_value(segments[n][i]) ~= 0) then
            digit = digit | (1 << (i - 1))
        end
    end
    if ascii == 1 then return digit_ascii(digit) end

    return digit
end

function interface.show_info(on)
    local colon = output_value("s0.6")
    if on == true then
        local d1 = getdigit(1, 1)
        local d2 = getdigit(2, 1)
        local d3 = getdigit(3, 1)
        local d4 = getdigit(4, 1)
        local d5 = getdigit(5, 1)
        local dot = output_value("s0.7")
        if d2:sub(1, 1) == "?" or d2:sub(1, 1) == "?" or d2:sub(1, 1) == "?" or
            d2:sub(1, 1) == "?" then
            emu.wait(0.1)
            d2 = getdigit(2, 1)
            d3 = getdigit(3, 1)
            d4 = getdigit(4, 1)
            d5 = getdigit(5, 1)
        end
        if colon == 1 then
            counter = 1
            l_pv = ""
        elseif dot == 1 then
            score = d2 .. d3 .. d4 .. d5
            counter = 1
            l_pv = ""
        elseif d5 == " " then
        else
            if counter == 1 and l_pv ~= d2 .. d3 .. d4 .. d5 then
                pv1 = d2 .. d3 .. d4 .. d5
                l_pv = pv1
                counter = 2

            elseif counter == 2 and l_pv ~= d2 .. d3 .. d4 .. d5 then
                pv2 = d2 .. d3 .. d4 .. d5
                l_pv = pv2
                counter = 3
                if pv2 == "____" then pv3 = "" end
            elseif counter == 3 and l_pv ~= d2 .. d3 .. d4 .. d5 then
                pv3 = d2 .. d3 .. d4 .. d5
                l_pv = pv3

            end
        end
        return
            "info score cp " .. score .. " depth 1 pv " .. pv1 .. " " .. pv2 ..
                " " .. pv3
    else
        pv1 = ""
        pv2 = ""
        pv3 = ""
        l_pv = ""
        counter = 1
    end
end

function interface.setlevel()
    On()
    if (interface.cur_level == nil or interface.cur_level == interface.level) then
        return
    end
    local cl = interface.cur_level % 100
    local nl = interface.level % 100
    local throttled = machine.video.throttled
    machine.video.throttled = false
    emu.wait(0.5)
    interface.cur_level = interface.level
    send_input(":IN.0", 0x08, 0.5) -- Level
    local val = {0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x6f}
    local key
    local dig

    if (nl > cl and nl <= cl + 50) or (nl < cl and nl <= cl - 50) then
        key = ":IN.0"
    else
        key = ":IN.1"
    end
    local d5 = nl % 10
    local d4 = (nl - d5) / 10
    dig = val[d4 + 1]
    emu.wait(0.5)
    ioport.ports[key]:field(0x10):set_value(1) -- Right/Left on
    repeat emu.wait(0.1) until getdigit(4) == dig
    ioport.ports[key]:field(0x10):set_value(0) -- Right/Left off

    emu.wait(0.5)
    dig = getdigit(5)
    for i = 0, 9 do
        if dig == val[i + 1] then
            cl = i
            break
        end
    end
    local dl = d5 - cl
    if dl > 0 then
        key = ":IN.0"
    else
        key = ":IN.1"
    end
    emu.wait(0.5)
    for i = 1, math.abs(dl) do
        send_input(key, 0x10, 0.25) -- Right/Left
        emu.wait(0.5)
    end

    emu.wait(0.5)
    send_input(":IN.0", 0x08, 0.5) -- Level
    machine.video.throttled = throttled
end

function interface.setup_machine()
    sb_reset_board(":board")
    send_input(":IN.1", 0x80, 2.5) -- New Game
    interface.cur_level = 6
    interface.setlevel()
    send_input(":IN.1", 0x20, 0.5) -- Info
    emu.wait(0.5)
    send_input(":IN.1", 0x20, 0.5) -- Info
    emu.wait(0.5)
    send_input(":IN.0", 0x20, 0.5) -- Analysis
    emu.wait(0.5)
    send_input(":IN.1", 0x20, 0.5) -- Info
end

function setpiece(n)
    if (n == 1) then
        send_input(":IN.1", 0x02, 0.5) -- K
    elseif (n == 2) then
        send_input(":IN.0", 0x02, 0.5) -- Q
    elseif (n == 3) then
        send_input(":IN.0", 0x40, 0.5) -- R
    elseif (n == 4) then
        send_input(":IN.1", 0x40, 0.5) -- B
    elseif (n == 5) then
        send_input(":IN.0", 0x01, 0.5) -- N
    elseif (n == 6) then
        send_input(":IN.0", 0x80, 0.5) -- P
    end
end

function interface.edit_game()
    On()
    send_input(":IN.0", 0x20, 0.5) -- Multi Move
end

function interface.start_play(init)
    On()
    send_input(":IN.1", 0x04, 0.5) -- Move
end

function interface.stop_play()
    On()
    send_input(":IN.1", 0x04, 0.5) -- Move
end

function interface.is_selected(x, y)
    local xval = output_value("1." .. 8 - x) ~= 0
    local yval = output_value("0." .. y - 1) ~= 0
    return xval and yval
end

function interface.select_piece(x, y, event)
    On()
    emu.wait(0.5)
    if (event == "en_passant") then
        sb_remove_piece(":board", x, y)
        if interface.is_selected(x, y) then
            sb_press_square(":board", 0.5, x, y)
        end
    else
        local led = true
        if event == "get" then led = interface.is_selected(x, y) end
        sb_select_piece(":board", 0.5, x, y, event)
        if not led and not interface.is_selected(x, y) then
            sb_press_square(":board", 0.5, x, y)
        end
    end
end

function interface.get_options()
    return {
        {"spin", "Level", "6", "1", "100"},
        {"spin", "Again Queen", "10", "0", "99"},
        {"spin", "Pawn around King", "10", "0", "99"},
        {"spin", "King attack", "10", "0", "99"},
        {"spin", "Aggressive with White", "10", "0", "99"},
        {"spin", "Aggressive with Black", "10", "0", "99"},
        {"spin", "Doubled Pawns", "10", "0", "99"},
        {"spin", "Rook (half)open lines", "10", "0", "99"}
    }
end

function interface.set_option(name, value)
    if (name == "level") then
        local level = tonumber(value)
        if (level < 1 or level > 100) then return end
        interface.level = level
        interface.setlevel()
    elseif (name == "again queen") then
        if (tonumber(value) < 0 or tonumber(value) > 99) then return end
        interface.feature(1, tonumber(value))
    elseif (name == "pawn around king") then
        if (tonumber(value) < 0 or tonumber(value) > 99) then return end
        interface.feature(2, tonumber(value))
    elseif (name == "king attack") then
        if (tonumber(value) < 0 or tonumber(value) > 99) then return end
        interface.feature(3, tonumber(value))
    elseif (name == "aggressive with white") then
        if (tonumber(value) < 0 or tonumber(value) > 99) then return end
        interface.feature(4, tonumber(value))
    elseif (name == "aggressive with black") then
        if (tonumber(value) < 0 or tonumber(value) > 99) then return end
        interface.feature(5, tonumber(value))
    elseif (name == "doubled pawns") then
        if (tonumber(value) < 0 or tonumber(value) > 99) then return end
        interface.feature(6, tonumber(value))
    elseif (name == "rook (half)open lines") then
        if (tonumber(value) < 0 or tonumber(value) > 99) then return end
        interface.feature(7, tonumber(value))
    end
end

function interface.get_promotion(x, y)
    return nil -- the machine shows its promotion piece after the move
end

function interface.test_promotion(x, y)
    On()
    emu.wait(0.5)
    interface.prom = true
    for i = 1, 4 do
        if output_value("s1.9") ~= 0 then
            send_input(":IN.0", 0x02, 0.5)
            return "Q"
        elseif output_value("s1.7") ~= 0 then
            send_input(":IN.0", 0x40, 0.5)
            return "R"
        elseif output_value("s1.6") ~= 0 then
            send_input(":IN.1", 0x40, 0.5)
            return "B"
        elseif output_value("s1.4") ~= 0 then
            send_input(":IN.0", 0x01, 0.5)
            return "N"
        end
        emu.wait(0.25)
    end
end

function interface.promote(x, y, piece)
    emu.wait(0.5)
    piece = string.lower(piece)
    if interface.prom == false then
        if (piece == "q") then
            send_input(":IN.0", 0x02, 0.5)
        elseif (piece == "r") then
            send_input(":IN.0", 0x40, 0.5)
            send_input(":IN.0", 0x40, 0.5)
        elseif (piece == "b") then
            send_input(":IN.1", 0x40, 0.5)
            send_input(":IN.1", 0x40, 0.5)
        elseif (piece == "n") then
            send_input(":IN.0", 0x01, 0.5)
            send_input(":IN.0", 0x01, 0.5)
        end
    end
    interface.prom = false
    sb_promote(":board", x, y, piece)
end

function digit_ascii(digit)
    local mapping = {
        [8] = "_",
        [64] = "-",
        [128] = "_",
        [0] = " ",
        [63] = "0",
        [6] = "1",
        [91] = "2",
        [79] = "3",
        [102] = "4",
        [109] = "5",
        [125] = "6",
        [7] = "7",
        [127] = "8",
        [111] = "9",
        [119] = "a",
        [124] = "b",
        [88] = "c",
        [57] = "c",
        [94] = "d",
        [121] = "e",
        [113] = "f",
        [61] = "g",
        [118] = "h",
        [4] = "i",
        [116] = "k",
        [56] = "l",
        [84] = "n",
        [92] = "o",
        [115] = "p",
        [80] = "r",
        [120] = "t",
        [28] = "u",
        [122] = "y",
        [73] = "#", -- 3 waagerechte Balken
        [9] = "|" -- 2 waagerechte Balken
    }

    return mapping[digit] or "?" .. digit .. "?"
end

function interface.feature(fx, value)
    send_input(":IN.1", 0x20, 0.5) -- Info
    emu.wait(0.5)
    send_input(":IN.1", 0x20, 0.5) -- Info
    emu.wait(0.5)
    for i = 1, fx do
        send_input(":IN.0", 0x04, 0.5) -- feature
        emu.wait(0.5)
    end
    local dx4 = getdigit(4, 1)
    local dx5 = getdigit(5, 1)
    if tonumber(dx4 .. dx5) == value then
        send_input(":IN.1", 0x20, 0.5) -- Info
        return
    end
    local cl = tonumber(dx4 .. dx5) % 100
    local nl = value % 100
    local throttled = machine.video.throttled
    machine.video.throttled = false
    emu.wait(0.5)
    local val = {0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x6f}
    local key
    local dig

    if (nl > cl and nl <= cl + 50) or (nl < cl and nl <= cl - 50) then
        key = ":IN.0"
    else
        key = ":IN.1"
    end
    local d5 = nl % 10
    local d4 = (nl - d5) / 10
    dig = val[d4 + 1]
    emu.wait(0.5)
    ioport.ports[key]:field(0x10):set_value(1) -- Right/Left on
    repeat emu.wait(0.1) until getdigit(4) == dig
    ioport.ports[key]:field(0x10):set_value(0) -- Right/Left off
    emu.wait(0.5)
    dig = getdigit(5)
    for i = 0, 9 do
        if dig == val[i + 1] then
            cl = i
            break
        end
    end
    local dl = d5 - cl
    if dl > 0 then
        key = ":IN.0"
    else
        key = ":IN.1"
    end
    emu.wait(0.5)
    for i = 1, math.abs(dl) do
        send_input(key, 0x10, 0.25) -- Right/Left
        emu.wait(0.5)
    end
    emu.wait(0.5)
    send_input(":IN.1", 0x20, 0.5) -- Info
    machine.video.throttled = throttled
end

function interface.set_pos(mode)
    On()
    if mode == 0 then
        send_input(":IN.0", 0x04, 0.5) -- Set Up
        send_input(":IN.1", 0x80, 0.5) -- Clear Board
        send_input(":IN.1", 0x80, 0.5) -- Clear Board
        return (":board")
    else
        local piece=7
        for y=1,8 do
            for x=1,8 do
                local p=get_piece_id(x,9-y)
                if p~=0 then
                    if p*piece<0 then
                        if p<0 then
                            send_input(":IN.1", 0x10, 0.5) -- Left (Black)
                        else
                            send_input(":IN.0", 0x10, 0.5) -- Right (White)
                        end
                    end
                    if math.abs(p)~=math.abs(piece) then
                        setpiece(math.abs(p))
                    end
                    sb_press_square(":board", 0.5, x, 9-y)
                    piece=p
                end
            end
        end
        if mode<0 then
            send_input(":IN.1", 0x10, 0.5) -- Left (Black)
        else
            send_input(":IN.0", 0x10, 0.5) -- Right (White)
        end
        send_input(":IN.0", 0x04, 0.5) -- Set Up
    end
end


return interface
