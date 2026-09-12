$api = "http://localhost:8765/api"
$passCount = 0
$failCount = 0

function Test-Result {
    param($Condition, $Message)
    if ($Condition) { Write-Host "  [PASS] $Message" -ForegroundColor Green; $script:passCount++ }
    else { Write-Host "  [FAIL] $Message" -ForegroundColor Red; $script:failCount++ }
}

function Invoke-Api {
    param($Method="GET", $Uri, $Body, $Headers=@{}, $QueryParams=@{})
    $params = @{ Method = $Method; Uri = $Uri; ContentType = "application/json"; Headers = $Headers; TimeoutSec = 30 }
    if ($Body) { $params.Body = ($Body | ConvertTo-Json -Depth 5) }
    if ($QueryParams.Count -gt 0) {
        $query = ($QueryParams.GetEnumerator() | ForEach-Object { "$($_.Key)=$([Uri]::EscapeDataString($_.Value))" }) -join "&"
        $params.Uri = "$Uri`?$query"
    }
    Invoke-RestMethod @params -ErrorAction Stop
}

function Invoke-ApiSafe {
    param($Method="GET", $Uri, $Body, $Headers=@{}, $QueryParams=@{})
    $params = @{ Method = $Method; Uri = $Uri; ContentType = "application/json"; Headers = $Headers; TimeoutSec = 30 }
    if ($Body) { $params.Body = ($Body | ConvertTo-Json -Depth 5) }
    if ($QueryParams.Count -gt 0) {
        $query = ($QueryParams.GetEnumerator() | ForEach-Object { "$($_.Key)=$([Uri]::EscapeDataString($_.Value))" }) -join "&"
        $params.Uri = "$Uri`?$query"
    }
    try { return ,@(Invoke-RestMethod @params -ErrorAction Stop) } catch { return $null }
}

Write-Host "Warming up..." -ForegroundColor Cyan
$null = Invoke-Api -Uri "$api/health"

for ($run = 1; $run -le 3; $run++) {
    Write-Host "`n${"="*50}" -ForegroundColor Magenta
    Write-Host "  COMPREHENSIVE E2E TEST RUN #$run" -ForegroundColor Yellow
    Write-Host "${"="*50}" -ForegroundColor Magenta

    $email1 = "e2e_${run}_$(Get-Random -Maximum 99999)@test.com"
    $phone1 = "9{0:d9}" -f (Get-Random -Maximum 999999999)
    $email2 = "e2e_${run}_$(Get-Random -Maximum 99999)@test.com"
    $phone2 = "9{0:d9}" -f (Get-Random -Maximum 999999999)
    $deviceId = "trusted_$run"
    $upiPin = "1234"

    Write-Host "`n[USER1: $email1]" -ForegroundColor Green
    Write-Host "[USER2: $email2]" -ForegroundColor Green

    # ===== 1. REGISTER USER 1 =====
    Write-Host "`n--- 1. REGISTER ---" -ForegroundColor Cyan
    $r = Invoke-Api -Method Post -Uri "$api/auth/register" -Body @{ name="Alice $run"; email=$email1; phone=$phone1; password="password123" }
    Test-Result ($r.success) "Registration successful"
    Test-Result ($r.data.token.Length -gt 20) "Access token returned"
    $token1 = $r.data.token
    $headers1 = @{ Authorization = "Bearer $token1" }
    $upiId1 = ($r.message -split " ")[-1]
    Test-Result ($upiId1 -match "@smartpay") "UPI ID auto-generated"

    # ===== 2. LOGIN + TRUST DEVICE (for later trusted-device test) =====
    Write-Host "`n--- 2. LOGIN & TRUST DEVICE ---" -ForegroundColor Cyan
    $r = Invoke-Api -Method Post -Uri "$api/auth/login" -Body @{ email=$email1; password="password123"; deviceId=$deviceId; deviceName="Trusted $run" }
    Test-Result ($r.data.requiresOtp) "New device requires OTP"
    $r = Invoke-Api -Method Post -Uri "$api/auth/verify-otp" -Body @{ email=$email1; otp=$r.data.otp; deviceId=$deviceId; deviceName="Trusted $run" }
    Test-Result ($r.success) "Device trusted"
    $token1 = $r.data.token
    $headers1 = @{ Authorization = "Bearer $token1" }

    # ===== 3. PROFILE =====
    Write-Host "`n--- 3. PROFILE ---" -ForegroundColor Cyan
    $r = Invoke-Api -Uri "$api/users/me" -Headers $headers1
    Test-Result ($r.data.email -eq $email1) "Email matches"
    Test-Result ($r.data.pinSet -eq $false) "PIN not set initially"
    Test-Result ($r.data.upiId -eq $upiId1) "UPI ID correct"

    # ===== 4. WALLET =====
    Write-Host "`n--- 4. WALLET ---" -ForegroundColor Cyan
    $r = Invoke-Api -Uri "$api/wallet/balance" -Headers $headers1
    Test-Result ($r.data.balance -eq 0) "Initial balance is 0"
    Test-Result ($r.data.upiId -eq $upiId1) "UPI ID matches wallet"

    # ===== 5. ADD MONEY =====
    Write-Host "`n--- 5. ADD MONEY ---" -ForegroundColor Cyan
    $r = Invoke-Api -Method Post -Uri "$api/wallet/add" -Body @{ amount=5000 } -Headers $headers1
    Test-Result ($r.success) "Balance added"
    Test-Result ($r.data.balance -eq 5000) "New balance: 5000"

    # ===== 6. SET UPI PIN =====
    Write-Host "`n--- 6. SET PIN ---" -ForegroundColor Cyan
    $r = Invoke-Api -Method Post -Uri "$api/users/set-pin" -Body @{ upiPin=$upiPin } -Headers $headers1
    Test-Result ($r.success) "UPI PIN set"

    # ===== 7. PROFILE (after PIN) =====
    $r = Invoke-Api -Uri "$api/users/me" -Headers $headers1
    Test-Result ($r.data.pinSet) "PIN set true in profile"

    # ===== 8. VERIFY PIN =====
    Write-Host "`n--- 7. VERIFY PIN ---" -ForegroundColor Cyan
    $r = Invoke-Api -Method Post -Uri "$api/users/verify-pin" -Body @{ upiPin=$upiPin } -Headers $headers1
    Test-Result ($r.success) "Correct PIN verified"

    # ===== 9. REGISTER USER 2 =====
    Write-Host "`n--- 8. USER 2 ---" -ForegroundColor Cyan
    $r = Invoke-Api -Method Post -Uri "$api/auth/register" -Body @{ name="Bob $run"; email=$email2; phone=$phone2; password="password123" }
    Test-Result ($r.success) "User 2 registered"
    $upiId2 = ($r.message -split " ")[-1]
    $token2 = $r.data.token
    $headers2 = @{ Authorization = "Bearer $token2" }
    Invoke-Api -Method Post -Uri "$api/wallet/add" -Body @{ amount=3000 } -Headers $headers2 | Out-Null

    # ===== 10. SEND MONEY =====
    Write-Host "`n--- 9. SEND MONEY ---" -ForegroundColor Cyan
    $r = Invoke-Api -Method Post -Uri "$api/payments/transfer" -Body @{ receiverUpiId=$upiId2; amount=1500; upiPin=$upiPin } -Headers $headers1
    Test-Result ($r.success) "Transfer completed"
    Test-Result ($r.data.amount -eq 1500) "Amount: 1500"
    Test-Result ($r.data.status -eq "SUCCESS") "Status: SUCCESS"

    # ===== 11. BALANCES =====
    Write-Host "`n--- 10. BALANCES ---" -ForegroundColor Cyan
    $r = Invoke-Api -Uri "$api/wallet/balance" -Headers $headers1
    Test-Result ($r.data.balance -eq 3500) "Sender: 3500 (5000-1500)"
    $r = Invoke-Api -Uri "$api/wallet/balance" -Headers $headers2
    Test-Result ($r.data.balance -eq 4500) "Receiver: 4500 (3000+1500)"

    # ===== 12. TRANSACTION HISTORY =====
    Write-Host "`n--- 11. TRANSACTION HISTORY ---" -ForegroundColor Cyan
    $r = Invoke-Api -Uri "$api/transactions" -Headers $headers1
    Test-Result ($r.data.content.Count -ge 1) "Sender has transaction entries"
    Test-Result ($r.data.totalElements -eq 1) "Sender sees exactly 1 transaction (DEBIT)"
    Test-Result ($r.data.content[0].type -eq "DEBIT") "Sender transaction is DEBIT"
    Test-Result ($r.data.content[0].amount -eq 1500) "Sender amount is 1500"

    $r = Invoke-Api -Uri "$api/transactions" -Headers $headers2
    Test-Result ($r.data.content.Count -ge 1) "Receiver has transaction entries"
    Test-Result ($r.data.totalElements -eq 1) "Receiver sees exactly 1 transaction (CREDIT)"
    Test-Result ($r.data.content[0].type -eq "CREDIT") "Receiver transaction is CREDIT"
    Test-Result ($r.data.content[0].amount -eq 1500) "Receiver amount is 1500"

    # ===== 13. STATS =====
    Write-Host "`n--- 12. STATS ---" -ForegroundColor Cyan
    $r = Invoke-Api -Uri "$api/transactions/stats" -Headers $headers1
    Test-Result ($r.data.totalSent -eq 1500) "totalSent: 1500"
    Test-Result ($r.data.sentCount -eq 1) "sentCount: 1"
    Test-Result ($r.data.totalReceived -eq 0) "totalReceived: 0"
    Test-Result ($r.data.receivedCount -eq 0) "receivedCount: 0"
    $r = Invoke-Api -Uri "$api/transactions/stats" -Headers $headers2
    Test-Result ($r.data.totalSent -eq 0) "totalSent: 0"
    Test-Result ($r.data.sentCount -eq 0) "sentCount: 0"
    Test-Result ($r.data.totalReceived -eq 1500) "totalReceived: 1500"
    Test-Result ($r.data.receivedCount -eq 1) "receivedCount: 1"

    # ===== 14. QR GENERATION =====
    Write-Host "`n--- 13. QR GENERATION ---" -ForegroundColor Cyan
    $r = Invoke-Api -Method GET -Uri "$api/payments/qr" -QueryParams @{ upiId=$upiId1; amount=500 } -Headers $headers1
    Test-Result ($r.data.qrPayload -match "upi://pay") "QR starts with upi://pay"
    Test-Result ($r.data.qrPayload -match [regex]::Escape($upiId1)) "QR contains sender UPI"
    Test-Result ($r.data.qrPayload -match "am=500") "QR contains amount 500"

    # ===== 15. QR PAYMENT =====
    Write-Host "`n--- 14. QR PAYMENT ---" -ForegroundColor Cyan
    $r = Invoke-Api -Method Post -Uri "$api/payments/qr/pay" -Body @{ receiverUpiId=$upiId2; amount=500; upiPin=$upiPin } -Headers $headers1
    Test-Result ($r.success) "QR payment completed"
    Test-Result ($r.data.amount -eq 500) "QR amount correct"

    $r = Invoke-Api -Uri "$api/wallet/balance" -Headers $headers1
    Test-Result ($r.data.balance -eq 3000) "Balance after QR: 3000 (3500-500)"

    # ===== 15. REFRESH TOKEN =====
    Write-Host "`n--- 15. REFRESH TOKEN ---" -ForegroundColor Cyan

    # Get a fresh token pair from login
    $r = Invoke-Api -Method Post -Uri "$api/auth/login" -Body @{ email=$email1; password="password123"; deviceId=$deviceId; deviceName="Trusted $run" }
    $loginToken = $r.data.token
    $loginRefresh = $r.data.refreshToken
    Test-Result ($loginToken.Length -gt 20) "Re-login gives access token"
    Test-Result ($loginRefresh.Length -gt 20) "Re-login gives refresh token"

    # Refresh to get new tokens
    $r = Invoke-Api -Method Post -Uri "$api/auth/refresh" -Body @{ refreshToken=$loginRefresh }
    Test-Result ($r.success) "Token refreshed"
    $newToken = $r.data.token
    $newRefreshToken = $r.data.refreshToken
    Test-Result ($newToken.Length -gt 20) "New access token valid"
    Test-Result ($newRefreshToken.Length -gt 20) "New refresh token valid"

    # Use the extracted variable, not $r.data again
    $refreshedHeaders = @{ Authorization = "Bearer $newToken" }
    $r2 = Invoke-Api -Uri "$api/users/me" -Headers $refreshedHeaders
    Test-Result ($r2.data.email -eq $email1) "New token functional"

    # ===== 16. TRUSTED DEVICE LOGIN (no OTP) =====
    Write-Host "`n--- 16. TRUSTED DEVICE LOGIN ---" -ForegroundColor Cyan
    $r = Invoke-Api -Method Post -Uri "$api/auth/login" -Body @{ email=$email1; password="password123"; deviceId=$deviceId; deviceName="Trusted $run" }
    Test-Result (-not $r.data.requiresOtp) "Trusted device: no OTP required"
    Test-Result ($r.data.token.Length -gt 20) "Token returned directly"

    # ===== 18. UNTRUSTED DEVICE LOGIN =====
    Write-Host "`n--- 17. UNTRUSTED DEVICE LOGIN ---" -ForegroundColor Cyan
    $newDevId = "newdev_${run}_$(Get-Random -Maximum 999)"
    $r = Invoke-Api -Method Post -Uri "$api/auth/login" -Body @{ email=$email1; password="password123"; deviceId=$newDevId; deviceName="New Device $run" }
    Test-Result ($r.data.requiresOtp) "New device requires OTP"
    Test-Result ($r.data.otp.Length -ge 6) "OTP returned"

    $r = Invoke-Api -Method Post -Uri "$api/auth/verify-otp" -Body @{ email=$email1; otp=$r.data.otp; deviceId=$newDevId; deviceName="New Device $run" }
    Test-Result ($r.success) "New device now trusted"

    # ===== 19. SESSION MANAGEMENT =====
    Write-Host "`n--- 18. SESSION MANAGEMENT ---" -ForegroundColor Cyan
    $r = Invoke-Api -Uri "$api/users/sessions" -Headers $headers1
    $sessionCount = $r.data.Count
    Test-Result ($sessionCount -ge 2) "At least 2 sessions (got $sessionCount)"

    # Revoke new device
    $r = Invoke-Api -Method Delete -Uri "$api/users/sessions/$newDevId" -Headers $headers1
    Test-Result ($r.success) "Session revoked"

    # Verify count decreased
    $r = Invoke-Api -Uri "$api/users/sessions" -Headers $headers1
    Test-Result ($r.data.Count -eq ($sessionCount - 1)) "Count decreased to $($r.data.Count)"

    # ===== 20. PIN RATE LIMITING =====
    Write-Host "`n--- 19. PIN RATE LIMITING ---" -ForegroundColor Cyan
    $rateLimited = $false
    for ($i = 1; $i -le 6; $i++) {
        try {
            Invoke-Api -Method Post -Uri "$api/users/verify-pin" -Body @{ upiPin="9999" } -Headers $headers1
        } catch {
            if ($_.Exception.Response.StatusCode.value__ -eq 400) {
                $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
                $body = $reader.ReadToEnd()
                $reader.Close()
                if ($body -match "Too many") { $rateLimited = $true; break }
            }
        }
    }
    Test-Result ($rateLimited) "Rate limiting engaged after wrong PINs"

    # ===== 21. REVOKE ALL SESSIONS =====
    Write-Host "`n--- 20. REVOKE ALL SESSIONS ---" -ForegroundColor Cyan
    $r = Invoke-Api -Method Delete -Uri "$api/users/sessions" -Headers $refreshedHeaders
    Test-Result ($r.success) "All sessions revoked"

    $r = Invoke-Api -Uri "$api/users/sessions" -Headers $refreshedHeaders
    Test-Result ($r.data.Count -eq 0) "No sessions remain"

    # ===== 22. INVALID OPERATIONS =====
    Write-Host "`n--- 21. INVALID OPERATIONS ---" -ForegroundColor Cyan

    # Self transfer
    try { Invoke-Api -Method Post -Uri "$api/payments/transfer" -Body @{ receiverUpiId=$upiId1; amount=100; upiPin=$upiPin } -Headers $headers1; Test-Result $false "Self-transfer should fail" }
    catch { Test-Result $true "Self-transfer rejected" }

    # Insufficient balance
    try { Invoke-Api -Method Post -Uri "$api/payments/transfer" -Body @{ receiverUpiId=$upiId2; amount=999999; upiPin=$upiPin } -Headers $headers1; Test-Result $false "Overdraft should fail" }
    catch { Test-Result $true "Insufficient balance rejected" }

    # Wrong PIN
    try { Invoke-Api -Method Post -Uri "$api/payments/transfer" -Body @{ receiverUpiId=$upiId2; amount=100; upiPin="1111" } -Headers $headers1; Test-Result $false "Wrong PIN should fail" }
    catch { Test-Result $true "Wrong PIN rejected" }

    # Wrong password
    try { Invoke-Api -Method Post -Uri "$api/auth/login" -Body @{ email=$email1; password="wrong!" }; Test-Result $false "Wrong password should fail" }
    catch { Test-Result $true "Wrong password rejected" }

    Write-Host "`n--- Run #$run done ---" -ForegroundColor Green
}

Write-Host "`n${"="*50}" -ForegroundColor Magenta
Write-Host "  E2E TEST SUMMARY" -ForegroundColor Cyan
Write-Host "  PASSED: $passCount  FAILED: $failCount" -ForegroundColor Green
Write-Host "${"="*50}" -ForegroundColor Magenta
