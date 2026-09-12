$api = "http://localhost:8765/api"
$passCount = 0
$failCount = 0

function Test-Result {
    param($Condition, $Message)
    if ($Condition) { Write-Host "  [PASS] $Message" -ForegroundColor Green; $script:passCount++ }
    else { Write-Host "  [FAIL] $Message" -ForegroundColor Red; $script:failCount++ }
}

function Get-OtpFromSmsLog {
    $logFile = "backend/logs/sms.log"
    if (Test-Path $logFile) {
        $lastLine = Get-Content $logFile -Tail 1 -ErrorAction SilentlyContinue
        if ($lastLine -match 'OTP is (\d{6})') {
            return $matches[1]
        }
    }
    return $null
}

# Clear sms.log for a fresh test run
Remove-Item -LiteralPath "backend/logs/sms.log" -ErrorAction SilentlyContinue

$null = Invoke-RestMethod -Uri "$api/health" -TimeoutSec 30

for ($run = 1; $run -le 7; $run++) {
    Write-Host "`n${"="*50}" -ForegroundColor Magenta
    Write-Host "  PHONE OTP TEST RUN #$run" -ForegroundColor Yellow
    Write-Host "${"="*50}" -ForegroundColor Magenta

    $email = "otp_${run}_$(Get-Random -Maximum 99999)@test.com"
    $phone = "9{0:d9}" -f (Get-Random -Maximum 999999999)
    $deviceId = "otp_dev_${run}"

    # 1. Register
    $r = Invoke-RestMethod -Uri "$api/auth/register" -Method Post -Body (@{ name="User $run"; email=$email; phone=$phone; password="password123"; deviceId=$deviceId; deviceName="Device $run" } | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 30
    Test-Result ($r.success) "Registration successful"
    $token = $r.data.token

    # 2. Login from same device (trusted — created during register) — no OTP
    $r = Invoke-RestMethod -Uri "$api/auth/login" -Method Post -Body (@{ email=$email; password="password123"; deviceId=$deviceId; deviceName="Device $run" } | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 30
    Test-Result (-not $r.data.requiresOtp) "Same device (registered-with) no OTP required"

    # 3. Login from new untrusted device — OTP required, OTP delivered via SMS log
    $r = Invoke-RestMethod -Uri "$api/auth/login" -Method Post -Body (@{ email=$email; password="password123"; deviceId="${deviceId}_new"; deviceName="New Device $run" } | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 30
    Test-Result ($r.data.requiresOtp) "New device requires OTP"
    Test-Result ($r.data.message -eq "OTP sent to your registered phone") "Message says phone, not email"
    Start-Sleep -Seconds 1
    $otp = Get-OtpFromSmsLog
    Test-Result ($r.data.otp.Length -eq 6 -and $r.data.otp -eq $otp) "OTP matches in API response and SMS log ($otp)"

    # 4. Verify OTP works
    $r = Invoke-RestMethod -Uri "$api/auth/verify-otp" -Method Post -Body (@{ email=$email; otp=$otp; deviceId="${deviceId}_new"; deviceName="New Device $run" } | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 30
    Test-Result ($r.success) "OTP verification successful"
    Test-Result ($r.data.token.Length -gt 20) "Token received after OTP"

    # 5. Trusted device login — no OTP
    $r = Invoke-RestMethod -Uri "$api/auth/login" -Method Post -Body (@{ email=$email; password="password123"; deviceId="${deviceId}_new"; deviceName="New Device $run" } | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 30
    Test-Result (-not $r.data.requiresOtp) "Trusted device: no OTP required"

    # 6. Wrong OTP rejected
    try {
        Invoke-RestMethod -Uri "$api/auth/verify-otp" -Method Post -Body (@{ email=$email; otp="000000"; deviceId="wrong_dev_${run}"; deviceName="Wrong Device" } | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 30 -ErrorAction Stop
        Test-Result $false "Wrong OTP should have failed"
    } catch { Test-Result $true "Wrong OTP rejected" }

    # 7. Correct OTP after wrong attempt works (fresh OTP from login)
    $r = Invoke-RestMethod -Uri "$api/auth/login" -Method Post -Body (@{ email=$email; password="password123"; deviceId="correct_dev_${run}"; deviceName="Correct Device" } | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 30
    Start-Sleep -Seconds 1
    $otp2 = Get-OtpFromSmsLog
    $r = Invoke-RestMethod -Uri "$api/auth/verify-otp" -Method Post -Body (@{ email=$email; otp=$otp2; deviceId="correct_dev_${run}"; deviceName="Correct Device" } | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 30
    Test-Result ($r.success) "Correct OTP works after wrong attempt"

    # 8. Multiple devices get OTP via phone
    $r = Invoke-RestMethod -Uri "$api/auth/login" -Method Post -Body (@{ email=$email; password="password123"; deviceId="multi_dev1_${run}"; deviceName="Multi Device 1" } | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 30
    Test-Result ($r.data.requiresOtp) "Another new device also gets OTP"
    Test-Result ($r.data.message -eq "OTP sent to your registered phone") "Message still references phone"
    Start-Sleep -Seconds 1
    $otp3 = Get-OtpFromSmsLog

    $r = Invoke-RestMethod -Uri "$api/auth/verify-otp" -Method Post -Body (@{ email=$email; otp=$otp3; deviceId="multi_dev1_${run}"; deviceName="Multi Device 1" } | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 30
    Test-Result ($r.success) "Multiple devices can verify OTP"

    # 9. End-to-end OTP flow
    $r = Invoke-RestMethod -Uri "$api/auth/login" -Method Post -Body (@{ email=$email; password="password123"; deviceId="last_dev_${run}"; deviceName="Last Device" } | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 30
    Start-Sleep -Seconds 1
    $otp4 = Get-OtpFromSmsLog
    $r = Invoke-RestMethod -Uri "$api/auth/verify-otp" -Method Post -Body (@{ email=$email; otp=$otp4; deviceId="last_dev_${run}"; deviceName="Last Device" } | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 30
    Test-Result ($r.success) "End-to-end OTP flow works"

    Write-Host "--- Run #$run done ---" -ForegroundColor Green
}

Write-Host "`n${"="*50}" -ForegroundColor Magenta
Write-Host "  PHONE OTP TEST SUMMARY" -ForegroundColor Cyan
Write-Host "  PASSED: $passCount  FAILED: $failCount" -ForegroundColor Green
Write-Host "${"="*50}" -ForegroundColor Magenta

