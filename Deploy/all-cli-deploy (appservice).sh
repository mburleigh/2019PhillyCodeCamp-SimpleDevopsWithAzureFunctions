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

	az group create --name $resourceGroupName --location $resourceGroupLocation 1> /dev/null
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

testurl=''

echo "Starting deployment..."
(
	servicePlanName=$deploymentName'-plan'
	applicationInsightsName=$deploymentName'-appinsights'

	#echo "*** app insights ***"
	az resource create -g $resourceGroupName --resource-type "Microsoft.Insights/components" -n $applicationInsightsName -l $resourceGroupLocation -p '{"Application_Type":"web"}'

	#echo "*** storage acct ***"
	az storage account create -n $storageAccountName -g $resourceGroupName -l $resourceGroupLocation --sku Standard_LRS

	#echo "*** server farm (app service plan) ***"
	az functionapp plan create -n $servicePlanName -g $resourceGroupName --sku S1

	#echo "*** function app ***"
	az functionapp create -g $resourceGroupName  -p $servicePlanName -n $serviceName -s $storageAccountName --app-insights $applicationInsightsName

	#echo "*** app settings ***"
	az functionapp config appsettings set -n $serviceName -g $resourceGroupName --settings \
    FUNCTION_APP_EDIT_MODE=readonly \
		FUNCTIONS_EXTENSION_VERSION=~2 \
		FUNCTIONS_WORKER_RUNTIME=node \
		WEBSITE_NODE_DEFAULT_VERSION=8.11.1

    if [ $# == 2 ]; then
		testurl='https://'$serviceName'.azurewebsites.net/api/'
	elif [ $# == 3 ]; then
		slotname=$3
		testurl='https://'$serviceName'-'$slotname'.azurewebsites.net/api/'

		#echo "*** slot *** " $slotname
		az webapp deployment slot create -n $serviceName -g $resourceGroupName -s $slotname --configuration-source $serviceName

		echo "##vso[task.setvariable variable=slotname]$slotname"
	else
		echo "$# parameters are not supported"
	fi
	#echo "test url " $testurl
)

if [ $? == 0 ]; then
	echo "Template has been successfully deployed to $deploymentName"
fi

# these values are needed by other tasks
echo "##vso[task.setvariable variable=serviceName]$serviceName"
echo "##vso[task.setvariable variable=resourceGroup]$resourceGroupName"
echo "##vso[task.setvariable variable=testurl]$testurl"