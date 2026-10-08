interface = load_interface("stratos")

interface.invert = false
interface.level = "a3"
interface.cur_level = nil
interface.firststart = true
interface.pv_depth = 0
interface.pv = ""

function interface.setup_machine()
    emu.wait(10)
    send_input(":IN.1", 0x04, 1) -- New Game
    emu.wait(2)
    sb_reset_board(":board")
    interface.invert = false
    interface.setlevel()
end

function interface.NewGame()
    emu.wait(10)
    send_input(":IN.1", 0x04, 1) -- New Game
    emu.wait(2)
    sb_reset_board(":board")
    interface.invert = false
    infoAnzeige_ein()
end

function infoAnzeige_ein()
    if interface.read_digit(1) ~= " info" then
        send_input(":IN.7", 0x04, 0.75) -- Normal
        repeat
            send_input(":IN.5", 0x02, 0.75) -- Function
            send_input(":IN.6", 0x02, 0.75) -- info
            emu.wait(0.25)
        until interface.read_digit(1) == " info"
    end
end

function interface.start_play(init)
    if (init) then
        sb_rotate_board(":board")
        interface.invert = true
    end
    send_input(":IN.4", 0x01, 1) -- Play
end

function interface.read_7_7_segment()
    local ddram
    if (machine.system.name == "tkinga") or (machine.system.name == "tkingb") then
        local digit = {
            [43] = "+",
            [49] = "1",
            [50] = "2",
            [51] = "3",
            [52] = "4",
            [53] = "5",
            [54] = "6",
            [55] = "7",
            [56] = "8",
            [57] = "9",
            [59] = "-"
        }
        ddram =
            emu.item(machine.devices[':maincpu'].items['0/:nvram.u6']):read_block(
                0x0962, 0x2)
        return digit[ddram:byte(1)]
    else
        local digit = {
            [39] = "+",
            [29] = "1",
            [30] = "2",
            [31] = "3",
            [32] = "4",
            [33] = "5",
            [34] = "6",
            [35] = "7",
            [36] = "8",
            [37] = "9",
            [40] = "-"
        }
        ddram =
            emu.item(machine.devices[':maincpu'].items['0/:nvram.u6']):read_block(
                0x0a2a, 0x2)
        return digit[ddram:byte(1)]
    end
    return digit[ddram:byte(1)]
end

-- function interface.show_info(on)
--    return "Anzeige = \n" ..interface.read_digit()  .. "\n Segment = \n" .. interface.read_7_7_segment()
-- end

function interface.read_digit(line)
    local ddram
    local info
    local info2
    if (machine.system.name == "tkinga") or (machine.system.name == "tkingb") then
        ddram =
            emu.item(machine.devices[':maincpu'].items['0/:nvram.u6']):read_block(
                0x095c, 0x10)
        info = digit_string(ddram:byte(2)) .. digit_string(ddram:byte(3)) ..
                   digit_string(ddram:byte(4)) .. digit_string(ddram:byte(5)) ..
                   digit_string(ddram:byte(6)) .. " Tking a/b"
        ddram =
            emu.item(machine.devices[':maincpu'].items['0/:nvram.u6']):read_block(
                0x0963, 0x10)
        info2 = digit_string(ddram:byte(2)) .. digit_string(ddram:byte(3)) ..
                    digit_string(ddram:byte(4)) .. digit_string(ddram:byte(5))
    else
        ddram =
            emu.item(machine.devices[':maincpu'].items['0/:nvram.u6']):read_block(
                0x0a24, 0x10)
        info = digit_string(ddram:byte(1)) .. digit_string(ddram:byte(2)) ..
                   digit_string(ddram:byte(3)) .. digit_string(ddram:byte(5)) ..
                   digit_string(ddram:byte(6))
        ddram =
            emu.item(machine.devices[':maincpu'].items['0/:nvram.u6']):read_block(
                0x0a2a, 0x10)
        info2 = digit_string(ddram:byte(2)) .. digit_string(ddram:byte(3)) ..
                    digit_string(ddram:byte(5)) .. digit_string(ddram:byte(6))
    end
    if line == 1 then
        return info
    elseif line == 2 then
        return info2
    end

    return info .. "\n" .. info2
end

function digit_string(d)
    if d == nil then return ("0") end

    if d == 63 or d == 63 + 128 then
        return ("0")
    elseif d == 92 then
        return ("o")
    elseif d == 8 then
        return ("_")
    elseif d == 20 then
        return ("i")
    elseif d == 80 then
        return ("r")
    elseif d == 32 or d == 0 then
        return (" ")
    elseif d == 16 then
        return ("i")
    elseif d == 84 then
        return ("n")
    elseif d == 56 then
        return ("l")
    elseif d == 110 then
        return ("y")
    elseif d == 120 then
        return ("t")
    elseif d == 14 then
        return ("") -- symbol clock
    elseif d == 6 or d == 6 + 128 then
        return ("1")
    elseif d == 91 or d == 91 + 128 then
        return ("2")
    elseif d == 79 or d == 79 + 128 then
        return ("3")
    elseif d == 102 or d == 102 + 128 then
        return ("4")
    elseif d == 109 or d == 109 + 128 then
        return ("5")
    elseif d == 125 or d == 125 + 128 then
        return ("6")
    elseif d == 7 or d == 7 + 128 then
        return ("7")
    elseif d == 127 or d == 127 + 128 then
        return ("8")
    elseif d == 111 or d == 111 + 128 then
        return ("9")
    elseif d == 119 or d == 119 + 128 then
        return ("a")
    elseif d == 124 then
        return ("b")
    elseif d == 57 or d == 88 then
        return ("c")
    elseif d == 94 then
        return ("d")
    elseif d == 121 then
        return ("e")
    elseif d == 113 then
        return ("f")
    elseif d == 61 then
        return ("g")
    elseif d == 116 then
        return ("h")
    elseif d == 0 or d == 128 then
        return (" ")
    elseif d == 28 then
        return ("Nr.")
    elseif d == 64 then
        return ("-")
    elseif d == 115 then
        return ("p")
    elseif d == 55 then
        return ("N")
    else
        return ((d) .. "?")
    end
end

return interface

