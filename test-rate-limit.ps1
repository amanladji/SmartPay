$api = "http://localhost:8765/api"
$passCount = 0
$failCount = 0

function Test-Result {
    param($Condition, $Message)
    if ($Condition) { Write-Host "  [PASS] $Message" -ForegroundColor Green; $script:passCount++ }
    else { Write-Host "  [FAIL] $Message" -ForegroundColor Red; $script:failCount++ }
}

function Should-Fail {
    param($Message)
    try { $null = Invoke-RestMethod @args -ErrorAction Stop; Test-Result $false $Message }
    catch { Test-Result $true $Message }
}

# Warmup
Write-Host "Warming up..." -ForegroundColor Cyan
$null = Invoke-RestMethod -Uri "$api/health" -TimeoutSec 30

for ($run = 1; $run -le 7; $run++) {
    Write-Host "`n========================================" -ForegroundColor Magenta
    Write-Host "  RATE LIMITING TEST RUN #$run" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Magenta

    $testEmail = "rate_$(Get-Random -Maximum 999999)@test.com"
    $testPhone = "9{0:d9}" -f (Get-Random -Maximum 999999999)

    # Step 1: Register
    Write-Host "[Step 1] Register" -ForegroundColor Yellow
    try {
        $body = @{ name = "Rate $run"; email = $testEmail; phone = $testPhone; password = "password123" } | ConvertTo-Json
        $r = Invoke-RestMethod -Uri "$api/auth/register" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
        Test-Result ($r.success) "Registration succeeded"
    } catch { Test-Result $false "Registration failed: $_"; continue }

    # Step 2: Attempt login with wrong password 6 times - 6th should be rate limited
    Write-Host "[Step 2] Rate limit on login (5 wrong attempts)" -ForegroundColor Yellow
    for ($i = 1; $i -le 5; $i++) {
        try {
            $body = @{ email = $testEmail; password = "wrongpass$i"; deviceId = "dev_rate"; deviceName = "Rate Test" } | ConvertTo-Json
            $null = Invoke-RestMethod -Uri "$api/auth/login" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
        } catch { }
    }
    # 6th attempt should be rate limited
    try {
        $body = @{ email = $testEmail; password = "wrongpass6"; deviceId = "dev_rate"; deviceName = "Rate Test" } | ConvertTo-Json
        $r = Invoke-RestMethod -Uri "$api/auth/login" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
        Test-Result $false "6th login attempt should be rate limited"
    } catch {
        $isRateLimit = $_.Exception.Message -match "429" -or $_.Exception.Message -match "Too many"
        Test-Result $isRateLimit "6th login attempt rate limited (429)"
    }

    # Step 3: Login with correct password - should also be blocked (rate limit active)
    Write-Host "[Step 3] Correct login blocked by rate limit" -ForegroundColor Yellow
    try {
        $body = @{ email = $testEmail; password = "password123"; deviceId = "dev_rate2"; deviceName = "Rate Test" } | ConvertTo-Json
        $r = Invoke-RestMethod -Uri "$api/auth/login" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
        Test-Result $false "Correct login should be rate limited too"
    } catch {
        $isRateLimit = $_.Exception.Message -match "429" -or $_.Exception.Message -match "Too many"
        Test-Result $isRateLimit "Correct login blocked by rate limit (429)"
    }

    # Note: OTP rate limiting test moved to a separate user to avoid login rate limit blocking it
    Write-Host "[Step 4] Rate limit on OTP (separate user)" -ForegroundColor Yellow
    $otpEmail = "otprate_$(Get-Random -Maximum 999999)@test.com"
    $otpPhone = "7{0:d9}" -f (Get-Random -Maximum 999999999)
    try {
        $body = @{ name = "OtpRate"; email = $otpEmail; phone = $otpPhone; password = "password123" } | ConvertTo-Json
        $r = Invoke-RestMethod -Uri "$api/auth/register" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
        $otpToken = $r.data.token
        # Login to trigger OTP
        $body = @{ email = $otpEmail; password = "password123"; deviceId = "dev_otp"; deviceName = "OTP Test" } | ConvertTo-Json
        $r = Invoke-RestMethod -Uri "$api/auth/login" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
        $otp = $r.data.otp
        Test-Result ($otp -ne $null) "OTP generated"
    } catch { Test-Result $false "OTP user setup failed: $_"; continue }

    # 5 wrong OTP attempts
    for ($i = 1; $i -le 5; $i++) {
        try {
            $body = @{ email = $otpEmail; otp = "00000$i"; deviceId = "dev_otp"; deviceName = "OTP Test" } | ConvertTo-Json
            $null = Invoke-RestMethod -Uri "$api/auth/verify-otp" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
        } catch { }
    }
    # 6th OTP should be rate limited (but the correct OTP also won't work since it's in the same window)
    try {
        $body = @{ email = $otpEmail; otp = $otp; deviceId = "dev_otp"; deviceName = "OTP Test" } | ConvertTo-Json
        $r = Invoke-RestMethod -Uri "$api/auth/verify-otp" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
        Test-Result $false "6th OTP attempt should be rate limited"
    } catch {
        $isRateLimit = $_.Exception.Message -match "429" -or $_.Exception.Message -match "Too many"
        Test-Result $isRateLimit "6th OTP attempt rate limited (429)"
    }

    # Step 5: Register a new user, set PIN, test PIN rate limiting
    Write-Host "[Step 5] Rate limit on PIN verify" -ForegroundColor Yellow
    $pinEmail = "pinrate_$(Get-Random -Maximum 999999)@test.com"
    $pinPhone = "8{0:d9}" -f (Get-Random -Maximum 999999999)
    try {
        $body = @{ name = "PinRate"; email = $pinEmail; phone = $pinPhone; password = "password123" } | ConvertTo-Json
        $r = Invoke-RestMethod -Uri "$api/auth/register" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
        $pinToken = $r.data.token
    } catch { Test-Result $false "PIN test user creation failed"; continue }

    try {
        $body = @{ upiPin = "1234" } | ConvertTo-Json
        $null = Invoke-RestMethod -Uri "$api/users/set-pin" -Method Post -Body $body -ContentType "application/json" -Headers @{ Authorization = "Bearer $pinToken" } -TimeoutSec 30
    } catch { Test-Result $false "PIN setup failed"; continue }

    # 5 wrong PIN attempts
    for ($i = 1; $i -le 5; $i++) {
        try {
            $body = @{ upiPin = "999$i" } | ConvertTo-Json
            $null = Invoke-RestMethod -Uri "$api/users/verify-pin" -Method Post -Body $body -ContentType "application/json" -Headers @{ Authorization = "Bearer $pinToken" } -TimeoutSec 30
        } catch { }
    }
    # 6th should be rate limited
    try {
        $body = @{ upiPin = "9999" } | ConvertTo-Json
        $r = Invoke-RestMethod -Uri "$api/users/verify-pin" -Method Post -Body $body -ContentType "application/json" -Headers @{ Authorization = "Bearer $pinToken" } -TimeoutSec 30
        Test-Result $false "6th PIN attempt should be rate limited"
    } catch {
        $errMsg = try { (New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())).ReadToEnd() | ConvertFrom-Json | Select -ExpandProperty message } catch { "" }
        Test-Result ($errMsg -match "Too many") "6th PIN attempt rate limited"
    }

    # Step 6: Correct PIN still blocked by rate limit
    Write-Host "[Step 6] Correct PIN still blocked by rate limit" -ForegroundColor Yellow
    try {
        $body = @{ upiPin = "1234" } | ConvertTo-Json
        $r = Invoke-RestMethod -Uri "$api/users/verify-pin" -Method Post -Body $body -ContentType "application/json" -Headers @{ Authorization = "Bearer $pinToken" } -TimeoutSec 30
        Test-Result $false "Correct PIN should still be rate limited"
    } catch {
        $errMsg = try { (New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())).ReadToEnd() | ConvertFrom-Json | Select -ExpandProperty message } catch { "" }
        Test-Result ($errMsg -match "Too many") "Correct PIN blocked (rate limit active)"
    }

    Write-Host "--- Run #$run done ---" -ForegroundColor Green
}

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  RATE LIMIT TEST SUMMARY" -ForegroundColor Cyan
Write-Host "  PASSED: $passCount  FAILED: $failCount" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Magenta
