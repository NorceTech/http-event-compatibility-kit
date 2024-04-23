az account set -s "<id>"

az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/<id>"

