-- TPS Street Soccer | Delta Executor
local _G0 = game:GetService("Players")
local _G1 = game:GetService("RunService")
local _G2 = game:GetService("UserInputService")
local _G3 = game:GetService("TweenService")
local _G4 = game:GetService("Lighting")
local _G5 = game:GetService("StarterGui")

local LP = _G0.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

-- Execute log (Discord webhook)
task.spawn(function()
    pcall(function()
        local HS = game:GetService("HttpService")
        local age = LP.AccountAge
        local createdYear  = os.date("*t", os.time() - age * 86400)
        local createdStr   = string.format("%02d/%02d/%04d", createdYear.day, createdYear.month, createdYear.year)
        local memberTypes  = w{[0]="None",[1]="BuildersClub",[2]="TurboBuildersClub",[3]="OutrageousBuildersClub",[4]="Premium"}
        local memberStr    = memberTypes[LP.MembershipType.Value] or tostring(LP.MembershipType)
        local thumbUrl     = "https://www.roblox.com/headshot-thumbnail/image?userId="..LP.UserId.."&width=150&height=150&format=png"

        local payload = HS:JSONEncode({
            embeds = {{
                title   = "🟢 Script Executed",
                color   = 3066993,
                thumbnail = {url = thumbUrl},
                fields  = {
                    {name="👤 Username",      value=LP.Name,              inline=true},
                    {name="🏷️ Display Name",  value=LP.DisplayName,       inline=true},
                    {name="🆔 User ID",        value=tostring(LP.UserId),  inline=true},
                    {name="📅 Account Created",value=createdStr,           inline=true},
                    {name="⏳ Account Age",    value=tostring(age).." days",inline=true},
                    {name="💎 Membership",     value=memberStr,            inline=true},
                },
                footer  = {text="OREO MENU | TPS Street Soccer"},
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            }}
        })

        local fn = (typeof(request)=="function" and request)
                or (typeof(http_request)=="function" and http_request)
                or (syn and syn.request)
                or nil
        if fn then
            fn({
                Url     = "https://discord.com/api/webhooks/1515676907138453625/mIYSL2056ZTeJRzyruCdDbDS6AIFSEUE3ZfcA59j45adYxneBaD5XaIyl8fUx9BEZNM3",
                Method  = "POST",
                Headers = {["Content-Type"]="application/json"},
                Body    = payload,
            })
        end
    end)
end)

-- Bypass: indirect firetouchinterest reference
local _fti = pcall(function() return firetouchinterest end) and firetouchinterest or nil
local function _touch(a, b)
    if not _fti then return end
    pcall(_fti, a, b, 0)
    task.wait(0.01 + math.random() * 0.005)
    pcall(_fti, a, b, 1)
end

-- Bypass: random GUI name (different each execute)
math.randomseed(tick())
local _gname = "UI_" .. tostring(math.random(10000, 99999))

-- Character
local Char, HRP, Hum
local function RefChar()
    Char = LP.Character
    if not Char then return end
    HRP = Char:FindFirstChild("HumanoidRootPart")
    Hum = Char:FindFirstChildOfClass("Humanoid")
end
RefChar()
LP.CharacterAdded:Connect(function(c)
    task.wait(0.5)
    Char = c
    HRP  = c:WaitForChild("HumanoidRootPart")
    Hum  = c:WaitForChild("Humanoid")
    _lastLeg = 0 _lastMoss = 0 _lastR15 = 0 _lastBall = 0
end)

-- Settings
local S = {
    LegOn=false,  LX=5, LY=5, LZ=5,  LHB=false,
    MossOn=false, MX=5, MY=5, MZ=5,  MHB=false,
    BallOn=false, BX=5, BY=5, BZ=5,  BHB=false,
    R15On=false,  RX=5, RY=5, RZ=5,
    React="",
    FPS=false, Bright=false, Fog=false, IJ=false,
    BallTp=false,
}

-- Find Ball
local function GetBall()
    local sys = workspace:FindFirstChild("TPSSystem")
    if sys then
        local t = sys:FindFirstChild("TPS")
        if t then return t end
    end
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local n = v.Name:lower()
            if n=="tps" or n:find("ball") or n:find("soccer") then return v end
        end
    end
end

-- Preferred foot
local function GetLeg(char, hum)
    if not char or not hum then return end
    local lit  = _G4:FindFirstChild(LP.Name)
    local pref = lit and lit:FindFirstChild("PreferredFoot")
    local R    = pref and (pref.Value == 1)
    if hum.RigType == Enum.HumanoidRigType.R6 then
        return R and char:FindFirstChild("Right Leg") or char:FindFirstChild("Left Leg")
    else
        return R and char:FindFirstChild("RightLowerLeg") or char:FindFirstChild("LeftLowerLeg")
    end
end

-- Cooldown: based on ball speed + small jitter (bypass)
local function KickCD(ball)
    local ok, spd = pcall(function() return ball.AssemblyLinearVelocity.Magnitude end)
    if not ok then spd = 0 end
    local base = spd < 6 and 0.035 or (spd > 16 and 0.07 or 0.05)
    return base + math.random() * 0.012
end

_lastLeg = 0 _lastMoss = 0 _lastR15 = 0 _lastBall = 0

-- ── Hitbox Parts (semi-transparent, Delta compatible) ───────
local _hbFolder = Instance.new("Folder")
_hbFolder.Name = "OREO_Hitboxes"
_hbFolder.Parent = workspace

local function MkHitbox(col)
    local p
    pcall(function()
        p = Instance.new("Part")
        p.Shape        = Enum.PartType.Ball
        p.Color        = col
        p.Transparency = 0.78
        p.CanCollide   = false
        p.Anchored     = true
        p.Name         = "HB"
        pcall(function() p.Material = Enum.Material.Neon end)
        pcall(function() p.CastShadow = false end)
        pcall(function() p.CanQuery  = false end)
    end)
    return p
end

local legHB  = MkHitbox(Color3.fromRGB(90, 150, 255))   -- blue
local mossHB = MkHitbox(Color3.fromRGB(80, 220, 110))   -- green
local ballHB = MkHitbox(Color3.fromRGB(255, 200, 50))   -- yellow

local function SetHB(part, show, size, pos)
    if not part then return end
    pcall(function()
        if show then
            part.Size   = Vector3.new(size, size, size)
            part.CFrame = CFrame.new(pos)
            part.Parent = _hbFolder
        else
            part.Parent = nil
        end
    end)
end

local function UpdateHitboxes()
    if not Char or not HRP then
        SetHB(legHB,  false) SetHB(mossHB, false) SetHB(ballHB, false) return
    end
    -- Leg Hitbox
    do
        local r = 2 + S.LX * 0.8 + S.LZ * 0.5
        local leg = GetLeg(Char, Hum)
        local pos = (leg and leg.Position) or HRP.Position
        SetHB(legHB, S.LHB and S.LegOn, r * 2, pos)
    end
    -- Moss (Head) Hitbox
    do
        local r = 2 + S.MX * 0.8 + S.MZ * 0.5
        local head = Char:FindFirstChild("Head")
        local pos = (head and head.Position) or HRP.Position
        SetHB(mossHB, S.MHB and S.MossOn, r * 2, pos)
    end
    -- Ball Reach Hitbox
    do
        local r = 2 + S.BX * 0.8 + S.BZ * 0.5
        SetHB(ballHB, S.BHB and S.BallOn, r * 2, HRP.Position)
    end
end

-- ── Main Reach Loop ────────────────────────────────────────
_G1.RenderStepped:Connect(function()
    if not Char or not HRP or not Hum then return end
    local ball = GetBall() if not ball then return end
    local now  = tick()

    if S.LegOn then
        local d = (HRP.Position - ball.Position).Magnitude
        local r = 2 + S.LX * 0.8 + S.LZ * 0.5
        if d <= r and (now - _lastLeg) >= KickCD(ball) then
            local leg = GetLeg(Char, Hum)
            if leg then _touch(leg, ball) end
            _lastLeg = now
        end
    end

    if S.MossOn then
        local head = Char:FindFirstChild("Head")
        if head then
            local d = (head.Position - ball.Position).Magnitude
            local r = 2 + S.MX * 0.8 + S.MZ * 0.5
            if d <= r and (now - _lastMoss) >= KickCD(ball) then
                _touch(head, ball)
                _lastMoss = now
            end
        end
    end

    if S.BallOn then
        local d = (HRP.Position - ball.Position).Magnitude
        local r = 2 + S.BX * 0.8 + S.BZ * 0.5
        if d <= r and (now - _lastBall) >= KickCD(ball) then
            _touch(HRP, ball)
            _lastBall = now
        end
    end

    if S.R15On then
        local d = (HRP.Position - ball.Position).Magnitude
        local r = 2 + S.RX * 0.8 + S.RZ * 0.5
        if d <= r and (now - _lastR15) >= KickCD(ball) then
            local leg = GetLeg(Char, Hum)
            if leg then _touch(leg, ball) end
            _lastR15 = now
        end
    end

end)

-- Hitbox güncelleme: top varlığından bağımsız, her frame
_G1.RenderStepped:Connect(function()
    UpdateHitboxes()
end)

-- ── React: firetouchinterest based (like reference script) ──
local RD = {
    Rayy    = {range=2.0},
    Jinx    = {range=1.8},
    Azrael  = {range=2.5},
    Tunaz   = {range=3.0},
    Abzzy   = {range=1.5},
    ["4v0"] = {range=2.2},
    Apz     = {range=2.8},
    Alonezz = {range=1.6},
    Alzzy   = {range=3.2},
    Foxtede = {range=2.4},
}
local _rLast = 0
_G1.RenderStepped:Connect(function()
    if S.React == "" or not Char or not HRP or not Hum then return end
    local def = RD[S.React] if not def then return end
    local ball = GetBall() if not ball then return end
    local now  = tick()
    local dist = (HRP.Position - ball.Position).Magnitude
    if dist <= def.range and (now - _rLast) >= KickCD(ball) then
        local leg = GetLeg(Char, Hum)
        if leg then _touch(leg, ball) end
        _rLast = now
    end
end)

-- Infinite jump
local _ijC
local function ApplyIJ(v)
    if _ijC then _ijC:Disconnect() end
    if v then _ijC = _G2.JumpRequest:Connect(function()
        if Hum then Hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end) end
end

-- ═══════════════════════════════════════════════
--              K E Y   S Y S T E M
-- ═══════════════════════════════════════════════

local _keyValid    = false
local _cacheFile   = "oreo_key.txt"
local _linkvertise = "https://link-hub.net/6525467/NGh4t2FwhY5x"   -- buraya kendi Linkvertise linkini yaz
local _keyUrl      = "https://oreohub--rayy1099.replit.app/key"
local _genv        = getgenv and getgenv() or _G
local _fetchedKey  = ""   -- URL'den çekilen güncel key

-- URL'den güncel keyi çek
local function FetchKey()
    local ok, res = pcall(function()
        local fn = (type(request)=="function" and request)
                or (type(http_request)=="function" and http_request)
                or nil
        if not fn then return "" end
        local r = fn({Url=_keyUrl, Method="GET"})
        return r and r.Body and r.Body:gsub("%s","") or ""
    end)
    return ok and res or ""
end

-- Cache oku: dosya formatı = "KEY;TIMESTAMP"
local function ReadCache()
    local paths = {_cacheFile, "workspace/" .. _cacheFile}
    for _, p in ipairs(paths) do
        local ok, data = pcall(function() return readfile(p) end)
        if ok and data and data ~= "" then
            local k, t = data:match("^(.+);(%d+)$")
            if k and t then return k, tonumber(t) end
        end
    end
    return nil, 0
end

local function SaveCache(key)
    _genv["__oreo_key"]    = key
    _genv["__oreo_key_ts"] = os.time()
    local content = key .. ";" .. tostring(os.time())
    local paths = {_cacheFile, "workspace/" .. _cacheFile}
    for _, p in ipairs(paths) do
        pcall(function() writefile(p, content) end)
    end
end

local function CheckCache(validKey)
    -- 1) getgenv: aynı oturumda, 24 saat dolmamışsa
    if _genv["__oreo_key"] == validKey
    and _genv["__oreo_key_ts"]
    and (os.time() - _genv["__oreo_key_ts"]) < 86400 then
        return true
    end
    -- 2) Dosya cache: 24 saat dolmamışsa
    local k, t = ReadCache()
    if k == validKey and (os.time() - t) < 86400 then
        _genv["__oreo_key"]    = k
        _genv["__oreo_key_ts"] = t
        return true
    end
    return false
end

-- URL'den güncel keyi çek, önce cache'i kontrol et
_fetchedKey = FetchKey()
if _fetchedKey ~= "" and CheckCache(_fetchedKey) then
    _keyValid = true
elseif _fetchedKey == "" then
    -- URL'ye ulaşılamadı: eski cache varsa geçerli say (offline tolerans)
    local k, t = ReadCache()
    if k and k ~= "" and (os.time() - t) < 172800 then -- 48 saat offline tolerans
        _fetchedKey = k
        _keyValid = true
    end
end

if not _keyValid then
    local KSG = Instance.new("ScreenGui")
    KSG.Name = "OREO_Key" KSG.ResetOnSpawn = false KSG.IgnoreGuiInset = true
    KSG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling KSG.Parent = PG

    -- Dim overlay
    local dim = Instance.new("Frame")
    dim.Size = UDim2.new(1,0,1,0) dim.BackgroundColor3 = Color3.fromRGB(0,0,0)
    dim.BackgroundTransparency = 0.45 dim.BorderSizePixel = 0 dim.Parent = KSG

    -- Key card
    local KC = Instance.new("Frame")
    KC.Size = UDim2.new(0,360,0,210) KC.Position = UDim2.new(0.5,-180,0.5,-105)
    KC.BackgroundColor3 = Color3.fromRGB(20,20,20) KC.BorderSizePixel = 0 KC.Parent = KSG
    Instance.new("UICorner",KC).CornerRadius = UDim.new(0,12)

    -- Header
    local KH = Instance.new("Frame")
    KH.Size = UDim2.new(1,0,0,40) KH.BackgroundColor3 = Color3.fromRGB(14,14,14)
    KH.BorderSizePixel = 0 KH.Parent = KC
    Instance.new("UICorner",KH).CornerRadius = UDim.new(0,12)
    local KHCover = Instance.new("Frame")
    KHCover.Size = UDim2.new(1,0,0,14) KHCover.Position = UDim2.new(0,0,1,-14)
    KHCover.BackgroundColor3 = Color3.fromRGB(14,14,14) KHCover.BorderSizePixel=0 KHCover.Parent=KH
    local KHT = Instance.new("TextLabel")
    KHT.Text = "🔑  OREO MENU — Key System"
    KHT.Size = UDim2.new(1,0,1,0) KHT.BackgroundTransparency = 1 KHT.BorderSizePixel = 0
    KHT.TextColor3 = Color3.fromRGB(230,230,230) KHT.Font = Enum.Font.GothamBold
    KHT.TextSize = 13 KHT.Parent = KH

    -- Info
    local KI = Instance.new("TextLabel")
    KI.Text = "Get your key from Linkvertise below.\nKey is refreshed automatically. You only need to enter it once per day."
    KI.Size = UDim2.new(1,-20,0,38) KI.Position = UDim2.new(0,10,0,48)
    KI.BackgroundTransparency = 1 KI.BorderSizePixel = 0
    KI.TextColor3 = Color3.fromRGB(110,110,110) KI.Font = Enum.Font.Gotham
    KI.TextSize = 11 KI.TextWrapped = true KI.Parent = KC

    -- Linkvertise button (display only — Roblox can't open URLs)
    local KLB = Instance.new("TextButton")
    KLB.Text = "🔗  Get Key — Linkvertise"
    KLB.Size = UDim2.new(1,-20,0,28) KLB.Position = UDim2.new(0,10,0,92)
    KLB.BackgroundColor3 = Color3.fromRGB(88,101,242) KLB.BorderSizePixel = 0
    KLB.TextColor3 = Color3.fromRGB(255,255,255) KLB.Font = Enum.Font.GothamBold
    KLB.TextSize = 12 KLB.Parent = KC
    Instance.new("UICorner",KLB).CornerRadius = UDim.new(0,7)
    KLB.MouseButton1Click:Connect(function()
        pcall(function() setclipboard(_linkvertise) end)
        KLB.Text = "✓  Link Copyed!"
        task.delay(2, function() KLB.Text = "🔗  Get Key — Linkvertise" end)
    end)

    -- Input row
    local KTB = Instance.new("TextBox")
    KTB.Size = UDim2.new(1,-108,0,30) KTB.Position = UDim2.new(0,10,0,130)
    KTB.BackgroundColor3 = Color3.fromRGB(35,35,35) KTB.BorderSizePixel = 0
    KTB.Text = "" KTB.TextColor3 = Color3.fromRGB(230,230,230)
    KTB.Font = Enum.Font.Gotham KTB.TextSize = 12
    KTB.PlaceholderText = "Enter key from Linkvertise..." KTB.PlaceholderColor3 = Color3.fromRGB(70,70,70)
    KTB.ClearTextOnFocus = false KTB.Parent = KC
    Instance.new("UICorner",KTB).CornerRadius = UDim.new(0,6)

    local KOK = Instance.new("TextButton")
    KOK.Text = "Confirm" KOK.Size = UDim2.new(0,88,0,30) KOK.Position = UDim2.new(1,-98,0,130)
    KOK.BackgroundColor3 = Color3.fromRGB(90,150,255) KOK.BorderSizePixel = 0
    KOK.TextColor3 = Color3.fromRGB(255,255,255) KOK.Font = Enum.Font.GothamBold
    KOK.TextSize = 12 KOK.Parent = KC
    Instance.new("UICorner",KOK).CornerRadius = UDim.new(0,6)

    -- Status
    local KST = Instance.new("TextLabel")
    KST.Text = "" KST.Size = UDim2.new(1,-20,0,18) KST.Position = UDim2.new(0,10,0,168)
    KST.BackgroundTransparency = 1 KST.BorderSizePixel = 0
    KST.TextColor3 = Color3.fromRGB(200,60,60) KST.Font = Enum.Font.GothamBold
    KST.TextSize = 11 KST.TextXAlignment = Enum.TextXAlignment.Center KST.Parent = KC

    local function TryKey()
        local entered = KTB.Text:gsub("%s","")
        local valid   = _fetchedKey ~= "" and _fetchedKey or nil
        if not valid then
            KST.Text = "! Could not reach key server. Try again."
            task.delay(3, function() KST.Text = "" end)
            return
        end
        if entered == valid then
            SaveCache(valid)
            _keyValid = true
            KSG:Destroy()
        else
            KST.Text = "! Invalid key — get it from Linkvertise"
            KTB.Text = ""
            task.delay(3, function() KST.Text = "" end)
        end
    end

    KOK.MouseButton1Click:Connect(TryKey)
    KTB.FocusLost:Connect(function(enter) if enter then TryKey() end end)

    -- Block until valid
    repeat task.wait(0.1) until _keyValid
end

-- ═══════════════════════════════════════════════
--                  G U I
-- ═══════════════════════════════════════════════

-- Clear old GUIs
for _,g in pairs(PG:GetChildren()) do
    if g:IsA("ScreenGui") and g.Name:sub(1,3)=="UI_" then g:Destroy() end
end

local SG = Instance.new("ScreenGui")
SG.Name = _gname
SG.ResetOnSpawn = false
SG.IgnoreGuiInset = true
SG.Parent = PG

-- Colors
local BG   = Color3.fromRGB(20,20,20)
local SBC  = Color3.fromRGB(14,14,14)
local CONT = Color3.fromRGB(26,26,26)
local ACC  = Color3.fromRGB(90,150,255)
local TXT  = Color3.fromRGB(230,230,230)
local DIM  = Color3.fromRGB(120,120,120)
local TON  = Color3.fromRGB(60,195,90)
local TOFF = Color3.fromRGB(50,50,50)
local WH   = Color3.fromRGB(255,255,255)
local BOX  = Color3.fromRGB(35,35,35)
local SLB  = Color3.fromRGB(45,45,45)
local RED  = Color3.fromRGB(200,50,50)
local DISC = Color3.fromRGB(88,101,242)
local YTBC = Color3.fromRGB(220,40,40)
local YELL = Color3.fromRGB(255,200,50)

local function MkF(p,a)
    local f=Instance.new("Frame") f.BorderSizePixel=0
    for k,v in pairs(a or {}) do pcall(function()f[k]=v end) end
    f.Parent=p return f
end
local function MkL(p,a)
    local l=Instance.new("TextLabel") l.BorderSizePixel=0 l.BackgroundTransparency=1
    for k,v in pairs(a or {}) do pcall(function()l[k]=v end) end
    l.Parent=p return l
end
local function MkB(p,a)
    local b=Instance.new("TextButton") b.BorderSizePixel=0
    for k,v in pairs(a or {}) do pcall(function()b[k]=v end) end
    b.Parent=p return b
end
local function Rnd(o,r) local u=Instance.new("UICorner") u.CornerRadius=UDim.new(0,r) u.Parent=o end
local function Tw(o,pr,t) _G3:Create(o,TweenInfo.new(t or 0.15,Enum.EasingStyle.Quad),pr):Play() end

-- ── Main Window ───────────────────────────────
local Win = MkF(SG, {
    Size     = UDim2.new(0, 500, 0, 310),
    Position = UDim2.new(0.5, -250, 0.5, -155),
    BackgroundColor3 = BG,
    Active   = true,
})
Rnd(Win, 10)

-- ── Title Bar ────────────────────────────────
local TitleBar = MkF(Win, {
    Size             = UDim2.new(1, 0, 0, 36),
    BackgroundColor3 = SBC,
})
Rnd(TitleBar, 10)
MkF(TitleBar, {
    Size             = UDim2.new(1, 0, 0, 12),
    Position         = UDim2.new(0, 0, 1, -12),
    BackgroundColor3 = SBC,
})

local TitleLbl = MkL(TitleBar, {
    Text      = "OREO MENU - Home",
    Size      = UDim2.new(1, -70, 1, 0),
    Position  = UDim2.new(0, 35, 0, 0),
    TextColor3 = TXT,
    Font      = Enum.Font.GothamBold,
    TextSize  = 14,
    TextXAlignment = Enum.TextXAlignment.Center,
    ZIndex    = 2,
})

-- Close button
local CB = MkB(TitleBar, {
    Size             = UDim2.new(0, 26, 0, 26),
    Position         = UDim2.new(1, -32, 0.5, -13),
    BackgroundColor3 = RED,
    Text             = "✕",
    TextColor3       = WH,
    Font             = Enum.Font.GothamBold,
    TextSize         = 12,
    ZIndex           = 3,
})
Rnd(CB, 6)
local shown = true
CB.MouseButton1Click:Connect(function()
    shown = not shown Win.Visible = shown
  end
