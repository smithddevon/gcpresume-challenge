import json
from flask import jsonify
from google.cloud import firestore, storage

# Initialize Firestore and Cloud Storage clients
db = firestore.Client()
storage_client = storage.Client()


def update_firestore(event, context):
    """Triggered by a change to a Cloud Storage bucket.
    Updates Firestore with the content of resume.json.
    """
    try:
        # Get bucket and file information from the event
        bucket_name = event['bucket']
        file_name = event['name']
        
        # Get the Cloud Storage bucket and blob
        bucket = storage_client.bucket(bucket_name)
        blob = bucket.blob(file_name)
        
        # Download the JSON data from Cloud Storage
        json_data = blob.download_as_text()
        data = json.loads(json_data)
        
        # Update Firestore with the data from the JSON file
        doc_ref = db.collection('resumes').document('1')  # Use the desired document ID
        doc_ref.set(data)
    except Exception as e:
        print(f"Error updating Firestore: {e}")

def get_resume(request):
    """Retrieves the resume data from Firestore and returns it as a JSON response."""
    try:
        # Get the resume data from Firestore
        resume_data = db.collection('resumes').document('1').get().to_dict()
        if resume_data is None:
            return jsonify({'error': 'Resume not found'}), 404
        return jsonify(resume_data), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500