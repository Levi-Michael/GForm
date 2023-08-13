#TODO 

## Create a project 
module "project" {
  source          = "git::github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/project"
  billing_account = "123456-123456-123456"
  name            = "project-03"
  prefix          = "scheduled-job"
  # If you useing as an organization you need to provide a parent folder for the project.
  # parent          = "folders/1234567890"
  services = [
    "cloudapis.googleapis.com",
    "iam.googleapis.com",
    "storage-api.googleapis.com"
  ]
}

## Create Service account
module "service-account" {
  source     = "git::github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/iam-service-account"
  project_id = module.project.project_id
  name       = "scheduled-job-sa"
  service_account_create = true
  # non-authoritative roles granted *to* the service accounts on other resources
  iam_project_roles = {
    "${module.project.project_id}" = [
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
      "roles/storage.admin"
    ]
  }
}

## Folders permissions ?

## Create Google cloud storage
module "gcs" {
  source     = "git::github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/gcs"
  project_id = module.project.project_id
  prefix     = "scheduled-job"
  name       = "bucket"
  versioning = true

  labels = {
    tag = "scheduled-job"
  }
}

## Create Docker artifact registry
## Create resource local_file Dockerfile
## Create resource local_file Copy Script
## Create null resource docker_build Build Image
## Create Google Cloud run JOB
## Create Google Cloud Scheduler - cron job