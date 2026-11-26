local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local old = playerGui:FindFirstChild("DoublexLite")
if old then old:Destroy() end
local noclip, speedHack, speed = false, false, 50
local antiKnockback = false
local collisions = {}
local humanoid, originalSpeed
local connections = {}
local gui = Instance.new("ScreenGui")
gui.Name = "DoublexLite"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
gui.Parent = playerGui
local function corner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = obj
end
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0.9, 0, 0, 330)
frame.Position = UDim2.fromScale(0.5, 0.5)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.BackgroundColor3 = Color3.fromRGB(24, 17, 33)
frame.Parent = gui
corner(frame, 16)
local limit = Instance.new("UISizeConstraint")
limit.MaxSize = Vector2.new(450, 330)
limit.Parent = frame
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(150, 75, 240)
stroke.Thickness = 2
stroke.Parent = frame
local function create(class, txt, pos, size, color)
    local obj = Instance.new(class)
    obj.Position = pos
    obj.Size = size
    obj.BackgroundColor3 = color
    obj.Text = txt
    obj.TextColor3 = Color3.new(1, 1, 1)
    obj.TextSize = 20
    obj.Font = Enum.Font.GothamBold
    obj.Parent = frame
    corner(obj, 10)
    return obj
end
local purple = Color3.fromRGB(100, 50, 155)
local green = Color3.fromRGB(35, 160, 95)
local dark = Color3.fromRGB(48, 32, 63)
local header = create("TextLabel", "DOUBLEX HUB", UDim2.fromOffset(12, 10), UDim2.new(1, -114, 0, 45), dark)
header.Active = true
header.TextScaled = true
local titleSize = Instance.new("UITextSizeConstraint")
titleSize.MaxTextSize = 20
titleSize.Parent = header
header.TextColor3 = Color3.fromRGB(195, 135, 255)
local close = create("TextButton", "X", UDim2.new(1, -48, 0, 10), UDim2.fromOffset(36, 45), Color3.fromRGB(175, 40, 65))
local minimize = create("TextButton", "−", UDim2.new(1, -92, 0, 10), UDim2.fromOffset(36, 45), purple)
local bubble = Instance.new("TextButton")
bubble.Name = "Reopen"
bubble.Size = UDim2.fromOffset(58, 58)
bubble.Position = UDim2.fromOffset(16, 100)
bubble.BackgroundColor3 = purple
bubble.TextColor3 = Color3.new(1, 1, 1)
bubble.Font = Enum.Font.GothamBold
bubble.TextSize = 23
bubble.Text = "DX"
bubble.Visible = false
bubble.Active = true
bubble.ZIndex = 10
bubble.Parent = gui
corner(bubble, 29)
local bubbleStroke = Instance.new("UIStroke")
bubbleStroke.Color = Color3.fromRGB(195, 135, 255)
bubbleStroke.Thickness = 2
bubbleStroke.Parent = bubble
minimize.Activated:Connect(function()
    frame.Visible = false
    bubble.Visible = true
end)
local bubblePress, bubbleStart, bubbleOrigin
local bubbleMoved = false
bubble.InputBegan:Connect(function(input)
    if bubblePress then return end
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        bubblePress = input
        bubbleStart = Vector2.new(input.Position.X, input.Position.Y)
        bubbleOrigin = Vector2.new(bubble.Position.X.Offset, bubble.Position.Y.Offset)
        bubbleMoved = false
    end
end)
table.insert(connections, UIS.InputChanged:Connect(function(input)
    if not bubblePress then return end
    if input ~= bubblePress and not (bubblePress.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement) then return end
    local delta = Vector2.new(input.Position.X, input.Position.Y) - bubbleStart
    if delta.Magnitude > 8 then bubbleMoved = true end
    if bubbleMoved then
        local bounds = gui.AbsoluteSize
        local pos = bubbleOrigin + delta
        bubble.Position = UDim2.fromOffset(math.clamp(pos.X, 0, math.max(0, bounds.X - 58)), math.clamp(pos.Y, 0, math.max(0, bounds.Y - 58)))
    end
end))
table.insert(connections, UIS.InputEnded:Connect(function(input)
    if input ~= bubblePress then return end
    bubblePress = nil
    if not bubbleMoved then
        bubble.Visible = false
        frame.Visible = true
    end
end))
local noclipBtn = create("TextButton", "Atravessar paredes: OFF", UDim2.new(0, 12, 0, 65), UDim2.new(1, -24, 0, 50), purple)
local speedBtn = create("TextButton", "SpeedHack: OFF", UDim2.new(0, 12, 0, 123), UDim2.new(1, -24, 0, 50), purple)
local antiBtn = create("TextButton", "Anti-Knockback: OFF", UDim2.new(0, 12, 0, 181), UDim2.new(1, -24, 0, 50), purple)
local speedLabel = create("TextLabel", "Velocidade:", UDim2.new(0, 12, 0, 242), UDim2.new(0.55, -12, 0, 50), dark)
local speedBox = create("TextBox", "50", UDim2.new(0.58, 0, 0, 242), UDim2.new(0.42, -12, 0, 50), dark)
speedBox.ClearTextOnFocus = false
local footer = create("TextLabel", "DOUBLEX HUB - LITE", UDim2.new(0, 12, 0, 298), UDim2.new(1, -24, 0, 25), frame.BackgroundColor3)
footer.TextSize = 12
local function restoreCollision()
    for part, value in pairs(collisions) do
        if part.Parent then part.CanCollide = value end
    end
    table.clear(collisions)
end
local function restoreSpeed()
    if humanoid and humanoid.Parent and originalSpeed then
        humanoid.WalkSpeed = originalSpeed
    end
    originalSpeed = nil
end
noclipBtn.Activated:Connect(function()
    noclip = not noclip
    noclipBtn.Text = "Atravessar paredes: " .. (noclip and "ON" or "OFF")
    noclipBtn.BackgroundColor3 = noclip and green or purple
    if not noclip then restoreCollision() end
end)
speedBtn.Activated:Connect(function()
    speedHack = not speedHack
    speedBtn.Text = "SpeedHack: " .. (speedHack and "ON" or "OFF")
    speedBtn.BackgroundColor3 = speedHack and green or purple
    if not speedHack then restoreSpeed() end
end)
antiBtn.Activated:Connect(function()
    antiKnockback = not antiKnockback
    antiBtn.Text = "Anti-Knockback: " .. (antiKnockback and "ON" or "OFF")
    antiBtn.BackgroundColor3 = antiKnockback and green or purple
end)
table.insert(connections, RunService.Heartbeat:Connect(function()
    if not antiKnockback then return end
    local char = player.Character
    if not char then return end
    local h = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not h or not root or h.Health <= 0 or h.SeatPart or root.Anchored then return end
    local v = root.AssemblyLinearVelocity
    local horizontal = Vector3.new(v.X, 0, v.Z)
    local move = Vector3.new(h.MoveDirection.X, 0, h.MoveDirection.Z)
    local corrected = horizontal
    if move.Magnitude < 0.05 then
        if horizontal.Magnitude > 1.5 then
            corrected = Vector3.zero
        end
    else
        local direction = move.Unit
        local forward = horizontal:Dot(direction)
        local sideways = horizontal - direction * forward
        local intended = math.max(0, h.WalkSpeed) * math.min(move.Magnitude, 1)
        if forward < -2 or forward > intended + 5 or sideways.Magnitude > math.max(3, intended * 0.3) then
            corrected = direction * math.clamp(forward, 0, intended)
        end
    end
    if (corrected - horizontal).Magnitude > 0.1 then
        root.AssemblyLinearVelocity = Vector3.new(corrected.X, v.Y, corrected.Z)
    end
end))
speedBox.FocusLost:Connect(function()
    speed = math.clamp(tonumber(speedBox.Text) or speed, 1, 200)
    speedBox.Text = tostring(speed)
end)
table.insert(connections, RunService.Stepped:Connect(function()
    local char = player.Character
    if not char then return end
    local current = char:FindFirstChildOfClass("Humanoid")
    if current ~= humanoid then
        restoreSpeed()
        restoreCollision()
        humanoid = current
    end
    if speedHack and humanoid then
        if originalSpeed == nil then originalSpeed = humanoid.WalkSpeed end
        humanoid.WalkSpeed = speed
    end
    if noclip then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if collisions[part] == nil then collisions[part] = part.CanCollide end
                part.CanCollide = false
            end
        end
    end
end))
local dragging = false
local dragStart, startPos, dragInput
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        if input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)
table.insert(connections, UIS.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end))
gui.Destroying:Connect(function()
    noclip, speedHack, antiKnockback = false, false, false
    for _, connection in ipairs(connections) do connection:Disconnect() end
    restoreCollision()
    restoreSpeed()
end)
close.Activated:Connect(function() gui:Destroy() end)
