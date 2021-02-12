// Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
import ballerina/http;
import ballerina/oauth2;
import ballerina/log;

public type AzureRedisConfiguration record {
    oauth2:ClientCredentialsGrantConfig oauth2Config;
    http:ClientSecureSocket secureSocketConfig?;
};

# Azure Cache for Redis Client Object.
# 
# + AzureRedisCacheManagementClient - the HTTP Client
public client class AzureRedisCacheManagementClient {

    http:Client AzureRedisCacheManagementClient;

    public function init(AzureRedisConfiguration azureConfig) {
        oauth2:OutboundOAuth2Provider oauth2Provider = new (azureConfig.oauth2Config);
        http:BearerAuthHandler bearerHandler = new (oauth2Provider);
        http:ClientSecureSocket? socketConfig = azureConfig?.secureSocketConfig;
        self.AzureRedisCacheManagementClient = new (BASE_URL, {
            auth: {authHandler: bearerHandler},
            secureSocket: socketConfig
        });
    }

    public function checkAzureCacheNameAvailability(string subscriptionId, string cacheName) 
    returns @tainted boolean|error {
        string requestPath = SUBSCRIPTION_PATH + subscriptionId + "/providers/Microsoft.Cache/CheckNameAvailability" + 
        API_VERSION_PATH + API_VERSION;
        http:Request request = new;
        json checkPayload = {
            "type": "Microsoft.Cache/Redis",
            "name": cacheName
        };
        request.setJsonPayload(checkPayload);
        http:Response checkResponse = <http:Response>check self.AzureRedisCacheManagementClient->post(requestPath, 
        request);
        if (checkResponse.statusCode == http:STATUS_OK) {
            return true;
        } else {
            json responsePayload = check checkResponse.getJsonPayload();
            return getAzureError(checkResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    //Operations related to Redis cache

    # This Function Creates a new Redis Cache Instance
    #
    # + subscriptionId - Subscription Id of a subscription
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + location - location where redis cache instance created
    # + properties - properties Parameter Description including Pricing tier(Basic, Standard, Premium)
    # + tags - Resource tags.
    # + zones - A list of availability zones denoting where the resource needs to come from
    # + return - If successful, returns RedisCacheInstance. Else returns error. 
    remote function createRedisCache(string subscriptionId, string redisCacheName, string resourceGroupName, 
                                     string location, CreateCacheProperty properties, json tags = (), 
                                     string[]? zones = ()) returns @tainted RedisCacheInstance|error {
        var checkAvailability = self.checkAzureCacheNameAvailability(subscriptionId, redisCacheName);
        if (checkAvailability is boolean) {
            string requestPath = SUBSCRIPTION_PATH + subscriptionId + RESOURCE_GROUP_PATH + resourceGroupName + 
            PROVIDER_PATH + redisCacheName + API_VERSION_PATH + API_VERSION;
            http:Request request = new;
            json createCachePayload = {
                "location": location,
                "properties": {
                    "sku": {
                        "name": properties.sku.name,
                        "family": properties.sku.family,
                        "capacity": properties.sku.capacity
                    },
                    "enableNonSslPort": properties?.enableNonSslPort,
                    "publicNetworkAccess": properties?.publicNetworkAccess,
                    "minimumTlsVersion": properties?.minimumTlsVersion,
                    "redisConfiguration": properties?.redisConfiguration,
                    "replicasPerMaster": properties?.replicasPerMaster,
                    "shardCount": properties?.shardCount,
                    "staticIP": properties?.staticIP,
                    "subnetId": properties?.subnetId,
                    "tenantSettings": properties?.tenantSettings
                },
                "tags": tags,
                "zones": zones
            };
            request.setJsonPayload(createCachePayload);
            http:Response createResponse = <http:Response>check self.AzureRedisCacheManagementClient->put(requestPath, 
            request);
            json responsePayload = check createResponse.getJsonPayload();
            if (createResponse.statusCode == http:STATUS_OK) {
                RedisCacheInstance getRedisCacheResponse = check responsePayload.cloneWithType(RedisCacheInstance);
                return getRedisCacheResponse;
            } else if (createResponse.statusCode == http:STATUS_CREATED) {
                RedisCacheInstance getRedisCacheResponse = check responsePayload.cloneWithType(RedisCacheInstance);
                return getRedisCacheResponse;
            } else {
                return getAzureError(createResponse.statusCode.toString() + SPACE + responsePayload.toString());
            }
        } else {
            return checkAvailability;
        }
    }

    # This Function Deletes a Redis Cache Instance
    #
    # + subscriptionId - Subscription Id of a subscription
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + return - If successful, returns boolean. Else returns error. 
    remote function deleteRedisCache(string subscriptionId, string redisCacheName, string resourceGroupName) 
    returns @tainted boolean|error {
        string requestPath = SUBSCRIPTION_PATH + subscriptionId + RESOURCE_GROUP_PATH + resourceGroupName + 
        PROVIDER_PATH + redisCacheName + API_VERSION_PATH + API_VERSION;
        http:Request request = new;
        http:Response deleteResponse = <http:Response>check self.AzureRedisCacheManagementClient->delete(requestPath, 
        request);
        if (deleteResponse.statusCode == http:STATUS_OK || deleteResponse.statusCode == http:STATUS_NO_CONTENT || 
        deleteResponse.statusCode == ACCEPTED) {
            return true;
        } else {
            json responsePayload = check deleteResponse.getJsonPayload();
            return getAzureError(deleteResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    # This Function Fetches a Redis Cache Instance
    #
    # + subscriptionId - Subscription Id of a subscription
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + return - If successful, returns RedisCacheInstance. Else returns error. 
    remote function getRedisCache(string subscriptionId, string redisCacheName, string resourceGroupName) returns @tainted 
    RedisCacheInstance|error {
        string requestPath = SUBSCRIPTION_PATH + subscriptionId + RESOURCE_GROUP_PATH + resourceGroupName + 
        PROVIDER_PATH + redisCacheName + API_VERSION_PATH + API_VERSION;
        http:Request request = new;
        http:Response getResponse = <http:Response>check self.AzureRedisCacheManagementClient->get(requestPath, request);
        json responsePayload = check getResponse.getJsonPayload();
        if (getResponse.statusCode == http:STATUS_OK) {
            RedisCacheInstance getRedisCacheResponse = check responsePayload.cloneWithType(RedisCacheInstance);
            return getRedisCacheResponse;
        } else {
            return getAzureError(getResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    # This Function Fetches Host Name of a specific Redis Cache Instance
    #
    # + subscriptionId - Subscription Id of a subscription
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + return - If successful, returns string. Else returns error. 
    remote function getHostName(string subscriptionId, string redisCacheName, string resourceGroupName) 
    returns @tainted string|error {
        string requestPath = SUBSCRIPTION_PATH + subscriptionId + RESOURCE_GROUP_PATH + resourceGroupName + 
        PROVIDER_PATH + redisCacheName + API_VERSION_PATH + API_VERSION;
        http:Request request = new;
        http:Response getResponse = <http:Response>check self.AzureRedisCacheManagementClient->get(requestPath, request);
        json responsePayload = check getResponse.getJsonPayload();
        if (getResponse.statusCode == http:STATUS_OK) {
            RedisCacheInstance getRedisCacheResponse = check responsePayload.cloneWithType(RedisCacheInstance);
            string hostName = getRedisCacheResponse.properties.hostName;
            return hostName;
        } else {
            return getAzureError(getResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    # This Function Fetches SSL Port number of a specific Redis Cache Instance
    #
    # + subscriptionId - Subscription Id of a subscription
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + return - If successful, returns int. Else returns error. 
    remote function getSSLPortNumber(string subscriptionId, string redisCacheName, string resourceGroupName) 
    returns @tainted int|error {
        string requestPath = SUBSCRIPTION_PATH + subscriptionId + RESOURCE_GROUP_PATH + resourceGroupName + 
        PROVIDER_PATH + redisCacheName + API_VERSION_PATH + API_VERSION;
        http:Request request = new;
        http:Response getResponse = <http:Response>check self.AzureRedisCacheManagementClient->get(requestPath, request);
        json responsePayload = check getResponse.getJsonPayload();
        if (getResponse.statusCode == http:STATUS_OK) {
            RedisCacheInstance getRedisCacheResponse = check responsePayload.cloneWithType(RedisCacheInstance);
            int sslPortNumber = getRedisCacheResponse.properties.sslPort;
            return sslPortNumber;
        } else {
            return getAzureError(getResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    # This Function Fetches Non SSL Port number of a specific Redis Cache Instance only can be used when NonSslPort enabled in instance
    #
    # + subscriptionId - Subscription Id of a subscription
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + return - If successful, returns int. Else returns error. 
    remote function getNonSSLPortNumber(string subscriptionId, string redisCacheName, string resourceGroupName) 
    returns @tainted int|error {
        string requestPath = SUBSCRIPTION_PATH + subscriptionId + RESOURCE_GROUP_PATH + resourceGroupName + 
        PROVIDER_PATH + redisCacheName + API_VERSION_PATH + API_VERSION;
        http:Request request = new;
        http:Response getResponse = <http:Response>check self.AzureRedisCacheManagementClient->get(requestPath, request);
        json responsePayload = check getResponse.getJsonPayload();
        if (getResponse.statusCode == http:STATUS_OK) {
            RedisCacheInstance getRedisCacheResponse = check responsePayload.cloneWithType(RedisCacheInstance);
            int nonSSlPortNumber = getRedisCacheResponse.properties.port;
            return nonSSlPortNumber;
        } else {
            return getAzureError(getResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    # This Function Fetches list of Redis Cache Instances in a subscription or Fetches list of Redis Cache Instances in resource group if resource group name if it is given
    #
    # + subscriptionId - Subscription Id of a subscription
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + return - If successful, returns RedisCacheInstance[]. Else returns error. 
    remote function listRedisCacheInstances(string subscriptionId, string? resourceGroupName = ()) returns @tainted 
    RedisCacheInstance[]|error {
        if (resourceGroupName is string) {
            string requestPath = 
            SUBSCRIPTION_PATH + subscriptionId + RESOURCE_GROUP_PATH + resourceGroupName + "/providers/Microsoft.Cache/redis" + 
            API_VERSION_PATH + API_VERSION;
            http:Request request = new;
            http:Response listResponse = <http:Response>check self.AzureRedisCacheManagementClient->get(requestPath, 
            request);
            json responsePayload = check listResponse.getJsonPayload();
            if (listResponse.statusCode == http:STATUS_OK) {
                RedisCacheInstanceList listRedisCacheInstance = check responsePayload.cloneWithType(
                RedisCacheInstanceList);
                RedisCacheInstance[] listRedisCacheInstanceArray = listRedisCacheInstance.value;
                return listRedisCacheInstanceArray;
            } else {
                return getAzureError(listResponse.statusCode.toString() + SPACE + responsePayload.toString());
            }
        } else {
            string requestPath = SUBSCRIPTION_PATH + subscriptionId + "/providers/Microsoft.Cache/redis" + 
            API_VERSION_PATH + API_VERSION;
            http:Request request = new;
            http:Response listResponse = <http:Response>check self.AzureRedisCacheManagementClient->get(requestPath, 
            request);
            json responsePayload = check listResponse.getJsonPayload();
            if (listResponse.statusCode == http:STATUS_OK) {
                RedisCacheInstanceList listRedisCacheInstance = check responsePayload.cloneWithType(
                RedisCacheInstanceList);
                RedisCacheInstance[] listRedisCacheInstanceArray = listRedisCacheInstance.value;
                return listRedisCacheInstanceArray;
            } else {
                return getAzureError(listResponse.statusCode.toString() + SPACE + responsePayload.toString());
            }
        }

    }

    # This Function Fetches list of primary and secondary keys for specific Redis Cache Instance
    #
    # + subscriptionId - Subscription Id of a subscription
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + return - If successful, returns AccessKey. Else returns error.
    remote function listKeys(string subscriptionId, string redisCacheName, string resourceGroupName) returns @tainted 
    AccessKey|error {
        string requestPath = SUBSCRIPTION_PATH + subscriptionId + RESOURCE_GROUP_PATH + resourceGroupName + 
        PROVIDER_PATH + redisCacheName + "/listKeys" + API_VERSION_PATH + API_VERSION;
        http:Request request = new;
        http:Response listResponse = <http:Response>check self.AzureRedisCacheManagementClient->post(requestPath, 
        request);
        json responsePayload = check listResponse.getJsonPayload();
        if (listResponse.statusCode == http:STATUS_OK) {
            AccessKey listKeys = check responsePayload.cloneWithType(AccessKey);
            return listKeys;
        } else {
            return getAzureError(listResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    # This Function Fetches a primary key of a specific Redis Cache Instance
    #
    # + subscriptionId - Subscription Id of a subscription
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + return - If successful, returns string. Else returns error.
    remote function getPrimaryKey(string subscriptionId, string redisCacheName, string resourceGroupName) 
    returns @tainted string|error {
        string requestPath = SUBSCRIPTION_PATH + subscriptionId + RESOURCE_GROUP_PATH + resourceGroupName + 
        PROVIDER_PATH + redisCacheName + "/listKeys" + API_VERSION_PATH + API_VERSION;
        http:Request request = new;
        http:Response listResponse = <http:Response>check self.AzureRedisCacheManagementClient->post(requestPath, 
        request);
        json responsePayload = check listResponse.getJsonPayload();
        if (listResponse.statusCode == http:STATUS_OK) {
            AccessKey listKeys = check responsePayload.cloneWithType(AccessKey);
            return listKeys.primaryKey;
        } else {
            return getAzureError(listResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    # This Function regenerates primary and secondary keys
    #
    # + subscriptionId - Subscription Id of a subscription
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + keyType - keyType (Primary or Secondary to be regenerated) 
    # + return - If successful, returns AccessKey. Else returns error.
    remote function regenerateKey(string subscriptionId, string redisCacheName, string resourceGroupName, string keyType) returns @tainted 
    AccessKey|error {
        string requestPath = SUBSCRIPTION_PATH + subscriptionId + RESOURCE_GROUP_PATH + resourceGroupName + 
        PROVIDER_PATH + redisCacheName + "/regenerateKey" + API_VERSION_PATH + API_VERSION;
        http:Request request = new;
        json regenerateKeyJsonPayload = {"keyType": keyType};
        request.setJsonPayload(regenerateKeyJsonPayload);
        http:Response regenerateResponse = <http:Response>check self.AzureRedisCacheManagementClient->post(requestPath, 
        request);
        json responsePayload = check regenerateResponse.getJsonPayload();
        if (regenerateResponse.statusCode == http:STATUS_OK) {
            AccessKey listKeys = check responsePayload.cloneWithType(AccessKey);
            return listKeys;
        } else {
            return getAzureError(regenerateResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    # This Function Updates an eisting Redis Cache Instance
    #
    # + subscriptionId - Subscription Id of a subscription
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + properties - properties Parameter Description including Pricing tier(Basic, Standard, Premium)
    # + return - If successful, returns RedisCacheInstance. Else returns error. 
    remote function updateRedisCache(string subscriptionId, string redisCacheName, string resourceGroupName, 
                                     CreateCacheProperty properties) returns @tainted RedisCacheInstance|error {
        string requestPath = SUBSCRIPTION_PATH + subscriptionId + RESOURCE_GROUP_PATH + resourceGroupName + 
        PROVIDER_PATH + redisCacheName + API_VERSION_PATH + API_VERSION;
        http:Request request = new;
        json updateCacheJsonPayload = {"properties": {
                "sku": {
                    "name": properties.sku.name,
                    "family": properties.sku.family,
                    "capacity": properties.sku.capacity
                },
                "enableNonSslPort": properties?.enableNonSslPort,
                "publicNetworkAccess": properties?.publicNetworkAccess,
                "minimumTlsVersion": properties?.minimumTlsVersion,
                "redisConfiguration": properties?.redisConfiguration,
                "replicasPerMaster": properties?.replicasPerMaster,
                "shardCount": properties?.shardCount,
                "staticIP": properties?.staticIP,
                "subnetId": properties?.subnetId,
                "tenantSettings": properties?.tenantSettings
            }};
        request.setJsonPayload(updateCacheJsonPayload);
        http:Response updateResponse = <http:Response>check self.AzureRedisCacheManagementClient->patch(requestPath, 
        request);
        json responsePayload = check updateResponse.getJsonPayload();
        if (updateResponse.statusCode == http:STATUS_OK) {
            RedisCacheInstance getRedisCacheResponse = check responsePayload.cloneWithType(RedisCacheInstance);
            return getRedisCacheResponse;
        } else {
            return getAzureError(updateResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    //Operations related to Firewall Rules (Continuous range of IP addresses permitted to connect)

    # This Function creates a FireWall rule or update if exists already
    #
    # + subscriptionId - Subscription Id of a subscription
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + ruleName - Name of Firewall Rule
    # + startIP - Start IP of permitted range
    # + endIP - End IP of permitted range
    # + return - If successful, returns FirewallRule. Else returns error. 
    remote function createFirewallRule(string subscriptionId, string redisCacheName, string resourceGroupName, 
                                       string ruleName, string startIP, string endIP) 
    returns @tainted FirewallRule|error {
        string requestPath = SUBSCRIPTION_PATH + subscriptionId + RESOURCE_GROUP_PATH + resourceGroupName + 
        PROVIDER_PATH + redisCacheName + "/firewallRules/" + ruleName + API_VERSION_PATH + API_VERSION;
        http:Request request = new;
        json createFilewallRuleJsonPayload = {"properties": {
                "startIP": startIP,
                "endIP": endIP
            }};
        request.setJsonPayload(createFilewallRuleJsonPayload);
        http:Response createResponse = <http:Response>check self.AzureRedisCacheManagementClient->put(requestPath, 
        request);
        json responsePayload = check createResponse.getJsonPayload();
        if (createResponse.statusCode == http:STATUS_OK) {
            FirewallRule createFirewallResponse = check responsePayload.cloneWithType(FirewallRule);
            return createFirewallResponse;
        } else if (createResponse.statusCode == http:STATUS_CREATED) {
            FirewallRule createFirewallResponse = check responsePayload.cloneWithType(FirewallRule);
            return createFirewallResponse;
        } else {
            return getAzureError(createResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    # This Function Deletes an existing FireWall Rule
    #
    # + subscriptionId - Subscription Id of a subscription
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + ruleName - Name of Firewall Rule Name
    # + return - If successful, returns boolean. Else returns error. 
    remote function deleteFirewallRule(string subscriptionId, string redisCacheName, string resourceGroupName, 
                                       string ruleName) returns @tainted boolean|error {
        string requestPath = SUBSCRIPTION_PATH + subscriptionId + RESOURCE_GROUP_PATH + resourceGroupName + 
        PROVIDER_PATH + redisCacheName + "/firewallRules/" + ruleName + API_VERSION_PATH + API_VERSION;
        http:Request request = new;
        http:Response deleteResponse = <http:Response>check self.AzureRedisCacheManagementClient->delete(requestPath, 
        request);
        if (deleteResponse.statusCode == http:STATUS_OK || deleteResponse.statusCode == http:STATUS_NO_CONTENT) {
            return true;
        } else {
            json responsePayload = check deleteResponse.getJsonPayload();
            return getAzureError(deleteResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    # This Function Fetches an FireWall rule
    #
    # + subscriptionId - Subscription Id of a subscription
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + ruleName - Name of FirewallRule Name
    # + return - If successful, returns FirewallRule. Else returns error. 
    remote function getFirewallRule(string subscriptionId, string redisCacheName, string resourceGroupName, 
                                    string ruleName) returns @tainted FirewallRule|error {
        string requestPath = SUBSCRIPTION_PATH + subscriptionId + RESOURCE_GROUP_PATH + resourceGroupName + 
        PROVIDER_PATH + redisCacheName + "/firewallRules/" + ruleName + API_VERSION_PATH + API_VERSION;
        http:Request request = new;
        http:Response getResponse = <http:Response>check self.AzureRedisCacheManagementClient->get(requestPath, request);
        json responsePayload = check getResponse.getJsonPayload();
        if (getResponse.statusCode == http:STATUS_OK) {
            FirewallRule getFirewallResponse = check responsePayload.cloneWithType(FirewallRule);
            return getFirewallResponse;
        } else {
            return getAzureError(getResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    # This Function Fetches list of FireWall rules
    #
    # + subscriptionId - Subscription Id of a subscription
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + return - If successful, returns FirewallRule[]. Else returns error. 
    remote function listFirewallRules(string subscriptionId, string redisCacheName, string resourceGroupName) returns @tainted 
    FirewallRule[]|error {
        string requestPath = SUBSCRIPTION_PATH + subscriptionId + RESOURCE_GROUP_PATH + resourceGroupName + 
        PROVIDER_PATH + redisCacheName + "/firewallRules" + API_VERSION_PATH + API_VERSION;
        http:Request request = new;
        http:Response listResponse = 
        <http:Response>check self.AzureRedisCacheManagementClient->get(requestPath, request);
        json responsePayload = check listResponse.getJsonPayload();
        if (listResponse.statusCode == http:STATUS_OK) {
            FirewallRuleList getFirewallRuleList = check responsePayload.cloneWithType(FirewallRuleList);
            FirewallRule[] getFirewallRuleArray = getFirewallRuleList.value;
            return getFirewallRuleArray;
        } else {
            return getAzureError(listResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    //Functions related to patching schedule for Redis cache.

    # This Function Creates or Updates Patch Schedule
    #
    # + subscriptionId - Subscription Id of a subscription
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + patchScheduleProperties - Contain properties such as Day of Week and Start Time
    # + return - If successful, returns PatchSchedule. Else returns error. 
    remote function createPatchSchedule(string subscriptionId, string redisCacheName, string resourceGroupName, 
                                        PatchScheduleProperty? patchScheduleProperties) 
    returns @tainted PatchSchedule|error {
        string requestPath = SUBSCRIPTION_PATH + subscriptionId + RESOURCE_GROUP_PATH + resourceGroupName + 
        PROVIDER_PATH + redisCacheName + "/patchSchedules/default" + API_VERSION_PATH + API_VERSION;
        http:Request request = new;
        json createPayload = {properties: <json>patchScheduleProperties.cloneWithType(json)};
        request.setJsonPayload(createPayload);
        http:Response createResponse = <http:Response>check self.AzureRedisCacheManagementClient->put(requestPath, 
        request);
        json responsePayload = check createResponse.getJsonPayload();
        if (createResponse.statusCode == http:STATUS_OK) {
            PatchSchedule createPatchResponse = check responsePayload.cloneWithType(PatchSchedule);
            return createPatchResponse;
        } else if (createResponse.statusCode == http:STATUS_CREATED) {
            PatchSchedule createPatchResponse = check responsePayload.cloneWithType(PatchSchedule);
            return createPatchResponse;
        } else {
            return getAzureError(createResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    # This Function Deletes an Patch Schedule
    #
    # + subscriptionId - Subscription Id of a subscription
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + return - If successful, returns boolean. Else returns error. 
    remote function deletePatchSchedule(string subscriptionId, string redisCacheName, string resourceGroupName) 
    returns @tainted boolean|error {
        string requestPath = SUBSCRIPTION_PATH + subscriptionId + RESOURCE_GROUP_PATH + resourceGroupName + 
        PROVIDER_PATH + redisCacheName + "/patchSchedules/default" + API_VERSION_PATH + API_VERSION;
        http:Request request = new;
        http:Response deleteResponse = <http:Response>check self.AzureRedisCacheManagementClient->delete(requestPath, 
        request);
        if (deleteResponse.statusCode == http:STATUS_OK || deleteResponse.statusCode == http:STATUS_NO_CONTENT) {
            return true;
        } else {
            json responsePayload = check deleteResponse.getJsonPayload();
            return getAzureError(deleteResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    # This Function Fetches Patch Schedule
    #
    # + subscriptionId - Subscription Id of a subscription
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + return - If successful, returns PatchSchedule. Else returns error. 
    remote function getPatchSchedule(string subscriptionId, string redisCacheName, string resourceGroupName) returns @tainted 
    PatchSchedule|error {
        string requestPath = SUBSCRIPTION_PATH + subscriptionId + RESOURCE_GROUP_PATH + resourceGroupName + 
        PROVIDER_PATH + redisCacheName + "/patchSchedules/default" + API_VERSION_PATH + API_VERSION;
        http:Request request = new;
        http:Response getResponse = <http:Response>check self.AzureRedisCacheManagementClient->get(requestPath, request);
        json responsePayload = check getResponse.getJsonPayload();
        if (getResponse.statusCode == http:STATUS_OK) {
            PatchSchedule getPatchResponse = check responsePayload.cloneWithType(PatchSchedule);
            return getPatchResponse;
        } else {
            return getAzureError(getResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    # This Function Fetches Patch Schedule
    #
    # + subscriptionId - Subscription Id of a subscription
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + return - If successful, returns PatchShedule[]. Else returns error. 
    remote function listPatchSchedules(string subscriptionId, string redisCacheName, string resourceGroupName) returns @tainted 
    PatchSchedule[]|error {
        string requestPath = SUBSCRIPTION_PATH + subscriptionId + RESOURCE_GROUP_PATH + resourceGroupName + 
        PROVIDER_PATH + redisCacheName + "/patchSchedules" + API_VERSION_PATH + API_VERSION;
        http:Request request = new;
        http:Response listResponse = 
        <http:Response>check self.AzureRedisCacheManagementClient->get(requestPath, request);
        json responsePayload = check listResponse.getJsonPayload();
        if (listResponse.statusCode == http:STATUS_OK) {
            PatchScheduleList getPatchSheduleList = check responsePayload.cloneWithType(PatchScheduleList);
            PatchSchedule[] getPatchSheduleArray = getPatchSheduleList.value;
            return getPatchSheduleArray;
        } else {
            return getAzureError(listResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    ///////////////////////////////////////////////////////////////////////////////////
    //    Following functions are not exposed as they are only acailable in          //
    //    premium tiers and others only available at preview version                 //
    ///////////////////////////////////////////////////////////////////////////////////

    # This Function Creates an Linked server
    #
    # + subscriptionId - Subscription Id of a subscription
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + linkedServerName - Name of Linked Server Name
    # + linkedRedisCacheId - Full name of Redis Cache Id
    # + linkedRedisCacheLocation - Location of Linked Server
    # + serverRole - Primary/Secondary
    # + return - If successful, returns LinkedServer. Else returns error. 
    remote function createLinkedServer(string subscriptionId, string redisCacheName, string resourceGroupName, 
                                       string linkedServerName, string linkedRedisCacheId, 
                                       string linkedRedisCacheLocation, string serverRole) 
    returns @tainted LinkedServer|error {
        string requestPath = SUBSCRIPTION_PATH + subscriptionId + RESOURCE_GROUP_PATH + resourceGroupName + 
        PROVIDER_PATH + redisCacheName + "/linkedServers/" + linkedServerName + API_VERSION_PATH + API_VERSION;
        http:Request request = new;
        json createLinkedServerJsonPayload = {"properties": {
                "linkedRedisCacheId": linkedRedisCacheId,
                "linkedRedisCacheLocation": linkedRedisCacheLocation,
                "serverRole": serverRole
            }};
        request.setJsonPayload(createLinkedServerJsonPayload);
        http:Response createResponse = <http:Response>check self.AzureRedisCacheManagementClient->put(requestPath, 
        request);
        string statusCode = createResponse.statusCode.toString();
        json responsePayload = check createResponse.getJsonPayload();
        if (createResponse.statusCode == http:STATUS_OK) {
            LinkedServer createLinkedServerResponse = check responsePayload.cloneWithType(LinkedServer);
            return createLinkedServerResponse;
        } else if (createResponse.statusCode == http:STATUS_CREATED) {
            LinkedServer createLinkedServerResponse = check responsePayload.cloneWithType(LinkedServer);
            return createLinkedServerResponse;
        } else {
            return getAzureError(createResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    # This Function Deletes an Linked server
    #
    # + subscriptionId - Subscription Id of a subscription
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + linkedServerName - Name of Linked Server Name
    # + return - If successful, returns boolean. Else returns error. 
    remote function deleteLinkedServer(string subscriptionId, string redisCacheName, string resourceGroupName, 
                                       string linkedServerName) returns @tainted boolean|error {
        string requestPath = SUBSCRIPTION_PATH + subscriptionId + RESOURCE_GROUP_PATH + resourceGroupName + 
        PROVIDER_PATH + redisCacheName + "/linkedServers/" + linkedServerName + API_VERSION_PATH + API_VERSION;
        http:Request request = new;
        http:Response deleteResponse = <http:Response>check self.AzureRedisCacheManagementClient->delete(requestPath, 
        request);
        string statusCode = deleteResponse.statusCode.toString();
        if (deleteResponse.statusCode == http:STATUS_OK || deleteResponse.statusCode == http:STATUS_NO_CONTENT) {
            return true;
        } else {
            json responsePayload = check deleteResponse.getJsonPayload();
            return getAzureError(deleteResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    //Operations related to Linked server (requires Premium SKU).

    # This Function Creates an Linked server
    #
    # + subscriptionId - Subscription Id of a subscription
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + linkedServerName - Name of Linked Server Name
    # + return - If successful, returns LinkedServer. Else returns error. 
    remote function getLinkedServer(string subscriptionId, string redisCacheName, string resourceGroupName, 
                                    string linkedServerName) returns @tainted LinkedServer|error {
        string requestPath = SUBSCRIPTION_PATH + subscriptionId + RESOURCE_GROUP_PATH + resourceGroupName + 
        PROVIDER_PATH + redisCacheName + "/linkedServers/" + linkedServerName + API_VERSION_PATH + API_VERSION;
        http:Request request = new;
        http:Response getResponse = <http:Response>check self.AzureRedisCacheManagementClient->get(requestPath, request);
        json responsePayload = check getResponse.getJsonPayload();
        if (getResponse.statusCode == http:STATUS_OK) {
            LinkedServer getLinkedServerResponse = check responsePayload.cloneWithType(LinkedServer);
            return getLinkedServerResponse;
        } else {
            return getAzureError(getResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    # This Function Fetches list of Linked Servers
    #
    # + subscriptionId - Subscription Id of a subscription
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + return - If successful, returns LinkedServer[]. Else returns error. 
    remote function listLinkedServers(string subscriptionId, string redisCacheName, string resourceGroupName) returns @tainted 
    LinkedServer[]|error {
        string requestPath = SUBSCRIPTION_PATH + subscriptionId + RESOURCE_GROUP_PATH + resourceGroupName + 
        PROVIDER_PATH + redisCacheName + "/linkedServers" + API_VERSION_PATH + API_VERSION;
        http:Request request = new;
        http:Response listResponse = 
        <http:Response>check self.AzureRedisCacheManagementClient->get(requestPath, request);
        json responsePayload = check listResponse.getJsonPayload();
        if (listResponse.statusCode == http:STATUS_OK) {
            LinkedServerList getLinkedServerList = check responsePayload.cloneWithType(LinkedServerList);
            LinkedServer[] getLinkedServerArray = getLinkedServerList.value;
            return getLinkedServerArray;
        } else {
            return getAzureError(listResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    //Operations related to Private Endpoint Connections (requires Premium SKU) Not currently not supported as it is in preview version.

    # This Function Add Private Endpoint Connection
    #
    # + subscriptionId - Subscription Id of a subscription
    # + redisCacheName - Redis Cache Instance Name. 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + privateEndpointConnectionName - Name of Private Endpoint Connection
    # + return - If successful, returns PrivateEndpointConnection. Else returns error. 
    remote function putPrivateEndpointConnection(string subscriptionId, string redisCacheName, string resourceGroupName, 
                                                 string privateEndpointConnectionName, string status, string description) returns @tainted 
    PrivateEndpointConnection|error {
        string requestPath = SUBSCRIPTION_PATH + subscriptionId + RESOURCE_GROUP_PATH + resourceGroupName + 
        PROVIDER_PATH + redisCacheName + "/privateEndpointConnections/" + privateEndpointConnectionName + 
        API_VERSION_PATH + API_VERSION;
        http:Request request = new;
        json putPrivateEndpointConnectionJsonPayload = {"properties": {"privateLinkServiceConnectionState": {
                    "status": status,
                    "description": description
                }}};
        request.setJsonPayload(putPrivateEndpointConnectionJsonPayload);
        http:Response putResponse = <http:Response>check self.AzureRedisCacheManagementClient->put(requestPath, request);
        json responsePayload = check putResponse.getJsonPayload();
        log:print(responsePayload.toString());
        if (putResponse.statusCode == http:STATUS_CREATED) {
            PrivateEndpointConnection getPrivateEndpointConnection = check responsePayload.cloneWithType(
            PrivateEndpointConnection);
            return getPrivateEndpointConnection;
        } else {
            return getAzureError(putResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    # This Function Fetches Private Endpoint Connection
    #
    # + subscriptionId - Subscription Id of a subscription
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + privateEndpointConnectionName - Name of Private Endpoint Connection
    # + return - If successful, returns PrivateEndpointConnection. Else returns error. 
    remote function getPrivateEndpointConnection(string subscriptionId, string redisCacheName, string resourceGroupName, 
                                                 string privateEndpointConnectionName) returns @tainted 
    PrivateEndpointConnection|error {
        string requestPath = SUBSCRIPTION_PATH + subscriptionId + RESOURCE_GROUP_PATH + resourceGroupName + 
        PROVIDER_PATH + redisCacheName + "/privateEndpointConnections/" + privateEndpointConnectionName + 
        API_VERSION_PATH + API_VERSION;
        http:Request request = new;
        http:Response getResponse = <http:Response>check self.AzureRedisCacheManagementClient->get(requestPath, request);
        json responsePayload = check getResponse.getJsonPayload();
        if (getResponse.statusCode == http:STATUS_OK) {
            PrivateEndpointConnection getPrivateEndpointConnection = check responsePayload.cloneWithType(
            PrivateEndpointConnection);
            return getPrivateEndpointConnection;
        } else {
            return getAzureError(getResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    # This Function Fetches Private Endpoint Connection
    #
    # + subscriptionId - Subscription Id of a subscription
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + return - If successful, returns PrivateEndpointConnection[]. Else returns error.
    remote function listPrivateEndpointConnection(string subscriptionId, string redisCacheName, string resourceGroupName) returns @tainted 
    PrivateEndpointConnection[]|error {
        string requestPath = SUBSCRIPTION_PATH + subscriptionId + RESOURCE_GROUP_PATH + resourceGroupName + 
        PROVIDER_PATH + redisCacheName + "/privateEndpointConnections" + API_VERSION_PATH + API_VERSION;
        http:Request request = new;
        http:Response listResponse = 
        <http:Response>check self.AzureRedisCacheManagementClient->get(requestPath, request);
        json responsePayload = check listResponse.getJsonPayload();
        if (listResponse.statusCode == http:STATUS_OK) {
            PrivateEndpointConnectionList getPrivateEndpointConnection = check responsePayload.cloneWithType(
            PrivateEndpointConnectionList);
            PrivateEndpointConnection[] getPrivateEndpointConnectionArray = getPrivateEndpointConnection.value;
            return getPrivateEndpointConnectionArray;
        } else {
            return getAzureError(listResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    # This Function Deletes Private Endpoint Connection
    #
    # + subscriptionId - Subscription Id of a subscription
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + privateEndpointConnectionName - Name of Private Endpoint Connection
    # + return - If successful, returns boolean. Else returns error.
    remote function deletePrivateEndpointConnection(string subscriptionId, string redisCacheName, 
                                                    string resourceGroupName, string privateEndpointConnectionName) 
    returns @tainted boolean|error {
        string requestPath = SUBSCRIPTION_PATH + subscriptionId + RESOURCE_GROUP_PATH + resourceGroupName + 
        PROVIDER_PATH + redisCacheName + "/privateEndpointConnections/" + privateEndpointConnectionName + 
        API_VERSION_PATH + API_VERSION;
        http:Request request = new;
        http:Response deleteResponse = <http:Response>check self.AzureRedisCacheManagementClient->delete(requestPath, 
        request);
        if (deleteResponse.statusCode == http:STATUS_OK || deleteResponse.statusCode == http:STATUS_NO_CONTENT) {
            return true;
        } else {
            json responsePayload = check deleteResponse.getJsonPayload();
            return getAzureError(deleteResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    //Function related to Private Link Resources

    # This Function Fetches Private Link Resource
    #
    # + subscriptionId - Subscription Id of a subscription
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + return - If successful, returns PrivateLinkResource. Else returns error.
    remote function getPrivateLinkResources(string subscriptionId, string redisCacheName, string resourceGroupName) returns @tainted 
    PrivateLinkResource|error {
        string requestPath = SUBSCRIPTION_PATH + subscriptionId + RESOURCE_GROUP_PATH + resourceGroupName + 
        PROVIDER_PATH + redisCacheName + "/privateLinkResources" + API_VERSION_PATH + API_VERSION;
        http:Request request = new;
        http:Response getResponse = <http:Response>check self.AzureRedisCacheManagementClient->get(requestPath, request);
        json responsePayload = check getResponse.getJsonPayload();
        if (getResponse.statusCode == http:STATUS_OK) {
            PrivateLinkResource getPrivateLinkResource = check responsePayload.cloneWithType(PrivateLinkResource);
            return getPrivateLinkResource;
        } else {
            return getAzureError(getResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    //Requires Premium Azure Redis Cache Instance
    //that your Redis Database (RDB) file or files are uploaded into page or block blobs in Azure storage, in the same region and subscription as your Azure Cache for Redis instance.

    # This Function exports a Redis Cache Instance to any azure storages
    #
    # + subscriptionId - Subscription Id of a subscription
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + prefix - file name to be exported 
    # + blobContainerUrl - path to bolb storage 
    # + sasKeyParameters - SAS key
    # + format - file format SUBSCRIPTION_PATH + subscriptionId + to which exported
    # + return - If successful, returns boolean. Else returns error. 
    remote function exportRedisCache(string subscriptionId, string redisCacheName, string resourceGroupName, 
                                     string prefix, string blobContainerUrl, string sasKeyParameters, 
                                     string? format = ()) returns @tainted boolean|error {
        string requestPath = SUBSCRIPTION_PATH + subscriptionId + RESOURCE_GROUP_PATH + resourceGroupName + 
        PROVIDER_PATH + redisCacheName + "/export" + API_VERSION_PATH + API_VERSION;
        http:Request request = new;
        json exportCacheJsonPayload = {
            "format": format,
            "prefix": prefix,
            "container": blobContainerUrl + sasKeyParameters
        };
        request.setJsonPayload(exportCacheJsonPayload);
        http:Response exportResponse = <http:Response>check self.AzureRedisCacheManagementClient->post(requestPath, 
        request);
        if (exportResponse.statusCode == http:STATUS_OK || exportResponse.statusCode == http:STATUS_NO_CONTENT) {
            return true;
        } else if (exportResponse.statusCode == ACCEPTED) {
            return true;
        } else {
            json responsePayload = check exportResponse.getJsonPayload();
            return getAzureError(exportResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    //Requires Premium Azure Redis Cache Instance
    //that your Redis Database (RDB) file or files are uploaded into page or block blobs in Azure storage, in the same region and subscription as your Azure Cache for Redis instance.

    # This Function imports a Redis Cache Instance from any azure storages
    #
    # + subscriptionId - Subscription Id of a subscription
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + files - file name to be imported  
    # + format - file format to be imported
    # + return - If successful, returns boolean. Else returns error. 
    remote function importRedisCache(string subscriptionId, string redisCacheName, string resourceGroupName, 
                                     string[] files, string? format = ()) returns @tainted boolean|error {
        string requestPath = SUBSCRIPTION_PATH + subscriptionId + RESOURCE_GROUP_PATH + resourceGroupName + 
        PROVIDER_PATH + redisCacheName + "/import" + API_VERSION_PATH + API_VERSION;
        http:Request request = new;
        json importCacheJsonPayload = {
            "format": format,
            "files": files
        };
        request.setJsonPayload(importCacheJsonPayload);
        http:Response importResponse = <http:Response>check self.AzureRedisCacheManagementClient->post(requestPath, 
        request);
        if (importResponse.statusCode == http:STATUS_OK || importResponse.statusCode == http:STATUS_NO_CONTENT) {
            return true;
        } else if (importResponse.statusCode == ACCEPTED) {
            return true;
        } else {
            json responsePayload = check importResponse.getJsonPayload();
            return getAzureError(importResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }
}
