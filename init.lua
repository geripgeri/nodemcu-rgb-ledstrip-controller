-- Based on: https://github.com/nodemcu/nodemcu-firmware/blob/master/lua_examples/http_server.lua

red = 0
green = 0
blue = 0

-- Controlling the ledstrip with values between 0 and 255
function led()
    pwm.setduty(1, 4 * red)
    pwm.setduty(2, 4 * green)
    pwm.setduty(3, 4 * blue)
end

-- Setup pwm for pin 1,2,3
gpio.mode(0, gpio.OUTPUT)
gpio.write(0, gpio.LOW)

pwm.setup(1, 100, 0)
pwm.setup(2, 100, 0)
pwm.setup(3, 100, 0)
pwm.start(1)
pwm.start(2)
pwm.start(3)

-- Retrun the actual pwm value of the pins
function getLed()
    return red .. "," .. green .. "," .. blue
end

-- Your Wifi connection data

local SSID = "SSID"
local SSID_PASSWORD = "PASSWORD"

local function connect(conn, data)
    local query_data

    conn:on("receive",
        function(cn, req_data)
            params = get_http_req(req_data)
            -- Only accept if all colors are exist and the values are between 0 and 255
            if (params["r"] ~= nil and params["g"] ~= nil and params["b"] ~= nil) then
                if (tonumber(params["r"]) >= 0 and tonumber(params["r"]) < 256 and tonumber(params["g"]) >= 0 and tonumber(params["g"]) < 256 and tonumber(params["b"]) >= 0 and tonumber(params["b"]) < 256) then
                    red = tonumber(params["r"])
                    green = tonumber(params["g"])
                    blue = tonumber(params["b"])
                    print(led())
                else
                    cn:send("Wrong parameter")
                end
            end

            -- Send the actual values.
            cn:send(getLed())
   
            -- Close the connection for the request
            cn:close()
        end)
end

-- Build and return a table of the http request data
function get_http_req(instr)
    local t = {}
    local str = string.sub(instr, 0, 200)
    local v = string.gsub(split(str, ' ')[2], '+', ' ')
    parts = split(v, '?')
    local params = {}
    if (table.maxn(parts) > 1) then
        for idx, part in ipairs(split(parts[2], '&')) do
            parmPart = split(part, '=')
            params[parmPart[1]] = parmPart[2]
        end
    end
    return params
end

-- Source: http://lua-users.org/wiki/MakingLuaLikePhp
-- Credit: http://richard.warburton.it/
function split(str, splitOn)
    if (splitOn == '') then return false end
    local pos, arr = 0, {}
    for st, sp in function() return string.find(str, splitOn, pos, true) end do
        table.insert(arr, string.sub(str, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(str, pos))
    return arr
end

-- Configure the ESP as a station (client)
wifi.setmode(wifi.STATION)
wifi.sta.config(SSID, SSID_PASSWORD)
wifi.sta.autoconnect(1)

-- Hang out until we get a wifi connection before the httpd server is started.
tmr.alarm(1, 800, 1, function()
    if wifi.sta.getip() == nil then
        print("Waiting for Wifi connection")
    else
        tmr.stop(1)
        print("Config done, IP is " .. wifi.sta.getip())
    end
end)

-- Create the httpd server
svr = net.createServer(net.TCP, 30)

-- Server listening on port 80, call connect function if a request is received
svr:listen(80, connect)
