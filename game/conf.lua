function love.conf(t)
	t.title = "Ibong Adarna"
	t.modules.audio = true
	t.modules.data = true
	t.modules.event = true
	t.modules.font = true
	t.modules.graphics = true
	t.modules.image = true
	t.modules.joystick = false
	t.modules.keyboard = true
	t.modules.math = true
	t.modules.mouse = true
	t.modules.physics = false
	t.modules.sound = true
	t.modules.system = true
	t.modules.thread = true
	t.modules.timer = true
	t.modules.touch = true
	t.modules.video = false
	t.modules.window = true

	t.window.width = 1920/2
	t.window.height = 1080/2
	t.window.resizable = false
	t.console = true

	t.identity = "IbongAdarna"
	t.version = "11.3"
end
