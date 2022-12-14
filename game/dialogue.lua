local Dialogue = class({
    name = "Dialogue"
})

local padding = 32
local mapping = {
    ["Don Juan"] = "player",
    ["Haring Fernando"] = "fernando",
    ["Ermitanyo"] = "ermitanyo",
    ["Don Diego"] = "diego",
    ["Don Pedro"] = "pedro",
    ["Higante"] = "giant",
    ["Prinsesa Juana"] = "juana",
    ["Serpyente"] = "serpent",
    ["Agila"] = "eagle",
    ["Prinsesa Maria"] = "maria",
    ["Haring Salermo"] = "salermo",
}

function Dialogue:new(opt)
    self.id = opt.id
    self.images = Assets.load_images("dialogue")
    self.faces = Assets.load_images("faces")
    self.sfx = Assets.load_sources("sfx", "static")
    self.sfx.dialogue_next:setLooping(false)
    for _, sfx in pairs(self.sfx) do
        sfx:setVolume(UserData.data.music * 0.5)
    end

    self.vos = Assets.load_vo(self.id)
    self.vo_index = 1

    self.enabled = not not opt.enabled
    self.repeating = opt.repeating
    self.simple = opt.simple

    self.data = opt.data
    self.current = 1
    self.text_index = 0

    self.w = opt.w or WW * 0.6
    self.bg_w = WW * 0.85
    self.h = WH * 0.3
    self.align = opt.align or "center"
    self.font = opt.font
    self.alpha = opt.alpha or 1
    self.color = opt.color or {1, 1, 1}
    self.speed = opt.speed or 1

    self.y = WH - self.font:getHeight() * 6 - padding * 0.25

    local bg_w, bg_h = self.images.bg:getDimensions()
    self.bg = {
        x = HALF_WW,
        y = self.y + self.h * 0.5,
        sx = (self.bg_w + padding * 1.5)/bg_w,
        sy = (self.h + padding * 1.5)/bg_h,
        ox = bg_w * 0.5,
        oy = bg_h * 0.5,
    }

    Events.register(self, "on_down_left")
    Events.register(self, "on_down_right")
    Events.register(self, "on_clicked_a")
    Events.register(self, "on_clicked_b")
    Events.register(self, "on_dialogue_show")
    Events.register(self, "on_exit")

    if self.enabled then
        self:show()
    end
end

function Dialogue:on_dialogue_show(id)
    if id and id ~= self then return end
    self.enabled = true
    self:show()
end

function Dialogue:show()
    if not self.enabled then return end
    local data = self.data[self.current]
    if not data then
        self.enabled = false
        self.current_name = nil
        self:on_exit()
        Events.emit("on_dialogue_end", self)

        if self.repeating then
            self.current = 1
            self.text_index = 0
        end
        return
    end

    self.current_vo = self.vos[tostring(self.vo_index)]
    if self.current_vo then
        self.current_vo:setLooping(false)
        self.current_vo:play()
        self.current_vo:setVolume(1)
        self.vo_index = self.vo_index + 1
    end

    self.current_name = data.name

    self.text_index = self.text_index + 1
    if self.text_index > #data then
        self.current = self.current + 1
        self.text_index = 0
        self.vo_index = self.vo_index - 1
        self:show()
        return
    end

    local next_text = data[self.text_index]
    if not next_text then
        self.current_name = nil
        return
    end

    self.text = next_text
    self.dt = 0
    self.t = 1
    self.skipped = false

    if self.sfx.dialogue_next:isPlaying() then
        self.sfx.dialogue_next:stop()
    end
    self.sfx.dialogue_next:play()

    if self.simple then
        self.w = self.bg_w
        self.x = self.bg.x - self.w * 0.5
        return
    end

    local face = mapping[data.name]
    if not face then
        error("no face asset found for " .. data.name)
    end

    local face_image = self.faces[face]
    local fw, fh = face_image:getDimensions()
    self.face = face_image
    self.fy = self.y + fh * 0.5
    self.fox = fw * 0.5
    self.foy = fh * 0.5

    if data.side == "left" then
        self.fx = self.bg.x - self.bg.ox + fw + padding
        self.x = self.fx + fw * 0.5 + padding
        self.fsx = 1
    elseif data.side == "right" then
        self.x = self.bg.x - self.bg.ox + fw * 0.5 + padding
        self.fx = self.x + self.w + fw * 0.5 + padding
        self.fsx = -1

        if face == "serpent" then
            self.fsx = 1
        end
    end
end

function Dialogue:update(dt)
    if not self.enabled then return end

    for _, vo in pairs(self.vos) do
        if vo ~= self.current_vo then
            vo:stop()
        end
    end

    if self.skipped then return end
    self.dt = math.min(self.t, self.dt + dt * self.speed)
end

function Dialogue:draw()
    if not self.enabled then return end
    local r, g, b = unpack(self.color)
    love.graphics.setColor(r, g, b, self.alpha)

    love.graphics.draw(
        self.images.bg,
        self.bg.x, self.bg.y, 0,
        self.bg.sx, self.bg.sy,
        self.bg.ox, self.bg.oy
    )

    if not self.simple then
        love.graphics.draw(self.face, self.fx, self.fy, 0, self.fsx, 1, self.fox, self.foy)
    end

    love.graphics.setFont(self.font)
    love.graphics.setColor(0, 0, 0, 1)

    local y = self.y

    if self.current_name then
        love.graphics.print(self.current_name .. ":", self.x, y)
        y = self.y + self.font:getHeight() * 1.25
    end

    reflowprint(self.dt/self.t, self.text, self.x, y, self.w, self.align)
    love.graphics.setColor(1, 1, 1, 1)
end

function Dialogue:on_clicked_a()
    if not self.enabled then return end
    if self.dt >= self.t then
        self:show()
        return true
    end
    return true
end

function Dialogue:on_clicked_b()
    if not self.enabled then return end
    self.dt = self.dt + 1000
    return true
end

function Dialogue:on_down_left() if self.enabled then return true end end
function Dialogue:on_down_right() if self.enabled then return true end end

function Dialogue:on_exit()
    for _, vo in pairs(self.vos) do
        vo:stop()
    end
end

return Dialogue
