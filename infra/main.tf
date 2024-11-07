provider "google" {
  project = "gcp-resume-challenge-083124"
  region  = "us-east4"
}

# Cloud Storage bucket for resume.json
resource "google_storage_bucket" "resume_bucket" {
  name     = "gcp-resume-bucket-083124"
  location = "us-central1"
}

# Pub/Sub topic for Cloud Storage updates
resource "google_pubsub_topic" "update_resume_topic" {
  name     = "update-resume-topic"
  project  = "gcp-resume-challenge-083124"
  location = "us-central1"
}

# Pub/Sub subscription for Cloud Function trigger
resource "google_pubsub_subscription" "update_resume_subscription" {
  name  = "update-resume-subscription"
  topic = google_pubsub_topic.update_resume_topic.name
  project = "gcp-resume-challenge-083124"
  ack_deadline_seconds = 20
}

# Cloud Function to retrieve resume data from Firestore (HTTP-triggered)
resource "google_cloudfunctions_function" "resume_function" {
  name                  = "get_resume"
  runtime               = "python39"
  entry_point           = "get_resume"
  source_archive_bucket = google_storage_bucket.resume_bucket.name
  source_archive_object = "source.zip"
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
  entry_point           = "upload_to_firestore"
  source_archive_bucket = google_storage_bucket.resume_bucket.name
  source_archive_object = "source.zip"
  available_memory_mb = 256
  environment_variables = {
    FIRESTORE_PROJECT = "gcp-resume-challenge-083124"
  }
  service_account_email = "cloud-storage-service@gcp-resume-challenge-083124.iam.gserviceaccount.com"
  
  event_trigger {
    event_type = "google.cloud.pubsub.topic.v1.messagePublished"
    resource   = google_pubsub_topic.update_resume_topic.name
  }
}

# Cloud Storage notification to Pub/Sub topic
resource "google_storage_notification" "resume_notification" {
  bucket         = google_storage_bucket.resume_bucket.name
  payload_format = "JSON_API_V1"
  topic          = google_pubsub_topic.update_resume_topic.name
  event_types    = ["OBJECT_FINALIZE", "OBJECT_UPDATE"]
}