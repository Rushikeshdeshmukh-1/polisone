# PolisOne Firebase Auto-Population Script
Write-Host "🚀 Populating Firebase with test data..." -ForegroundColor Green

$apiKey = "AIzaSyB79GgEg75pEGfMsntcspInkIKKIevcUtA"

# Create users
$users = @(
    @{email="admin@polisone.com"; password="Admin@123"},
    @{email="officer1@polisone.com"; password="Officer@123"},
    @{email="officer2@polisone.com"; password="Officer@123"},
    @{email="officer3@polisone.com"; password="Officer@123"}
)

Write-Host "`n📧 Creating users..." -ForegroundColor Cyan
foreach ($user in $users) {
    try {
        $body = @{
            email = $user.email
            password = $user.password
            returnSecureToken = $true
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey" -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
        Write-Host "✅ Created: $($user.email)" -ForegroundColor Green
    } catch {
        if ($_.Exception.Message -like "*EMAIL_EXISTS*") {
            Write-Host "⚠️  Already exists: $($user.email)" -ForegroundColor Yellow
        } else {
            Write-Host "❌ Error: $($user.email) - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host "`n✅ Users created successfully!" -ForegroundColor Green
Write-Host "`n📝 Next: Add officers in Firestore" -ForegroundColor Cyan
Write-Host "   Go to: https://console.firebase.google.com/project/polisone-b1179/firestore" -ForegroundColor Gray
Write-Host "   Or use the manual guide in populate_test_data.md" -ForegroundColor Gray
Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
