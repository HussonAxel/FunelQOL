local addonName, addon = ...

-- These assets are imported locally by tools/Import-Media.ps1.
-- Paths belong to FunelQOL: EllesmereUI does not need to be enabled at runtime.
local root = "Interface\\AddOns\\" .. addonName .. "\\Media\\Ellesmere\\"

addon.media = {
    textures = {
        pixelsFill = root .. "textures\\pixels-fill.tga",
        pixelsDark = root .. "textures\\pixels-dark.tga",
        pixelsBackground = root .. "textures\\pixels-bg.tga",
    },
    borders = {
        pixels = {
            name = "Pixels",
            edgeFile = root .. "borders\\pixels.tga",
            separatorHorizontal = root .. "borders\\pixels-sep.tga",
            separatorVertical = root .. "borders\\pixels-vsep.tga",
        },
        pixelsTextured = {
            name = "Pixels Textured",
            edgeFile = root .. "borders\\pixels-textured.tga",
            separatorHorizontal = root .. "borders\\pixels-textured-sep.tga",
            separatorVertical = root .. "borders\\pixels-textured-vsep.tga",
        },
    },
    shields = {
        pixels = root .. "textures\\shields\\pixels-shield.tga",
        pixelsEdge = root .. "textures\\shields\\pixels-shield-edge.tga",
        pixelsFill = root .. "textures\\shields\\pixels-shield-fill.tga",
        pixelsGlowLine = root .. "textures\\shields\\pixels-glowline.tga",
        pixelsOvershieldLine = root .. "textures\\shields\\pixels-overshield-line.tga",
    },
}
