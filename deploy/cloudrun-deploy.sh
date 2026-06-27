#!/usr/bin/env bash
# Deploy the remote paperbanana MCP server to Google Cloud Run.
#
# Prereqs (run once):
#   gcloud auth login
#   gcloud config set project YOUR_PROJECT_ID
#   gcloud services enable run.googleapis.com cloudbuild.googleapis.com \
#       artifactregistry.googleapis.com secretmanager.googleapis.com
#
# Create the API-key secrets (run once):
#   printf '%s' "sk-..."   | gcloud secrets create openai-key  --data-file=-
#   printf '%s' "AIza..."  | gcloud secrets create google-key  --data-file=-
#
# Then run this script from the directory that contains the Dockerfile.
set -euo pipefail

SERVICE="${SERVICE:-paperbanana-mcp}"
REGION="${REGION:-europe-west1}"

gcloud run deploy "$SERVICE" \
  --source . \
  --region "$REGION" \
  --port 8080 \
  --timeout 3600 \
  --min-instances 1 \
  --max-instances 3 \
  --cpu 2 \
  --memory 2Gi \
  --no-cpu-throttling \
  --set-secrets "OPENAI_API_KEY=openai-key:latest,GOOGLE_API_KEY=google-key:latest" \
  --no-allow-unauthenticated

echo
echo "Deployed. Service URL:"
gcloud run services describe "$SERVICE" --region "$REGION" --format='value(status.url)'
echo
echo "The MCP endpoint is <URL>/mcp (Streamable HTTP)."
