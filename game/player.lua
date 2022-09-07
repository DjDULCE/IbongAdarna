local Player = class({
    name = "player"
})

local data = {
    walk = { 49,  53},
    attack = {92, 49}
}

local healths = {10, 8, 5}
local damages = {3, 2, 1}

function Player:new(x, y, difficulty)
    self.images = Assets.load_images("player")
    self.ui = Assets.load_images("ui")
    self.x = x
    self.y = y
    self.dir = 1
    self.health = healths[difficulty]
    self.damage = damages[difficulty]
    self.damage = 100

    self.cur_anim = "walk"

    self.speed = 256
    self.gravity = 256
    self.current_meter = 0
    self.anim_loop = 0

    local walk_width, walk_height = self.images.walk:getDimensions()
    local walk_w, walk_h = unpack(data.walk)
    local grid_walk = Anim8.newGrid(walk_w, walk_h, walk_width, walk_height)
    self.anim_walk = Anim8.newAnimation(grid_walk("1-9", 1), 0.1)

    local aw, ah = self.images.attack:getDimensions()
    local atw, ath = unpack(data.attack)
    local grid_attack = Anim8.newGrid(atw, ath, aw, ah)
    self.anim_attack = Anim8.newAnimation(grid_attack("1-4", 1), 0.1,
        function(anim)
            self.anim_loop = self.anim_loop + 1
            if self.anim_loop >= 2 then
                anim:gotoFrame(1)
                self:end_attack()
                self.anim_loop = 0
            end
        end)

    self.anim = self.anim_walk
    self.width, self.height = unpack(data[self.cur_anim])

    self.ox = self.width * 0.5

    self.vpos = vec2(self.x, self.y)
    self.vsize = vec2(self.width * 0.5, self.height * 0.5)

    self.can_move = true

    Events.register(self, "on_down_left")
    Events.register(self, "on_down_right")
    Events.register(self, "on_clicked_a")
    Events.register(self, "on_clicked_b")
    Events.register(self, "on_collide")
    Events.register(self, "on_remove_collide")
    Events.register(self, "start_battle")
    Events.register(self, "end_battle")
    Events.register(self, "start_attack")
    Events.register(self, "end_attack")
    Events.register(self, "damage_player")
end

function Player:damage_player(damage)
    Events.emit("display_damage", self, damage)
    self.health = self.health - damage

    if self.health <= 0 then
        error("Game Over")
    end
end

function Player:start_battle()
    self.anim:gotoFrame(1)
end

function Player:end_battle()
    self.anim:gotoFrame(1)
    self.can_move = true
end

function Player:start_attack()
    self.cur_anim = "attack"
    self.anim = self.anim_attack
    self.dir = -self.dir
    self.width, self.height = unpack(data[self.cur_anim])
    self.target_x = self.x + 128
    self.timer_attack = timer(1,
        function(progress)
            self.x = mathx.lerp(self.x, self.target_x, progress)
            self.anim:update(love.timer.getDelta())
        end)
end

function Player:end_attack()
    Events.emit("damage_enemy", self.damage)
    self.anim_attack:pauseAtStart()
    self.target_x = self.x - 128
    self.timer_attack = timer(1,
        function(progress)
            self.x = mathx.lerp(self.x, self.target_x, progress)
            self.anim:update(love.timer.getDelta())
        end,
        function()
            self.timer_attack = nil
            self.cur_anim = "walk"
            self.anim = self.anim_walk
            self.dir = -self.dir
            self.width, self.height = unpack(data[self.cur_anim])
            self.target_x = nil
            Events.emit("finished_turn")
        end)
end

function Player:on_down_left()
    if not self.can_move then return end
    if self.current_meter <= 0 then return end

    local dt = love.timer.getDelta()
    if not self.fake_move then
        self.x = self.x - self.speed * dt
        self.vpos.x = self.x
    end
    self.dir = 1
    self.anim:update(dt)
    Events.emit("on_player_move_x", -1, dt)
end

function Player:on_down_right()
    if not self.can_move then return end
    local dt = love.timer.getDelta()
    if not self.fake_move then
        self.x = self.x + self.speed * dt
        self.vpos.x = self.x
    end
    self.dir = -1
    self.anim:update(dt)
    Events.emit("on_player_move_x", 1, dt)
end

function Player:on_clicked_a()
    if not self.ref_other then return end
    Events.emit("on_dialogue_show")
end

function Player:on_clicked_b()
end

function Player:on_collide(other)
    self.ref_other = other
    if self.notif then
        self.notif.alpha = 1
        return
    end
    local sbw, sbh = self.ui.speech_bubble:getDimensions()
    local scale = 0.25
    self.notif = Sprite({
        image = self.ui.speech_bubble,
        x = other.x + sbw * scale * 0.5,
        y = other.y - other.vsize.y,
        ox = sbw * 0.5, oy = sbh,
        sx = scale, sy = scale,
    })
end

function Player:on_remove_collide()
    if self.notif then
        self.notif.alpha = 0
        self.ref_other = nil
    end
end

function Player:update(dt, ground_height)
    if self.timer_attack then self.timer_attack:update(dt) end
    self.y = self.y + self.gravity * dt
    self.vpos.y = self.y

    while (self.x - self.vsize.x) < 0 do
        self.x = self.x + dt
    end

    while (self.x + self.vsize.x) > WW do
        self.x = self.x - dt
    end

    while (self.y + self.height) > (WH - ground_height) do
        self.y = self.y - dt
    end
end

function Player:draw()
    love.graphics.setColor(1, 1, 1, 1)
    self.anim:draw(self.images[self.cur_anim], self.x, self.y, 0, self.dir, 1, self.ox, 0)
    if self.notif then self.notif:draw() end
    love.graphics.setColor(1, 1, 1, 1)
end

return Player
