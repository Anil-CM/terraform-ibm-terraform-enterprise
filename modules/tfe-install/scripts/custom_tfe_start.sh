#!/bin/bash
set -e

# Modify database.yml to add IBM extension schema
sed -i '/^[ ]\{2\}pool:/a\ \ schema_search_path: "public,ibm_extension"' /app/config/database.yml

# Skip nginx modification - /etc/nginx/ is read-only in the container
# The nginx server_names_hash_bucket_size modification should be handled via:
# - Custom TFE image build, OR
# - TFE environment variable (if available), OR
# - Volume mount of custom nginx config

# TFE 2.0.0+ uses a different startup mechanism (supervisord removed)
# Start TFE application directly
if [ -f /usr/local/bin/supervisord-run ]; then
    # Pre-2.0.0 versions use supervisord
    /usr/local/bin/supervisord-run
else
    # TFE 2.0.0+ - start the application directly
    # The container's default entrypoint will handle process management
    exec /usr/local/bin/terraform-enterprise
fi

set +e
