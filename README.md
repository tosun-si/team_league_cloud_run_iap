# teams-league-cloudrun-service-fastapi

Project showing a complete use and secure a Cloud Run service with IAP.

## Enable IAP

```bash
gcloud beta services identity create --service=iap.googleapis.com --project=$PROJECT_ID
```

```bash
gcloud run services add-iam-policy-binding $SERVICE_NAME \
    --region=$LOCATION \
    --member="serviceAccount:service-975119474255@gcp-sa-iap.iam.gserviceaccount.com" \
    --role="roles/run.invoker"
```

### Grant the invoker permission to the service account

```bash
gcloud run services add-iam-policy-binding $SERVICE_NAME \
    --region=$LOCATION \
    --member="serviceAccount:service-975119474255@gcp-sa-iap.iam.gserviceaccount.com" \
    --role="roles/run.invoker"
```

```bash
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="group:gcp-group-test@groupbees.fr" \
    --role="roles/iap.httpsResourceAccessor"
```

## Deploy the Cloud Run service in a secure way

```bash
gcloud run deploy "$SERVICE_NAME" \
  --image "$LOCATION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME:$IMAGE_TAG" \
  --region="$LOCATION" \
  --no-allow-unauthenticated \
  --set-env-vars PROJECT_ID="$PROJECT_ID" \
  --set-env-vars OUTPUT_DATASET="$OUTPUT_DATASET" \
  --set-env-vars OUTPUT_TABLE="$OUTPUT_TABLE" \
  --set-env-vars INPUT_BUCKET="$INPUT_BUCKET" \
  --set-env-vars INPUT_OBJECT="$INPUT_OBJECT"
```

## Create a backend service for cloud run 

Create Health check for the service

```bash
gcloud compute health-checks create http cloud-run-health-check \
    --port 80 \
    --request-path /healthz
```

```bash
gcloud compute backend-services create cloud-run-backend \
    --global \
    --protocol=HTTP \
    --enable-cdn \
    --health-checks=cloud-run-health-check
```

URL map

```bash
gcloud compute url-maps create cloud-run-url-map \
    --default-service cloud-run-backend
```

Target HTTP proxy

```bash
gcloud compute target-http-proxies create cloud-run-target-proxy \
    --url-map=cloud-run-url-map
```

Create forwarding rule

```bash
gcloud compute forwarding-rules create cloud-run-forwarding-rule \
    --global \
    --target-http-proxy=cloud-run-target-proxy \
    --ports=80
```

Enable IAP for the backend service

```bash
gcloud compute backend-services update cloud-run-backend \
    --global \
    --iap=enabled \
    --no-enable-cdn
```


IAP is automatically available for Cloud Run. To restrict access to a specific Google Group, configure access control in IAP.

Identify the IAP Resource for Your Cloud Run Service: Get the IAP client ID for your service

```bash
gcloud run services describe $SERVICE_NAME --region $LOCATION \
    --format "value(status.url)"
```

## Grant Roles to the Google Group for IAP

Grant Roles to the Google Group: Assign the roles/iap.httpsResourceAccessor role to the Google Group to allow access via IAP:

```bash
gcloud iap web add-iam-policy-binding \
    --resource=https://teams-league-service-iap-4wtmsxga6q-ew.a.run.app \
    --member=group:gcp-group-test@groupbees.fr \
    --role=roles/iap.httpsResourceAccessor
```

### Grant the Cloud Run Invoker role (roles/run.invoker) to the Google Group

```bash
gcloud run services add-iam-policy-binding SERVICE_NAME \
    --region $LOCATION \
    --member=group:gcp-group-test@groupbees.fr \
    --role=roles/run.invoker
```

```bash
gcloud builds submit \
    --project=$PROJECT_ID \
    --region=$LOCATION \
    --config terraform-apply-modules.yaml \
    --substitutions _TF_STATE_BUCKET=$TF_STATE_BUCKET,_TF_STATE_PREFIX=$TF_STATE_PREFIX,_REPO_NAME=$REPO_NAME,_IMAGE_NAME=$IMAGE_NAME,_IMAGE_TAG=$IMAGE_TAG,_SERVICE_NAME=$SERVICE_NAME \
    --verbosity="debug" .
```