provider "google" {
  project = "gcp-resume-challenge-083124"
  region  = "us-east4"
}

# Cloud Storage bucket for resume.json
resource "google_storage_bucket" "resume_bucket" {
  name     = "gcp-resume-bucket-083124"
  location = "us-central1"
}

# Cloud Function to retrieve resume data from Firestore (HTTP-triggered)
resource "google_cloudfunctions_function" "resume_function" {
  name                  = "get_resume"
  runtime               = "python39"
  entry_point           = "get_resume"  # Function to return data from Firestore

  source_archive_bucket = google_storage_bucket.resume_bucket.name
  source_archive_object = "source.zip"   # This will be updated by Cloud Build

  trigger_http          = true
  available_memory_mb   = 256

  environment_variables = {
    FIRESTORE_PROJECT = "gcp-resume-challenge-083124"
  }

  service_account_email = "gcp-resume-challenge-083124@appspot.gserviceaccount.com"
}

# Cloud Function to update Firestore when resume.json is modified in Cloud Storage
resource "google_cloudfunctions_function" "update_firestore_function" {
  name                  = "update_resume_firestore"
  runtime               = "python39"
  entry_point           = "upload_to_firestore"  # Function to process the file and update Firestore

  source_archive_bucket = google_storage_bucket.resume_bucket.name
  source_archive_object = "source.zip"   # This will be updated by Cloud Build

  available_memory_mb = 256

  environment_variables = {
    FIRESTORE_PROJECT = "gcp-resume-challenge-083124"
  }

  service_account_email = "cloud-storage-service@gcp-resume-challenge-083124.iam.gserviceaccount.com"

  # Directly trigger this function on changes in the Cloud Storage bucket
  event_trigger {
    event_type = "google.storage.object.finalize"
    resource   = google_storage_bucket.resume_bucket.name
  }
}