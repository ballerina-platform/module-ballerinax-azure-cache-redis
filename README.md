 ## Connector Overview
 
 Azure Cache for Redis Ballerina connector is a connector for managing to Azure Cache for
 Redis via Ballerina language easily. It provides capability to perform operations related to managing redis cache like Create, Read, Update and delete Redis cache instances, firewall rules, patch schedules and private endpoint connections. Apart from this it allows the special features provided by Azure Cache for Redis
 like operations on Redis Enterprise Cluster and Redis Enterprise Cluster Databases. This
 connector promotes easy integration and access to Azure Cache for Redis via ballerina by
 handling most of the burden on ballerina developers in configuring a new connection to the
 Azure Cache for Redis from scratch.

 Ballerina Azure Cache for Redis connector provides support for all the operations for 
 management of Redis Cache Instances and where used extensively by the existing developer 
 community. For version 0.1.0 of this connector, version 2020-06-01 or 2020-10-01-preview of 
 Azure Cache for Redis REST API is used.



## Compatibility

|                               |      	       Version                 |
| :---------------------------: | :----------------------------------: |
|      Ballerina Language       |         Swan Lake Preview 8 	       |
| Azure Redis Cache API Version |   2020-06-01 or 2020-10-01-preview   |

# Supported Operations

## Operations regarding creating and managing Redis Cache Instances
The `ballerinax/azure_redis_cache` module contains operations regarding
* checkeRedisCacheAvailability
* createRedisCache
* getRedisCache
* importRedisCache
* exportRedisCache
* listByResourceGroup
* listBySubscription
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
Client ID and Client Secret can be obtained from Certificates & secrets section in azure Active Directory which is used in getting access token. Azure Active Directory OAuth2 Implicit Flow approach is used to obtain access token.

* Java 11 Installed
Java Development Kit (JDK) with version 11 is required.

* Ballerina SLP8 Installed
Ballerina Swan Lake Preview Version 8 is required.

## Limitations
* Only Management operations are supported from the connector. (Cache related operations are not supported as they are not provided by Azure cache for redis REST API).
* Redis Enterprise Cluster supports only after version 2020-10-01-preview.
* Some Redis Enterprise Cluster operations are still not supported at the moment as they are not supported by Azure Redis Cache REST API yet.


# Configuration
Instantiate the connector by giving authorization credentials that a client application can use.

## Getting the authorization credentials
Have to create an app in azure active directory


## Azure Redis Cache Client

There is only one client provided by Ballerina to interact with Azure Redis Cache.

**azure_redis_cache:Client** - This creates a Azure Redis Client instance and perform different actions related to creating managing that Redis cache Instance, Firewall Rules, Patch Schedules and Linked Servers.

You can now make the connection configuration using the connection string and entity path.

```ballerina
azure_redis_cache:AzureRedisConfiguration config = {oauth2Config: {
        tokenUrl: <TOKEN_URL>,
        clientId: <CLIENT_ID>,
        clientSecret: <CLIENT_SECRET>,
        scopes: <SCOPES_ARRAY>
}};
Client azureRedisClient = new (config);
```

# Sample
First, import the `ballerinax/azure_redis_cache` module into the Ballerina project.
```ballerina
import ballerinax/azure_redis_cache;
```

You can now make the connection configuration using the connection string and entity path.
```ballerina
azure_redis_cache:AzureRedisConfiguration config = {oauth2Config: {
        tokenUrl: "https://login.microsoftonline.com/" + config:getAsString("TENANT_ID") + "/oauth2/v2.0/token",
        clientId: config:getAsString("CLIENT_ID"),
        clientSecret: config:getAsString("CLIENT_SECRET"),
        scopes: ["https://management.azure.com/.default"]
}};
Client azureRedisClient = new (config);
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
        "replicasPerMaster": 2,
        "redisConfiguration": {"maxmemory-policy": "allkeys-lru"},
        "subnetId": "/subscriptions/subid/resourceGroups/rg2/providers/Microsoft.Network/virtualNetworks/network1/subnets/subnet1",
        "staticIP": "192.168.0.5",
        "minimumTlsVersion": minimumTlsVersion
    };

    var response = azureRedisClient->createRedisCache("TestRedisConnectorCache", "TestRedisConnector", "South India", properties);
    if (response is RedisCacheInstance) {
        boolean createSuccess = true;
        io:println("Redis cache instance created and deployment in progress");
        json state = response.properties.provisioningState;
        while (state != "Succeeded") {
            var getresponse = azureRedisClient->getRedisCache("TestRedisConnectorCache", "TestRedisConnector");
            if (getresponse is json) {
                state = getresponse.properties.provisioningState;
            }
        }
        io:println("Redis cache instance deployed and running");
    } else {
        io:println(response);
    }
```

```ballerina
    RedisCacheInstance|error response = azureRedisClient->getRedisCache("TestRedisConnectorCache", "TestRedisConnector");
    if (response is RedisCacheInstance) {
        io:println("Redis cache instance fetched");
        string hostName = response.properties.hostName;
    } else {
        io:println(response);
    }
```

FireWall Rule can be created to allow particular ranges of IP addresses only connect to redis cache instance. This can be done by specifing statring and ending IP address of the range.

```ballerina
    FirewallRuleResponse|error response = azureRedisClient->createFirewallRule("TestRedisConnectorCache", "TestRedisConnector", "TestFilewallRule", "192.168.1.1", "192.168.1.4");
    if (response is FirewallRuleResponse) {
        io:println("Firewall Rule created");
    } else {
        io:println(response);
    }
```

Linked Servers can be created to achieve Geo-Replication of redis cache instance. This can be done by specifing another redis cache instance to be linked and server role.

```ballerina
     var response = azureRedisClient->createLinkedServer("TestRedisConnectorCache", "TestRedisConnector", 
     "TestRedisConnectorCacheLinkedServer", 
     "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/Redis/TestRedisConnectorCacheLinkedServer", 
     "South India", "Secondary");
    if (response is LinkedServer) {
        io:println("LinkedServer created");
    } else {
        io:println(response);
    }
```