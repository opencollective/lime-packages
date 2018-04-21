#!/usr/bin/lua

local libuci = require("uci")
local hardware_detection = require("lime.hardware_detection")
local config = require("lime.config")

local openwrt_wan = {}

openwrt_wan.sectionName = hardware_detection.sectionNamePrefix.."openwrt_wan"

function openwrt_wan.clean()
	if config.autogenerable(openwrt_wan.sectionName) then
		config.delete(openwrt_wan.sectionName)
	end
end

function openwrt_wan.detect_hardware()
	if config.autogenerable(openwrt_wan.sectionName) then
		local handle = io.popen("sh /usr/lib/lua/lime/hwd/openwrt_wan.sh")
		local ifname = handle:read("*a")
		handle:close()
		if ifname and ifname ~= "" then
			local protos = {}
			local net = require("lime.network")
			local utils = require("lime.utils")
			for _, pArgs in pairs(config.get("network", "protocols")) do
				local pArr = utils.split(pArgs, net.protoParamsSeparator)
				if ( pArr[1] == "bmx6" or pArr[1] == "bmx7") then
					pArr[2] = 0
					pArgs = table.concat(pArr, net.protoParamsSeparator)
					table.insert(protos, pArgs)
				elseif ( pArr[1]~="lan" and pArr[1]~="wan" ) then
					table.insert(protos, pArgs)
				end
			end
			table.insert(protos, "wan")

			config.init_batch()
			config.set(openwrt_wan.sectionName, "net")
			config.set(openwrt_wan.sectionName, "autogenerated", "true")
			config.set(openwrt_wan.sectionName, "protocols", protos)
			config.set(openwrt_wan.sectionName, "linux_name", ifname)
			config.end_batch()
		else
			print("No wan interface detected")
		end
	end
end

return openwrt_wan
