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

## Azure Redis Cache Client

There is only one client provided by Ballerina to interact with Azure Redis Cache.

1. **azure_redis_cache:Client** - This creates a Azure Redis Cache instance and perform different actions related to managing that instance created



## Sample

First, import the `ballerinax/azure_redis_cache` module into the Ballerina project.

