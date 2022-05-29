## AWS configure
- profile
- access_key    
- secret_key    
- region

## create file .env
- export AWS_ACCESS_KEY_ID= ?
- export AWS_SECRET_ACCESS_KEY= ?
- export AWS_DEFAULT_REGION= ?

```
...clone DIR...
source .env
```
## use of Terraform
```
terraform init
terraform plan
terraform apply --auto-approve
terraform output

terraform destroy --auto-approve

```