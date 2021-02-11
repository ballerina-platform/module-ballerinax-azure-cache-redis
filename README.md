# Ballerina Azure Cache for Redis

[![Build](https://github.com/ballerina-platform/module-ballerinax-azure-cache-redis/workflows/CI/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-azure.eventhub/actions?query=workflow%3ACI)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerinax-azure-cache-redis.svg)](https://github.com/ballerina-platform/module-ballerinax-azure.eventhub/commits/master)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

Connects to Microsoft Azure Cache for Redis using Ballerina.

# Introduction

## What is Azure Cache for Redis?

[Azure Cache for Redis](https://docs.microsoft.com/en-us/azure/azure-cache-for-redis/cache-overview)

## Key Features of Azure Cache for Redis

* Azure Cache for Redis offers both the Redis open-source and a commercial product from Redis Labs as a managed service.
* Automatic updates and patching (Patch can be Scheduled).
* Capacity management with automatic scaling options in terms of Service tiers (Basic, Standard, Premium).
https://docs.microsoft.com/en-us/azure/azure-cache-for-redis/cache-overview#service-tiers

 ## Connector Overview
 
 Azure Cache for Redis Ballerina connector is a connector for managing to Azure Cache for
 Redis via Ballerina language easily. It provides capability to perform operations related to managing redis cache like Create, Read, Update and delete Redis cache instances, firewall rules, patch schedules and private endpoint connections. This connector promotes easy integration and access to Azure Cache for Redis via ballerina by handling most of the burden on ballerina developers in configuring a new connection to the Azure Cache for Redis from scratch.

 Ballerina Azure Cache for Redis connector provides support for all the operations for 
 management of Redis Cache Instances and where used extensively by the existing developer 
 community. For version 0.1.0 of this connector, version 2020-06-01 of Azure Cache for Redis REST API is used.

# Supported Operations

## Operations regarding creating and managing Redis Cache Instances
The `ballerinax/azure-cache-redis` module contains operations regarding
* checkeRedisCacheAvailability
* createRedisCache
* getRedisCache
* importRedisCache
* exportRedisCache
* listRedisInstances
* listKeys
* regenerateKey
* updateRedisCache

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

## Operations regarding creating and managing Linked Servers
* createLinkedServer
* getLinkedServer
* listLinkedServer
* deleteLinkedServer

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

|                               |      	       Version                 |
| :---------------------------: | :----------------------------------: |
|      Ballerina Language       |         Swan Lake Preview 8 	       |
| Azure Redis Cache API Version |              2020-06-01              |

## Limitations

* Only Management operations are supported from the connector. (Cache related operations are not supported as they are not provided by Azure cache for redis REST API).
* Operations only available as a preview are not supported such as Private Endpoint Connections and Redis Enterprise (2020-10-01-preview).
* Some Redis Enterprise Cluster operations are still not supported at the moment as they are not supported by Azure Redis Cache REST API yet.
* Operations only available in Premium pricing tier are not included.


# Quickstart(s)

# Configuration
Instantiate the connector by giving authorization credentials that a client application can use.

## Getting the authorization credentials
Have to register an application in azure Active Directory and generate Client Id and Client Secret for that application in Active Directory.

## Azure Redis Cache Management Client

There is only one client provided by Ballerina to interact with Azure Redis Cache.

**azure_cache_redis:Client** - This creates a Azure Redis Client instance and perform different actions related to creating managing that Redis cache Instance, Firewall Rules, Patch Schedules and Linked Servers.

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

```ballerina
    CreateCacheProperty properties = 
    {
        "sku": {
            "name": "Premium",
            "family": "P",
            "capacity": 1
        },
        "enableNonSslPort": true,
        "shardCount": 2,
        "redisConfiguration": {"maxmemory-policy": "allkeys-lru"},
        "minimumTlsVersion": minimumTlsVersion
    };

    RedisCacheInstance|error response = azureRedisManagementClient->createRedisCache("TestRedisConnectorCache", "TestResourceGroup", "Southeast Asia", properties);
    if (response is RedisCacheInstance) {
        boolean createSuccess = true;
        log:print("Redis cache instance created and deployment in progress");
        json state = response.properties.provisioningState;
        while (state != "Succeeded") {
            var getresponse = azureRedisManagementClient->getRedisCache("TestRedisConnectorCache", "TestResourceGroup");
            if (getresponse is json) {
                state = getresponse.properties.provisioningState;
            }
        }
        log:print("Redis cache instance deployed and running");
    } else {
        log:print(response);
    }
```

```ballerina
    RedisCacheInstance|error response = azureRedisManagementClient->getRedisCache("TestRedisConnectorCache", "TestResourceGroup");
    if (response is RedisCacheInstance) {
        log:print("Redis cache instance fetched");
        string hostName = response.properties.hostName;
    } else {
        log:print(response);
    }

    AccessKey|error keys = azureRedisManagementClient->listKeys("TestRedisConnectorCache", "TestResourceGroup");
    if (keys is AccessKey) {
        json primaryKey = keys.primaryKey;
        json secondaryKey = keys.secondaryKey;
        log:print(primaryKey);
    } else {
        log:print(keys.message());
    }
```

FireWall Rule can be created to allow particular ranges of IP addresses only connect to redis cache instance. This can be done by specifing statring and ending IP address of the range.

```ballerina
    FirewallRule|error response = azureRedisManagementClient->createFirewallRule("TestRedisConnectorCache", "TestResourceGroup", "TestFilewallRule", "192.168.1.1", "192.168.1.4");
    if (response is FirewallRuleResponse) {
        log:print("Firewall Rule created");
    } else {
        log:print(response);
    }
```

Linked Servers can be created to achieve Geo-Replication of redis cache instance. This can be done by specifing another redis cache instance to be linked and server role.

```ballerina
     LinkedServer|error response = azureRedisManagementClient->createLinkedServer("TestRedisConnectorCache", "TestResourceGroup", 
     "TestRedisConnectorCacheLinkedServer", 
     "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/TestResourceGroup/providers/Microsoft.Cache/Redis/TestRedisConnectorCacheLinkedServer", 
     "South India", "Secondary");
    if (response is LinkedServer) {
        log:print("LinkedServer created");
    } else {
        log:print(response);
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

## Issues and Projects 

Issues and Projects tabs are disabled for this repository as this is part of the Ballerina Standard Library. To report bugs, request new features, start new discussions, view project boards, etc. please visit Ballerina Standard Library [parent repository](https://github.com/ballerina-platform/ballerina-standard-library). 

This repository only contains the source code for the module.

## Contributing to Ballerina

As an open source project, Ballerina welcomes contributions from the community. 

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of Conduct

All the contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).

## Useful Links

* Discuss the code changes of the Ballerina project in [ballerina-dev@googlegroups.com](mailto:ballerina-dev@googlegroups.com).
* Chat live with us via our [Slack channel](https://ballerina.io/community/slack/).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.