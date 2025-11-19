# PowerShell script to check if GitHub OIDC provider already exists in AWS account

Write-Host "Checking for existing GitHub OIDC provider..." -ForegroundColor Cyan
Write-Host ""

try {
    # List all OIDC providers
    $providers = aws iam list-open-id-connect-providers --query 'OpenIDConnectProviderList[*].Arn' --output json | ConvertFrom-Json

    if ($null -eq $providers -or $providers.Count -eq 0) {
        Write-Host "No OIDC providers found in your AWS account." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "You can proceed with the default configuration:"
        Write-Host "  use_existing_oidc_provider = false"
        exit 0
    }

    # Check for GitHub OIDC provider
    $githubProvider = $providers | Where-Object { $_ -like "*token.actions.githubusercontent.com*" }

    if ($githubProvider) {
        Write-Host "✓ GitHub OIDC provider found!" -ForegroundColor Green
        Write-Host ""
        Write-Host "ARN: $githubProvider" -ForegroundColor White
        Write-Host ""
        Write-Host "Update your terraform.tfvars with:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "use_existing_oidc_provider = true" -ForegroundColor Cyan
        Write-Host "existing_oidc_provider_arn = `"$githubProvider`"" -ForegroundColor Cyan
        Write-Host ""

        # Get provider details
        Write-Host "Provider details:" -ForegroundColor Yellow
        aws iam get-open-id-connect-provider --open-id-connect-provider-arn "$githubProvider"
    }
    else {
        Write-Host "No GitHub OIDC provider found." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Found these OIDC providers:" -ForegroundColor Yellow
        $providers | ForEach-Object { Write-Host "  $_" }
        Write-Host ""
        Write-Host "You can proceed with the default configuration:"
        Write-Host "  use_existing_oidc_provider = false"
    }
}
catch {
    Write-Host "Error checking OIDC providers: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Make sure AWS CLI is configured with valid credentials."
    exit 1
}
