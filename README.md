# Open Policy Agent Evaluate Infrastructure Score

This repo contains a library of constraint templates and sample constraints.


### Available Commands
The commands are intended to run in Google Cloud Shell
```
terraform init                                       Init terraform
terraform plan -out=test.tfplan                      Generate terraform plan file in test.tfplan
terraform show -json ./test.tfplan > ./tfplan.json   Convert terraform plan into json format
opa exec --decision templates/gcp/GCPCheckScoreConstraintV1/score --bundle score/ ./tfplan.json      evaluate score using opa
```


### Medium article references

You may find the step by step instruction in [Open Policy Agent Evaluate Infrastructure Score](https://zhangran1.medium.com/open-policy-agent-evaluate-infrastructure-score-8cdf13c7cc46).

