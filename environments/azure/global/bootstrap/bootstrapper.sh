# Variables

WORKING_DIR="environments/azure/global/bootstrap"

# Set subscription ID for IaC as variable.
TENANT_ID=$(az account show --output tsv --query 'tenantId')
SUBSCRIPTION_ID_IAC=$(az account list --query "[?contains(name,'iac')].{SubscriptionID:id}" --output tsv)
echo -e "Tenant: $TENANT_ID \nSubscription: $SUBSCRIPTION_ID_IAC"

while true; do
    read -p "Proceed with Terraform deployment? (y/n) " result1
    case $result1 in
        [Yy]* ) echo "Proceeding..."; 
        
        # Terraform: Initialize (setup required providers).
        terraform -chdir=$WORKING_DIR init

        # Terraform: Validate (verify code syntax and consistency).
        terraform -chdir=$WORKING_DIR validate

        # Terraform: Plan (generate plan file of intended changes).
        terraform -chdir=$WORKING_DIR plan -out=bootstrap.tfplan -var-file=bootstrap.tfvars \
        -var="tenant_id=$TENANT_ID" \
        -var="subscription_id_iac=$SUBSCRIPTION_ID_IAC"

        # Terraform: Apply (deploy changes from plan file).
        terraform -chdir=$WORKING_DIR apply bootstrap.tfplan

        # Set environment variables to Terraform outputs.
        TF_BACKEND_RG=$(terraform -chdir=$WORKING_DIR output -raw out_bootstrap_iac_rg)
        TF_BACKEND_SA=$(terraform -chdir=$WORKING_DIR output -raw out_bootstrap_iac_sa)
        TF_BACKEND_CONTAINER=$(terraform -chdir=$WORKING_DIR output -raw out_bootstrap_iac_cn)
        TF_BACKEND_KEY="azure-mgt-iac-bootstrap.tfstate"
        echo -e "RG: $TF_BACKEND_RG \nSA: $TF_BACKEND_SA \nCN: $TF_BACKEND_CONTAINER \nKEY: $TF_BACKEND_KEY"

        cat << EOF > $WORKING_DIR/backend.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "$$TF_BACKEND_RG"
    storage_account_name = "$$TF_BACKEND_SA"
    container_name       = "$TF_BACKEND_CONTAINER"
    key                  = "$TF_BACKEND_KEY"
  }
}
EOF

        break;;
        [Nn]* ) echo "Exiting..."; exit;;
        * ) echo "Invalid response. Please answer y or n.";;
    esac
done

# Migrate local state to Azure backend.
while true; do
    read -p "Proceed with Terraform migration to Azure backend? (y/n) " result
    case $result in
        [Yy]* ) echo "Proceeding..."; 
        
        terraform -chdir=$WORKING_DIR init -migrate-state -force-copy -input=false \
        -backend-config="resource_group_name=$TF_BACKEND_RG" \
        -backend-config="storage_account_name=$TF_BACKEND_SA" \
        -backend-config="container_name=$TF_BACKEND_CONTAINER" \
        -backend-config="key=$TF_BACKEND_KEY"

        # Remove local Terraform files, no longer required. 
        rm -r $WORKING_DIR/.terraform \
        $WORKING_DIR/.terraform.* \
        $WORKING_DIR/*.tfstate* \
        $WORKING_DIR/*.tfplan
        
        break;;
        [Nn]* ) echo "Exiting..."; exit;;
        * ) echo "Invalid response. Please answer y or n.";;
    esac
done

# END
