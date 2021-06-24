import os
import requests

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

def set_workflow_config(workspaceNamespace, workspaceName, methodConfigNamespace, methodConfigName, methodConfigVersion, methodConfigRootEntityType):

    myUrl = f'https://api.firecloud.org/api/workspaces/{workspaceNamespace}/{workspaceName}/method_configs/{methodConfigNamespace}/{methodConfigName}'

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
      "methodConfigVersion": 100,
      "methodRepoMethod": {
        "methodName": methodConfigName,
        "methodVersion": methodConfigVersion,
        "methodNamespace": methodConfigNamespace,
        "methodUri": f"agora://{methodConfigNamespace}/{methodConfigName}/{methodConfigVersion}",
        "sourceRepo": "agora"
      },
      "name": methodConfigName,
      "namespace": methodConfigNamespace,
      "outputs": {
        "SingleM_SRA.SingleM_tables": "this.singlem_table"
      },
      "prerequisites": {},
      "rootEntityType": methodConfigRootEntityType
    }
    
    head = prepare_header()

    response = requests.put(myUrl, data=json.dumps(data), headers=head)
    return response

def get_workflow_config(methodConfigNamespace, methodConfigName, methodConfigVersion):

    myUrl = f'https://api.firecloud.org/api/methods/{methodConfigNamespace}/{methodConfigName}/{methodConfigVersion}?onlyPayload=false'
    
    head = prepare_header()

    response = requests.get(myUrl, headers=head)
    return response
