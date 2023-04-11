
# Deploying a Containerised Flask Application in GCP

This project demonstrates how to deploy a containerised flask application to GCP. 

The solution involves the following:
1. Infrastructure-as-Code (Terraform) to provision the GCP infrastructure.
2. Cloud Build pipeline to build a Docker image, push it to the GCP registry and deploy to Cloud Run. 

The cloud run service will be exposed via an External HTTPS Load Balancer to enable us to route traffic via the VPC network and utilise additional GCP services like Cloud CDN and Cloud Armor.

## Pre-requisites
1. A GCP project with billing enabled
2. Terraform CLI (https://developer.hashicorp.com/terraform/downloads)
3. gcloud CLI (https://cloud.google.com/sdk/docs/install). Configure with `gcloud init` and `gcloud auth application-default login`
4. A registered domain for provisioning SSL certificates
5. Update the `terraform.tfvars` file with your own configuration

## How to provision the infrastructure
1. Go to the terraform directory
2. Run `terraform init` to initialise the working directory
3. Provision the GCP resources using `terraform fmt/validate/plan/apply`
4. Once terraform completes, it will output the public IP address of the load balancer. Setup an `A record` on your DNS service for the domain in the tfvars file and this IP address. In a production environment this should be handled by Terraform on Cloud DNS or similar. 
5. Certificate provisioning may take up to an hour to complete. Monitor this in [Certificate Manager](https://cloud.google.com/certificate-manager/docs/overview)

## How to build and deploy the Flask application
1. Go to the app directory 
2. Go to IAM and grant the Cloud Build Service Account `Cloud Run Admin` and `Service Account User` roles.
3. Run the following: 
`gcloud builds submit --config cloudbuild.yaml --substitutions=REPO_NAME="flask-app-test",_REGION="australia-southeast1"`. This triggers the pipeline as defined in `cloudbuild.yaml`.

## Shutting down the infrastructure
1. Go to the sample-static-website-gcp/terraform directory
2. Run `terraform destroy` and review the resources before proceeding.
