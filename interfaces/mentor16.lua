interface = {}

local function output_value(name)
    local out = machine.devices[":"]:output(name)
    return out ~= nil and out:get() or 0
end

interface.level = 1
interface.cur_level = nil

function interface.setlevel()
    if (interface.cur_level == nil or interface.cur_level == interface.level) then
        return
    end
    interface.cur_level = interface.level
    local cols_idx = {a = 1, b = 2, c = 3, d = 4, e = 5, f = 6, g = 7, h = 8}
    local x = cols_idx[interface.level:sub(1, 1)]
    local y = tonumber(interface.level:sub(2, 2))
    send_input(":IN.0", 0x40, 0.5) -- Set Level
    sb_press_square(":board", 0.5, x, y)
    send_input(":IN.1", 0x80, 0.5) -- Go
end

function interface.setup_machine()
    sb_reset_board(":board")
    send_input(":IN.1", 0x01, 0.5) -- New Game
    emu.wait(0.5)

    interface.cur_level = 1
    interface.setlevel()
end

function interface.set_pos(mode)
    if mode == 0 then
        send_input(":IN.0", 0x04, 0.5) -- Sound
        send_input(":IN.1", 0x02, 0.5) -- Verify/Setup
        send_input(":IN.1", 0x02, 0.5) -- Verify/Setup
        send_input(":IN.1", 0x08, 0.5) -- Clear Board
        return (":board")
    else
        local piece=7
        for y=1,8 do
            for x=1,8 do
                local p=get_piece_id(x,9-y)
                if p~=0 then
                    if p*piece<0 then
                        send_input(":IN.1", 0x04, 0.5) -- Change Color
                    end
                    if math.abs(p)~=math.abs(piece) then
                        setpiece(math.abs(p))
                    end
                    sb_press_square(":board", 0.5, x, 9-y)
                    piece=p
                end
            end
        end
        send_input(":IN.1", 0x80, 0.5) -- Go
        if mode==-1 then
            send_input(":IN.1", 0x04, 0.5) -- Change Color
        end
        send_input(":IN.0", 0x04, 0.5) -- Sound
    end
end

function interface.edit_game()
    send_input(":IN.0", 0x01, 0.5) -- Player/Player
    emu.wait(0.5)
end

function interface.start_play(init)
    send_input(":IN.1", 0x80, 0.5) -- Go
    emu.wait(0.5)
end

function interface.is_selected(x, y)
    local xval = output_value("1." .. tostring(8 - x)) ~= 0
    local yval = output_value("0." .. tostring(8 - y)) ~= 0
    return xval and yval
end

-- The machine sometimes ignores a square (and then shows ERROR on the next
-- one). A player's lifted piece lights its LEDs once accepted, so it is
-- pressed again until they do (the FROM square of the machine's own move is
-- already lit and goes dark when pressed, so it is left alone). Likewise the
-- TO square is pressed again while the FROM square stays lit.
local function lifted(x, y)
    for i = 1, 10 do
        if interface.is_selected(x, y) then
            return true
        end
        emu.wait(0.1)
    end
    return false
end

local function put_down(x, y)
    for i = 1, 10 do
        if not interface.is_selected(x, y) then
            return true
        end
        emu.wait(0.1)
    end
    return false
end

local from_sq = nil

function interface.select_piece(x, y, event)
    local shown = event == "get" and interface.is_selected(x, y)
    sb_select_piece(":board", 1, x, y, event)
    if event == "get" then
        from_sq = { x = x, y = y }
        if not shown then
            for i = 1, 3 do
                if lifted(x, y) then
                    break
                end
                sb_select_piece(":board", 1, x, y, event)
            end
        end
    elseif event == "put" and from_sq ~= nil then
        -- the FROM square stays lit if the TO square was ignored
        for i = 1, 3 do
            if put_down(from_sq.x, from_sq.y) then
                break
            end
            sb_select_piece(":board", 1, x, y, event)
        end
        from_sq = nil
    end
end

function interface.get_options() return {{"string", "Level", "a1"}} end

function interface.set_option(name, value)
    if (name == "level") then
        local level = value:lower():match("^%s*(.-)%s*$"):gsub("%s%s+", " ") -- trim
        if (level:match("^[a-f][1-8]$")) then
            interface.level = level
            interface.setlevel()
        end
    end
end

function interface.get_promotion(x, y)
    return 'q' 
end

function interface.promote(x, y, piece)
    promotion_error(piece)
    sb_promote(":board", x, y, "q") -- TODO
end

function setpiece(n)
    if     (n == 1) then send_input(":IN.0", 0x01, 0.5) -- K
    elseif (n == 2) then send_input(":IN.0", 0x02, 0.5) -- Q
    elseif (n == 3) then send_input(":IN.0", 0x10, 0.5) -- R
    elseif (n == 4) then send_input(":IN.0", 0x04, 0.5) -- B
    elseif (n == 5) then send_input(":IN.0", 0x08, 0.5) -- N
    elseif (n == 6) then send_input(":IN.0", 0x20, 0.5) -- P
    end
end

return interface
