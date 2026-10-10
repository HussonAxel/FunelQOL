local addonName, addon = ...

-- These assets are imported locally by tools/Import-Media.ps1.
-- Paths belong to FunelQOL: source addons do not need to be enabled at runtime.
local root = "Interface\\AddOns\\" .. addonName .. "\\Media\\Ellesmere\\"

addon.media = {
    font = "Interface\\AddOns\\" .. addonName .. "\\Media\\Fonts\\Expressway-Bold.ttf",
    regularFont = "Interface\\AddOns\\" .. addonName .. "\\Media\\Fonts\\Expressway.ttf",
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

-- Shared bar texture (d1); tools/Sync-BarTexture.ps1 copies it into RefineUI.
addon.media.statusbar = "Interface\\AddOns\\" .. addonName .. "\\Media\\Bars\\d1.tga"

local refineRoot = "Interface\\AddOns\\" .. addonName .. "\\Media\\RefineUI\\"
addon.media.refine = {
    border = refineRoot .. "Textures\\RefineBorder.blp",
    fill = refineRoot .. "Textures\\SmoothV2.tga",
    font = refineRoot .. "Fonts\\ITCAvantGardeStd-Demi.ttf",
    boldFont = refineRoot .. "Fonts\\ITCAvantGardeStd-Bold.ttf",
}

-- The client loads a font file on first use; text laid out before that stays blank
-- until it changes. Font objects created at load time preload Expressway.
if CreateFont then
    for _, flags in ipairs({ "", "OUTLINE" }) do
        CreateFont("FunelQOLFont" .. flags):SetFont(addon.media.font, 12, flags)
        CreateFont("FunelQOLRefineFont" .. flags):SetFont(addon.media.refine.font, 12, flags)
        CreateFont("FunelQOLRefineBoldFont" .. flags):SetFont(addon.media.refine.boldFont, 12, flags)
    end
end

-- Expressway is the default; panel styles can request their own local face.
-- Keep the template size, with Expressway/Blizzard fallbacks for missing files.
function addon.SetFont(fontString, size, flags, font)
    font = font or addon.media.font
    local currentFont, currentSize, currentFlags = fontString:GetFont()
    size, flags = size or currentSize or 12, flags or ""
    if currentFont == font and currentSize and math.abs(currentSize - size) < 0.05 and (currentFlags or "") == flags then return end
    fontString:SetFont(font, size, flags)
    -- FontStrings need not return a success boolean: inspect the applied face.
    if fontString:GetFont() ~= font then
        fontString:SetFont(addon.media.regularFont, size, flags)
        if fontString:GetFont() ~= addon.media.regularFont then fontString:SetFont(STANDARD_TEXT_FONT, size, flags) end
    end
    -- Text set before the font change is laid out again with the new font.
    local text = fontString:GetText()
    if text and text ~= "" then fontString:SetText(""); fontString:SetText(text) end
end

local ayijeRoot ="Interface\\AddOns\\" .. addonName .. "\\Media\\AyijeUI\\"

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
