---@class BigFont
local BigFont = {

    ---@type Image[]
    charImages = {},
    charWidth = 6,

    replacements = {
        ["forwardslash"] = "/"
    }
}

---Loads the font
function BigFont.load()
    local chars = os.listDirectory("plugins/libcomputer/bigfont")
    for i, v in pairs(chars) do
        local image = Image.new()
        image:loadFromFile("plugins/libcomputer/bigfont/" .. v.name)
        local name = BigFont.replacements[v.stem] or v.stem
        BigFont.charImages[name] = image
    end
end

---Draws a string
---@param computer LibComputerItem
---@param x number
---@param y number
---@param color Enum.color.computer
---@param str string
function BigFont.draw(computer, x, y, color, str)
    local i = 0
    for c in str:gmatch(".") do
        local image = BigFont.charImages[c]
        if image then
            for cy = 0, image.height - 1 do
                for cx = 0, image.width - 1 do
                    local r, g, b = image:getRGB(cx, cy)
                    if r == 255 and g == 255 and b == 255 then
                        computer:setChar(x + i * BigFont.charWidth + cx, y + cy, " ", color)
                    end
                end
            end
        end
        i = i + 1
    end
end

BigFont.load()

return BigFont
