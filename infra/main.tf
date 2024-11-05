terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3.5"
    }
  }
  required_version = ">= 0.12"
}

provider "google" {
  project = "gcp-resume-challenge-083124"
  region  = "us-east4"
}

# Cloud Storage bucket for resume.json
resource "google_storage_bucket" "resume_bucket" {
  name     = "gcp-resume-bucket-083124"
  location = "us-central1"
}

# Cloud Function to update Firestore when resume.json is modified in Cloud Storage
resource "google_cloudfunctions_function" "update_firestore_function" {
  name                  = "update_resume_firestore"
  runtime               = "python39"
  entry_point           = "upload_to_firestore"  # Your main function to update Firestore

  source_archive_bucket = google_storage_bucket.resume_bucket.name
  source_archive_object = "source.zip"  # Archive containing the function code

  trigger_event         = "google.storage.object.finalize"  # Trigger on file creation or modification
  trigger_resource      = google_storage_bucket.resume_bucket.name  # Your bucket

  available_memory_mb   = 256

  environment_variables = {
    FIRESTORE_PROJECT = "gcp-resume-challenge-083124"
    BUCKET_NAME       = google_storage_bucket.resume_bucket.name
  }

  service_account_email = "cloud-storage-service@gcp-resume-challenge-083124.iam.gserviceaccount.com"
}

# IAM Permissions for the Cloud Function service account to access Storage and Firestore
resource "google_project_iam_member" "cloud_function_storage_access" {
  project = "gcp-resume-challenge-083124"
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:cloud-storage-service@gcp-resume-challenge-083124.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "cloud_function_firestore_access" {
  project = "gcp-resume-challenge-083124"
  role    = "roles/datastore.user"
  member  = "serviceAccount:cloud-storage-service@gcp-resume-challenge-083124.iam.gserviceaccount.com"
}