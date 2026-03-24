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
	end
end)
