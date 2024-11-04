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

# Pub/Sub topic for Eventarc to use as an intermediary
resource "google_pubsub_topic" "resume_update_topic" {
  name = "resume-update-topic"
}

# Cloud Function to update Firestore when resume.json is modified in Cloud Storage, using Eventarc
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
}

# Eventarc trigger to connect Cloud Storage bucket events to the Cloud Function
resource "google_eventarc_trigger" "resume_update_eventarc_trigger" {
  name     = "resume-update-eventarc-trigger"
  location = "us-central1"
  
  # Eventarc trigger for Cloud Storage object finalization (i.e., when an object is uploaded or changed)
  event_filters {
    attribute = "type"
    value     = "google.cloud.storage.object.v1.finalized"
  }

  event_filters {
    attribute = "bucket"
    value     = google_storage_bucket.resume_bucket.name
  }

  transport {
    pubsub_topic = google_pubsub_topic.resume_update_topic.id
  }

  destination {
    cloud_function = google_cloudfunctions_function.update_firestore_function.id
  }
}

# IAM Permissions for the Eventarc service account to access Pub/Sub
resource "google_project_iam_member" "eventarc_pubsub_publisher" {
  project = "gcp-resume-challenge-083124"
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-772953776671@gcp-sa-eventarc.iam.gserviceaccount.com"  # Eventarc service account
}

