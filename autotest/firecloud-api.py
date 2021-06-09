import os
import requests

token = os.popen('gcloud auth --account=terra-api@maximal-dynamo-308105.iam.gserviceaccount.com print-access-token').read().rstrip()
head = {'accept': 'application/json','Authorization': 'Bearer {}'.format(token)}
myUrl = 'https://api.firecloud.org/me?userDetailsOnly=false'
response = requests.get(myUrl, headers=head)
print(response.json())

