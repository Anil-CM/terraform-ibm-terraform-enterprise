# TFE Installation Module Changes

## Version 2.0.0 Upgrade (2026-05-13)

### Changes Made
- **Helm Chart Version**: Updated from 1.6.3 to 1.6.8
- **TFE Version**: Updated from v202504-1 to v202406-1 (Terraform Enterprise 2.0.0)
- **App Version**: Updated from v202506-1 to v202406-1

### TFE 2.0.0 Release Information
- **Release Date**: 2026-04-21
- **Terraform CLI Version**: 1.14.4
- **Supported Kubernetes Versions**: 1.35, 1.34, 1.33
- **Container Digest**:
  - amd64/linux: sha256:80802683e65385fce80dd3e1ec6d992888773f2d6549b185fe2d357a5bc55d51
  - arm64/linux: sha256:ae52dab862eef58b0f4182da736ceac9809bd30e44f5d2b1f1c960058f29bdf6

### Breaking Changes in TFE 2.0.0
🔴 **Supervisord Removed**: Terraform Enterprise 2.0.0 has removed supervisord from the container architecture. This represents a significant architectural change in how TFE manages its internal processes. Any custom scripts or configurations that relied on supervisord will need to be updated.

### Known Issues with TFE 2.0.0
⚠️ **Important**: Starting in Terraform Enterprise 2.0.0, policy evaluations may not complete correctly in some cases, which can cause runs to become stuck. This issue primarily affects workspaces with a large number of configured policies.

**Recommendation**: If you are running a version prior to 2.0.0 and using policies, do not upgrade to 2.0.x until this issue is resolved. A support knowledge base article is available with additional details and guidance.

**Workaround**: You can disable policy checks and evaluations in affected workspaces as a temporary workaround.

### Bug Fixes in 2.0.0
1. Fixed issue where Terraform Stacks runs would fail when Terraform Enterprise was deployed on Kubernetes or OpenShift
2. Database monitoring now correctly refreshes connections after restart in some TFE components (mainly operator admin UI/API)
3. Task worker check now correctly returns DRAINING status instead of ERROR during node drain

---

## Previous Changes

## Overview
This document describes the changes made to fix TFE deployment issues on OpenShift/Kubernetes, specifically addressing file permission errors in the custom startup script.

## Changes Made

### 1. Updated Custom Startup Script
**File:** `scripts/custom_tfe_start.sh`

**Issue:** The script was attempting to modify `/etc/nginx/nginx.conf.tmpl` using `sed -i`, which failed with "Permission denied" because:
- The `/etc/nginx/` directory is read-only in the TFE container
- Even with `anyuid` SCC and running as root, the filesystem remains immutable

**Solution:** Removed the nginx configuration modification from the startup script. The script now only modifies `/app/config/database.yml` which is in a writable location.

**Modified Lines:**
- Removed: `sed -i 's/server_names_hash_bucket_size 128;/server_names_hash_bucket_size 256;/' /etc/nginx/nginx.conf.tmpl`
- Added comments explaining why the modification was removed and alternative approaches

### 2. Updated Helm Chart Deployment Template
**File:** `chart/tfe/templates/deployment.yaml`

**Changes:**
- Added volume definition for the custom startup script ConfigMap (after line 100)
- Added volumeMount for the scripts directory (after line 221)
- Changed `runAsNonRoot: true` to `runAsNonRoot: false` for OpenShift deployments (line 134)

### 3. Updated Helm Values
**File:** `chart/tfe/values.yaml`

**Changes:**
- Set `container.command` to `["/bin/sh"]`
- Set `container.args` to `["-c", "/scripts/custom_tfe_start.sh"]`

### 4. Created ConfigMap Template
**File:** `chart/tfe/templates/custom-script-configmap.yaml` (NEW)

**Purpose:** Creates a Kubernetes ConfigMap containing the custom startup script, making it available to the TFE pods.

## Nginx Configuration Workaround

Since the nginx `server_names_hash_bucket_size` modification cannot be done at runtime, use one of these alternatives if needed:

### Option A: Custom TFE Image (Recommended)
Build a custom TFE image with the nginx configuration pre-modified:

```dockerfile
FROM images.releases.hashicorp.com/hashicorp/terraform-enterprise:v202406-1
RUN sed -i 's/server_names_hash_bucket_size 128;/server_names_hash_bucket_size 256;/' /etc/nginx/nginx.conf.tmpl
```

Then update the Helm values to use your custom image:
```yaml
image:
  repository: your-registry.com
  name: your-org/terraform-enterprise-custom
  tag: v202406-1
```

### Option B: Environment Variable
Check TFE documentation for environment variables that control nginx configuration. If available, add to `values.yaml`:
```yaml
env:
  variables:
    TFE_NGINX_SERVER_NAMES_HASH_BUCKET_SIZE: "256"
```

### Option C: Volume Mount
Mount a custom nginx configuration file:
```yaml
extraVolumes:
  - name: nginx-config
    configMap:
      name: custom-nginx-config
extraVolumeMounts:
  - name: nginx-config
    mountPath: /etc/nginx/nginx.conf.tmpl
    subPath: nginx.conf.tmpl
```

## Testing

After applying these changes:

1. Deploy TFE using the updated Helm chart
2. Verify pods start successfully without CrashLoopBackOff
3. Check logs for database connection and schema search path
4. Confirm TFE application becomes ready and accessible

## Database Schema Configuration

The startup script still modifies `/app/config/database.yml` to add:
```yaml
schema_search_path: "public,ibm_extension"
```

This is essential for TFE to access IBM Cloud PostgreSQL extensions and remains functional in the updated script.

## Rollback

If issues occur, revert to the original startup script and use one of the nginx workarounds listed above.