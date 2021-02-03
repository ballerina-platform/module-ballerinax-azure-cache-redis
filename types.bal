
// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

# Represents a property that provided during creation of Redis Cache
#
# + sku - Stock Keeping Unit which provide Pricing information
# + enableNonSslPort - Whether non SSL port Enabled/Not
# + shardCount - No of Shards
# + replicasPerMaster - No of Replicas
# + redisConfiguration - Configuration of Redis Instance
# + subnetId - Full url of Subnet id 
# + staticIP - Static IP address used to connect
# + minimumTlsVersion - minimum of TlsVersion to be supported
# + publicNetworkAccess - Whether public access is Enabled/Not
public type CreateCacheProperty record {|
    StockKeepingUnit sku;
    boolean enableNonSslPort;
    int shardCount?;
    int replicasPerMaster?;
    json redisConfiguration?;
    string subnetId?;
    string staticIP?;
    TlsVersion minimumTlsVersion?;
    string publicNetworkAccess;
|};

# Represents a property that provided during creation of Redis Enterprise
#
# + minimumTlsVersion - minimum of TlsVersion to be supported
public type CreateEnterpriseCacheProperty record {|
    TlsVersion minimumTlsVersion?;
|};

# Represents a property that provided during creation of Redis Enterprise Database
#
# + clientProtocol - Whether redis clients connect using TLS-encrypted or plaintext redis protocols
# + clusteringPolicy - Name of Clustering policy 
# + evictionPolicy - Redis eviction policy
# + port - Port through which Connection done
# + modules - Name of Redis Labs modules that can be used
public type CreateEnterpriseDBProperty record {|
    string clientProtocol;
    string clusteringPolicy;
    string evictionPolicy;
    int port;
    string[] modules;
|};

# Represents a pricing tier information of Redis Cache
#
# + name - Name of Stock Keeping Unit(Basic/Standard/Premium)
# + family - Group of Stock Keeping Unit
# + capacity - Size of Cache instance to be deployed
public type StockKeepingUnit record {|
    string name;
    string family;
    int capacity;
|};

# Represents a pricing tier information of Redis Cache
#
# + name - Name of Enterprise Stock Keeping Unit
# + capacity - Size of Redis Enterprise instance to be deployed
public type EnterpriseStockKeepingUnit record {|
    string name?;
    int capacity?;
|};

# Represents a firewall rule
#
# + id - Firewall rule url
# + name - Name of Redis cache to which firewall rule created
# + type - Type of firewall rule created
# + properties - Properties consist of range of IP addresses allowed
public type FirewallRule record {|
    string id?;
    string name?;
    string 'type?;
    FirewallRuleProperty properties?;
|};

# Represents a firewall rule property
#
# + startIP - Start IP address of range
# + endIP - End IP address of range
public type FirewallRuleProperty record {|
    string startIP = "";
    string endIP = "";
|};

# Represents a firewall rule list
#
# + value - Array of firewall rule 
public type FirewallRuleList record {|
    FirewallRule[] value;
|};

public type RedisConfingPolicy record {|
    string maxmemory_policy?;
|};

# Represents a TlsVersion during creation of Redis Cache
#
# + minimumTlsVersion - minimum of TlsVersion to be supported
public type TlsVersion record {|
    string minimumTlsVersion;
|};

# Represents a Status code of operations
#
# + code - Http response Status code
# + message - Http response Status message
public type StatusCode record {|
    int code;
    string message?;
|};

# Represents a Error returned by Azure for operations
public type AzureRedisError distinct error;

# Represents a Error created in connector
public type CustomError distinct error;

public type RedisCacheInstance record {|
    string id;
    string location;
    string name;
    string 'type;
    json tags;
    RedisCacheInstanceProperty properties;
|};

public type RedisCacheInstanceProperty record {|
    string provisioningState;
    string redisVersion?;
    StockKeepingUnit sku;
    boolean enableNonSslPort;
    Instance[] instances?;
    string publicNetworkAccess?;
    PrivateEndpointConnection[] privateEndpointConnections?;
    json redisConfiguration?;
    json accessKeys?;
    string hostName;
    int port?;
    int sslPort?;
    LinkedServer[] linkedServers?;
|};

public type RedisCacheInstanceList record {|
    RedisCacheInstance[] value;
|};

public type Instance record {|
    int sslPort?;
    int nonSslPort?;
    boolean isMaster?;
|};

public type PrivateEndpointConnection record {|
    string id;
    string name;
    string 'type;
    PrivateEndpointConnectionProperty properties;
|};

public type PrivateEndpointConnectionProperty record {|
    PrivateEndpoint privateEndpoint?;
    PrivateLinkServiceConnectionState privateLinkServiceConnectionState?;
|};

public type PrivateEndpoint record {|
    string id?;
|};

public type PrivateLinkServiceConnectionState record {|
    string status?;
    string description?;
    string actionRequired?;
|};

public type RedisEnterpriseInstance record {|
    string name;
    string 'type;
    string id;
    string location;
    EnterpriseStockKeepingUnit sku;
    string[] zones?;
    json tags?;
    RedisEnterpriseInstanceProperty properties;
|};

public type RedisEnterpriseInstanceProperty record {|
    string provisioningState;
    string resourceState?;
    string publicNetworkAccess?;
    PrivateEndpointConnection[] privateEndpointConnections?;
    string hostName?;
    string redisVersion?;
    string minimumTlsVersion?;
|};

public type PrivateLinkResource record {|
    string name;
    string 'type;
    string id;
    json properties;
|};

public type PrivateEndpointConnectionList record {|
    PrivateEndpointConnection[] value;
|};

public type RedisEnterpriseInstanceList record {|
    RedisEnterpriseInstance[] value;
|};

public type LinkedServer record {|
    string id;
    string name;
    string 'type;
    LinkedServerProperty properties;
|};

public type LinkedServerProperty record {|
    string linkedRedisCacheId;
    string linkedRedisCacheLocation;
    string provisioningState;
    string serverRole;
|};

public type LinkedServerList record {|
    LinkedServer[] value;
|};

# Represents a PatchSchedule
#
# + id - Id of Patch Schedule
# + location - Location where Patch Schedule is to be created
# + name - Patch Schedule Name
# + type - Type of Patch Schedule
# + properties - Properties of Patch Schedule such as day and time window
public type PatchSchedule record {|
    string id;
    string location;
    string name;
    string 'type;
    PatchScheduleProperty properties;
|};

public type ScheduleEntry record {|
    string dayOfWeek?;
    int startHourUtc?;
    string maintenanceWindow?;
|};

public type PatchScheduleProperty record {|
    ScheduleEntry[] scheduleEntries?;
|};

# Represents a List of PatchSchedule
#
# + value - Array of PatchSchedule
public type PatchScheduleList record {|
    PatchSchedule[] value;
|};

public type RedisEnterpriseDatabase record {|
    string id;
    string name;
    string 'type;
    json properties;
|};

public type RedisEnterpriseDatabaseProperty record {|
    string provisioningState;
    string resourceState;
    string clientProtocol;
    string clusteringPolicy;
    string evictionPolicy;
    int port;
    RedisEnterpriseDatabasePropertyModule[] modules;
|};

public type RedisEnterpriseDatabasePropertyModule record {|
    string name;
    string args;
    string 'version;
|};

public type RedisEnterpriseDatabaseList record {|
    RedisEnterpriseDatabase[] value;
|};

# Represents a Set of Keys used for access
#
# + primaryKey - used to make connection to redis cache
# + secondaryKey - secondary for primary key
public type AccessKey record {|
    string primaryKey;
    string secondaryKey;
|};
