export AWS_VPC_ID=$(aws cloudformation describe-stacks --stack-name vpcstack --query "Stacks[0].Outputs[?OutputKey=='VPCID'].OutputValue" --output text)
export AWS_VPC_SUBNET1_ID=$(aws cloudformation describe-stacks --stack-name vpcstack --query "Stacks[0].Outputs[?OutputKey=='PublicSubnet1ID'].OutputValue" --output text)
export AWS_VPC_SUBNET2_ID=$(aws cloudformation describe-stacks --stack-name vpcstack --query "Stacks[0].Outputs[?OutputKey=='PublicSubnet2ID'].OutputValue" --output text)
export AWS_CROMWELL_STACKNAME=cromwell
export AWS_CROMWELL_TEMPLATE_URL=https://aws-genomics-workflows.s3.amazonaws.com/latest/templates/cromwell/cromwell-resources.template.yaml 
export AWS_CROMWELL_NAMESPACE=cromwell
export AWS_CROMWELL_GWFCORE_NAMESPACE=gwfcore
export AWS_CROMWELL_KEYNAME=MyKeyPair
export AWS_CROMWELL_DBPASSWORD=PEreNSTOGl