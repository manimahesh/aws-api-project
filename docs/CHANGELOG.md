# Changelog

## Support for Existing OIDC Providers

### What Changed

The Terraform configuration now supports reusing existing GitHub OIDC providers instead of always creating a new one.

### New Features

1. **Conditional OIDC Provider Creation**
   - Terraform will only create a GitHub OIDC provider if `use_existing_oidc_provider = false`
   - Can reuse existing OIDC provider by setting `use_existing_oidc_provider = true`

2. **Helper Scripts**
   - `scripts/check-oidc-provider.sh` - Bash script to detect existing OIDC providers
   - `scripts/check-oidc-provider.ps1` - PowerShell script for Windows users

3. **New Terraform Variables**
   - `use_existing_oidc_provider` - Boolean to control OIDC provider creation
   - `existing_oidc_provider_arn` - ARN of existing OIDC provider to use

4. **Enhanced Documentation**
   - [OIDC-CONFIGURATION.md](OIDC-CONFIGURATION.md) - Comprehensive OIDC setup guide
   - [QUICK-START.md](../QUICK-START.md) - Simplified quick start guide
   - Updated [README.md](../README.md) with quick links and OIDC check step

### Files Modified

- `terraform/github_oidc.tf` - Conditional OIDC provider creation
- `terraform/variables.tf` - Added new variables
- `terraform/terraform.tfvars.example` - Added example configuration
- `README.md` - Added OIDC check step and quick links

### Files Added

- `scripts/check-oidc-provider.sh` - Bash helper script
- `scripts/check-oidc-provider.ps1` - PowerShell helper script
- `docs/OIDC-CONFIGURATION.md` - Detailed OIDC guide
- `QUICK-START.md` - Quick start guide
- `.gitattributes` - Git line ending configuration
- `docs/CHANGELOG.md` - This file

### Why This Matters

AWS accounts can only have **one** OIDC provider per URL. If you already use GitHub Actions with OIDC in your AWS account, the previous configuration would fail with an `EntityAlreadyExists` error.

Now you can:
- ✅ Share one OIDC provider across multiple projects
- ✅ Avoid deployment failures from duplicate providers
- ✅ Easily detect and reuse existing providers

### Migration Guide

If you already deployed this project before these changes:

1. **Check if you have an OIDC provider:**
   ```bash
   bash scripts/check-oidc-provider.sh
   ```

2. **Update your `terraform.tfvars`:**
   ```hcl
   use_existing_oidc_provider = true
   existing_oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
   ```

3. **Run Terraform:**
   ```bash
   terraform init
   terraform apply
   ```

### Breaking Changes

None. The default behavior remains unchanged:
- `use_existing_oidc_provider = false` (creates new OIDC provider)

Existing deployments will continue to work without modifications.

### Compatibility

- Terraform >= 1.0
- AWS Provider >= 5.0
- Works with existing and new AWS accounts
- Compatible with all previous configurations

---

**Date:** 2025-11-18
**Version:** 1.1.0
