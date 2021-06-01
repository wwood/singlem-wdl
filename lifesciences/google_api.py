from pprint import pprint
from google.oauth2 import service_account
from googleapiclient import discovery

service_account_file = '/home/mitchac/credentials.json'
scopes = ['https://www.googleapis.com/auth/cloud-platform']
credentials = service_account.Credentials.from_service_account_file(
        service_account_file, scopes=scopes)
service = discovery.build('lifesciences', 'v2beta', credentials=credentials)

# The name of the operation's parent resource.
name = 'projects/maximal-dynamo-308105/locations/us-central1'  # TODO: Update placeholder value.

request = service.projects().locations().operations().list(name=name)
while True:
    response = request.execute()

    for operation in response.get('operations', []):
        # TODO: Change code below to process each `operation` resource:
        pprint(operation)

    request = service.projects().locations().operations().list_next(previous_request=request, previous_response=response)
    if request is None:
        break
