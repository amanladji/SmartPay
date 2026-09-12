$api = "http://localhost:8765/api"
$passCount = 0
$failCount = 0
$testNum = 0

function Test-Result {
    param($Condition, $Message)
    if ($Condition) {
        Write-Host "  [PASS] $Message" -ForegroundColor Green
        $script:passCount++
    } else {
        Write-Host "  [FAIL] $Message" -ForegroundColor Red
        $script:failCount++
    }
}

function Register-User {
    param($Name, $Email, $Phone, $Password)
    $body = @{ name = $Name; email = $Email; phone = $Phone; password = $Password } | ConvertTo-Json
    try {
        $res = Invoke-RestMethod -Uri "$api/auth/register" -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
        return $res.data.token
    } catch {
        Write-Host "  [FAIL] Registration failed: $_" -ForegroundColor Red
        $script:failCount++
        return $null
    }
}

function Add-Money {
    param($Token, $Amount)
    $headers = @{ Authorization = "Bearer $Token" }
    $body = @{ amount = $Amount } | ConvertTo-Json
    try {
        $res = Invoke-RestMethod -Uri "$api/wallet/add" -Method Post -Body $body -ContentType "application/json" -Headers $headers -ErrorAction Stop
        return $res
    } catch {
        return $null
    }
}

function Send-Money {
    param($Token, $Receiver, $Amount, $Pin)
    $headers = @{ Authorization = "Bearer $Token" }
    $body = @{ receiverUpiId = $Receiver; amount = $Amount; description = "Test payment"; upiPin = $Pin } | ConvertTo-Json
    try {
        $res = Invoke-RestMethod -Uri "$api/payments/transfer" -Method Post -Body $body -ContentType "application/json" -Headers $headers -ErrorAction Stop
        return $res
    } catch {
        return $null
    }
}

function Set-Pin {
    param($Token, $Pin)
    $headers = @{ Authorization = "Bearer $Token" }
    $body = @{ upiPin = $Pin } | ConvertTo-Json
    try {
        $res = Invoke-RestMethod -Uri "$api/users/set-pin" -Method Post -Body $body -ContentType "application/json" -Headers $headers -ErrorAction Stop
        return $res
    } catch {
        return $null
    }
}

function Verify-Pin {
    param($Token, $Pin)
    $headers = @{ Authorization = "Bearer $Token" }
    $body = @{ upiPin = $Pin } | ConvertTo-Json
    try {
        $res = Invoke-RestMethod -Uri "$api/users/verify-pin" -Method Post -Body $body -ContentType "application/json" -Headers $headers -ErrorAction Stop
        return $res
    } catch {
        return $null
    }
}

# Create a receiver user that we'll use across all tests
Write-Host "`n=== Creating receiver user ===" -ForegroundColor Cyan
$receiverToken = Register-User -Name "Receiver User" -Email "receiver_test_$(Get-Random -Maximum 99999)@test.com" -Phone "90000$(Get-Random -Maximum 99999)" -Password "password123"
if ($receiverToken) {
    $headers = @{ Authorization = "Bearer $receiverToken" }
    $receiverProfile = Invoke-RestMethod -Uri "$api/users/me" -Headers $headers
    $receiverUpiId = $receiverProfile.data.upiId
    Add-Money -Token $receiverToken -Amount 50000
    Write-Host "Receiver UPI ID: $receiverUpiId" -ForegroundColor Cyan
} else {
    Write-Host "Failed to create receiver user" -ForegroundColor Red
    exit 1
}

# ===== RUN 7 TESTS =====
for ($run = 1; $run -le 7; $run++) {
    Write-Host "`n========================================" -ForegroundColor Magenta
    Write-Host "  TEST RUN #$run" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Magenta

    $testEmail = "test_user_$(Get-Random -Maximum 999999)@test.com"
    $testPhone = "70000$(Get-Random -Maximum 99999)"
    $testPin = "1234"
    $wrongPin = "9999"

    Write-Host "`n[Step 1] Register user: $testEmail" -ForegroundColor Yellow
    $token = Register-User -Name "Test User $run" -Email "$testEmail" -Phone "$testPhone" -Password "password123"
    Test-Result -Condition ($token -ne $null) -Message "User registration returned token"

    if (-not $token) { continue }

    # Add money to user wallet
    Add-Money -Token $token -Amount 10000
    Write-Host "  [INFO] Added ₹10000 to wallet" -ForegroundColor Gray

    Write-Host "`n[Step 2] Send money WITHOUT setting PIN (should fail)" -ForegroundColor Yellow
    $result = Send-Money -Token $token -Receiver $receiverUpiId -Amount 100 -Pin "1234"
    $failed = $result -eq $null -or $result.success -eq $false
    Test-Result -Condition $failed -Message "Transfer fails because PIN not set"
    if ($result -eq $null) { Write-Host "  (expected error: PIN not set)" -ForegroundColor Gray }

    Write-Host "`n[Step 3] Set UPI PIN to '$testPin'" -ForegroundColor Yellow
    $result = Set-Pin -Token $token -Pin $testPin
    Test-Result -Condition ($result -ne $null -and $result.success) -Message "PIN set successfully"

    Write-Host "`n[Step 4] Verify with WRONG PIN (should fail)" -ForegroundColor Yellow
    $result = Verify-Pin -Token $token -Pin $wrongPin
    $failed = $result -eq $null -or $result.success -eq $false
    Test-Result -Condition $failed -Message "Wrong PIN correctly rejected"
    if ($result -eq $null) { Write-Host "  (expected error: Invalid PIN)" -ForegroundColor Gray }

    Write-Host "`n[Step 5] Verify with CORRECT PIN (should succeed)" -ForegroundColor Yellow
    $result = Verify-Pin -Token $token -Pin $testPin
    Test-Result -Condition ($result -ne $null -and $result.success) -Message "Correct PIN verified successfully"

    Write-Host "`n[Step 6] Send money with WRONG PIN (should fail)" -ForegroundColor Yellow
    $result = Send-Money -Token $token -Receiver $receiverUpiId -Amount 100 -Pin $wrongPin
    $failed = $result -eq $null -or $result.success -eq $false
    Test-Result -Condition $failed -Message "Transfer with wrong PIN correctly rejected"
    if ($result -eq $null) { Write-Host "  (expected error: Invalid PIN)" -ForegroundColor Gray }

    Write-Host "`n[Step 7] Send money with CORRECT PIN (should succeed)" -ForegroundColor Yellow
    $result = Send-Money -Token $token -Receiver $receiverUpiId -Amount 100 -Pin $testPin
    Test-Result -Condition ($result -ne $null -and $result.success) -Message "Transfer with correct PIN succeeded"
    if ($result -ne $null -and $result.success) {
        Write-Host "  Reference ID: $($result.data.referenceId)" -ForegroundColor Gray
    }

    Write-Host "`n--- Run #$run complete ---" -ForegroundColor Green
}

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  TEST SUMMARY" -ForegroundColor Cyan
Write-Host "  Passed: $passCount" -ForegroundColor Green
Write-Host "  Failed: $failCount" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Magenta
