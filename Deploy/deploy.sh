#!/bin/bash

# NOTE: special characters here will cause problems with the storage acct name
deploymentName=$1
#echo "deployment name " $deploymentName

# this is the Azure region where the resource group will live
resourceGroupLocation=$2

resourceGroupName="$deploymentName-rg"
#echo "resource group name " $resourceGroupName

# check for existing resource group
az group show --name $resourceGroupName 1> /dev/null
if [ $? != 0 ]; then
	echo "Resource group with name" $resourceGroupName "could not be found. Creating new resource group..."
	(
		az group create --name $resourceGroupName --location $resourceGroupLocation 1> /dev/null
	)
else
	echo "Using existing resource group..."
fi

###
# base the rest of the parameters on the deploymentName
###
serviceName=$deploymentName'-svc'
#echo "service name " $serviceName

# TODO: remove special characters (only a-z0-9 allowed in storage acct name)
storageAccountName=${deploymentName,,}'sa'
#echo "storage account name " $storageAccountName

slotname=''
testurl=''
if [ $# == 2 ]; then
	templateFilePath=$PWD'/template.json'
	testurl='https://'$serviceName'.azurewebsites.net/api/'
elif [ $# == 3 ]; then
	templateFilePath=$PWD'/templatewithslot.json'
	slotname=$3
	testurl='https://'$serviceName'-'$slotname'.azurewebsites.net/api/'
else
	echo "$# parameters are not supported"
fi
#echo "test url " $testurl
#echo "template file path " $templateFilePath

echo "Starting deployment..."
(
    # these parameters match the ones in the ARM template
	#params="{
	#	\"functionName\": { \"value\": \"$serviceName\" },
	#	\"appServicePlanName\": { \"value\": \"$deploymentName-plan\" },
	#	\"applicationInsightsName\": { \"value\": \"$deploymentName-ai\" },
	#	\"storageAccountName\": { \"value\": \"$storageAccountName\" },
	#	\"location\": { \"value\": \"$resourceGroupLocation\" }
	#}"
	params="{
		\"functionName\": { \"value\": \"$serviceName\" },
		\"appServicePlanName\": { \"value\": \"$deploymentName-plan\" },
		\"applicationInsightsName\": { \"value\": \"$deploymentName-ai\" },
		\"storageAccountName\": { \"value\": \"$storageAccountName\" },
		\"location\": { \"value\": \"$resourceGroupLocation\" },
		\"slotName\": { \"value\": \"$slotname\" }
	}"
	#echo $params

	# call the Azure CLI
	az group deployment create --name "$deploymentName" --resource-group "$resourceGroupName" --template-file "$templateFilePath" --parameters "$params"
)

if [ $? == 0 ]; then
	echo "Template has been successfully deployed to $deploymentName"
fi

# these values are needed by other tasks
echo "##vso[task.setvariable variable=serviceName]$serviceName"
echo "##vso[task.setvariable variable=resourceGroup]$resourceGroupName"
echo "##vso[task.setvariable variable=slotname]$slotname"
echo "##vso[task.setvariable variable=testurl]$testurl"