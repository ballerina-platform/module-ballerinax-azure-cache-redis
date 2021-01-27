 ## Connector Overview
 
 Azure Cache for Redis Ballerina connector is a connector for connecting to Azure Cache for
 Redis via Ballerina language easily. It provides capability to connect to Azure Cache for Redis and to perform operations related to managing redis cache like Create, Read, Update and delete Redis cache instances, firewall rules, patch schedules and private endpoint connections. Apart from this it allows the special features provided by Azure Cache for Redis
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

## Operations regarding creating and managing Firewall Rules

## Operations regarding creating and managing Patch Schedules

## Operations regarding creating and managing Linked Servers


## Azure Redis Cache Client

There is only one client provided by Ballerina to interact with Azure Redis Cache.

1. **azure_redis_cache:Client** - This creates a Azure Redis Client instance and perform different actions related to creating managing that Redis cache Instance, Firewall Rules, Patch Schedules and Linked Servers.

# Prerequisites

* .[Create Azure Account to access azure portal].(https://docs.microsoft.com/en-us/learn/modules/create-an-azure-account/)

* .[Create Resource Group].(https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal#create-resource-groups)

* Access to Azure Active Directory.
Application has to be created under Active Directory under same tenant.
Client ID and Client Secret can be obtained from Certificates & secrets section in azure Active Directory which is used in getting access token. Azure Active Directory OAuth2 Implicit Flow approach is used to obtain access token.

* Java 11 Installed
Java Development Kit (JDK) with version 11 is required.

* Ballerina SLP8 Installed
Ballerina Swan Lake Preview Version 8 is required.


# Configuration
Instantiate the connector by giving authorization credentials that a client application can use.

## Getting the authorization credentials
Have to create an app in azure active directory


## Azure Redis Cache Client

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

