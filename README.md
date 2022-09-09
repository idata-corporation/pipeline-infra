# pipeline-infra
Infrastructure and deployment for the IData Pipeline on AWS

If you need help with intallation, send an email to support@idata.net and one of our technical staff will be in contact.

cli requirements
- install aws cli v2 https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
- install terraform cli https://www.terraform.io/downloads
- install helm https://helm.sh/docs/intro/install/ 

## Manage Terraform states
- Manually create an S3 bucket for the Terraform states in an account where the Terraform code will have access (e.g. idata-poc-terraform-states)
- Ensure that the Terraform code backend.tf files in the directory ./terraform of this repository use this states bucket

## Install VPC (Optional)
If you don't already have a VPC setup in your account, run the IAC to install a VPC in your account.  If you already have a VPC setup, ensure that
other Terraform files in this repository read values from your existing VPC.
```
Change directories to ./pipeline-infra/terraform/vpc
terraform init
terraform apply
```

## Install EKS
```
Change directories to ./pipeline-infra/terraform/eks
terraform init
terraform apply
```

Log into EKS
```
aws eks update-kubeconfig --name idata-poc
```

Create namespaces and identity mapping
```
 kubectl create ns idata-poc
 kubectl create ns ingress-nginx
 kubectl create ns pipeline
 kubectl create ns spark
 eksctl create iamidentitymapping --cluster idata-poc --namespace spark --service-name "emr-containers"
 ```

## Install EMR on EKS
```
Change directories to ./pipeline-infra/terraform/emr-on-eks
terraform init
terraform apply
```

Provide permissioning
```
eksctl utils associate-iam-oidc-provider --cluster idata-poc --approve
aws emr-containers update-role-trust-policy --cluster-name idata-poc --namespace spark --role-name EMRContainers-JobExecutionRole
```

## Install AWS Core Infrastructure
```
Change directories to ./pipeline-infra/terraform/core
terraform init
terraform apply
```

## Create the Ingress
- Note: The IData Terraform code creates a Load Balancer, and uses the AWS Certificate Manager to generate a certificate bound to a Route 53 endpoint. Obviously there are a number of other options here.
- Change the ingress according to your company's standard.  Basically you need 2 DNS entries for ingress, one DNS entry pointing to the Pipeline Server API and and one DNS entry pointing to the Pipeline UI.

DNS Change 
- Ingress DNS should be mapped to A Record or CName (from Load balancer) via DNS Management (e.g. Route53 in our IAC)

TLS Termination
- Option 1: Terminate the TLS on Load Balancer (e.g. Annotation from ingress service.beta.kubernetes.io/aws-load-balancer-ssl-cert with cert arn)
- Option 2: Terminate the TLS on the ingress controller (e.g. https://kubernetes.github.io/ingress-nginx/examples/tls-termination/)

IData Pipeline Example using a Load Balancer and Route53
```
Change directories to ./pipeline-infra/helm
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm upgrade -i ingress-nginx ingress-nginx/ingress-nginx -f ./values/ingress-nginx/values.yaml -n ingress-nginx
```

## Configure & Install the Pipeline Server
- Edit the ./pipeline-infra/helm/values/pipeline/idata-poc/values.yaml file
- Change the values tagged with TODO accordingly

```
Change directories to ./pipeline-infra/helm
helm upgrade -i pipeline ./charts/pipeline -f ./values/pipeline/idata-poc/values.yaml -n pipeline
```

## Configure & Install the Pipeline UI
- Edit the ./pipeline-infra/helm/values/pipeline-ui/idata-poc/values.yaml file
- Change the values tagged with TODO accordingly

```
Change directories to ./pipeline-infra/helm
helm upgrade -i ui ./charts/pipeline-ui -f ./values/pipeline-ui/idata-poc/values.yaml -n pipeline
```

## Copy the Pipeline Files to the S3 Config Bucket
```
aws s3 cp s3://idata-config/emr-config.json s3://idata-poc-config/spark/
aws s3 cp s3://idata-config/pipeline-schemagenerator-assembly-2.2.4.jar s3://idata-poc-config/spark/
aws s3 cp s3://idata-config/pipeline-transform-assembly-2.2.4.jar s3://idata-poc-config/spark/
aws s3 cp s3://idata-config/pipeline-triggertemplate-assembly-2.2.4.jar s3://idata-poc-config/spark/
```

## Quick Start
Check logs for error on pipeline server startup
```
kubectl logs -f deploy/pipeline -n pipeline
```

If no error, register a test dataset (stock_price)



## Additional Commands
```
# uninstall pipeline server
helm delete pipeline -n pipeline

# uninstall pipeline ui
helm delete pipeline -n pipeline

# login to eks
aws eks update-kubeconfig --name idata-poc

# check running pod in pipeline namespace
kubectl get pod -n pipeline

# get name of deployed pods
kubectl get deploy -n pipeline

# check pipeline server logs 
kubectl logs -f deploy/pipeline -n pipeline

# get emr-containers virtual-cluster-id
aws emr-containers list-virtual-clusters --query "virtualClusters[?state=='RUNNING'].id" --output text
```
