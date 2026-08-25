hs.ipc.cliInstall()

hs.hotkey.bind({ "cmd", "alt", "shift" }, "z", function()
	hs.notify.show("Reload", "Reloading configuration...", "")
	hs.timer.doAfter(0.5, function()
		hs.execute("/opt/homebrew/bin/aerospace reload-config")
		hs.execute("/opt/homebrew/bin/sketchybar --reload")
		hs.reload()
	end)
end)

local function runCommand(cmd, callback)
	local task = hs.task.new("/bin/zsh", function(exitCode, stdOut, stdErr)
		if callback then
			callback(exitCode, stdOut, stdErr)
		end
	end, { "-lc", cmd })
	task:start()
end

local caffeineTimer = nil

hs.hotkey.bind({ "cmd", "alt" }, "g", function()
	local isActive = hs.caffeinate.get("displayIdle")

	if isActive then
		if caffeineTimer then
			caffeineTimer:stop()
			caffeineTimer = nil
		end
		hs.caffeinate.set("displayIdle", false)
		hs.caffeinate.set("systemIdle", false)
		hs.notify.show("Caffeine", "Sleep prevention disabled", "")
	else
		hs.caffeinate.set("displayIdle", true)
		hs.caffeinate.set("systemIdle", true)
		caffeineTimer = hs.timer.new(3600, function()
			hs.caffeinate.set("displayIdle", false)
			hs.caffeinate.set("systemIdle", false)
			caffeineTimer = nil
			hs.notify.show("Caffeine", "Auto-disabled after 1 hour", "")
		end)
		caffeineTimer:start()
		hs.notify.show("Caffeine", "Preventing sleep for 1 hour", "")
	end
end)

hs.hotkey.bind({ "cmd", "alt", "shift" }, "g", function()
	local isActive = hs.caffeinate.get("displayIdle")

	if isActive then
		if caffeineTimer and caffeineTimer:running() then
			local remaining = caffeineTimer:nextTrigger()
			local minutes = math.floor(remaining / 60)
			local seconds = math.floor(remaining % 60)
			hs.notify.show("Caffeine", "Status: Active", string.format("Remaining: %d:%02d", minutes, seconds))
		else
			hs.notify.show("Caffeine", "Status: Active", "No timer set")
		end
	else
		local displaySleep = hs.execute("pmset -g | grep displaysleep | awk '{print $2}'"):gsub("%s+$", "")
		hs.notify.show("Caffeine", "Status: Inactive", string.format("Display sleeps in %s min", displaySleep))
	end
end)

local lastHandledId = 0
local SWIPE_THRESHOLD = 0.07

Swipe = hs.loadSpoon("Swipe")
Swipe:start(3, function(direction, distance, id)
	if id <= lastHandledId then
		return
	end

	if distance < SWIPE_THRESHOLD then
		return
	end

	lastHandledId = id

	if direction == "left" then
		runCommand("/opt/homebrew/bin/aerospace workspace --wrap-around prev --no-stdin")
	elseif direction == "right" then
		runCommand("/opt/homebrew/bin/aerospace workspace --wrap-around next --no-stdin")
	elseif direction == "down" then
		hs.execute('open "raycast://extensions/raycast/navigation/switch-windows"')
	end
end)

local function bindMouseDoublePress(buttonNumber, singleFn, doubleFn, timeout)
	local state = { clickCount = 0, timer = nil, downData = nil, upData = nil }
	local eventtap

	eventtap = hs.eventtap.new({
		hs.eventtap.event.types.otherMouseDown,
		hs.eventtap.event.types.otherMouseUp,
	}, function(event)
		local pressedButton = event:getProperty(hs.eventtap.event.properties.mouseEventButtonNumber)
		if pressedButton ~= buttonNumber then
			return false
		end

		if event:getProperty(hs.eventtap.event.properties.eventSourceUnixProcessID) > 0 then
			return false
		end

		local eventType = event:getType()

		if eventType == hs.eventtap.event.types.otherMouseDown then
			state.clickCount = state.clickCount + 1

			if state.clickCount == 1 then
				state.downData = event:asData()
				state.timer = hs.timer.doAfter(timeout, function()
					local downData = state.downData
					local upData = state.upData
					state.clickCount = 0
					state.timer = nil
					state.downData = nil
					state.upData = nil

					if downData then
						hs.eventtap.event.newEventFromData(downData):post()
					end
					if upData then
						hs.eventtap.event.newEventFromData(upData):post()
					end

					if singleFn then
						singleFn()
					end
				end)
				return true
			elseif state.clickCount == 2 then
				if state.timer then
					state.timer:stop()
					state.timer = nil
				end
				state.clickCount = 0
				state.downData = nil
				state.upData = nil
				doubleFn()
				return true
			end
		elseif eventType == hs.eventtap.event.types.otherMouseUp then
			if state.clickCount == 1 and not state.upData then
				state.upData = event:asData()
			end
			return true
		end

		return false
	end)

	eventtap:start()
	return eventtap
end

bindMouseDoublePress(4, nil, function()
	hs.execute('open "raycast://extensions/raycast/navigation/switch-windows"')
end, 0.3)

bindMouseDoublePress(3, nil, function()
	hs.execute('open "raycast://extensions/limonkufu/aerospace/showShortcuts"')
end, 0.3)

hs.hotkey.bind({ "cmd", "alt" }, "t", function()
	hs.execute('open "obsidian://adv-uri?vault=brain&commandid=tasknotes%3Acreate-new-task"')
end)

hs.hotkey.bind({ "cmd", "alt", "shift" }, "t", function()
	hs.execute('open "obsidian://adv-uri?vault=brain&filepath=Tasks%2FTasks.base"')
end)
