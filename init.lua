--[[
AUTHOR: Samuel M.H. <samuel.munoz@beeva.com>
DESCRIPTION: Lua script for NodeMCU.
 - Connect the ESP8266 chip to an access point.
 - Create a MQTT client.
 - Wait for an interruption to publish a message.
HW:
 - PIR motion sensor V1.0
]]

require "config" -- CONFIGURATION


-- Sensor Interruption callback
function presence_detected()
  print("[PIR] Presence detected")
  MQTT_CLIENT:publish(MQTT_TOPIC.."/PRESENCE", "1", 0 ,0,
    function(client) print("[MQTT] Published") end
  )
end

-- Main logic
function mqtt_connected(client)
  print("[MQTT] Connected "..MQTT_BROKER_IP..":"..MQTT_BROKER_PORT)
end

function mqtt_disconnected(client, reason)
  print("[MQTT] Disconnected: "..reason)
  tmr.create():alarm(30000, tmr.ALARM_SINGLE, mqtt_connect)
end

function mqtt_connect()
  print("[MQTT] Connecting... ")
  -- Doc says do NOT use autoreconnect
  MQTT_CLIENT:connect(MQTT_BROKER_IP, MQTT_BROKER_PORT, 0, 0,
    mqtt_connected, mqtt_disconnected
  )
end

function launch_program()
  -- MQTT
  MQTT_CLIENT = mqtt.Client(THING_ID, 120)
  mqtt_connect()

  -- Initialize sensor
  gpio.mode(PIR_PIN, gpio.INT, gpio.PULLUP)
  gpio.trig(PIR_PIN, "up", presence_detected)
end


-- WiFi events
function print_ip()
  addr, nm, MQTT_BROKER_IP = wifi.sta.getip()
  print("[WIFI] GOTIP: "..addr)
  launch_program()
end

wifi.setmode(wifi.STATION)
wifi.sta.eventMonReg(wifi.STA_GOTIP, print_ip)
wifi.sta.eventMonReg(wifi.STA_IDLE, function() print("[WIFI] IDLE") end)
wifi.sta.eventMonReg(wifi.STA_CONNECTING, function() print("[WIFI] CONNECTING") end)
wifi.sta.eventMonReg(wifi.STA_WRONGPWD, function() print("[WIFI] WRONG_PASSWORD") end)
wifi.sta.eventMonReg(wifi.STA_APNOTFOUND, function() print("[WIFI] NO_AP_FOUND") end)
wifi.sta.eventMonReg(wifi.STA_FAIL, function() print("[WIFI] CONNECT_FAIL") end)


---
--- Run
---

print("[NODEMCU] Thing Id: "..THING_ID)


-- Launch WiFi
wifi.sta.eventMonStart()
wifi.sta.config(AP, PASSWORD)
