name: Terraform

on: [push, workflow_dispatch]

permissions:
  contents: 'read'
  id-token: 'write'

env:
  AWS_ROLE: arn:aws:iam::111111111111:role/github-actions-oidc-OIDCRoleStack
  TF_PLAN_FILE: ${{github.sha}}.tfplan

jobs:
  terraform-plan:
    name: "Terraform Plan"
    runs-on: external-k8s
    steps:
      - name: Checkout
        uses: actions/checkout@v2

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          role-to-assume: ${{env.AWS_ROLE}}
          aws-region: eu-central-1

      - name: Configure Git Credentials
        run: git config --global url."https://token:$ORG_REPOS_INTERNAL_READ_ONLY@github.com/bayer-int".insteadOf https://github.com/bayer-int
        env:
          ORG_REPOS_INTERNAL_READ_ONLY: ${{ secrets.ORG_REPOS_INTERNAL_READ_ONLY }}

      - name: Setup Node
        uses: actions/setup-node@v2
        with:
          node-version: '16'

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v1
        with:
          terraform_version: 1.1.6

      - name: Terraform Init
        id: init
        run: terraform init

      - name: Terraform Plan
        id: plan
        run: terraform plan -out=$TF_PLAN_FILE -input=false

      - name: Upload Plan
        uses: actions/upload-artifact@v2
        with:
          name: tfplan
          path: ${{env.TF_PLAN_FILE}}

  terraform-apply:
    name: "Terraform Apply"
    runs-on: external-k8s
    needs: [terraform-plan]
    environment: dev
    steps:
      - name: Checkout
        uses: actions/checkout@v2

      - name: Download Plan
        uses: actions/download-artifact@v2
        with:
          name: tfplan

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          role-to-assume: ${{env.AWS_ROLE}}
          aws-region: eu-central-1

      - name: Configure Git Credentials
        run: git config --global url."https://token:$ORG_REPOS_INTERNAL_READ_ONLY@github.com/bayer-int".insteadOf https://github.com/bayer-int
        env:
          ORG_REPOS_INTERNAL_READ_ONLY: ${{ secrets.ORG_REPOS_INTERNAL_READ_ONLY }}

      - name: Setup Node
        uses: actions/setup-node@v2
        with:
          node-version: '16'

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v1
        with:
          terraform_version: 1.1.6

      - name: Terraform Init
        id: init
        run: terraform init

      - name: Terraform Apply
        id: apply
        run: terraform apply -input=false $TF_PLAN_FILE
