-- // MACROPEAK | DELTA STYLE UI //

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

-- Player
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Colors (Delta Style)
local Colors = {
    Background = Color3.fromRGB(25, 25, 30),
    Primary = Color3.fromRGB(40, 40, 50),
    Secondary = Color3.fromRGB(35, 35, 45),
    Accent = Color3.fromRGB(80, 160, 255),
    Text = Color3.fromRGB(240, 240, 240),
    TextSecondary = Color3.fromRGB(180, 180, 180),
    Success = Color3.fromRGB(0, 200, 0),
    Error = Color3.fromRGB(200, 0, 0),
    Warning = Color3.fromRGB(255, 180, 0)
}

-- Main Variables
local Settings = {
    -- Aimbot
    Aimbot = {
        Enabled = false,
        TargetPart = "Head",
        FOV = 100,
        Smoothness = 0.1,
        WallCheck = false,
        TeamCheck = false,
        BlatantMode = false,
        SilentAim = false,
        HitChance = 100,
        Triggerbot = false,
        TriggerbotDelay = 0.1
    },
    -- Visual
    Visual = {
        ESP = false,
        Tracers = false,
        BoxESP = false,
        HealthBar = false,
        Chams = false,
        TeamColors = false,
        TracerThickness = 1,
        MaxDistance = 500
    },
    -- Movement
    Movement = {
        Walkspeed = false,
        WalkspeedValue = 50,
        Jumppower = false,
        JumppowerValue = 75,
        Noclip = false,
        Fly = false,
        FlySpeed = 25,
        InfiniteJump = false
    }
}

-- UI References
local ScreenGui
local MainFrame
local IsMinimized = false

-- Connections
local Connections = {}

-----------------------------------------------------------
--                     UTILITY FUNCTIONS
-----------------------------------------------------------
local function SafeCall(callback, ...)
    local success, result = pcall(callback, ...)
    if not success then
        warn("Error:", result)
    end
    return result
end

local function CreateGradient(color1, color2, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color1),
        ColorSequenceKeypoint.new(1, color2)
    })
    gradient.Rotation = rotation or 0
    return gradient
end

-----------------------------------------------------------
--                     AIMBOT SYSTEM
-----------------------------------------------------------
local function IsValidPlayer(player)
    if player == LocalPlayer then return false end
    if not player.Character then return false end
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if not humanoid then return false end
    if humanoid.Health <= 0 then return false end
    
    if Settings.Aimbot.TeamCheck then
        if player.Team and LocalPlayer.Team then
            return player.Team ~= LocalPlayer.Team
        end
    end
    
    return true
end

local function IsTargetVisible(targetPart)
    if not targetPart then return false end
    if not Settings.Aimbot.WallCheck then return true end
    
    local character = LocalPlayer.Character
    if not character then return false end
    
    local head = character:FindFirstChild("Head")
    if not head then return false end
    
    local origin = head.Position
    local direction = (targetPart.Position - origin).Unit
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {character}
    raycastParams.IgnoreWater = true
    
    local ray = Workspace:Raycast(origin, direction * Settings.Visual.MaxDistance, raycastParams)
    if ray then
        return ray.Instance:IsDescendantOf(targetPart.Parent)
    end
    return true
end

local function GetClosestTarget()
    if not LocalPlayer.Character then return nil end
    local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    
    local closest = nil
    local shortestDistance = Settings.Aimbot.FOV
    
    for _, player in pairs(Players:GetPlayers()) do
        if IsValidPlayer(player) then
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local distance = (root.Position - targetRoot.Position).Magnitude
                if distance <= shortestDistance then
                    if IsTargetVisible(targetRoot) then
                        closest = player.Character
                        shortestDistance = distance
                    end
                end
            end
        end
    end
    
    return closest
end

local function GetTargetPosition(target)
    if not target then return nil end
    
    if Settings.Aimbot.TargetPart == "Head" then
        return target:FindFirstChild("Head") and target.Head.Position
    elseif Settings.Aimbot.TargetPart == "Body" then
        local torso = target:FindFirstChild("Torso") or target:FindFirstChild("UpperTorso")
        return torso and torso.Position
    else
        return target:FindFirstChild("HumanoidRootPart") and target.HumanoidRootPart.Position
    end
end

local function AimbotLoop()
    if not Settings.Aimbot.Enabled then return end
    if Settings.Aimbot.SilentAim and math.random(1, 100) > Settings.Aimbot.HitChance then return end
    
    local target = GetClosestTarget()
    if not target then return end
    
    local targetPos = GetTargetPosition(target)
    if not targetPos then return end
    
    local currentCFrame = Camera.CFrame
    local targetCFrame = CFrame.new(currentCFrame.Position, targetPos)
    
    if Settings.Aimbot.BlatantMode then
        Camera.CFrame = targetCFrame
    else
        Camera.CFrame = currentCFrame:Lerp(targetCFrame, Settings.Aimbot.Smoothness)
    end
end

local function TriggerbotLoop()
    if not Settings.Aimbot.Triggerbot then return end
    
    local target = GetClosestTarget()
    if not target then return end
    
    local targetPos = GetTargetPosition(target)
    if not targetPos then return end
    
    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
    if onScreen then
        local mousePos = Vector2.new(Mouse.X, Mouse.Y)
        local targetScreenPos = Vector2.new(screenPos.X, screenPos.Y)
        local distance = (mousePos - targetScreenPos).Magnitude
        
        if distance <= 20 then
            mouse1click()
            task.wait(Settings.Aimbot.TriggerbotDelay)
        end
    end
end

-----------------------------------------------------------
--                     VISUAL SYSTEM
-----------------------------------------------------------
local ESPObjects = {}

local function CreateESP(player)
    if not Settings.Visual.ESP then return end
    if not player.Character then return end
    if ESPObjects[player] then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "MACROPEAK_ESP"
    highlight.FillColor = Settings.Visual.TeamColors and (player.Team and player.Team.TeamColor.Color or Colors.Accent) or Color3.fromRGB(255, 255, 255)
    highlight.OutlineColor = highlight.FillColor
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Adornee = player.Character
    highlight.Parent = player.Character
    
    if Settings.Visual.Chams then
        local chams = Instance.new("BoxHandleAdornment")
        chams.Name = "Chams"
        chams.Adornee = player.Character:FindFirstChild("HumanoidRootPart")
        chams.Size = Vector3.new(2, 4, 1)
        chams.Color3 = highlight.FillColor
        chams.Transparency = 0.3
        chams.AlwaysOnTop = true
        chams.ZIndex = 10
        chams.Parent = player.Character
    end
    
    ESPObjects[player] = {Highlight = highlight}
end

local function RemoveESP(player)
    if ESPObjects[player] then
        if ESPObjects[player].Highlight then
            ESPObjects[player].Highlight:Destroy()
        end
        if player.Character and player.Character:FindFirstChild("Chams") then
            player.Character.Chams:Destroy()
        end
        ESPObjects[player] = nil
    end
end

local function UpdateESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local distance = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and 
                    (LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude or 9999)
                
                if distance <= Settings.Visual.MaxDistance then
                    CreateESP(player)
                else
                    RemoveESP(player)
                end
            else
                RemoveESP(player)
            end
        else
            RemoveESP(player)
        end
    end
end

-----------------------------------------------------------
--                     MOVEMENT SYSTEM
-----------------------------------------------------------
local function UpdateMovement()
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    -- Walkspeed
    if Settings.Movement.Walkspeed then
        humanoid.WalkSpeed = Settings.Movement.WalkspeedValue
    else
        humanoid.WalkSpeed = 16
    end
    
    -- Jumppower
    if Settings.Movement.Jumppower then
        humanoid.JumpPower = Settings.Movement.JumppowerValue
    else
        humanoid.JumpPower = 50
    end
end

local function NoclipLoop()
    if not Settings.Movement.Noclip then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

local function FlyLoop()
    if not Settings.Movement.Fly then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local velocity = root:FindFirstChild("BodyVelocity") or Instance.new("BodyVelocity")
    velocity.Parent = root
    velocity.MaxForce = Vector3.new(40000, 40000, 40000)
    
    local cam = Camera.CFrame
    
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        velocity.Velocity = cam.LookVector * Settings.Movement.FlySpeed
    elseif UserInputService:IsKeyDown(Enum.KeyCode.S) then
        velocity.Velocity = -cam.LookVector * Settings.Movement.FlySpeed
    elseif UserInputService:IsKeyDown(Enum.KeyCode.A) then
        velocity.Velocity = -cam.RightVector * Settings.Movement.FlySpeed
    elseif UserInputService:IsKeyDown(Enum.KeyCode.D) then
        velocity.Velocity = cam.RightVector * Settings.Movement.FlySpeed
    else
        velocity.Velocity = Vector3.new(0, 0, 0)
    end
end

local function InfiniteJump()
    if not Settings.Movement.InfiniteJump then return end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end

-----------------------------------------------------------
--                     CONNECTION MANAGER
-----------------------------------------------------------
local function StartFeatures()
    -- Clear existing connections
    for _, conn in pairs(Connections) do
        conn:Disconnect()
    end
    table.clear(Connections)
    
    -- Main loop
    local mainConn = RunService.Heartbeat:Connect(function()
        SafeCall(AimbotLoop)
        SafeCall(TriggerbotLoop)
        SafeCall(UpdateESP)
        SafeCall(UpdateMovement)
        SafeCall(NoclipLoop)
        SafeCall(FlyLoop)
        SafeCall(InfiniteJump)
    end)
    table.insert(Connections, mainConn)
    
    -- Character added event
    local charConn = LocalPlayer.CharacterAdded:Connect(function()
        SafeCall(UpdateMovement)
    end)
    table.insert(Connections, charConn)
end

local function StopFeatures()
    for _, conn in pairs(Connections) do
        conn:Disconnect()
    end
    table.clear(Connections)
    
    -- Clean up ESP
    for _, esp in pairs(ESPObjects) do
        if esp.Highlight then
            esp.Highlight:Destroy()
        end
    end
    table.clear(ESPObjects)
    
    -- Reset movement
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 16
            humanoid.JumpPower = 50
        end
    end
end

-----------------------------------------------------------
--                     DELTA STYLE UI
-----------------------------------------------------------
local function CreateUI()
    -- ScreenGui
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "MACROPEAK_DELTA_UI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = CoreGui
    
    -- Main Frame
    MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 500, 0, 450)
    MainFrame.Position = UDim2.new(0.5, -250, 0.5, -225)
    MainFrame.BackgroundColor3 = Colors.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 12)
    MainCorner.Parent = MainFrame
    
    -- Shadow
    local Shadow = Instance.new("ImageLabel")
    Shadow.Size = UDim2.new(1, 15, 1, 15)
    Shadow.Position = UDim2.new(0, -7.5, 0, -7.5)
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxassetid://5554236805"
    Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    Shadow.ImageTransparency = 0.5
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    Shadow.ZIndex = -1
    Shadow.Parent = MainFrame
    
    -- Top Bar
    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 45)
    TopBar.BackgroundColor3 = Colors.Primary
    TopBar.BorderSizePixel = 0
    
    local TopBarCorner = Instance.new("UICorner")
    TopBarCorner.CornerRadius = UDim.new(0, 12, 0, 0)
    TopBarCorner.Parent = TopBar
    
    -- Gradient Effect
    local TopGradient = CreateGradient(Colors.Accent, Colors.Primary, 90)
    TopGradient.Parent = TopBar
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(0, 200, 1, 0)
    Title.Position = UDim2.new(0, 20, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "MACROPEAK"
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 20
    Title.TextColor3 = Colors.Text
    Title.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Subtitle
    local Subtitle = Instance.new("TextLabel")
    Subtitle.Size = UDim2.new(0, 150, 1, 0)
    Subtitle.Position = UDim2.new(0, 20, 0, 20)
    Subtitle.BackgroundTransparency = 1
    Subtitle.Text = "Made By @LuaDev"
    Subtitle.Font = Enum.Font.Gotham
    Subtitle.TextSize = 12
    Subtitle.TextColor3 = Colors.TextSecondary
    Subtitle.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Control Buttons
    local ControlButtons = Instance.new("Frame")
    ControlButtons.Size = UDim2.new(0, 80, 1, 0)
    ControlButtons.Position = UDim2.new(1, -85, 0, 0)
    ControlButtons.BackgroundTransparency = 1
    
    -- Minimize Button
    local MinButton = Instance.new("TextButton")
    MinButton.Size = UDim2.new(0, 35, 0, 35)
    MinButton.Position = UDim2.new(0, 5, 0.5, -17.5)
    MinButton.BackgroundColor3 = Colors.Warning
    MinButton.Text = "-"
    MinButton.Font = Enum.Font.GothamBold
    MinButton.TextSize = 20
    MinButton.TextColor3 = Colors.Text
    MinButton.AutoButtonColor = false
    
    local MinCorner = Instance.new("UICorner")
    MinCorner.CornerRadius = UDim.new(0, 6)
    MinCorner.Parent = MinButton
    
    -- Close Button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(0, 35, 0, 35)
    CloseButton.Position = UDim2.new(0, 45, 0.5, -17.5)
    CloseButton.BackgroundColor3 = Colors.Error
    CloseButton.Text = "×"
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.TextSize = 24
    CloseButton.TextColor3 = Colors.Text
    CloseButton.AutoButtonColor = false
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 6)
    CloseCorner.Parent = CloseButton
    
    -- Sidebar
    local Sidebar = Instance.new("Frame")
    Sidebar.Size = UDim2.new(0, 150, 1, -45)
    Sidebar.Position = UDim2.new(0, 0, 0, 45)
    Sidebar.BackgroundColor3 = Colors.Secondary
    Sidebar.BorderSizePixel = 0
    
    local SidebarCorner = Instance.new("UICorner")
    SidebarCorner.CornerRadius = UDim.new(0, 0, 0, 0, 12)
    SidebarCorner.Parent = Sidebar
    
    -- Content Area
    local ContentArea = Instance.new("Frame")
    ContentArea.Size = UDim2.new(1, -150, 1, -45)
    ContentArea.Position = UDim2.new(0, 150, 0, 45)
    ContentArea.BackgroundColor3 = Colors.Background
    ContentArea.BorderSizePixel = 0
    
    -- Scrolling Frame
    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Size = UDim2.new(1, -20, 1, -20)
    ScrollFrame.Position = UDim2.new(0, 10, 0, 10)
    ScrollFrame.BackgroundTransparency = 1
    ScrollFrame.BorderSizePixel = 0
    ScrollFrame.ScrollBarThickness = 5
    ScrollFrame.ScrollBarImageColor3 = Colors.Accent
    
    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Padding = UDim.new(0, 15)
    UIListLayout.Parent = ScrollFrame
    
    -- Parent everything
    MinButton.Parent = ControlButtons
    CloseButton.Parent = ControlButtons
    ControlButtons.Parent = TopBar
    Title.Parent = TopBar
    Subtitle.Parent = TopBar
    TopBar.Parent = MainFrame
    Sidebar.Parent = MainFrame
    ScrollFrame.Parent = ContentArea
    ContentArea.Parent = MainFrame
    MainFrame.Parent = ScreenGui
    
    -- Tab System
    local Tabs = {
        {Name = "AIMBOT", Icon = "🎯"},
        {Name = "VISUAL", Icon = "👁️"},
        {Name = "MOVEMENT", Icon = "⚡"},
        {Name = "MISC", Icon = "⚙️"}
    }
    
    local TabButtons = {}
    local TabContents = {}
    local CurrentTab = nil
    
    -- Create Tabs
    for i, tab in ipairs(Tabs) do
        -- Tab Button
        local TabButton = Instance.new("TextButton")
        TabButton.Name = tab.Name .. "Tab"
        TabButton.Size = UDim2.new(1, -20, 0, 45)
        TabButton.Position = UDim2.new(0, 10, 0, (i-1)*55 + 10)
        TabButton.BackgroundColor3 = Colors.Primary
        TabButton.BorderSizePixel = 0
        TabButton.Text = tab.Icon .. "  " .. tab.Name
        TabButton.Font = Enum.Font.GothamBold
        TabButton.TextSize = 14
        TabButton.TextColor3 = Colors.TextSecondary
        TabButton.TextXAlignment = Enum.TextXAlignment.Left
        TabButton.AutoButtonColor = false
        
        local TabCorner = Instance.new("UICorner")
        TabCorner.CornerRadius = UDim.new(0, 8)
        TabCorner.Parent = TabButton
        
        -- Tab Content
        local TabContent = Instance.new("Frame")
        TabContent.Name = tab.Name .. "Content"
        TabContent.Size = UDim2.new(1, 0, 0, 0)
        TabContent.BackgroundTransparency = 1
        TabContent.Visible = false
        
        local ContentList = Instance.new("UIListLayout")
        ContentList.Padding = UDim.new(0, 10)
        ContentList.Parent = TabContent
        
        TabButton.Parent = Sidebar
        TabContent.Parent = ScrollFrame
        
        TabButtons[tab.Name] = TabButton
        TabContents[tab.Name] = TabContent
        
        -- Click Event
        TabButton.MouseButton1Click:Connect(function()
            if CurrentTab then
                CurrentTab.Button.BackgroundColor3 = Colors.Primary
                CurrentTab.Button.TextColor3 = Colors.TextSecondary
                CurrentTab.Content.Visible = false
            end
            
            CurrentTab = {
                Button = TabButton,
                Content = TabContent
            }
            
            TabButton.BackgroundColor3 = Colors.Accent
            TabButton.TextColor3 = Colors.Text
            TabContent.Visible = true
            
            -- Auto-size content
            ContentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                TabContent.Size = UDim2.new(1, 0, 0, ContentList.AbsoluteContentSize.Y)
                ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, ContentList.AbsoluteContentSize.Y)
            end)
        end)
        
        -- Hover Effects
        TabButton.MouseEnter:Connect(function()
            if CurrentTab and CurrentTab.Button ~= TabButton then
                TweenService:Create(TabButton, TweenInfo.new(0.2), {
                    BackgroundColor3 = Color3.fromRGB(50, 50, 60)
                }):Play()
            end
        end)
        
        TabButton.MouseLeave:Connect(function()
            if CurrentTab and CurrentTab.Button ~= TabButton then
                TweenService:Create(TabButton, TweenInfo.new(0.2), {
                    BackgroundColor3 = Colors.Primary
                }):Play()
            end
        end)
    end
    
    -- Set first tab active
    if TabButtons["AIMBOT"] then
        TabButtons["AIMBOT"]:MouseButton1Click()
    end
    
    -- Button Hover Effects
    local function SetupButtonHover(button, normalColor, hoverColor)
        button.MouseEnter:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.2), {
                BackgroundColor3 = hoverColor
            }):Play()
        end)
        
        button.MouseLeave:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.2), {
                BackgroundColor3 = normalColor
            }):Play()
        end)
    end
    
    SetupButtonHover(MinButton, Colors.Warning, Color3.fromRGB(255, 200, 50))
    SetupButtonHover(CloseButton, Colors.Error, Color3.fromRGB(255, 80, 80))
    
    -- Minimize Function
    MinButton.MouseButton1Click:Connect(function()
        IsMinimized = not IsMinimized
        if IsMinimized then
            TweenService:Create(MainFrame, TweenInfo.new(0.3), {
                Size = UDim2.new(0, 500, 0, 45)
            }):Play()
            Sidebar.Visible = false
            ContentArea.Visible = false
        else
            TweenService:Create(MainFrame, TweenInfo.new(0.3), {
                Size = UDim2.new(0, 500, 0, 450)
            }):Play()
            Sidebar.Visible = true
            ContentArea.Visible = true
        end
    end)
    
    -- Close Function
    CloseButton.MouseButton1Click:Connect(function()
        TweenService:Create(MainFrame, TweenInfo.new(0.3), {
            Size = UDim2.new(0, 0, 0, 0)
        }):Play()
        wait(0.3)
        SafeCall(StopFeatures)
        ScreenGui:Destroy()
    end)
    
    -- UI Creation Functions
    local function CreateSection(parent, title)
        local Section = Instance.new("Frame")
        Section.Size = UDim2.new(1, 0, 0, 0)
        Section.BackgroundColor3 = Colors.Primary
        Section.BorderSizePixel = 0
        
        local SectionCorner = Instance.new("UICorner")
        SectionCorner.CornerRadius = UDim.new(0, 10)
        SectionCorner.Parent = Section
        
        -- Title
        local TitleLabel = Instance.new("TextLabel")
        TitleLabel.Size = UDim2.new(1, -20, 0, 35)
        TitleLabel.Position = UDim2.new(0, 10, 0, 0)
        TitleLabel.BackgroundTransparency = 1
        TitleLabel.Text = title
        TitleLabel.Font = Enum.Font.GothamBold
        TitleLabel.TextSize = 16
        TitleLabel.TextColor3 = Colors.Text
        TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        -- Content
        local Content = Instance.new("Frame")
        Content.Name = "Content"
        Content.Size = UDim2.new(1, -20, 0, 0)
        Content.Position = UDim2.new(0, 10, 0, 40)
        Content.BackgroundTransparency = 1
        
        local ContentLayout = Instance.new("UIListLayout")
        ContentLayout.Padding = UDim.new(0, 10)
        ContentLayout.Parent = Content
        
        -- Auto-size
        ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Content.Size = UDim2.new(1, -20, 0, ContentLayout.AbsoluteContentSize.Y)
            Section.Size = UDim2.new(1, 0, 0, ContentLayout.AbsoluteContentSize.Y + 45)
        end)
        
        TitleLabel.Parent = Section
        Content.Parent = Section
        Section.Parent = parent
        
        return Content
    end
    
    local function CreateToggle(parent, text, default, callback)
        local ToggleFrame = Instance.new("Frame")
        ToggleFrame.Size = UDim2.new(1, 0, 0, 35)
        ToggleFrame.BackgroundTransparency = 1
        
        local ToggleButton = Instance.new("TextButton")
        ToggleButton.Size = UDim2.new(1, 0, 1, 0)
        ToggleButton.BackgroundTransparency = 1
        ToggleButton.Text = ""
        ToggleButton.AutoButtonColor = false
        
        -- Text
        local TextLabel = Instance.new("TextLabel")
        TextLabel.Size = UDim2.new(0.7, 0, 1, 0)
        TextLabel.BackgroundTransparency = 1
        TextLabel.Text = text
        TextLabel.Font = Enum.Font.Gotham
        TextLabel.TextSize = 14
        TextLabel.TextColor3 = Colors.Text
        TextLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        -- Toggle
        local Toggle = Instance.new("Frame")
        Toggle.Size = UDim2.new(0, 50, 0, 25)
        Toggle.Position = UDim2.new(1, -55, 0.5, -12.5)
        Toggle.BackgroundColor3 = default and Colors.Success or Colors.Error
        Toggle.BorderSizePixel = 0
        
        local ToggleCorner = Instance.new("UICorner")
        ToggleCorner.CornerRadius = UDim.new(0, 12)
        ToggleCorner.Parent = Toggle
        
        local ToggleCircle = Instance.new("Frame")
        ToggleCircle.Size = UDim2.new(0, 21, 0, 21)
        ToggleCircle.Position = default and UDim2.new(1, -23, 0.5, -10.5) or UDim2.new(0, 2, 0.5, -10.5)
        ToggleCircle.BackgroundColor3 = Colors.Text
        ToggleCircle.BorderSizePixel = 0
        
        local CircleCorner = Instance.new("UICorner")
        CircleCorner.CornerRadius = UDim.new(0, 10)
        CircleCorner.Parent = ToggleCircle
        
        local state = default
        
        ToggleButton.MouseButton1Click:Connect(function()
            state = not state
            SafeCall(callback, state)
            
            if state then
                TweenService:Create(Toggle, TweenInfo.new(0.2), {
                    BackgroundColor3 = Colors.Success
                }):Play()
                TweenService:Create(ToggleCircle, TweenInfo.new(0.2), {
                    Position = UDim2.new(1, -23, 0.5, -10.5)
                }):Play()
            else
                TweenService:Create(Toggle, TweenInfo.new(0.2), {
                    BackgroundColor3 = Colors.Error
                }):Play()
                TweenService:Create(ToggleCircle, TweenInfo.new(0.2), {
                    Position = UDim2.new(0, 2, 0.5, -10.5)
                }):Play()
            end
        end)
        
        TextLabel.Parent = ToggleButton
        Toggle.Parent = ToggleButton
        ToggleCircle.Parent = Toggle
        ToggleButton.Parent = ToggleFrame
        ToggleFrame.Parent = parent
        
        return {
            Set = function(value)
                state = value
                Toggle.BackgroundColor3 = state and Colors.Success or Colors.Error
                ToggleCircle.Position = state and UDim2.new(1, -23, 0.5, -10.5) or UDim2.new(0, 2, 0.5, -10.5)
            end
        }
    end
    
    local function CreateSlider(parent, text, min, max, default, callback)
        local SliderFrame = Instance.new("Frame")
        SliderFrame.Size = UDim2.new(1, 0, 0, 60)
        SliderFrame.BackgroundTransparency = 1
        
        -- Text
        local TextLabel = Instance.new("TextLabel")
        TextLabel.Size = UDim2.new(1, 0, 0, 25)
        TextLabel.BackgroundTransparency = 1
        TextLabel.Text = text .. ": " .. default
        TextLabel.Font = Enum.Font.Gotham
        TextLabel.TextSize = 14
        TextLabel.TextColor3 = Colors.Text
        TextLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        -- Slider
        local Slider = Instance.new("Frame")
        Slider.Size = UDim2.new(1, 0, 0, 6)
        Slider.Position = UDim2.new(0, 0, 0, 35)
        Slider.BackgroundColor3 = Colors.Secondary
        
        local SliderCorner = Instance.new("UICorner")
        SliderCorner.CornerRadius = UDim.new(0, 3)
        SliderCorner.Parent = Slider
        
        local Fill = Instance.new("Frame")
        Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        Fill.BackgroundColor3 = Colors.Accent
        Fill.BorderSizePixel = 0
        
        local FillCorner = Instance.new("UICorner")
        FillCorner.CornerRadius = UDim.new(0, 3)
        FillCorner.Parent = Fill
        
        local Button = Instance.new("TextButton")
        Button.Size = UDim2.new(0, 20, 0, 20)
        Button.Position = UDim2.new((default - min) / (max - min), -10, 0, 30)
        Button.BackgroundColor3 = Colors.Text
        Button.Text = ""
        Button.AutoButtonColor = false
        
        local ButtonCorner = Instance.new("UICorner")
        ButtonCorner.CornerRadius = UDim.new(0, 10)
        ButtonCorner.Parent = Button
        
        local value = default
        local dragging = false
        
        local function update(newValue)
            value = math.clamp(math.floor(newValue), min, max)
            local percentage = (value - min) / (max - min)
            
            Fill.Size = UDim2.new(percentage, 0, 1, 0)
            Button.Position = UDim2.new(percentage, -10, 0, 30)
            TextLabel.Text = text .. ": " .. value
            
            SafeCall(callback, value)
        end
        
        Button.MouseButton1Down:Connect(function()
            dragging = true
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        
        Slider.MouseButton1Down:Connect(function(x)
            local relativeX = x - Slider.AbsolutePosition.X
            local percentage = math.clamp(relativeX / Slider.AbsoluteSize.X, 0, 1)
            update(min + (max - min) * percentage)
        end)
        
        game:GetService("UserInputService").InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local mousePos = input.Position
                local relativeX = mousePos.X - Slider.AbsolutePosition.X
                local percentage = math.clamp(relativeX / Slider.AbsoluteSize.X, 0, 1)
                update(min + (max - min) * percentage)
            end
        end)
        
        Fill.Parent = Slider
        Slider.Parent = SliderFrame
        Button.Parent = SliderFrame
        TextLabel.Parent = SliderFrame
        SliderFrame.Parent = parent
        
        update(default)
    end
    
    local function CreateDropdown(parent, text, options, default, callback)
        local DropdownFrame = Instance.new("Frame")
        DropdownFrame.Size = UDim2.new(1, 0, 0, 40)
        DropdownFrame.BackgroundTransparency = 1
        
        -- Text
        local TextLabel = Instance.new("TextLabel")
        TextLabel.Size = UDim2.new(0.5, 0, 1, 0)
        TextLabel.BackgroundTransparency = 1
        TextLabel.Text = text
        TextLabel.Font = Enum.Font.Gotham
        TextLabel.TextSize = 14
        TextLabel.TextColor3 = Colors.Text
        TextLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        -- Dropdown
        local Dropdown = Instance.new("TextButton")
        Dropdown.Size = UDim2.new(0.5, 0, 1, 0)
        Dropdown.Position = UDim2.new(0.5, 0, 0, 0)
        Dropdown.BackgroundColor3 = Colors.Secondary
        Dropdown.Text = options[default] or options[1]
        Dropdown.Font = Enum.Font.Gotham
        Dropdown.TextSize = 13
        Dropdown.TextColor3 = Colors.Text
        Dropdown.AutoButtonColor = false
        
        local DropdownCorner = Instance.new("UICorner")
        DropdownCorner.CornerRadius = UDim.new(0, 6)
        DropdownCorner.Parent = Dropdown
        
        local current = default or 1
        
        Dropdown.MouseButton1Click:Connect(function()
            current = (current % #options) + 1
            Dropdown.Text = options[current]
            SafeCall(callback, options[current])
        end)
        
        SetupButtonHover(Dropdown, Colors.Secondary, Colors.Primary)
        
        TextLabel.Parent = DropdownFrame
        Dropdown.Parent = DropdownFrame
        DropdownFrame.Parent = parent
    end
    
    local function CreateInput(parent, text, placeholder, callback)
        local InputFrame = Instance.new("Frame")
        InputFrame.Size = UDim2.new(1, 0, 0, 40)
        InputFrame.BackgroundTransparency = 1
        
        -- Text
        local TextLabel = Instance.new("TextLabel")
        TextLabel.Size = UDim2.new(0.5, 0, 1, 0)
        TextLabel.BackgroundTransparency = 1
        TextLabel.Text = text
        TextLabel.Font = Enum.Font.Gotham
        TextLabel.TextSize = 14
        TextLabel.TextColor3 = Colors.Text
        TextLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        -- Input
        local InputBox = Instance.new("TextBox")
        InputBox.Size = UDim2.new(0.5, 0, 1, 0)
        InputBox.Position = UDim2.new(0.5, 0, 0, 0)
        InputBox.BackgroundColor3 = Colors.Secondary
        InputBox.BorderSizePixel = 0
        InputBox.Text = ""
        InputBox.PlaceholderText = placeholder
        InputBox.Font = Enum.Font.Gotham
        InputBox.TextSize = 13
        InputBox.TextColor3 = Colors.Text
        
        local InputCorner = Instance.new("UICorner")
        InputCorner.CornerRadius = UDim.new(0, 6)
        InputCorner.Parent = InputBox
        
        InputBox.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                SafeCall(callback, InputBox.Text)
            end
        end)
        
        TextLabel.Parent = InputFrame
        InputBox.Parent = InputFrame
        InputFrame.Parent = parent
    end
    
    -- Create UI Elements
    -- AIMBOT Tab
    local AimTab = TabContents["AIMBOT"]
    local AimSection = CreateSection(AimTab, "Aimbot Settings")
    local AimAdvanced = CreateSection(AimTab, "Advanced Settings")
    
    CreateToggle(AimSection, "Enable Aimbot", false, function(state)
        Settings.Aimbot.Enabled = state
    end)
    
    CreateToggle(AimSection, "Wall Check", false, function(state)
        Settings.Aimbot.WallCheck = state
    end)
    
    CreateToggle(AimSection, "Team Check", false, function(state)
        Settings.Aimbot.TeamCheck = state
    end)
    
    CreateDropdown(AimSection, "Aim Part", {"Head", "Body", "HumanoidRootPart"}, 1, function(option)
        Settings.Aimbot.TargetPart = option
    end)
    
    CreateSlider(AimSection, "FOV", 10, 500, 100, function(value)
        Settings.Aimbot.FOV = value
    end)
    
    CreateToggle(AimAdvanced, "Blatant Mode", false, function(state)
        Settings.Aimbot.BlatantMode = state
    end)
    
    CreateToggle(AimAdvanced, "Silent Aim", false, function(state)
        Settings.Aimbot.SilentAim = state
    end)
    
    CreateToggle(AimAdvanced, "Triggerbot", false, function(state)
        Settings.Aimbot.Triggerbot = state
    end)
    
    CreateSlider(AimAdvanced, "Smoothness", 1, 100, 10, function(value)
        Settings.Aimbot.Smoothness = value / 100
    end)
    
    CreateSlider(AimAdvanced, "Hit Chance %", 1, 100, 100, function(value)
        Settings.Aimbot.HitChance = value
    end)
    
    CreateSlider(AimAdvanced, "Triggerbot Delay", 1, 100, 10, function(value)
        Settings.Aimbot.TriggerbotDelay = value / 100
    end)
    
    -- VISUAL Tab
    local VisualTab = TabContents["VISUAL"]
    local VisualSection = CreateSection(VisualTab, "ESP Settings")
    local VisualConfig = CreateSection(VisualTab, "Visual Configuration")
    
    CreateToggle(VisualSection, "Enable ESP", false, function(state)
        Settings.Visual.ESP = state
        if not state then
            for player in pairs(ESPObjects) do
                RemoveESP(player)
            end
        end
    end)
    
    CreateToggle(VisualSection, "Show Tracers", false, function(state)
        Settings.Visual.Tracers = state
    end)
    
    CreateToggle(VisualConfig, "Box ESP", false, function(state)
        Settings.Visual.BoxESP = state
    end)
    
    CreateToggle(VisualConfig, "Health Bar", false, function(state)
        Settings.Visual.HealthBar = state
    end)
    
    CreateToggle(VisualConfig, "Chams", false, function(state)
        Settings.Visual.Chams = state
    end)
    
    CreateToggle(VisualConfig, "Team Colors", false, function(state)
        Settings.Visual.TeamColors = state
    end)
    
    CreateSlider(VisualConfig, "Tracer Thickness", 1, 10, 1, function(value)
        Settings.Visual.TracerThickness = value
    end)
    
    CreateSlider(VisualConfig, "Max Distance", 50, 1000, 500, function(value)
        Settings.Visual.MaxDistance = value
    end)
    
    -- MOVEMENT Tab
    local MovementTab = TabContents["MOVEMENT"]
    local SpeedSection = CreateSection(MovementTab, "Speed Settings")
    local FlySection = CreateSection(MovementTab, "Fly Settings")
    local OtherSection = CreateSection(MovementTab, "Other Features")
    
    CreateToggle(SpeedSection, "Enable Walkspeed", false, function(state)
        Settings.Movement.Walkspeed = state
    end)
    
    CreateInput(SpeedSection, "Walkspeed Value", "16-200", function(text)
        local value = tonumber(text)
        if value and value >= 16 and value <= 200 then
            Settings.Movement.WalkspeedValue = value
        end
    end)
    
    CreateToggle(SpeedSection, "Enable Jumppower", false, function(state)
        Settings.Movement.Jumppower = state
    end)
    
    CreateInput(SpeedSection, "Jumppower Value", "50-300", function(text)
        local value = tonumber(text)
        if value and value >= 50 and value <= 300 then
            Settings.Movement.JumppowerValue = value
        end
    end)
    
    CreateToggle(OtherSection, "Enable Noclip", false, function(state)
        Settings.Movement.Noclip = state
    end)
    
    CreateToggle(FlySection, "Enable Fly", false, function(state)
        Settings.Movement.Fly = state
    end)
    
    CreateSlider(FlySection, "Fly Speed", 1, 100, 25, function(value)
        Settings.Movement.FlySpeed = value
    end)
    
    CreateToggle(OtherSection, "Infinite Jump", false, function(state)
        Settings.Movement.InfiniteJump = state
    end)
    
    -- MISC Tab
    local MiscTab = TabContents["MISC"]
    local UtilitySection = CreateSection(MiscTab, "Utility")
    local ConfigSection = CreateSection(MiscTab, "Configuration")
    
    CreateToggle(UtilitySection, "Anti-AFK", false, function(state)
        -- Anti-AFK logic here
    end)
    
    CreateToggle(UtilitySection, "Auto Farm", false, function(state)
        -- Auto Farm logic here
    end)
    
    -- Credits
    local CreditsSection = CreateSection(MiscTab, "Credits")
    local CreditsLabel = Instance.new("TextLabel")
    CreditsLabel.Size = UDim2.new(1, 0, 0, 60)
    CreditsLabel.BackgroundTransparency = 1
    CreditsLabel.Text = "MACROPEAK GUI\nVersion 1.0.0\nMade By @LuaDev\nDelta Style UI"
    CreditsLabel.Font = Enum.Font.Gotham
    CreditsLabel.TextSize = 14
    CreditsLabel.TextColor3 = Colors.TextSecondary
    CreditsLabel.TextYAlignment = Enum.TextYAlignment.Center
    CreditsLabel.Parent = CreditsSection
    
    return ScreenGui
end

-----------------------------------------------------------
--                     INITIALIZATION
-----------------------------------------------------------
-- Create UI
local UI = SafeCall(CreateUI)

-- Start features
SafeCall(StartFeatures)

-- Initial movement update
if LocalPlayer.Character then
    SafeCall(UpdateMovement)
end

-- Notification
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "MACROPEAK",
    Text = "Delta Style UI Loaded!\nMade By @LuaDev",
    Duration = 5
})

print("MACROPEAK GUI Loaded Successfully!")
print("Delta Style UI")
print("Made By @LuaDev")
print("Version: 1.0.0")
