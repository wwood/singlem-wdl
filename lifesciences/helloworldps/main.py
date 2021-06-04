import os
import base64
from pprint import pprint
from google.oauth2 import service_account
from googleapiclient import discovery

from flask import Flask
from flask import request

app = Flask(__name__)


@app.route("/")
def hello_world():
    service_account_file = '/etc/credentials/credentials.json'
    scopes = ['https://www.googleapis.com/auth/cloud-platform']
    credentials = service_account.Credentials.from_service_account_file(
        service_account_file, scopes=scopes)
    service = discovery.build('lifesciences', 'v2beta', credentials=credentials)

    # The name of the operation's parent resource.
    name = 'projects/maximal-dynamo-308105/locations/us-central1'  # TODO: Update placeholder value.

    request = service.projects().locations().operations().list(name=name)
    
    ops = ""
    while True:
        response = request.execute()

        for operation in response.get('operations', []):
            # TODO: Change code below to process each `operation` resource:
            ops+=str(operation)

        request = service.projects().locations().operations().list_next(previous_request=request, previous_response=response)
        if request is None:
            break
    return ops

@app.route("/")
def hello():
    return hello_world()


@app.route("/", methods=["POST"])
def index():
    envelope = request.get_json()
    if not envelope:
        msg = "no Pub/Sub message received"
        print(f"error: {msg}")
        return f"Bad Request: {msg}", 400

    if not isinstance(envelope, dict) or "message" not in envelope:
        msg = "invalid Pub/Sub message format"
        print(f"error: {msg}")
        return f"Bad Request: {msg}", 400

    pubsub_message = envelope["message"]

    name = "World"
    if isinstance(pubsub_message, dict) and "data" in pubsub_message:
        name = base64.b64decode(pubsub_message["data"]).decode("utf-8").strip()

    print(f"Hello {name}!")

    return ("", 204)


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
