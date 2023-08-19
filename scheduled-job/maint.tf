#TODO 
locals {
  billing_account = "123456-123456-123456"
  project_prefix = "scheduled-job"
  project_name = "project-06"
  location = "us-central1"

}
## Create a project 
module "project" {
  source          = "git::github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/project"
  name            = local.project_name
  billing_account = local.billing_account
  prefix          = local.project_prefix
  project_create = true
  # If you useing as an organization you need to provide a parent folder for the project.
  # parent          = "folders/1234567890"
  services = [
    "cloudbuild.googleapis.com",
    "serviceusage.googleapis.com",
    "run.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudscheduler.googleapis.com",
    "compute.googleapis.com",
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
  location = local.location
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
  location   = local.location
  format = {docker = {}}
  name       = "${module.project.project_id}-artifact"
  depends_on = [ 
    module.gcs
   ]
}

## Create resource local_file Dockerfile
resource "local_file" "dockerfile" {
  content = "FROM python:3.9-slim \nWORKDIR /app \nCOPY ./requirements.txt requirements.txt \nCOPY ./script.py script.py \nRUN pip install -r requirements.txt"
  filename = "./Dockerfile"
}

## Create resource local_file requirements
resource "local_file" "requirements" {
  content = "requests==2.31.0 \ngoogle-auth==2.20.0"
  filename = "./requirements.txt"
}

# ## Create resource local_file Copy Script
# resource "local_file" "copy-script" {
#   content_base64 = filebase64("./script.py") #${path.module}
#   filename = "${path.cwd}/script.py"
# }

## Create null resource docker_build Build Image
resource "null_resource" "docker_build" {
  provisioner "local-exec" {
    command = <<EOT
    gcloud config set project ${module.project.project_id}
    gcloud builds submit --tag ${local.location}-docker.pkg.dev/${module.project.project_id}/${module.docker_artifact_registry.name}/python-slim:latest
    EOT
  }
  depends_on = [ 
    module.docker_artifact_registry
   ]
}

## Create Google Cloud run JOB
resource "google_cloud_run_v2_job" "default" {
  project = module.project.project_id
  name     = "${module.project.project_id}cloudrun-job"
  location = local.location

  template {
    template {
      containers {
        image = "${local.location}-docker.pkg.dev/${module.project.project_id}/${module.docker_artifact_registry.name}/python-slim:latest"
        command = ["python3", "script.py"]
      }
      service_account = module.service-account.email
    }
  }
  lifecycle {
      ignore_changes = [
        launch_stage,
      ]
    }
  depends_on = [
    resource.null_resource.docker_build,
    module.docker_artifact_registry
  ]
}

## Create Google Cloud Scheduler - cron job