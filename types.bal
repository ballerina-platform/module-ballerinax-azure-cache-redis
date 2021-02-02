
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

public type StockKeepingUnit record {|
    string name;
    string family;
    int capacity;
|};

public type FirewallRule record {|
    string id?;
    string name?;
    string 'type?;
    FirewallRuleProperty properties?;
|};

public type FirewallRuleProperty record {|
    string startIP = "";
    string endIP = "";
|};

public type FirewallRuleList record {|
    FirewallRule[] value;
|};

public type RedisConfingPolicy record {|
    string maxmemory_policy?;
|};

public type TlsVersion record {|
    string minimumTlsVersion;
|};

public type StatusCode record {|
    int code;
    string message?;
|};

public type AzureRedisError distinct error;

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
    boolean enableNonSslPort?;
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

public type EnterpriseStockKeepingUnit record {|
    string name?;
    int capacity?;
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

public type PatchScheduleList record {|
    PatchSchedule[] value;
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

public type ErrorDescription record {|
    string code;
    string message?;
    string target?;
|};

public type AccessKey record {|
    string primaryKey;
    string secondaryKey;
|};
