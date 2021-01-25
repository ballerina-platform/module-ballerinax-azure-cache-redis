
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

public type Auth record {
    string token_type;
    int expires_in;
    int ext_expires_in;
    string access_token;
};

public type BaseUrlProperty record {|
    string redisCacheName = "";
    string resourceGroupName = "";
|};

public type PatchScheduleProperty record {|
    ScheduleEntry[] scheduleEntries?;
|};

public type CreateCacheProperty record {|
    SKU sku;
    boolean enableNonSslPort?;
    int shardCount?;
    int replicasPerMaster?;
    json redisConfiguration?;
    string subnetId?;
    string staticIP?;
    TlsVersion minimumTlsVersion?;
|};

public type SKU record {|
    string name = "";
    string family = "";
    int capacity = 0;
|};

public type FirewallRule record {|
    FirewallRuleProperty firewallProperties;
|};

public type FirewallRuleResponse record {|
    string id?;
    string name?;
    string 'type?;
    FirewallRuleProperty properties?;
|};

public type FirewallRuleProperty record {|
    string startIP = "";
    string endIP = "";
|};

public type FirewallRuleListResponse record {|
    FirewallRuleResponse[] value?;
|};

public type RedisConfingPolicy record {|
    string maxmemory_policy?;
|};

public type TlsVersion record {|
    string minimumTlsVersion;
|};

public type StatusCode record {|
    string code?;
    string message?;
|};

public type AzureRedisError distinct error;

public type RedisCacheInstance record {|
    string id?;
    string location;
    string name?;
    string 'type?;
    json tags?;
    RedisCacheInstanceProperty properties;
|};

public type RedisCacheInstanceProperty record {|
    string provisioningState;
    string redisVersion?;
    SKU sku;
    boolean enableNonSslPort?;
    Instance[] instances?;
    string publicNetworkAccess?;
    PrivateEndpointConnection[] privateEndpointConnections?;
    json redisConfiguration?;
    json accessKeys?;
    string hostName?;
    int port?;
    int sslPort?;
    LinkedServer[] linkedServers?;
|};

public type Instance record {|
    int sslPort?;
    int nonSslPort?;
    boolean isMaster?;
|};

public type PrivateEndpointConnection record {|
    string id?;
    PrivateEndpointConnectionProperty properties?;
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

public type RedisEnterpriseCacheInstance record {|
    string name?;
    string 'type?;
    string id?;
    string location?;
    EnterpriseSKU sku?;
    string[] zones?;
    json tags?;
    RedisEnterpriseCacheInstanceProperty properties?;
|};

public type EnterpriseSKU record {|
    string name?;
    int capacity?;
|};

public type RedisEnterpriseCacheInstanceProperty record {|
    string provisioningState;
    string resourceState?;
    string publicNetworkAccess?;
    PrivateEndpointConnection[] privateEndpointConnections?;
    string hostName?;
    string redisVersion?;
    string minimumTlsVersion?;
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

public type PatchShedule record {|
    string id;
    string location;
    string name;
    string 'type;
    PatchSheduleProperty properties;
|};

public type ScheduleEntry record {|
    string dayOfWeek?;
    int startHourUtc?;
    string maintenanceWindow?;
|};

public type PatchSheduleProperty record {|
    ScheduleEntry[] scheduleEntries;
|};

public type PatchSheduleList record {|
    PatchShedule[] value?;
|};

public type RedisEnterpriseDatabase record {|
    string id;
    string name;
    string 'type;
    RedisEnterpriseDatabaseProperty properties;
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
