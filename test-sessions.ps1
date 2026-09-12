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
    Write-Host "  SESSION MANAGEMENT TEST RUN #$run" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Magenta

    $testEmail = "sess_$(Get-Random -Maximum 999999)@test.com"
    $testPhone = "9{0:d9}" -f (Get-Random -Maximum 999999999)

    # Step 1: Register
    Write-Host "[Step 1] Register" -ForegroundColor Yellow
    $body = @{ name = "Sess $run"; email = $testEmail; phone = $testPhone; password = "password123" } | ConvertTo-Json
    $r = Invoke-RestMethod -Uri "$api/auth/register" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
    Test-Result ($r.success) "Registration succeeded"
    $token = $r.data.token

    # Step 2: Login from device 1 (triggers OTP)
    Write-Host "[Step 2] Login device 1" -ForegroundColor Yellow
    $body = @{ email = $testEmail; password = "password123"; deviceId = "dev1_$run"; deviceName = "iPhone $run" } | ConvertTo-Json
    $r = Invoke-RestMethod -Uri "$api/auth/login" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
    Test-Result ($r.data.requiresOtp -eq $true) "New device requires OTP"
    $body = @{ email = $testEmail; otp = $r.data.otp; deviceId = "dev1_$run"; deviceName = "iPhone $run" } | ConvertTo-Json
    $r = Invoke-RestMethod -Uri "$api/auth/verify-otp" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
    $token = $r.data.token
    Test-Result ($token -ne $null) "Device 1 trusted"

    # Step 3: Login from device 2 (triggers OTP)
    Write-Host "[Step 3] Login device 2" -ForegroundColor Yellow
    $body = @{ email = $testEmail; password = "password123"; deviceId = "dev2_$run"; deviceName = "Android Tablet" } | ConvertTo-Json
    $r = Invoke-RestMethod -Uri "$api/auth/login" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
    $body = @{ email = $testEmail; otp = $r.data.otp; deviceId = "dev2_$run"; deviceName = "Android Tablet" } | ConvertTo-Json
    $r = Invoke-RestMethod -Uri "$api/auth/verify-otp" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
    Test-Result ($r.success) "Device 2 trusted"

    # Step 4: Get sessions
    Write-Host "[Step 4] Get sessions" -ForegroundColor Yellow
    $headers = @{ Authorization = "Bearer $token" }
    $r = Invoke-RestMethod -Uri "$api/users/sessions" -Headers $headers -ContentType "application/json" -TimeoutSec 30
    Test-Result ($r.success) "Sessions fetched"
    Test-Result ($r.data.Count -ge 2) "At least 2 devices found (got $($r.data.Count))"

    # Step 5: Revoke device 1
    Write-Host "[Step 5] Revoke device 1" -ForegroundColor Yellow
    try {
        $null = Invoke-RestMethod -Uri "$api/users/sessions/dev1_$run" -Method Delete -Headers $headers -ContentType "application/json" -TimeoutSec 30
        Test-Result $true "Device 1 revoked"
    } catch { Test-Result $false "Revoke failed: $_" }

    # Step 6: Verify only device 2 remains
    Write-Host "[Step 6] Verify sessions after revoke" -ForegroundColor Yellow
    $r = Invoke-RestMethod -Uri "$api/users/sessions" -Headers $headers -ContentType "application/json" -TimeoutSec 30
    $remaining = $r.data.Count
    Test-Result ($remaining -eq 1) "Only 1 session remaining (got $remaining)"

    # Step 7: Login from device 1 again (should require OTP since it was revoked)
    Write-Host "[Step 7] Re-login revoked device" -ForegroundColor Yellow
    $body = @{ email = $testEmail; password = "password123"; deviceId = "dev1_$run"; deviceName = "iPhone $run" } | ConvertTo-Json
    $r = Invoke-RestMethod -Uri "$api/auth/login" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
    Test-Result ($r.data.requiresOtp -eq $true) "Revoked device requires OTP again"

    # Step 8: Revoke all sessions (use the updated token from re-login)
    Write-Host "[Step 8] Revoke all sessions" -ForegroundColor Yellow
    $body = @{ email = $testEmail; otp = $r.data.otp; deviceId = "dev1_$run"; deviceName = "iPhone $run" } | ConvertTo-Json
    $r2 = Invoke-RestMethod -Uri "$api/auth/verify-otp" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
    $newToken = $r2.data.token
    $headers2 = @{ Authorization = "Bearer $newToken" }
    try {
        $null = Invoke-RestMethod -Uri "$api/users/sessions" -Method Delete -Headers $headers2 -ContentType "application/json" -TimeoutSec 30
        Test-Result $true "All sessions revoked"
    } catch { Test-Result $false "Revoke all failed: $_" }

    # Step 9: Verify no sessions left
    Write-Host "[Step 9] Verify no sessions" -ForegroundColor Yellow
    $r = Invoke-RestMethod -Uri "$api/users/sessions" -Headers $headers2 -ContentType "application/json" -TimeoutSec 30
    Test-Result ($r.data.Count -eq 0) "No sessions remaining"

    Write-Host "--- Run #$run done ---" -ForegroundColor Green
}

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  SESSION TEST SUMMARY" -ForegroundColor Cyan
Write-Host "  PASSED: $passCount  FAILED: $failCount" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Magenta
