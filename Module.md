# Ballerina Azure Cache for Redis

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

Connects to Microsoft Azure Cache for Redis using Ballerina.

# Introduction

## What is Azure Cache for Redis?

[Azure Cache for Redis](https://docs.microsoft.com/en-us/azure/azure-cache-for-redis/cache-overview) is Microsoft’s in-memory data store in Azure technology stack. Azure Cache for Redis improves the performance of an application that rely on large data stores. Key purpose of the Azure Cache for Redis is able to process mass amount of request by storing frequently requested data in the server that can be written to and read from  rapidly. Redis allow a low-latency and high-throughput data storage solution to modern applications. Azure Cache for Redis is created to manage Cache instances.


## Key Features of Azure Cache for Redis

* Azure Cache for Redis offers both the Redis open-source and a commercial product from Redis Labs as a managed service.
* Automatic updates and patching (Patch can be Scheduled).
* Capacity management with automatic scaling options in terms of Service tiers (Basic, Standard, Premium).
https://docs.microsoft.com/en-us/azure/azure-cache-for-redis/cache-overview#service-tiers

 ## Connector Overview
 
 Azure Cache for Redis Ballerina connector is a connector for managing to Azure Cache for
 Redis via Ballerina language easily. It provides capability to perform operations related to managing redis cache like Create, Read, Update and delete Azure cache instances, firewall rules, patch schedules and private endpoint connections. This connector promotes easy integration and access to Azure Cache for Redis via ballerina by handling most of the burden on ballerina developers in configuring a new connection to the Azure Cache for Redis from scratch.

 Ballerina Azure Cache for Redis connector provides support for all the operations for 
 management of Azure Cache Instances and where used extensively by the existing developer 
 community. For version 0.1.0 of this connector, version 2020-06-01 of Azure Cache for Redis REST API is used.

# Supported Operations

## Operations regarding creating and managing Azure Cache Instances
The `ballerinax/azure-cache-redis` module contains operations regarding
* createRedisCache
* getRedisCache
* getHostName
* getSSLPortNumber
* getNonSSLPortNumber
* getPrimaryKey
* listRedisInstances
* listKeys
* regenerateKey
* updateRedisCache
* deleteRedisCache

## Operations regarding creating and managing Firewall Rules
* createFirewallRule
* getFireWallRule
* listFireWallRule
* deleteFireWallRule

## Operations regarding creating and managing Patch Schedules
* createPatchSchedule
* getPatchSchedule
* listPatchSchedule
* deletePatchSchedule

# Prerequisites

* You'll need an Azure subscription before you begin. If you don't have one, create a free account first. [Create Azure Account to access azure portal](https://docs.microsoft.com/en-us/learn/modules/create-an-azure-account)

* [Create Resource Group](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal#create-resource-groups)

* Access to Azure Active Directory.
Application has to be created under Active Directory under same tenant.
Client ID and Client Secret can be obtained from Certificates & secrets section in azure Active Directory which is used in authorization.

* Ballerina SLP8 Installed
Ballerina Swan Lake Preview Version 8 is required.

# Supported Versions & Limitations

## Supported Versions

|                                   |      	       Version                 |
| :-------------------------------: | :----------------------------------: |
|      Ballerina Language           |         Swan Lake Preview 8 	       |
| Azure Cache for Redis API Version |              2020-06-01              |

## Limitations

* Only Management operations are supported from the connector. (Cache related operations are not supported as they are not provided by Azure cache for redis REST API).
* Operations only available as a preview are not supported such as Private Endpoint Connections and Redis Enterprise (2020-10-01-preview).
* Some Redis Enterprise Cluster operations are still not supported at the moment as they are not supported by Azure Cache for Redis REST API yet.
* Operations only available in Premium pricing tier are not included.


# Quickstart(s)

# Configuration
Instantiate the connector by giving authorization credentials that a client application can use.

## Getting the authorization credentials
Have to register an application in azure Active Directory and generate Client Id and Client Secret for that application in Active Directory.

## Azure Cache for Redis Management Client

There is only one client provided by Ballerina to interact with Azure Cache for Redis

**azure_cache_redis:Client** - This creates a Azure Cache for Redis Client instance and perform different actions related to creating managing that Azure cache Instance, Firewall Rules, Patch Schedules and Linked Servers.

```ballerina
azure_cache_redis:AzureRedisConfiguration config = {oauth2Config: {
        tokenUrl: "https://login.microsoftonline.com/" + <TENANT_ID> + "/oauth2/v2.0/token",
        clientId: <CLIENT_ID>,
        clientSecret: <CLIENT_SECRET>,
        scopes: ["https://management.azure.com/.default"]
}};
Client azureRedisManagementClient = new (config);
```

# Sample
First, import the `ballerinax/azure_cache_redis` module into the Ballerina project.
```ballerina
import ballerinax/azure_cache_redis;
```

You can now make the connection configuration using the connection string and entity path.
```ballerina
azure_cache_redis:AzureRedisConfiguration config = {oauth2Config: {
        tokenUrl: "https://login.microsoftonline.com/" + config:getAsString("TENANT_ID") + "/oauth2/v2.0/token",
        clientId: config:getAsString("CLIENT_ID"),
        clientSecret: config:getAsString("CLIENT_SECRET"),
        scopes: ["https://management.azure.com/.default"]
}};
Client azureRedisManagementClient = new (config);
```

### Create Azure Cache Instance

This part describes how to use the ballerina connector to create a azure cache for redis instance. We must pass subscription id, resource group name where cache instance should be created, cache instance name, location, properties of type CreateCacheProperty and optional parameters such as tags and array of zones as parameters to create a cache instance. It returns an RedisCacheInstance if  operation is successful or error if the operation is unsuccessful.
Azure Cache for Redis istances are created and take some time to get deployed and start running. We can check for state of cache instance by keep track of provisioningState which is one property of the cache instance created. Once state is running we can perform operations on the cache instance.

```ballerina
    CreateCacheProperty properties = 
    {
        "sku": {
            "name": "Basic",
            "family": "C",
            "capacity": 1
        },
        "enableNonSslPort": true,
        "redisConfiguration": {"maxmemory-policy": "allkeys-lru"},
        "minimumTlsVersion": minimumTlsVersion
    };

    RedisCacheInstance|error response = azureRedisManagementClient->createRedisCache("TestCache", "TestResourceGroup", "Southeast Asia", properties);
    if (response is RedisCacheInstance) {
        log:print("Azure cache instance created and deployment in progress");
        json state = response.properties.provisioningState;
        while (state != "Succeeded") {
            var getresponse = azureRedisManagementClient->getRedisCache("TestCache", "TestResourceGroup");
            if (getresponse is json) {
                state = getresponse.properties.provisioningState;
            }
        }
        log:print("Azure cache instance deployed and running");
    } else {
        log:print(response.message());
    }
```

### Get Azure Cache Instance

This part describes how to use the ballerina connector to get information regarding a specific azure cache for redis instance. We must pass subscription id, resource group name where cache instance resides and cache instance name as parameters to get all the data associated with a specific cache instance. It returns an RedisCacheInstance if  operation is successful or error if the operation is unsuccessful.

```ballerina
    RedisCacheInstance|error response = azureRedisManagementClient->getRedisCache(<SUBSCRIPTION_ID>, "TestCache", "TestResourceGroup");
    if (response is RedisCacheInstance) {
        log:print("Azure cache instance fetched");
    } else {
        log:print(response.message());
    }
```

### Get all Azure Cache Instances in a resource group

This part describes how to use the ballerina connector to get information regarding a  azure cache for redis instances in a specific resource group. We must pass subscription id and resource group name where cache instances resides as parameters to get all the data associated with a cache instances. It returns an RedisCacheInstance[] if  operation is successful or error if the operation is unsuccessful.

```ballerina
    RedisCacheInstance|error response = azureRedisManagementClient->getRedisCache(<SUBSCRIPTION_ID>, "TestCache", "TestResourceGroup");
    if (response is RedisCacheInstance[]) {
        log:print("Array of Azure cache instances fetched");
        foreach RedisCacheInstance redisInstance in response {
            log:print(redisInstance.toString());
        }
    } else {
        log:print(response.message());
    }
```

### Get all Azure Cache Instances in all resource group within a subscription

This part describes how to use the ballerina connector to get information regarding a azure cache for redis instances within a subscription. We must pass subscription id as parameter to get all the data associated with a cache instances in that subscription. It returns an RedisCacheInstance[] if  operation is successful or error if the operation is unsuccessful.

```ballerina
    RedisCacheInstance[]|error response = azureRedisManagementClient->listRedisCacheInstances(<SUBSCRIPTION_ID>);
    if (response is RedisCacheInstance[]) {
        foreach RedisCacheInstance redisInstance in response {
            log:print(redisInstance.toString());
        }
    } else {
        log:print(response.message());
    }
```

### Get Host Name

Host name is used in redis clients for making connection to an Azure Cache for Redis instance. It returns an string which will be used as host name(DNS name) in redis client if  operation is successful or error if the operation is unsuccessful.

```ballerina
    string|error response = azureRedisManagementClient->getHostName(<SUBSCRIPTION_ID>, "TestCache", "TestResourceGroup");
    if (response is string) {
        log:print(response);
    } else {
        log:print(response.message());
    }
```

### Get SSL Port Number

SSL Port number is used in redis clients for making connection to an Azure Cache for Redis instance. It returns an integer which will be used as SSL port number in redis client if  operation is successful or error if the operation is unsuccessful.

```ballerina
    int|error response = azureRedisManagementClient->getSSLPortNumber(<SUBSCRIPTION_ID>, "TestCache", "TestResourceGroup");
    if (response is int) {
        log:print(response);
    } else {
        log:print(response.message());
    }
```

### Get Non SSL Port Number

Non SSL Port number is used in redis clients for making connection to an Azure Cache for Redis instance when only via SSL is disabled in instance. It returns an integer which will be used as non SSL port number (If NonSslPort is enabled only can connect through this port) in redis client if  operation is successful or error if the operation is unsuccessful.

```ballerina
    int|error response = azureRedisManagementClient->getNonSSLPortNumber(<SUBSCRIPTION_ID>, "TestCache", "TestResourceGroup");
    if (response is int) {
        log:print(response);
    } else {
        log:print(response.message());
    }
```

### Get Primary Key

Primary Key is used in redis clients for making connection to an Azure Cache for Redis instance. It returns an string which will be used as password in redis client if  operation is successful or error if the operation is unsuccessful.

```ballerina
    string|error response = azureRedisManagementClient->getPrimaryKey(<SUBSCRIPTION_ID>, "TestCache", "TestResourceGroup");
    if (response is string) {
        log:print(response);
    } else {
        log:print(response.message());
    }
```

### Get Access Keys

Keys are also sometime referred as passwords used in redis clients for making connection to an Azure Cache for Redis instance. There are Primary and Secondary Keys. Those Keys are referred as access keys which can be optained by using this operation in a form of AccessKeys. It returns an AccessKey if  operation is successful or error if the operation is unsuccessful.

```ballerina
    AccessKey|error response = azureRedisManagementClient->listKeys<SUBSCRIPTION_ID>, ("TestCache", "TestResourceGroup");
    if (response is AccessKey) {
        json primaryKey = response.primaryKey;
        json secondaryKey = response.secondaryKey;
        log:print(primaryKey);
    } else {
        log:print(response.message());
    }
```

### Regenerate Access Keys

Those Primary and Secondary Keys can be regenerated by using this operation and opbained in a form of AccessKeys. It returns an AccessKey if  operation is successful or error if the operation is unsuccessful.

```ballerina
    AccessKey|error response = azureRedisManagementClient->regenerateKey<SUBSCRIPTION_ID>, ("TestCache", "TestResourceGroup", "Primary");
    if (response is AccessKey) {
        json primaryKey = response.primaryKey;
        json secondaryKey = response.secondaryKey;
        log:print(primaryKey);
    } else {
        log:print(response.message());
    }
```

### Update a Azure Cache Instance

This part describes how to use the ballerina connector to update a azure cache for redis instance. We must pass subscription id, resource group name where cache instance should be created, cache instance name and properties to be updated as parameters to update a cache instance. Some informations such as location and zones can't be updated once created. It returns an RedisCacheInstance if  operation is successful or error if the operation is unsuccessful.

```ballerina
    CreateCacheProperty properties = 
    {        
        "sku": {
            "name": "Basic",
            "family": "C",
            "capacity": 1
        },
        "enableNonSslPort": true,
        "redisConfiguration": {"maxmemory-policy": "allkeys-lru"},
        "minimumTlsVersion": minimumTlsVersion
    };

    RedisCacheInstance|error response = azureRedisManagementClient->updateRedisCache(SUBSCRIPTION_ID>, "TestCache", "TestResourceGroup", properties);
    if (response is RedisCacheInstance) {
        log:print("Azure cache instance updating in progress");
        json state = response.properties.provisioningState;
        while (state != "Succeeded") {
            var getresponse = azureRedisManagementClient->getRedisCache((SUBSCRIPTION_ID>,  "TestCache", "TestResourceGroup");
            if (getresponse is json) {
                state = getresponse.properties.provisioningState;
            }
        }
        log:print("Azure cache instance updated and running");
    } else {
        log:print(response.message());
    }
```

### Delete a Azure Cache Instance

This part describes how to use the ballerina connector to delete a specific azure cache for redis instance. We must pass subscription id, resource group name where cache instance resides and cache instance name as parameters to delete a specific azure cache for redis instance. It returns an boolean if  operation is successful or error if the operation is unsuccessful. Only after deleted completely another instance can be created with the same name. It takes some time to delete instance, so we can check for state of cache instance to ensure it is deleted.

```ballerina
    boolean|error response = azureRedisManagementClient->deleteRedisCache(SUBSCRIPTION_ID>, "TestCache", "TestResourceGroup");
    if (response is boolean) {
        var getresponse = azureRedisManagementClient->getRedisCache(SUBSCRIPTION_ID>, "TestCache", "TestResourceGroup");
        json state = ();
        if (getresponse is RedisCacheInstance) {
            state = getresponse.properties.provisioningState;
        }
        while (state == "Deleting") {
            var getresponse = azureRedisManagementClient->getRedisCacheSUBSCRIPTION_ID>, "TestCache", "TestResourceGroup");
            if (getresponse is RedisCacheInstance) {
                state = getresponse.properties.provisioningState;
            }
            else {
            state = "Deleted";
            }
        }
        log:print("Azure cache instance deleted");
    } else {
        log:print(response.message());
    }
    
```

### Create Firewall Rule to a cache instance

FireWall Rule can be created to allow particular ranges of IP addresses only connect to redis cache instance. This can be done by specifing statring and ending IP address of the range.
This part describes how to use the ballerina connector to create a firewall rule for a specific azure cache for redis instance. We must pass subscription id, resource group name where cache instance resides, cache instance name, name of a firewall rule, start IP address of permitted range to be allowed and end IP address of permitted range to be allowed as parameters to create a firewall rule for a specific cache instance. It returns an FirewallRule if  operation is successful or error if the operation is unsuccessful.

```ballerina
    FirewallRule|error response = azureRedisManagementClient->createFirewallRule(<SUBSCRIPTION_ID>, "TestCache", "TestResourceGroup", "TestFilewallRule", "192.168.1.1", "192.168.1.4");
    if (response is FirewallRule) {
        log:print("Firewall Rule created");
    } else {
        log:print(response.message());
    }
```

### Get a Firewall Rule related to a cache instance

This part describes how to use the ballerina connector to get information regarding a firewall rule for a specific azure cache for redis instance. We must pass subscription id, resource group name where cache instance resides, cache instance name and name of firewall rule as parameters to get all the data associated with a specific firewall rule of a specific cache instance. It returns an FirewallRule if  operation is successful or error if the operation is unsuccessful.

```ballerina
    FirewallRule|error response = azureRedisManagementClient->getFirewallRule(<SUBSCRIPTION_ID>, "TestCache", "TestResourceGroup", "TestFilewallRule");
    if (response is FirewallRule) {
        log:print("Firewall Rule fetched");
    } else {
        log:print(response.message());
    }
```

### Get a all Firewall Rules related to a cache instance

This part describes how to use the ballerina connector to get information regarding all the firewall rules for a specific azure cache for redis instance. We must pass subscription id, resource group name where cache instance resides and cache instance name as parameters to get all the data associated with firewall rules of a specific cache instance. It returns an Array of FirewallRule[] if  operation is successful or error if the operation is unsuccessful.

```ballerina
    FirewallRule[]|error response = azureRedisManagementClient->listFirewallRule(<SUBSCRIPTION_ID>, "TestCache", "TestResourceGroup");
    if (response is FirewallRule) {
        log:print("Firewall Rule fetched");
    } else {
        log:print(response.message());
    }
```
### Delete a Firewall Rule of a cache instance

This part describes how to use the ballerina connector to delete a firewall rule for a specific azure cache for redis instance. We must pass subscription id, resource group name where cache instance resides, cache instance name and name of firewall rule as parameters to delete a specific firewall rule. It returns an boolean if  operation is successful or error if the operation is unsuccessful.

```ballerina
    boolean|error response = azureRedisManagementClient->deleteFirewallRule(<SUBSCRIPTION_ID>, "TestCache", "TestResourceGroup", "TestFilewallRule");
    if (response is boolean) {
        log:print("Firewall Rule deleted");
    } else {
        log:print(response.message());
    }
```

### Create a Patch Schedule to a cache instance

Azure Cache for Redis patch schedule is used to install important software updates in 
specified time windows.
This part describes how to use the ballerina connector to create a patch schedule for a specific azure cache for redis instance. We must pass subscription id, resource group name where cache instance resides, cache instance name, name of a patch schedule and properties of type PatchScheduleProperty as parameters to create a patch schedule for a specific cache instance. It returns an PatchSchedule if  operation is successful or error if the operation is unsuccessful.

```ballerina
    PatchScheduleProperty properties = {scheduleEntries: [{
        dayOfWeek: "Monday",
        startHourUtc: 12,
        maintenanceWindow: "PT5H"
    }, {
        dayOfWeek: "Tuesday",
        startHourUtc: 12
    }]};

    PatchSchedule|error response = azureRedisManagementClient->createPatchSchedule(<SUBSCRIPTION_ID>, "TestCache", "TestResourceGroup", "TestPatchSchedule", properties);
    if (response is PatchSchedule) {
        log:print("Patch Schedule created");
    } else {
        log:print(response.message());
    }
```

### Get a Patch Schedule related to a cache instance

This part describes how to use the ballerina connector to get information regarding a patch schedule for a specific azure cache for redis instance. We must pass subscription id, resource group name where cache instance resides, cache instance name and name of a patch schedule as parameters to get all the data associated with a specific patch schedule of a specific cache instance. It returns an PatchSchedule if  operation is successful or error if the operation is unsuccessful.

```ballerina
    PatchSchedule|error response = azureRedisManagementClient->getPatchSchedule(<SUBSCRIPTION_ID>, "TestCache", "TestResourceGroup", "TestPatchSchedule");
    if (response is PatchSchedule) {
        log:print("Patch Schedule fetched");
    } else {
        log:print(response.message());
    }
```

### Get a all Patch Schedules related to a cache instance

This part describes how to use the ballerina connector to get information regarding all the patch schedules for a specific azure cache for redis instance. We must pass subscription id, resource group name where cache instance resides and cache instance name as parameters to get all the data associated with patch schedules of a specific cache instance. It returns an Array of Patch Schedule if  operation is successful or error if the operation is unsuccessful.

```ballerina
    PatchSchedule[]|error response = azureRedisManagementClient->listPatchSchedule(<SUBSCRIPTION_ID>, "TestCache", "TestResourceGroup");
    if (response is PatchSchedule[]) {
        log:print("List of Patch Schedules fetched");
    } else {
        log:print(response.message());
    }
```
### Delete a Patch Schedule

This part describes how to use the ballerina connector to delete a patch schedule for a specific azure cache for redis instance. We must pass subscription id, resource group name where cache instance resides, cache instance name and name of patch schedule as parameters to delete a specific patch scehedule. It returns an boolean if  operation is successful or error if the operation is unsuccessful.

```ballerina
    boolean|error response = azureRedisManagementClient->deletePatchSchedule(<SUBSCRIPTION_ID>, "TestCache", "TestResourceGroup", "TestPatchSchedule");
    if (response is boolean) {
        log:print("Patch Schedule deleted");
    } else {
        log:print(response.message());
    }
```


## Building from the Source

### Setting Up the Prerequisites

Download and install [Ballerina SLP8](https://ballerina.io/). 

### Building the Source

Execute the commands below to build from the source after installing Ballerina SLP8 version.

1. To build the library:
```shell script
    ballerina build
```

2. To build the module without the tests:
```shell script
    ballerina build --skip-tests
```

## Contributing to Ballerina

As an open source project, Ballerina welcomes contributions from the community. 

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of Conduct

All the contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).

## Useful Links

* Discuss the code changes of the Ballerina project in [ballerina-dev@googlegroups.com](mailto:ballerina-dev@googlegroups.com).
* Chat live with us via our [Slack channel](https://ballerina.io/community/slack/).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.