# terraform-infra

AWS SIEM projemiz terraform reposu.

terraform e2e — pipeline, backend, dashboard hepsi burada.

## layout

```
terraform-infra/
├── dashboard/          # root: s3 + cloudfront for the frontend
├── backend_service/    # root: ec2 t3.micro running master.py
├── siem/               # root: empty — phase 1+ goes here
└── modules/
    ├── dashboard_hosting/
    └── backend_service/
```

each root has its own state file in `s3://cloudguard-dns-terraform-state`:

| stack            | state key                          |
|------------------|------------------------------------|
| dashboard        | `dashboard/terraform.tfstate`      |
| backend_service  | `backend_service/terraform.tfstate`|
| siem             | `siem/terraform.tfstate`           |

separate states = blast radius isolated. applying siem won't replan cloudfront.

## branches

never apply from `main`. always feature branch first, merge after review.

## commands

```bash
# pick a stack
cd terraform-infra/dashboard

# usual cycle
terraform init
terraform plan
terraform apply

# what's deployed
terraform state list

# everything tagged with the project (across all stacks)
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Project,Values=cloudguard-dns \
  --region eu-central-1 \
  --query 'ResourceTagMappingList[].ResourceARN' \
  --output table
```

## state backend

bucket `cloudguard-dns-terraform-state` (eu-central-1), `use_lockfile = true` so no dynamodb lock table needed. encryption on.

if state lock gets stuck (usually from a killed `terraform plan`):

```bash
terraform force-unlock <LOCK_ID>
```
