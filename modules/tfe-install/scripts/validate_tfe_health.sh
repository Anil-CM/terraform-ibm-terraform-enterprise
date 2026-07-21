#!/bin/bash
# Validates that a Terraform Enterprise deployment is healthy by probing
# its documented health endpoints:
#   /api/v1/health/readiness  - pod readiness (returns 200 when all replicas ready)
#   /api/v2/ping              - API reachability  (returns {"status":"ok"})
#   /api/v2/organizations     - authenticated API (returns valid JSON org list)
#
# Usage: validate_tfe_health.sh <TFE_HOSTNAME> <API_TOKEN>
# Exits 0 on success, 1 on failure.
# Emits a single JSON object to stdout for the Terraform `external` data source:
#   {"status": "healthy"} on success

set -e

TFE_HOSTNAME=$1
API_TOKEN=$2

LOGFILE="/tmp/tfe_health_check.log"
echo "=== TFE health check started at $(date) ===" >> "$LOGFILE"

if [ -z "$TFE_HOSTNAME" ] || [ -z "$API_TOKEN" ]; then
  echo "Usage: $0 <TFE_HOSTNAME> <API_TOKEN>" >&2
  exit 1
fi

MAX_RETRIES=20
RETRY_INTERVAL=15

##############################################################################
# Helper: probe an endpoint, return HTTP status code
##############################################################################
probe() {
  local url=$1
  local extra_args=${2:-}
  curl -sk -o /dev/null -w "%{http_code}" --max-time 10 $extra_args "$url"
}

##############################################################################
# 1. Readiness endpoint — waits until the deployment is fully ready
##############################################################################
echo "Checking /api/v1/health/readiness ..." >> "$LOGFILE"
ATTEMPT=1
while [ $ATTEMPT -le $MAX_RETRIES ]; do
  CODE=$(probe "https://${TFE_HOSTNAME}/api/v1/health/readiness")
  echo "  attempt $ATTEMPT: HTTP $CODE" >> "$LOGFILE"
  if [ "$CODE" = "200" ]; then
    echo "  readiness OK" >> "$LOGFILE"
    break
  fi
  if [ $ATTEMPT -eq $MAX_RETRIES ]; then
    echo "  ERROR: readiness endpoint not healthy after $MAX_RETRIES attempts (last HTTP $CODE)" >> "$LOGFILE"
    >&2 echo "ERROR: TFE readiness endpoint returned HTTP $CODE after $MAX_RETRIES attempts."
    exit 1
  fi
  sleep $RETRY_INTERVAL
  ATTEMPT=$((ATTEMPT + 1))
done

##############################################################################
# 2. API ping endpoint — confirms the API layer is reachable
##############################################################################
echo "Checking /api/v2/ping ..." >> "$LOGFILE"
CODE=$(probe "https://${TFE_HOSTNAME}/api/v2/ping")
echo "  HTTP $CODE" >> "$LOGFILE"
if [ "$CODE" != "204" ] && [ "$CODE" != "200" ]; then
  echo "  ERROR: ping endpoint returned HTTP $CODE" >> "$LOGFILE"
  >&2 echo "ERROR: TFE API ping endpoint returned unexpected HTTP $CODE."
  exit 1
fi
echo "  ping OK" >> "$LOGFILE"

##############################################################################
# 3. Authenticated organizations endpoint — confirms token and API are working
##############################################################################
echo "Checking /api/v2/organizations ..." >> "$LOGFILE"
CODE=$(probe "https://${TFE_HOSTNAME}/api/v2/organizations" \
  "-H 'Authorization: Bearer ${API_TOKEN}' -H 'Content-Type: application/vnd.api+json'")
echo "  HTTP $CODE" >> "$LOGFILE"
if [ "$CODE" != "200" ]; then
  echo "  ERROR: organizations endpoint returned HTTP $CODE" >> "$LOGFILE"
  >&2 echo "ERROR: TFE authenticated API returned unexpected HTTP $CODE."
  exit 1
fi
echo "  organizations OK" >> "$LOGFILE"

echo "=== TFE health check passed at $(date) ===" >> "$LOGFILE"
echo '{"status": "healthy"}'
