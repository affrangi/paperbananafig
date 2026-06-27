#!/usr/bin/env bash
# One-time Google Cloud setup for keyless GitHub Actions -> Cloud Run deploys
# via Workload Identity Federation (WIF).
#
# Edit PROJECT_ID and REPO, then run:  bash gcp-wif-setup.sh
# At the end it prints the two values to add as GitHub repo secrets:
#   GCP_WIF_PROVIDER, GCP_SERVICE_ACCOUNT
set -euo pipefail

PROJECT_ID="YOUR_PROJECT_ID"          # <-- edit
REPO="affrangi/paperbananafig"        # <-- owner/repo, must match exactly
SA_NAME="gh-deployer"
POOL="github-pool"
PROVIDER="github-provider"

PROJECT_NUMBER="$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
RUNTIME_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

echo ">> Enabling APIs..."
gcloud services enable run.googleapis.com cloudbuild.googleapis.com \
  artifactregistry.googleapis.com secretmanager.googleapis.com \
  iamcredentials.googleapis.com --project "$PROJECT_ID"

echo ">> Creating deployer service account (ignore error if it exists)..."
gcloud iam service-accounts create "$SA_NAME" --project "$PROJECT_ID" \
  --display-name "GitHub Actions Cloud Run deployer" || true

echo ">> Granting deployer roles..."
for ROLE in roles/run.admin roles/cloudbuild.builds.editor \
            roles/artifactregistry.writer roles/storage.admin \
            roles/iam.serviceAccountUser; do
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member "serviceAccount:${SA_EMAIL}" --role "$ROLE" --condition=None >/dev/null
done

echo ">> Granting the Cloud Run runtime SA access to the secrets..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member "serviceAccount:${RUNTIME_SA}" \
  --role roles/secretmanager.secretAccessor --condition=None >/dev/null

echo ">> Creating Workload Identity pool + provider (ignore errors if they exist)..."
gcloud iam workload-identity-pools create "$POOL" \
  --project "$PROJECT_ID" --location global --display-name "GitHub pool" || true

gcloud iam workload-identity-pools providers create-oidc "$PROVIDER" \
  --project "$PROJECT_ID" --location global \
  --workload-identity-pool "$POOL" \
  --display-name "GitHub provider" \
  --attribute-mapping "google.subject=assertion.sub,attribute.repository=assertion.repository" \
  --attribute-condition "assertion.repository=='${REPO}'" \
  --issuer-uri "https://token.actions.githubusercontent.com" || true

WIF_POOL_ID="$(gcloud iam workload-identity-pools describe "$POOL" \
  --project "$PROJECT_ID" --location global --format='value(name)')"

echo ">> Allowing the repo to impersonate the deployer SA..."
gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
  --project "$PROJECT_ID" \
  --role roles/iam.workloadIdentityUser \
  --member "principalSet://iam.googleapis.com/${WIF_POOL_ID}/attribute.repository/${REPO}" >/dev/null

WIF_PROVIDER="$(gcloud iam workload-identity-pools providers describe "$PROVIDER" \
  --project "$PROJECT_ID" --location global \
  --workload-identity-pool "$POOL" --format='value(name)')"

cat <<INNER

============================================================
Add these as GitHub repo secrets
(Settings -> Secrets and variables -> Actions -> New secret):

  GCP_WIF_PROVIDER    = ${WIF_PROVIDER}
  GCP_SERVICE_ACCOUNT = ${SA_EMAIL}
============================================================
INNER
