$api = "http://localhost:8765/api"
$passCount = 0
$failCount = 0

function Test-Result {
    param($Condition, $Message)
    if ($Condition) { Write-Host "  [PASS] $Message" -ForegroundColor Green; $script:passCount++ }
    else { Write-Host "  [FAIL] $Message" -ForegroundColor Red; $script:failCount++ }
}

# Warmup
Write-Host "Warming up..." -ForegroundColor Cyan
$null = Invoke-RestMethod -Uri "$api/health" -TimeoutSec 30

for ($run = 1; $run -le 7; $run++) {
    Write-Host "`n========================================" -ForegroundColor Magenta
    Write-Host "  OTP & DEVICE TEST RUN #$run" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Magenta

    $testEmail = "otp_$(Get-Random -Maximum 999999)@test.com"
    $testPhone = "9{0:d9}" -f (Get-Random -Maximum 999999999)
    $deviceId = "dev_$(Get-Random -Maximum 99999)"
    $deviceName = "Browser $run"

    # Step 1: Register
    Write-Host "[Step 1] Register" -ForegroundColor Yellow
    try {
        $body = @{ name = "User $run"; email = $testEmail; phone = $testPhone; password = "password123" } | ConvertTo-Json
        $r = Invoke-RestMethod -Uri "$api/auth/register" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
        Test-Result ($r.success) "Registration succeeded"
    } catch { Test-Result $false "Registration failed: $_"; continue }

    # Step 2: Login from new device - should require OTP
    Write-Host "[Step 2] Login from new device" -ForegroundColor Yellow
    try {
        $body = @{ email = $testEmail; password = "password123"; deviceId = $deviceId; deviceName = $deviceName } | ConvertTo-Json
        $r = Invoke-RestMethod -Uri "$api/auth/login" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
        Test-Result ($r.data.requiresOtp -eq $true) "Login requires OTP"
        $otp = $r.data.otp
        Test-Result (($otp -ne $null) -and ($otp.Length -eq 6)) "OTP received: $otp"
    } catch { Test-Result $false "Login failed: $_"; continue }

    # Step 3: Verify with wrong OTP - should fail
    Write-Host "[Step 3] Wrong OTP" -ForegroundColor Yellow
    try {
        $body = @{ email = $testEmail; otp = "000000"; deviceId = $deviceId; deviceName = $deviceName } | ConvertTo-Json
        $r = Invoke-RestMethod -Uri "$api/auth/verify-otp" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
        Test-Result $false "Wrong OTP should be rejected"
    } catch { Test-Result $true "Wrong OTP correctly rejected" }

    # Step 4: Verify with correct OTP - should succeed
    Write-Host "[Step 4] Correct OTP" -ForegroundColor Yellow
    try {
        $body = @{ email = $testEmail; otp = $otp; deviceId = $deviceId; deviceName = $deviceName } | ConvertTo-Json
        $r = Invoke-RestMethod -Uri "$api/auth/verify-otp" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
        Test-Result ($r.success) "OTP verified"
        Test-Result ($r.data.token -ne $null) "Access token received"
        $accessToken = $r.data.token
    } catch { Test-Result $false "OTP verify failed: $_"; continue }

    # Step 5: Verify access token works
    Write-Host "[Step 5] Access token" -ForegroundColor Yellow
    try {
        $profile = Invoke-RestMethod -Uri "$api/users/me" -Headers @{ Authorization = "Bearer $accessToken" } -ContentType "application/json" -TimeoutSec 30
        Test-Result ($profile.success) "Access token valid"
        Test-Result ($profile.data.email -eq $testEmail) "Profile email matches"
    } catch { Test-Result $false "Profile fetch failed: $_" }

    # Step 6: Login from same device - should NOT require OTP
    Write-Host "[Step 6] Same device re-login" -ForegroundColor Yellow
    try {
        $body = @{ email = $testEmail; password = "password123"; deviceId = $deviceId; deviceName = $deviceName } | ConvertTo-Json
        $r = Invoke-RestMethod -Uri "$api/auth/login" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
        Test-Result ($r.success -and ($r.data.requiresOtp -ne $true)) "Trusted device - no OTP"
        Test-Result ($r.data.token -ne $null) "Access token received directly"
    } catch { Test-Result $false "Same device login failed: $_" }

    # Step 7: Login from different device - should require OTP again
    Write-Host "[Step 7] Different device" -ForegroundColor Yellow
    try {
        $deviceId2 = "dev2_$(Get-Random -Maximum 99999)"
        $body = @{ email = $testEmail; password = "password123"; deviceId = $deviceId2; deviceName = "Device 2" } | ConvertTo-Json
        $r = Invoke-RestMethod -Uri "$api/auth/login" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
        Test-Result ($r.data.requiresOtp -eq $true) "New device requires OTP"
        $otp2 = $r.data.otp
    } catch { Test-Result $false "Different device login failed: $_"; continue }

    Write-Host "[Step 8] No OTP requested rejected" -ForegroundColor Yellow
    try {
        $body = @{ email = $testEmail; otp = "999999"; deviceId = "dev_unreq"; deviceName = "Unreq" } | ConvertTo-Json
        $r = Invoke-RestMethod -Uri "$api/auth/verify-otp" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
        Test-Result $false "No OTP should be rejected"
    } catch { Test-Result $true "No OTP correctly rejected" }

    Write-Host "--- Run #$run done ---" -ForegroundColor Green
}

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  PASSED: $passCount  FAILED: $failCount" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Magenta
