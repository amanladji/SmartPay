$api = "http://localhost:8765/api"
$passCount = 0
$failCount = 0

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

function Call-Api {
    param($Method, $Uri, $Body, $Token)
    $headers = @{ "Content-Type" = "application/json" }
    if ($Token) { $headers["Authorization"] = "Bearer $Token" }
    $params = @{ Method = $Method; Uri = $Uri; Headers = $headers; ContentType = "application/json" }
    if ($Body) { $params["Body"] = ($Body | ConvertTo-Json) }
    try {
        $res = Invoke-RestMethod @params -ErrorAction Stop
        return $res
    } catch {
        return $null
    }
}

for ($run = 1; $run -le 7; $run++) {
    Write-Host "`n========================================" -ForegroundColor Magenta
    Write-Host "  JWT REFRESH TEST RUN #$run" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Magenta

    $testEmail = "refresh_test_$(Get-Random -Maximum 999999)@test.com"
    $testPhone = "80000$(Get-Random -Maximum 99999)"

    Write-Host "`n[Step 1] Register user" -ForegroundColor Yellow
    $res = Call-Api -Method Post -Uri "$api/auth/register" -Body @{ name = "Refresh Test $run"; email = $testEmail; phone = $testPhone; password = "password123" }
    Test-Result -Condition ($res -ne $null -and $res.success) -Message "Registration succeeded"
    $accessToken = $res.data.token
    $refreshToken = $res.data.refreshToken
    Test-Result -Condition ($accessToken -ne $null) -Message "Access token received"
    Test-Result -Condition ($refreshToken -ne $null) -Message "Refresh token received"

    Write-Host "`n[Step 2] Verify access token works" -ForegroundColor Yellow
    $res2 = Call-Api -Method Get -Uri "$api/users/me" -Token $accessToken
    Test-Result -Condition ($res2 -ne $null -and $res2.success) -Message "Access token is valid for API calls"
    $emailFromProfile = $res2.data.email
    Test-Result -Condition ($emailFromProfile -eq $testEmail) -Message "Profile email matches"

    Write-Host "`n[Step 3] Refresh with valid refresh token" -ForegroundColor Yellow
    $res3 = Call-Api -Method Post -Uri "$api/auth/refresh" -Body @{ refreshToken = $refreshToken }
    Test-Result -Condition ($res3 -ne $null -and $res3.success) -Message "Token refresh succeeded"
    $newAccessToken = $res3.data.token
    $newRefreshToken = $res3.data.refreshToken
    Test-Result -Condition ($newAccessToken -ne $null -and $newAccessToken -ne $accessToken) -Message "New access token is different from old"
    Test-Result -Condition ($newRefreshToken -ne $null) -Message "New refresh token received"

    Write-Host "`n[Step 4] Verify new access token works" -ForegroundColor Yellow
    $res4 = Call-Api -Method Get -Uri "$api/users/me" -Token $newAccessToken
    Test-Result -Condition ($res4 -ne $null -and $res4.success) -Message "New access token is valid"

    Write-Host "`n[Step 5] Try using OLD refresh token (should fail - revoked)" -ForegroundColor Yellow
    $res = Call-Api -Method Post -Uri "$api/auth/refresh" -Body @{ refreshToken = $refreshToken }
    Test-Result -Condition ($res -eq $null) -Message "Old refresh token correctly rejected (revoked)"

    Write-Host "`n[Step 6] Try using INVALID refresh token (should fail)" -ForegroundColor Yellow
    $res = Call-Api -Method Post -Uri "$api/auth/refresh" -Body @{ refreshToken = "totally_invalid_token_12345" }
    Test-Result -Condition ($res -eq $null) -Message "Invalid refresh token correctly rejected"

    Write-Host "`n[Step 7] Try using EXPIRED-LIKE garbage refresh token (should fail)" -ForegroundColor Yellow
    $res = Call-Api -Method Post -Uri "$api/auth/refresh" -Body @{ refreshToken = "" }
    Test-Result -Condition ($res -eq $null) -Message "Empty refresh token correctly rejected"

    Write-Host "`n--- Run #$run complete ---" -ForegroundColor Green
}

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  JWT REFRESH TEST SUMMARY" -ForegroundColor Cyan
Write-Host "  Passed: $passCount" -ForegroundColor Green
Write-Host "  Failed: $failCount" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Magenta
