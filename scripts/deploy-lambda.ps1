# PowerShell script to deploy Lambda function code
# Run this after terraform apply to deploy the actual application code

$ErrorActionPreference = "Stop"

Write-Host "🚀 Deploying Lambda function code..." -ForegroundColor Cyan
Write-Host ""

# Check if terraform directory exists
if (-not (Test-Path "terraform")) {
    Write-Host "❌ Error: terraform directory not found." -ForegroundColor Red
    Write-Host "Please run this script from the project root directory."
    exit 1
}

# Check if node_modules exists
if (-not (Test-Path "node_modules")) {
    Write-Host "📦 Installing Node.js dependencies..." -ForegroundColor Yellow
    npm install
    Write-Host ""
}

# Create deployment package
Write-Host "📦 Creating deployment package..." -ForegroundColor Yellow
if (Test-Path "lambda.zip") {
    Remove-Item "lambda.zip"
}

# Determine what to include in package
$itemsToZip = @("src/", "package.json")
if (Test-Path "package-lock.json") {
    $itemsToZip += "package-lock.json"
}
if (Test-Path "node_modules") {
    $itemsToZip += "node_modules/"
}

# Try to use system zip command (from Git for Windows or 7zip)
if (Get-Command "zip" -ErrorAction SilentlyContinue) {
    Write-Host "Using zip command..." -ForegroundColor Gray
    $zipArgs = $itemsToZip -join " "
    Invoke-Expression "zip -r lambda.zip $zipArgs" 2>&1 | Out-Null
} elseif (Get-Command "7z" -ErrorAction SilentlyContinue) {
    Write-Host "Using 7-Zip..." -ForegroundColor Gray
    $7zArgs = $itemsToZip -join " "
    Invoke-Expression "7z a -tzip lambda.zip $7zArgs" 2>&1 | Out-Null
} else {
    Write-Host "⚠️  Using PowerShell Compress-Archive (slower)..." -ForegroundColor Yellow
    # Create temp directory and copy files
    $tempDir = "temp_lambda_package"
    if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir }
    New-Item -ItemType Directory -Path $tempDir | Out-Null

    foreach ($item in $itemsToZip) {
        $source = $item.TrimEnd('/')
        if (Test-Path $source) {
            if (Test-Path $source -PathType Container) {
                Copy-Item -Recurse $source "$tempDir/$source"
            } else {
                Copy-Item $source "$tempDir/"
            }
        }
    }

    Compress-Archive -Path "$tempDir/*" -DestinationPath lambda.zip -Force
    Remove-Item -Recurse -Force $tempDir
}

$zipSize = (Get-Item "lambda.zip").Length / 1MB
Write-Host "✓ Package created: $([math]::Round($zipSize, 2)) MB" -ForegroundColor Green
Write-Host ""

# Get function name from Terraform
Write-Host "🔍 Getting Lambda function name from Terraform..." -ForegroundColor Yellow
Push-Location terraform

try {
    $functionName = terraform output -raw lambda_function_name 2>$null

    if (-not $functionName) {
        Write-Host "❌ Error: Could not get Lambda function name from Terraform." -ForegroundColor Red
        Write-Host "Make sure you've run 'terraform apply' first."
        Pop-Location
        exit 1
    }

    Write-Host "✓ Function name: $functionName" -ForegroundColor Green
    Write-Host ""

    # Get AWS region from Terraform
    $awsRegion = terraform output -raw aws_region 2>$null
    if (-not $awsRegion) {
        $awsRegion = "us-east-1"
    }
}
finally {
    Pop-Location
}

# Deploy to Lambda
Write-Host "🚀 Updating Lambda function code..." -ForegroundColor Cyan
aws lambda update-function-code `
    --function-name $functionName `
    --zip-file fileb://lambda.zip `
    --region $awsRegion `
    --no-cli-pager

Write-Host ""
Write-Host "⏳ Waiting for function update to complete..." -ForegroundColor Yellow
aws lambda wait function-updated `
    --function-name $functionName `
    --region $awsRegion

Write-Host ""
Write-Host "✅ Lambda function deployed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Open your frontend URL (from terraform output s3_website_url)"
Write-Host "2. Enter your API Gateway URL in the frontend"
Write-Host "3. Test the vulnerable endpoints"
Write-Host ""
Write-Host "To get your URLs:" -ForegroundColor Yellow
Write-Host "  cd terraform" -ForegroundColor White
Write-Host "  terraform output" -ForegroundColor White
