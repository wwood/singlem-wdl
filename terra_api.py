import os
import requests
import json
from requests_toolbelt.multipart.encoder import MultipartEncoder

def prepare_header():
    token = os.popen('gcloud auth --account=terra-api@maximal-dynamo-308105.iam.gserviceaccount.com print-access-token').read().rstrip()
    head = {'accept': '*/*',"Content-Type": "application/json", 'Authorization': 'Bearer {}'.format(token)}
    return head
    

def submit_workflow(workspaceNamespace, workspaceName, submissionEntityType, submissionEntityName, submissionExpression):
    data={
      "methodConfigurationNamespace": "singlem",
      "methodConfigurationName": "singlem-single-task",
      "entityType": submissionEntityType,
      "entityName": submissionEntityName,
      "expression": submissionExpression,
      "useCallCache": False,
      "deleteIntermediateOutputFiles": True,
      "useReferenceDisks": False,
      "workflowFailureMode": "NoNewCalls"
    }
    
    head = prepare_header()
    
    myUrl = f'https://api.firecloud.org/api/workspaces/{workspaceNamespace}/{workspaceName}/submissions'
    response = requests.post(myUrl, data=json.dumps(data), headers=head)
    return response

def get_workflow_config(workspaceNamespace, workspaceName, methodConfigNamespace, methodConfigName):
    
    myUrl = f'https://api.firecloud.org/api/workspaces/{workspaceNamespace}/{workspaceName}/method_configs/{methodConfigNamespace}/{methodConfigName}'

    head = prepare_header()

    response = requests.get(myUrl, headers=head)
    return response

def set_workflow_config(workspaceNamespace, workspaceName, methodNamespace, methodName, methodVersion, methodConfigRootEntityType, methodConfigVersion):

    myUrl = f'https://api.firecloud.org/api/workspaces/{workspaceNamespace}/{workspaceName}/method_configs/{methodNamespace}/{methodName}'

    data = {
      "deleted": False,
      "inputs": {
        "SingleM_SRA.GCloud_User_Key_File": "\"gs://fc-833c2d81-556a-4c83-aed7-21f884f6fec0/sa-private-key.json\"",
        "SingleM_SRA.AWS_User_Key": "",
        "SingleM_SRA.metagenome_size_in_GB": "this.metagenome_size_in_GB",
        "SingleM_SRA.SRA_accession_num": "this.sra_accession",
        "SingleM_SRA.GCloud_Paid": "false",
        "SingleM_SRA.metagenome_size_in_gbp": "this.metagenome_size_in_gbp",
        "SingleM_SRA.Download_Method_Order": "\"aws-http prefetch\"",
        "SingleM_SRA.AWS_User_Key_Id": ""
      },
      "methodConfigVersion": methodConfigVersion,
      "methodRepoMethod": {
        "methodName": methodName,
        "methodVersion": methodVersion,
        "methodNamespace": methodNamespace,
        "methodUri": f"agora://{methodNamespace}/{methodName}/{methodVersion}",
        "sourceRepo": "agora"
      },
      "name": methodName,
      "namespace": methodNamespace,
      "outputs": {
        "SingleM_SRA.SingleM_tables": "this.singlem_table"
      },
      "prerequisites": {},
      "rootEntityType": methodConfigRootEntityType
    }
    
    head = prepare_header()

    response = requests.put(myUrl, data=json.dumps(data), headers=head)
    return response

def get_method(methodConfigNamespace, methodConfigName, methodConfigVersion):

    myUrl = f'https://api.firecloud.org/api/methods/{methodConfigNamespace}/{methodConfigName}/{methodConfigVersion}?onlyPayload=false'
    
    head = prepare_header()

    response = requests.get(myUrl, headers=head)
    return response

def import_entity_from_tsv(file_path):
    token = os.popen('gcloud auth --account=terra-api@maximal-dynamo-308105.iam.gserviceaccount.com print-access-token').read().rstrip()

    url = 'https://api.firecloud.org/api/workspaces/firstterrabillingaccount/singlem-pilot-2/flexibleImportEntities'

    m = MultipartEncoder(
        fields={"workspaceNamespace": "firstterrabillingaccount","workspaceName": "singlem-pilot-2",
                'entities': ('filename', open(file_path, 'rb'), 'text/plain')}
        )

    head = {'accept': '*/*','Content-Type': m.content_type, 'Authorization': 'Bearer {}'.format(token)}

    response = requests.post(url, data=m, headers=head)
    return response
