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
  source_archive_object = google_storage_bucket_object.source_archive.name
  available_memory_mb   = 256
  environment_variables = {
    FIRESTORE_PROJECT = "gcp-resume-challenge-083124"
  }
  service_account_email = "cloud-storage-service@gcp-resume-challenge-083124.iam.gserviceaccount.com"

  event_trigger {
    event_type = "google.cloud.storage.object.v1.finalized"
    resource   = google_storage_bucket.resume_bucket.name
  }
}

# Create firestore db
resource "google_firestore_database" "(default)" {
  project     = "gcp-resume-challenge-083124"
  name        = (default)
  location_id = us-central1
  type        = FIRESTORE_NATIVE
}

# Firestore document (automatically creates the collection if not already created)
# resource "google_firestore_document" "resume_document" {
#  project     = "gcp-resume-challenge-083124"
#  database    = google_firestore_database.default_db.id
#  collection  = "resumes" # This is where the collection "resumes" is created
#  document_id = "resume"  # Document ID for your resume data
#  fields = {
#   title = {
#      string_value = "Resume Data"
#   }
#    // Add other fields as required from your resume.json file
#  }
# }