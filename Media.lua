local addonName, addon = ...

-- These assets are imported locally by tools/Import-Media.ps1.
-- Paths belong to FunelQOL: source addons do not need to be enabled at runtime.
local root = "Interface\\AddOns\\" .. addonName .. "\\Media\\Ellesmere\\"

addon.media = {
    menuFont = "Interface\\AddOns\\" .. addonName .. "\\Media\\Fonts\\NotoSans-Bold.ttf",
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

local ayijeRoot = "Interface\\AddOns\\" .. addonName .. "\\Media\\AyijeUI\\"

addon.media.ayije = {
    statusbars = {
        aj_absorb = ayijeRoot .. "Statusbar\\aj_absorb.tga",
        Ayije_gradient_light = ayijeRoot .. "Statusbar\\Ayije_gradient_light.tga",
        Ayije_Hgradient = ayijeRoot .. "Statusbar\\Ayije_Hgradient.tga",
        Ayije_light = ayijeRoot .. "Statusbar\\Ayije_light.tga",
        blizzdesat = ayijeRoot .. "Statusbar\\blizzdesat.tga",
        focus = ayijeRoot .. "Statusbar\\focus.tga",
        ShieldAbsorbGlowline = ayijeRoot .. "Statusbar\\ShieldAbsorbGlowline.tga",
        Empty = ayijeRoot .. "Statusbar\\Empty.tga",
    },
    borders = {
        Ayije_Thin = { edgeFile = ayijeRoot .. "Borders\\Ayije_Thin.tga", edgeSize = 16 },
        Ayije_Empty = { edgeFile = ayijeRoot .. "Borders\\Ayije_Empty.tga", edgeSize = 16 },
    },
    textures = {
        auraRingEmpty = ayijeRoot .. "Textures\\Ayije_AuraRingEmpty.tga",
        circleMask = ayijeRoot .. "Textures\\CircleMaskScalable.tga",
        minimapRectangle = ayijeRoot .. "Textures\\MinimapRectangle.tga",
        portraitBorder = ayijeRoot .. "Textures\\portraitborder.tga",
        separatorHorizontal = ayijeRoot .. "Textures\\Separator.tga",
        separatorVertical = ayijeRoot .. "Textures\\vSeparator.tga",
        squareWhite = ayijeRoot .. "Textures\\Square_White.tga",
    },
    glyphs = {
        arrow = ayijeRoot .. "Textures\\Glyphs\\Arrow.tga",
        bars = ayijeRoot .. "Textures\\Glyphs\\Bars.tga",
        duplicate = ayijeRoot .. "Textures\\Glyphs\\Duplicate.tga",
        minus = ayijeRoot .. "Textures\\Glyphs\\Minus.tga",
        plus = ayijeRoot .. "Textures\\Glyphs\\Plus.tga",
        sword = ayijeRoot .. "Textures\\Glyphs\\Sword.tga",
        swords = ayijeRoot .. "Textures\\Glyphs\\Swords.tga",
        treeArrow = ayijeRoot .. "Textures\\Glyphs\\TreeArrow.tga",
        pixelClose = ayijeRoot .. "Textures\\Glyphs\\Pixel\\Close.tga",
        pixelCloseSmall = ayijeRoot .. "Textures\\Glyphs\\Pixel\\CloseSmall.tga",
        pixelDiamond = ayijeRoot .. "Textures\\Glyphs\\Pixel\\Diamond.tga",
    },
}
