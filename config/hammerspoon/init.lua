hs.hotkey.bind({ "cmd", "shift", "alt" }, "g", function()
	hs.reload()
	hs.notify.show("Hammerspoon", "Config Reloaded", 3600)
end)

local function runCommand(cmd, callback)
	local task = hs.task.new("/bin/zsh", function(exitCode, stdOut, stdErr)
		if callback then
			callback(exitCode, stdOut, stdErr)
		end
	end, { "-lc", cmd })
	task:start()
end

hs.hotkey.bind({ "cmd", "alt" }, "g", function()
	hs.caffeinate.set("display", true, 3600)
	hs.caffeinate.set("system", true, 3600)
	hs.notify.show("Caffeine", "Preventing sleep for 1 hour", "")
end)

hs.hotkey.bind({ "cmd", "alt" }, "G", function()
	hs.caffeinate.set("display", false)
	hs.caffeinate.set("system", false)
	hs.notify.show("Caffeine", "Sleep prevention disabled", "")
end)

local lastHandledId = 0
Swipe = hs.loadSpoon("Swipe")
Swipe:start(3, function(direction, distance, id)
	if id <= lastHandledId then
		return
	end
	lastHandledId = id

	if direction == "left" then
		runCommand("/opt/homebrew/bin/aerospace workspace --wrap-around prev --no-stdin")
	elseif direction == "right" then
		runCommand("/opt/homebrew/bin/aerospace workspace --wrap-around next --no-stdin")
	end
end)
