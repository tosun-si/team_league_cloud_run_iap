#!/usr/bin/env bash

set -e
set -o pipefail
set -u

terraform init \
  -backend-config="bucket=${TF_STATE_BUCKET}" \
  -backend-config="prefix=${TF_STATE_PREFIX}/team_league_cloud_run_iap"
