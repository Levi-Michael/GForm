#TODO 

## Create a project 
module "project" {
  source          = "git::github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/project"
  name            = "project-03"
  billing_account = "123456-123456-123456"
  prefix          = "scheduled-job"
  project_create = true
  # If you useing as an organization you need to provide a parent folder for the project.
  # parent          = "folders/1234567890"
  services = [
    "cloudbuild.googleapis.com",
    "serviceusage.googleapis.com",
    "run.googleapis.com",
    "cloudresourcemanger.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudscheduler.googleapis.com",
    "compute.googleapis.com"
  ]
}

## Create Service account
module "service-account" {
  source     = "git::github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/iam-service-account"
  project_id = module.project.project_id
  name       = "${module.project.project_id}-sa"
  generate_key = false
  service_account_create = true
  # non-authoritative roles granted *to* the service accounts on other resources
  iam_project_roles = {
    "${module.project.project_id}" = [
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
      "roles/run.invoker",
      "roles/serviceusage.serviceUsageAdmin"
    ]
  }
}

## Folders permissions ?

## Create Google cloud storage
module "gcs" {
  source     = "git::github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/gcs"
  project_id = module.project.project_id
  name       = "${module.project.project_id}_cloudbuild"
  versioning = true
  location = "me-west1"
  storage_class = "REGIONAL"
  force_destroy = true

  labels = {
    tag = "scheduled-job"
  }
}

## Create Docker artifact registry
module "docker_artifact_registry" {
  source     = "git::github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/artifact-registry"
  project_id = module.project.project_id
  location   = "me-west1"
  format = {docker = {}}
  name       = "${module.project.project_id}-artifact"
  iam = {
    "roles/artifactregistry.admin" = ["ServiceAccount:${module.service-account.email}"]
  }
}

## Create resource local_file Dockerfile
resource "local_file" "dockerfile" {
  content = "FROM python:3.9-slim \nWORKDIR  /app \nCOPY requirements.txt requirements.txt \nCOPY ./script.py script.py \nRUN pip install -r requirements.txt"
  filename = "./Dockerfile"
}

## Create resource local_file requirements
resource "local_file" "requirements" {
  content = "requests==2.31.0 \ngoogle-auth==2.20.0"
  filename = "./requirements.txt"
}

## Create resource local_file Copy Script
## Create null resource docker_build Build Image
## Create Google Cloud run JOB
## Create Google Cloud Scheduler - cron job