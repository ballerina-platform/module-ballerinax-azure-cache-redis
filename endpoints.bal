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
import ballerina/config;
import ballerina/log;

public type AzureRedisConfiguration record {
    oauth2:ClientCredentialsGrantConfig oauth2Config;
    http:ClientSecureSocket secureSocketConfig?;
};

# Azure Redis Cache Client Object.
# 
# + AzureRedisClient - the HTTP Client
public client class Client {

    http:Client AzureRedisClient;

    public function init(AzureRedisConfiguration azureConfig) {

        string url = BASE_URL + config:getAsString("SUBSCRIPTION_ID");

        oauth2:OutboundOAuth2Provider oauth2Provider = new (azureConfig.oauth2Config);
        http:BearerAuthHandler bearerHandler = new (oauth2Provider);
        http:ClientSecureSocket? socketConfig = azureConfig?.secureSocketConfig;
        self.AzureRedisClient = new (url, {
            auth: {authHandler: bearerHandler},
            secureSocket: socketConfig
        });
    }

    //Operations related to Redis cache

    # This Function checks a Redis Cache Instance with input name already exist or not
    #
    # + cacheName - Redis Cache Instance Name 
    # + return - If successful, returns boolean. Else returns error. 
    remote function checkRedisCacheNameAvailability(string cacheName) returns @tainted boolean|error {
        string requestPath = "/providers/Microsoft.Cache/CheckNameAvailability" + API_VERSION + config:getAsString(
        "API_VERSION");
        http:Request request = new;
        json checkPayload = {
            "type": "Microsoft.Cache/Redis",
            "name": cacheName
        };
        request.setJsonPayload(checkPayload);
        http:Response checkResponse = <http:Response>check self.AzureRedisClient->post(requestPath, request);
        if (checkResponse.statusCode == http:STATUS_OK) {
            return true;
        } else {
            json responsePayload = check checkResponse.getJsonPayload();
            return getAzureError(checkResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    # This Function Creates a new Redis Cache Instance
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + location - location where redis cache instance created
    # + properties - properties Parameter Description including Pricing tier(Basic, Standard, Premium)
    # + return - If successful, returns RedisCacheInstance. Else returns error. 
    remote function createRedisCache(string redisCacheName, string resourceGroupName, string location, 
                                     CreateCacheProperty properties) returns @tainted RedisCacheInstance|error {
        string requestPath = RESOURCE_GROUP_PATH + resourceGroupName + PROVIDER_PATH + redisCacheName + API_VERSION + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        json createCachePayload = {
            "location": location,
            "properties": {
                "sku": {
                    "name": properties.sku.name,
                    "family": properties.sku.family,
                    "capacity": properties.sku.capacity
                },
                "enableNonSslPort": properties.enableNonSslPort,
                "publicNetworkAccess": properties.publicNetworkAccess
            }
        };
        request.setJsonPayload(createCachePayload);
        http:Response createResponse = <http:Response>check self.AzureRedisClient->put(requestPath, request);
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
    }

    # This Function Deletes a Redis Cache Instance
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + return - If successful, returns boolean. Else returns error. 
    remote function deleteRedisCache(string redisCacheName, string resourceGroupName) returns @tainted boolean|error {
        string requestPath = RESOURCE_GROUP_PATH + resourceGroupName + PROVIDER_PATH + redisCacheName + API_VERSION + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        http:Response deleteResponse = <http:Response>check self.AzureRedisClient->delete(requestPath, request);
        if (deleteResponse.statusCode == http:STATUS_OK || deleteResponse.statusCode == http:STATUS_NO_CONTENT || deleteResponse.statusCode == 
        ACCEPTED) {
            return true;
        } else {
            json responsePayload = check deleteResponse.getJsonPayload();
            return getAzureError(deleteResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    //Requires Premium Azure Redis Cache Instance
    //that your Redis Database (RDB) file or files are uploaded into page or block blobs in Azure storage, in the same region and subscription as your Azure Cache for Redis instance.

    # This Function exports a Redis Cache Instance to any azure storages
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + prefix - file name to be exported 
    # + blobContainerUrl - path to bolb storage 
    # + sasKeyParameters - SAS key
    # + format - file format to which exported
    # + return - If successful, returns boolean. Else returns error. 
    remote function exportRedisCache(string redisCacheName, string resourceGroupName, string prefix, 
                                     string blobContainerUrl, string sasKeyParameters, string? format = ()) 
                                     returns @tainted boolean|error {
        string requestPath = 
        RESOURCE_GROUP_PATH + resourceGroupName + PROVIDER_PATH + redisCacheName + "/export" + API_VERSION + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        json exportCacheJsonPayload = {
            "format": format,
            "prefix": prefix,
            "container": blobContainerUrl + sasKeyParameters
        };
        request.setJsonPayload(exportCacheJsonPayload);
        http:Response exportResponse = <http:Response>check self.AzureRedisClient->post(requestPath, request);
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
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + files - file name to be imported  
    # + format - file format to be imported
    # + return - If successful, returns boolean. Else returns error. 
    remote function importRedisCache(string redisCacheName, string resourceGroupName, string[] files, 
                                     string? format = ()) returns @tainted boolean|error {
        string requestPath = 
        RESOURCE_GROUP_PATH + resourceGroupName + PROVIDER_PATH + redisCacheName + "/import" + API_VERSION + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        json importCacheJsonPayload = {
            "format": format,
            "files": files
        };
        request.setJsonPayload(importCacheJsonPayload);
        http:Response importResponse = <http:Response>check self.AzureRedisClient->post(requestPath, request);
        if (importResponse.statusCode == http:STATUS_OK || importResponse.statusCode == http:STATUS_NO_CONTENT) {
            return true;
        } else if (importResponse.statusCode == ACCEPTED) {
            return true;
        } else {
            json responsePayload = check importResponse.getJsonPayload();
            return getAzureError(importResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    # This Function Fetches a Redis Cache Instance
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + return - If successful, returns RedisCacheInstance. Else returns error. 
    remote function getRedisCache(string redisCacheName, string resourceGroupName) 
    returns @tainted RedisCacheInstance|error {
        string requestPath = RESOURCE_GROUP_PATH + resourceGroupName + PROVIDER_PATH + redisCacheName + API_VERSION + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        http:Response getResponse = <http:Response>check self.AzureRedisClient->get(requestPath, request);
        json responsePayload = check getResponse.getJsonPayload();
        if (getResponse.statusCode == http:STATUS_OK) {
            RedisCacheInstance getRedisCacheResponse = check responsePayload.cloneWithType(RedisCacheInstance);
            return getRedisCacheResponse;
        } else {
            return getAzureError(getResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    # This Function force reboots a Redis Cache Instance
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + shardId - Id od the shard
    # + rebootType - Nodes type which should be rebooted
    # + ports - ports which are to be rebooted
    # + return - If successful, returns StatusCode. Else returns error. 
    remote function forceRebootRedisCache(string redisCacheName, string resourceGroupName, int shardId, 
                                          string rebootType, int[] ports) returns @tainted StatusCode|error {
        string requestPath = 
        RESOURCE_GROUP_PATH + resourceGroupName + PROVIDER_PATH + redisCacheName + "/forceReboot" + API_VERSION + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        json rebootCacheJsonPayload = {
            "shardId": shardId,
            "rebootType": rebootType,
            "ports": ports
        };
        request.setJsonPayload(rebootCacheJsonPayload);
        http:Response rebootResponse = <http:Response>check self.AzureRedisClient->post(requestPath, request);
        json responsePayload = check rebootResponse.getJsonPayload();
        if (rebootResponse.statusCode == http:STATUS_OK) {
            return jsonToStatusCode(rebootResponse.statusCode);
        } else {
            return getAzureError(rebootResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    # This Function Fetches list of Redis Cache Instance in a resource group
    #
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + return - If successful, returns RedisCacheInstance[]. Else returns error. 
    remote function listByResourceGroup(string resourceGroupName) returns @tainted RedisCacheInstance[]|error {
        string requestPath = RESOURCE_GROUP_PATH + resourceGroupName + "/providers/Microsoft.Cache/redis" + API_VERSION + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        http:Response listResponse = <http:Response>check self.AzureRedisClient->get(requestPath, request);
        json responsePayload = check listResponse.getJsonPayload();
        if (listResponse.statusCode == http:STATUS_OK) {
            RedisCacheInstanceList listRedisCacheInstance = check responsePayload.cloneWithType(RedisCacheInstanceList);
            RedisCacheInstance[] listRedisCacheInstanceArray = listRedisCacheInstance.value;
            return listRedisCacheInstanceArray;
        } else {
            return getAzureError(listResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    # This Function Fetches list of Redis Cache Instance in a subscription
    #
    # + return - If successful, returns RedisCacheInstance[]. Else returns error. 
    remote function listBySubscription() returns @tainted RedisCacheInstance[]|error {
        string requestPath = "/providers/Microsoft.Cache/redis" + API_VERSION + config:getAsString("API_VERSION");
        http:Request request = new;
        http:Response listResponse = <http:Response>check self.AzureRedisClient->get(requestPath, request);
        json responsePayload = check listResponse.getJsonPayload();
        if (listResponse.statusCode == http:STATUS_OK) {
            RedisCacheInstanceList listRedisCacheInstance = check responsePayload.cloneWithType(RedisCacheInstanceList);
            RedisCacheInstance[] listRedisCacheInstanceArray = listRedisCacheInstance.value;
            return listRedisCacheInstanceArray;
        } else {
            return getAzureError(listResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    # This Function Fetches list of primary and secondary keys for specific Redis Cache Instance
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + return - If successful, returns AccessKey. Else returns error.
    remote function listKeys(string redisCacheName, string resourceGroupName) returns @tainted AccessKey|error {
        string requestPath = 
        RESOURCE_GROUP_PATH + resourceGroupName + PROVIDER_PATH + redisCacheName + "/listKeys" + API_VERSION + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        http:Response listResponse = <http:Response>check self.AzureRedisClient->post(requestPath, request);
        json responsePayload = check listResponse.getJsonPayload();
        if (listResponse.statusCode == http:STATUS_OK) {
            AccessKey listKeys = check responsePayload.cloneWithType(AccessKey);
            return listKeys;
        } else {
            return getAzureError(listResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    # This Function regenerates primary and secondary keys
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + keyType - keyType (Primary or Secondary to be regenerated) 
    # + return - If successful, returns AccessKey. Else returns error.
    remote function regenerateKey(string redisCacheName, string resourceGroupName, string keyType) returns @tainted 
    AccessKey|error {
        string requestPath = 
        RESOURCE_GROUP_PATH + resourceGroupName + PROVIDER_PATH + redisCacheName + "/regenerateKey" + API_VERSION + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        json regenerateKeyJsonPayload = {"keyType": keyType};
        request.setJsonPayload(regenerateKeyJsonPayload);
        http:Response regenerateResponse = <http:Response>check self.AzureRedisClient->post(requestPath, request);
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
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + properties - properties Parameter Description including Pricing tier(Basic, Standard, Premium)
    # + return - If successful, returns RedisCacheInstance. Else returns error. 
    remote function updateRedisCache(string redisCacheName, string resourceGroupName, string location, CreateCacheProperty properties) returns @tainted 
    RedisCacheInstance|error {
        string requestPath = RESOURCE_GROUP_PATH + resourceGroupName + PROVIDER_PATH + redisCacheName + API_VERSION + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        json updateCacheJsonPayload = {
            "location": location,
            "properties": {
                "sku": {
                    "name": properties.sku.name,
                    "family": properties.sku.family,
                    "capacity": properties.sku.capacity
                },
                "enableNonSslPort": properties.enableNonSslPort,
                "publicNetworkAccess": properties.publicNetworkAccess
            }
        };
        request.setJsonPayload(updateCacheJsonPayload);
        http:Response updateResponse = <http:Response>check self.AzureRedisClient->patch(requestPath, request);
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
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + ruleName - Name of Firewall Rule
    # + startIP - Start IP of permitted range
    # + endIP - End IP of permitted range
    # + return - If successful, returns FirewallRule. Else returns error. 
    remote function createFirewallRule(string redisCacheName, string resourceGroupName, string ruleName, string startIP, 
                                       string endIP) returns @tainted FirewallRule|error {
        string requestPath = 
        RESOURCE_GROUP_PATH + resourceGroupName + PROVIDER_PATH + redisCacheName + "/firewallRules/" + ruleName + API_VERSION + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        json createFilewallRuleJsonPayload = {"properties": {
                "startIP": startIP,
                "endIP": endIP
            }};
        request.setJsonPayload(createFilewallRuleJsonPayload);
        http:Response createResponse = <http:Response>check self.AzureRedisClient->put(requestPath, request);
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
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + ruleName - Name of Firewall Rule Name
    # + return - If successful, returns boolean. Else returns error. 
    remote function deleteFirewallRule(string redisCacheName, string resourceGroupName, string ruleName) 
    returns @tainted boolean|error {
        string requestPath = 
        RESOURCE_GROUP_PATH + resourceGroupName + PROVIDER_PATH + redisCacheName + "/firewallRules/" + ruleName + API_VERSION + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        http:Response deleteResponse = <http:Response>check self.AzureRedisClient->delete(requestPath, request);
        if (deleteResponse.statusCode == http:STATUS_OK || deleteResponse.statusCode == http:STATUS_NO_CONTENT) {
            return true;
        } else {
            json responsePayload = check deleteResponse.getJsonPayload();
            return getAzureError(deleteResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    # This Function Fetches an FireWall rule
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + ruleName - Name of FirewallRule Name
    # + return - If successful, returns FirewallRule. Else returns error. 
    remote function getFirewallRule(string redisCacheName, string resourceGroupName, string ruleName) returns @tainted 
    FirewallRule|error {
        string requestPath = 
        RESOURCE_GROUP_PATH + resourceGroupName + PROVIDER_PATH + redisCacheName + "/firewallRules/" + ruleName + API_VERSION + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        http:Response getResponse = <http:Response>check self.AzureRedisClient->get(requestPath, request);
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
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + return - If successful, returns FirewallRule[]. Else returns error. 
    remote function listFirewallRules(string redisCacheName, string resourceGroupName) returns @tainted 
    FirewallRule[]|error {
        string requestPath = 
        RESOURCE_GROUP_PATH + resourceGroupName + PROVIDER_PATH + redisCacheName + "/firewallRules" + API_VERSION + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        http:Response listResponse = <http:Response>check self.AzureRedisClient->get(requestPath, request);
        json responsePayload = check listResponse.getJsonPayload();
        if (listResponse.statusCode == http:STATUS_OK) {
            FirewallRuleList getFirewallRuleList = check responsePayload.cloneWithType(
            FirewallRuleList);
            FirewallRule[] getFirewallRuleArray = getFirewallRuleList.value;
            return getFirewallRuleArray;
        } else {
            return getAzureError(listResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    //Operations related to Linked server (requires Premium SKU).

    # This Function Creates an Linked server
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + linkedServerName - Name of Linked Server Name
    # + linkedRedisCacheId - Full name of Redis Cache Id
    # + linkedRedisCacheLocation - Location of Linked Server
    # + serverRole - Primary/Secondary
    # + return - If successful, returns LinkedServer. Else returns error. 
    remote function createLinkedServer(string redisCacheName, string resourceGroupName, string linkedServerName, 
                                       string linkedRedisCacheId, string linkedRedisCacheLocation, string serverRole) returns @tainted 
                                       LinkedServer|error {
        string requestPath = 
        RESOURCE_GROUP_PATH + resourceGroupName + PROVIDER_PATH + redisCacheName + "/linkedServers/" + linkedServerName + API_VERSION + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        json createLinkedServerJsonPayload = {"properties": {
                "linkedRedisCacheId": linkedRedisCacheId,
                "linkedRedisCacheLocation": linkedRedisCacheLocation,
                "serverRole": serverRole
            }};
        request.setJsonPayload(createLinkedServerJsonPayload);
        http:Response createResponse = <http:Response>check self.AzureRedisClient->put(requestPath, request);
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
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + linkedServerName - Name of Linked Server Name
    # + return - If successful, returns boolean. Else returns error. 
    remote function deleteLinkedServer(string redisCacheName, string resourceGroupName, string linkedServerName) 
    returns @tainted boolean|error {
        string requestPath = 
        RESOURCE_GROUP_PATH + resourceGroupName + PROVIDER_PATH + redisCacheName + "/linkedServers/" + linkedServerName + API_VERSION + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        http:Response deleteResponse = <http:Response>check self.AzureRedisClient->delete(requestPath, request);
        string statusCode = deleteResponse.statusCode.toString();
        if (deleteResponse.statusCode == http:STATUS_OK || deleteResponse.statusCode == http:STATUS_NO_CONTENT) {
            return true;
        } else {
            json responsePayload = check deleteResponse.getJsonPayload();
            return getAzureError(deleteResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    # This Function Creates an Linked server
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + linkedServerName - Name of Linked Server Name
    # + return - If successful, returns LinkedServer. Else returns error. 
    remote function getLinkedServer(string redisCacheName, string resourceGroupName, string linkedServerName) returns @tainted 
    LinkedServer|error {
        string requestPath = 
        RESOURCE_GROUP_PATH + resourceGroupName + PROVIDER_PATH + redisCacheName + "/linkedServers/" + linkedServerName + API_VERSION + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        http:Response getResponse = <http:Response>check self.AzureRedisClient->get(requestPath, request);
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
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + return - If successful, returns LinkedServer[]. Else returns error. 
    remote function listLinkedServers(string redisCacheName, string resourceGroupName) 
    returns @tainted LinkedServer[]|error {
        string requestPath = 
        RESOURCE_GROUP_PATH + resourceGroupName + PROVIDER_PATH + redisCacheName + "/linkedServers" + API_VERSION + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        http:Response listResponse = <http:Response>check self.AzureRedisClient->get(requestPath, request);
        json responsePayload = check listResponse.getJsonPayload();
        if (listResponse.statusCode == http:STATUS_OK) {
            LinkedServerList getLinkedServerList = check responsePayload.cloneWithType(LinkedServerList);
            LinkedServer[] getLinkedServerArray = getLinkedServerList.value;
            return getLinkedServerArray;
        } else {
            return getAzureError(listResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    //Functions related to patching schedule for Redis cache.

    # This Function Creates or Updates Patch Schedule
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + patchScheduleProperties - Contain properties such as Day of Week and Start Time
    # + return - If successful, returns PatchSchedule. Else returns error. 
    remote function createPatchSchedule(string redisCacheName, string resourceGroupName, 
                                        PatchScheduleProperty? patchScheduleProperties) 
                                        returns @tainted PatchSchedule|error {
        string requestPath = 
        RESOURCE_GROUP_PATH + resourceGroupName + PROVIDER_PATH + redisCacheName + "/patchSchedules/default" + API_VERSION + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        json createPayload = {properties: <json>patchScheduleProperties.cloneWithType(json)};
        request.setJsonPayload(createPayload);
        http:Response createResponse = <http:Response>check self.AzureRedisClient->put(requestPath, request);
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
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + return - If successful, returns boolean. Else returns error. 
    remote function deletePatchSchedule(string redisCacheName, string resourceGroupName) returns @tainted boolean|error {
        string requestPath = 
        RESOURCE_GROUP_PATH + resourceGroupName + PROVIDER_PATH + redisCacheName + "/patchSchedules/default" + API_VERSION + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        http:Response deleteResponse = <http:Response>check self.AzureRedisClient->delete(requestPath, request);
        if (deleteResponse.statusCode == http:STATUS_OK || deleteResponse.statusCode == http:STATUS_NO_CONTENT) {
            return true;
        } else {
            json responsePayload = check deleteResponse.getJsonPayload();
            return getAzureError(deleteResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    # This Function Fetches Patch Schedule
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + return - If successful, returns PatchSchedule. Else returns error. 
    remote function getPatchSchedule(string redisCacheName, string resourceGroupName) 
    returns @tainted PatchSchedule|error {
        string requestPath = 
        RESOURCE_GROUP_PATH + resourceGroupName + PROVIDER_PATH + redisCacheName + "/patchSchedules/default" + API_VERSION + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        http:Response getResponse = <http:Response>check self.AzureRedisClient->get(requestPath, request);
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
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + return - If successful, returns PatchShedule[]. Else returns error. 
    remote function listPatchSchedules(string redisCacheName, string resourceGroupName) returns @tainted 
    PatchSchedule[]|error {
        string requestPath = 
        RESOURCE_GROUP_PATH + resourceGroupName + PROVIDER_PATH + redisCacheName + "/patchSchedules" + API_VERSION + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        http:Response listResponse = <http:Response>check self.AzureRedisClient->get(requestPath, request);
        json responsePayload = check listResponse.getJsonPayload();
        if (listResponse.statusCode == http:STATUS_OK) {
            PatchScheduleList getPatchSheduleList = check responsePayload.cloneWithType(PatchScheduleList);
            PatchSchedule[] getPatchSheduleArray = getPatchSheduleList.value;
            return getPatchSheduleArray;
        } else {
            return getAzureError(listResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    //Operations related to Private Endpoint Connections (requires Premium SKU) Not currently not supported as it is in preview.

    # This Function Add Private Endpoint Connection
    #
    # + redisCacheName - Redis Cache Instance Name. 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + privateEndpointConnectionName - Name of Private Endpoint Connection
    # + return - If successful, returns PrivateEndpointConnection. Else returns error. 
    remote function putPrivateEndpointConnection(string redisCacheName, string resourceGroupName, 
                                                 string privateEndpointConnectionName, string status, string description) returns @tainted PrivateEndpointConnection|error {
        string requestPath = 
        RESOURCE_GROUP_PATH + resourceGroupName + PROVIDER_PATH + redisCacheName + "/privateEndpointConnections/" + 
        privateEndpointConnectionName + API_VERSION + config:getAsString("API_VERSION");
        http:Request request = new;
        json putPrivateEndpointConnectionJsonPayload = {"properties": {"privateLinkServiceConnectionState": {
                    "status": status,
                    "description": description
                }}};
        request.setJsonPayload(putPrivateEndpointConnectionJsonPayload);
        http:Response putResponse = <http:Response>check self.AzureRedisClient->put(requestPath, request);
        json responsePayload = check putResponse.getJsonPayload();
        log:print(responsePayload.toString());
        if (putResponse.statusCode == http:STATUS_CREATED) {
            PrivateEndpointConnection getPrivateEndpointConnection = check responsePayload.cloneWithType(PrivateEndpointConnection);
            return getPrivateEndpointConnection;
        } else {
            return getAzureError(putResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    # This Function Fetches Private Endpoint Connection
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + privateEndpointConnectionName - Name of Private Endpoint Connection
    # + return - If successful, returns PrivateEndpointConnection. Else returns error. 
    remote function getPrivateEndpointConnection(string redisCacheName, string resourceGroupName, 
                                                 string privateEndpointConnectionName) returns @tainted PrivateEndpointConnection|error {
        string requestPath = 
        RESOURCE_GROUP_PATH + resourceGroupName + PROVIDER_PATH + redisCacheName + "/privateEndpointConnections/" + 
        privateEndpointConnectionName + API_VERSION + config:getAsString("API_VERSION");
        http:Request request = new;
        http:Response getResponse = <http:Response>check self.AzureRedisClient->get(requestPath, request);
        json responsePayload = check getResponse.getJsonPayload();
        if (getResponse.statusCode == http:STATUS_OK) {
            PrivateEndpointConnection getPrivateEndpointConnection = check responsePayload.cloneWithType(PrivateEndpointConnection);
            return getPrivateEndpointConnection;
        } else {
            return getAzureError(getResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    # This Function Fetches Private Endpoint Connection
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + return - If successful, returns PrivateEndpointConnection[]. Else returns error.
    remote function listPrivateEndpointConnection(string redisCacheName, string resourceGroupName) returns @tainted 
    PrivateEndpointConnection[]|error {
        string requestPath = 
        RESOURCE_GROUP_PATH + resourceGroupName + PROVIDER_PATH + redisCacheName + "/privateEndpointConnections" + API_VERSION + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        http:Response listResponse = <http:Response>check self.AzureRedisClient->get(requestPath, request);
        json responsePayload = check listResponse.getJsonPayload();
        if (listResponse.statusCode == http:STATUS_OK) {
            PrivateEndpointConnectionList getPrivateEndpointConnection = check responsePayload.cloneWithType(PrivateEndpointConnectionList);
            PrivateEndpointConnection[] getPrivateEndpointConnectionArray = getPrivateEndpointConnection.value;
            return getPrivateEndpointConnectionArray;
        } else {
            return getAzureError(listResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    # This Function Deletes Private Endpoint Connection
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + privateEndpointConnectionName - Name of Private Endpoint Connection
    # + return - If successful, returns boolean. Else returns error.
    remote function deletePrivateEndpointConnection(string redisCacheName, string resourceGroupName, 
                                                    string privateEndpointConnectionName) 
                                                    returns @tainted boolean|error {
        string requestPath = 
        RESOURCE_GROUP_PATH + resourceGroupName + PROVIDER_PATH + redisCacheName + "/privateEndpointConnections/" + 
        privateEndpointConnectionName + API_VERSION + config:getAsString("API_VERSION");
        http:Request request = new;
        http:Response deleteResponse = <http:Response>check self.AzureRedisClient->delete(requestPath, request);
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
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + return - If successful, returns PrivateLinkResource. Else returns error.
    remote function getPrivateLinkResources(string redisCacheName, string resourceGroupName) 
    returns @tainted PrivateLinkResource|error {
        string requestPath = 
        RESOURCE_GROUP_PATH + resourceGroupName + PROVIDER_PATH + redisCacheName + "/privateLinkResources" + API_VERSION + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        http:Response getResponse = <http:Response>check self.AzureRedisClient->get(requestPath, request);
        json responsePayload = check getResponse.getJsonPayload();
        if (getResponse.statusCode == http:STATUS_OK) {
            PrivateLinkResource getPrivateLinkResource = check responsePayload.cloneWithType(
            PrivateLinkResource);
            return getPrivateLinkResource;
        } else {
            return getAzureError(getResponse.statusCode.toString() + SPACE + responsePayload.toString());
        }
    }

    //Functions related to Redis enterprise only available is Public Preview Edition released

    # This Function Creates a new Redis Enterprise Cluster
    #
    # + redisEnterpriseClusterName - Redis Enterprise ClusterName. 
    # + resourceGroupName - Resource Group Name where Redis Enterprise found.
    # + location - Location specifies Server Location. 
    # + skuName - provide information about Enterprise Allowed Names Only.
    # + skuCapacity - provide information about capacity.
    # + return - If successful, returns RedisEnterpriseInstance. Else returns error. 
    remote function createRedisEnterprise(string redisEnterpriseClusterName, string resourceGroupName, string location, 
                                          string skuName, int skuCapacity, string[] zones, string tags, CreateEnterpriseCacheProperty properties) 
                                          returns @tainted RedisEnterpriseInstance|error {
        string requestPath = RESOURCE_GROUP_PATH + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
        redisEnterpriseClusterName + API_VERSION + config:getAsString("ENTERPRISE_API_VERSION");
        http:Request request = new;
        json createEnterpriseCacheJsonPayload = {
            "location": location,
            "sku": {
                "name": skuName,
                "capacity": skuCapacity
            },
            "zones": zones,
            "properties": properties,
            "tags": {"tag1": tags }
        };
        request.setJsonPayload(createEnterpriseCacheJsonPayload);
        http:Response createResponse = <http:Response>check self.AzureRedisClient->put(requestPath, request);
        json responsePayload = check createResponse.getJsonPayload();
        if (createResponse.statusCode == http:STATUS_OK) {
            RedisEnterpriseInstance redisEnterpriseResponse = check responsePayload.cloneWithType(
            RedisEnterpriseInstance);
            return redisEnterpriseResponse;
        } else if (createResponse.statusCode == http:STATUS_CREATED) {
            RedisEnterpriseInstance redisEnterpriseResponse = check responsePayload.cloneWithType(
            RedisEnterpriseInstance);
            return redisEnterpriseResponse;
        } else {
            return getAzureError(responsePayload.toString());
        }
    }

    # This Function Fetches a Redis Enterprise Cluster
    #
    # + redisEnterpriseClusterName - Redis Enterprise ClusterName 
    # + resourceGroupName - Resource Group Name where Redis Enterprise found.
    # + return - If successful, returns RedisEnterpriseInstance. Else returns error. 
    remote function getRedisEnterprise(string redisEnterpriseClusterName, string resourceGroupName) returns @tainted 
    RedisEnterpriseInstance|error {
        string requestPath = RESOURCE_GROUP_PATH + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
        redisEnterpriseClusterName + API_VERSION + config:getAsString("ENTERPRISE_API_VERSION");
        http:Request request = new;
        http:Response getResponse = <http:Response>check self.AzureRedisClient->get(requestPath, request);
        json responsePayload = check getResponse.getJsonPayload();
        if (getResponse.statusCode == http:STATUS_OK) {
            RedisEnterpriseInstance getRedisEnterprise = check responsePayload.cloneWithType(RedisEnterpriseInstance);
            return getRedisEnterprise;
        } else {
            return getAzureError(responsePayload.toString());
        }
    }

    # This Function Deletes a Redis Enterprise Cluster
    #
    # + redisEnterpriseClusterName - Redis Enterprise ClusterName 
    # + resourceGroupName - Resource Group Name where Redis Enterprise found.
    # + return - If successful, returns boolean. Else returns error. 
    remote function deleteRedisEnterprise(string redisEnterpriseClusterName, string resourceGroupName) 
    returns @tainted boolean|error {
        string requestPath = RESOURCE_GROUP_PATH + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
        redisEnterpriseClusterName + API_VERSION + config:getAsString("ENTERPRISE_API_VERSION");
        http:Request request = new;
        http:Response deleteResponse = <http:Response>check self.AzureRedisClient->delete(requestPath, request);
        string responsePayload = deleteResponse.getJsonPayload().toString();
        if (deleteResponse.statusCode == http:STATUS_OK || deleteResponse.statusCode == http:STATUS_NO_CONTENT) {
            return true;
        } else if (deleteResponse.statusCode == ACCEPTED) {
            return true;
        } else {
            return getAzureError(deleteResponse.toString());
        }
    }

    # This Function Fetches a list of Redis Enterprise Cluster in a subscription
    # 
    # + return - If successful, returns RedisEnterpriseInstance[]. Else returns error. 
    remote function listRedisEnterprise() returns @tainted RedisEnterpriseInstance[]|error {
        string requestPath = "/providers/Microsoft.Cache/redisEnterprise" + API_VERSION + config:getAsString(
        "ENTERPRISE_API_VERSION");
        http:Request request = new;
        http:Response listResponse = <http:Response>check self.AzureRedisClient->get(requestPath, request);
        json responsePayload = check listResponse.getJsonPayload();
        if (listResponse.statusCode == http:STATUS_OK) {
            RedisEnterpriseInstanceList getRedisEnterpriseList = check responsePayload.cloneWithType(
            RedisEnterpriseInstanceList);
            RedisEnterpriseInstance[] getRedisEnterpriseArray = getRedisEnterpriseList.value;
            return getRedisEnterpriseArray;
        } else {
            return getAzureError(responsePayload.toString());
        }
    }

    # This Function Fetches a Redis Enterprise Cluster in a subscription within a specific resource group
    # 
    # + resourceGroupName - Resource Group Name where Redis Enterprise found.
    # + return - If successful, returns RedisEnterpriseInstance[]. Else returns error. 
    remote function listRedisEnterpriseByResourceGroup(string resourceGroupName) returns @tainted 
    RedisEnterpriseInstance[]|error {
        string requestPath = 
        RESOURCE_GROUP_PATH + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise" + API_VERSION + 
        config:getAsString("ENTERPRISE_API_VERSION");
        http:Request request = new;
        http:Response listResponse = <http:Response>check self.AzureRedisClient->get(requestPath, request);
        json responsePayload = check listResponse.getJsonPayload();
        if (listResponse.statusCode == http:STATUS_OK) {
            RedisEnterpriseInstanceList getRedisEnterpriseList = check responsePayload.cloneWithType(
            RedisEnterpriseInstanceList);
            RedisEnterpriseInstance[] getRedisEnterpriseArray = getRedisEnterpriseList.value;
            return getRedisEnterpriseArray;
        } else {
            return getAzureError(responsePayload.toString());
        }
    }

    //This function is currently not supported at the moment as stated in Azure Redis REST API Documentation.

    # This Function Updates the Redis Enterprise Cluster
    #  
    # + redisEnterpriseClusterName - Redis Enterprise ClusterName 
    # + resourceGroupName - Resource Group Name where Redis Enterprise found.
    # + return - If successful, returns RedisEnterpriseInstance. Else returns error. 
    remote function updateRedisEnterprise(string redisEnterpriseClusterName, string resourceGroupName, string location, 
                                          string skuName, int skuCapacity, string[] zones, string tags, CreateEnterpriseCacheProperty properties) returns @tainted 
                                          RedisEnterpriseInstance|error {
        string requestPath = RESOURCE_GROUP_PATH + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
        redisEnterpriseClusterName + API_VERSION + config:getAsString("ENTERPRISE_API_VERSION");
        http:Request request = new;
        json updateCacheJsonPayload = {
            "location": location,
            "sku": {
                "name": skuName,
                "capacity": skuCapacity
            },
            "zones": zones,
            "properties": properties,
            "tags": {"tag1": tags }
        };
        request.setJsonPayload(updateCacheJsonPayload);
        http:Response updateResponse = <http:Response>check self.AzureRedisClient->patch(requestPath, request);
        json responsePayload = check updateResponse.getJsonPayload();
        if (updateResponse.statusCode == http:STATUS_OK) {
            RedisEnterpriseInstance updatedRedisEnterprise = check responsePayload.cloneWithType(RedisEnterpriseInstance);
            return updatedRedisEnterprise;
        } else {
            return getAzureError(responsePayload.toString());
        }
    }

    //Function related to Redis enterprise cache Databases

    # This Function Creates Redis Enterprise Cache Database
    #
    # + redisEnterpriseName - Redis Enterprise Cache Database Name
    # + resourceGroupName - Resource Group Name where Redis Cache found
    # + databaseName - Name of Database Name
    # + return - If successful, returns RedisEnterpriseDatabase. Else returns error 
    remote function createRedisEnterpriseDatabase(string redisEnterpriseName, string resourceGroupName, 
                                                  string databaseName, CreateEnterpriseDBProperty properties) 
                                                  returns @tainted RedisEnterpriseDatabase|error {
        string requestPath = RESOURCE_GROUP_PATH + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
        redisEnterpriseName + "/databases/" + databaseName + API_VERSION + config:getAsString(
        "ENTERPRISE_API_VERSION");
        http:Request request = new;
        json createEnterpriseCacheDBJsonPayload = {"properties": {
                "clientProtocol": properties.clientProtocol,
                "clusteringPolicy": properties.clusteringPolicy,
                "evictionPolicy": properties.evictionPolicy,
                "port": properties.port,
                "modules": properties.modules
            }};
        request.setJsonPayload(createEnterpriseCacheDBJsonPayload);
        http:Response createResponse = <http:Response>check self.AzureRedisClient->put(requestPath, request);
        json responsePayload = check createResponse.getJsonPayload();
        if (createResponse.statusCode == http:STATUS_OK || createResponse.statusCode == http:STATUS_CREATED) {
            RedisEnterpriseDatabase getRedisEnterpriseDatabase = check responsePayload.cloneWithType(RedisEnterpriseDatabase);
            return getRedisEnterpriseDatabase;
        } else {
            return getAzureError(responsePayload.toString());
        }
    }

    # This Function Deletes Redis Enterprise Cache Database
    #
    # + redisEnterpriseName - Redis Enterprise Cache Database Name. 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + databaseName - Name of Database Name
    # + return - If successful, returns boolean. Else returns error. 
    remote function deleteRedisEnterpriseDatabase(string redisEnterpriseName, string resourceGroupName, 
                                                  string databaseName) returns @tainted boolean|error {
        string requestPath = RESOURCE_GROUP_PATH + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
        redisEnterpriseName + "/databases/" + databaseName + API_VERSION + config:getAsString(
        "ENTERPRISE_API_VERSION");
        http:Request request = new;
        http:Response deleteResponse = <http:Response>check self.AzureRedisClient->delete(requestPath, request);
        json responsePayload = check deleteResponse.getJsonPayload();
        if (deleteResponse.statusCode == http:STATUS_OK || deleteResponse.statusCode == http:STATUS_NO_CONTENT) {
            return true;
        } else if (deleteResponse.statusCode == ACCEPTED) {
            return true;
        } else {
            return getAzureError(responsePayload.toString());
        }
    }

    # This Function exports Redis Enterprise Cache Database
    #
    # + redisEnterpriseName - Redis Enterprise Cache Database Name. 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + databaseName - Name of Database Name
    # + blobContainerUrl - path to bolb container 
    # + sasKeyParameters - SAS key of storage resource
    # + return - If successful, returns boolean. Else returns error. 
    remote function exportRedisEnterpriseDatabase(string redisEnterpriseName, string resourceGroupName, 
                                                  string databaseName, string blobContainerUrl, string sasKeyParameters) returns @tainted 
                                                  boolean|error {
        string requestPath = RESOURCE_GROUP_PATH + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
        redisEnterpriseName + "/databases/" + databaseName + "/export" + API_VERSION + config:getAsString(
        "ENTERPRISE_API_VERSION");
        http:Request request = new;
        json exportCacheJsonPayload = {"sasUri": blobContainerUrl + "?" + sasKeyParameters};
        request.setJsonPayload(exportCacheJsonPayload);
        http:Response exportResponse = <http:Response>check self.AzureRedisClient->post(requestPath, request);
        json responsePayload = check exportResponse.getJsonPayload();
        if (exportResponse.statusCode == http:STATUS_OK || exportResponse.statusCode == http:STATUS_NO_CONTENT || exportResponse.statusCode == ACCEPTED) {
            return true;
        } else {
            return getAzureError(responsePayload.toString());
        }
    }

    # This Function imports Redis Enterprise Cache Database
    #
    # + redisEnterpriseName - Redis Enterprise Cache Database Name. 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + databaseName - Name of Database Name
    # + blobFileUrl - path to bolb file storage 
    # + sasKeyParameters - SAS key
    # + return - If successful, returns boolean. Else returns error. 
    remote function importRedisEnterpriseDatabase(string redisEnterpriseName, string resourceGroupName, 
                                                  string databaseName, string blobFileUrl, string sasKeyParameters) returns @tainted 
                                                  boolean|error {
        string requestPath = RESOURCE_GROUP_PATH + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
        redisEnterpriseName + "/databases/" + databaseName + "/import" + API_VERSION + config:getAsString(
        "ENTERPRISE_API_VERSION");
        http:Request request = new;
        json importCacheJsonPayload = {"sasUri": blobFileUrl + "?" + sasKeyParameters};
        request.setJsonPayload(importCacheJsonPayload);
        http:Response importResponse = <http:Response>check self.AzureRedisClient->post(requestPath, request);
        json responsePayload = check importResponse.getJsonPayload();
        if (importResponse.statusCode == http:STATUS_OK || importResponse.statusCode == http:STATUS_NO_CONTENT || importResponse.statusCode == ACCEPTED) {
            return true;
        } else {
            return getAzureError(responsePayload.toString());
        }
    }

    # This Function Fetches Redis Enterprise Cache Database
    #
    # + redisEnterpriseName - Redis Enterprise Cache Database Name. 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + databaseName - Name of Database Name
    # + return - If successful, returns RedisEnterpriseDatabase. Else returns error. 
    remote function getRedisEnterpriseDatabase(string redisEnterpriseName, string resourceGroupName, string databaseName) returns @tainted 
    RedisEnterpriseDatabase|error {
        string requestPath = RESOURCE_GROUP_PATH + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
        redisEnterpriseName + "/databases/" + databaseName + API_VERSION + config:getAsString(
        "ENTERPRISE_API_VERSION");
        http:Request request = new;
        http:Response getResponse = <http:Response>check self.AzureRedisClient->get(requestPath, request);
        json responsePayload = check getResponse.getJsonPayload();
        if (getResponse.statusCode == http:STATUS_OK) {
            RedisEnterpriseDatabase getRedisEnterpriseDatabase = check responsePayload.cloneWithType(RedisEnterpriseDatabase);
            return getRedisEnterpriseDatabase;
        } else {
            return getAzureError(responsePayload.toString());
        }
    }

    # This Function lists Redis Enterprise Cache Database
    #
    # + redisEnterpriseName - Redis Enterprise Cache Database Name. 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + return - If successful, returns RedisEnterpriseDatabase[]. Else returns error. 
    remote function listRedisEnterpriseDatabaseByCluster(string redisEnterpriseName, string resourceGroupName) returns @tainted 
    RedisEnterpriseDatabase[]|error {
        string requestPath = RESOURCE_GROUP_PATH + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
        redisEnterpriseName + "/databases" + API_VERSION + config:getAsString("ENTERPRISE_API_VERSION");
        http:Request request = new;
        http:Response listResponse = <http:Response>check self.AzureRedisClient->get(requestPath, request);
        json responsePayload = check listResponse.getJsonPayload();
        if (listResponse.statusCode == http:STATUS_OK) {
            RedisEnterpriseDatabaseList getRedisEnterpriseDatabaseList = check responsePayload.cloneWithType(RedisEnterpriseDatabaseList);
            RedisEnterpriseDatabase[] getRedisEnterpriseDatabaseArray = getRedisEnterpriseDatabaseList.value;
            return getRedisEnterpriseDatabaseArray;
        } else {
            return getAzureError(responsePayload.toString());
        }
    }

    # This Function lists Redis Enterprise Cache Database Keys
    #
    # + redisEnterpriseName - Redis Enterprise Cache Database Name. 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + return - If successful, returns AccessKey. Else returns error. 
    remote function listRedisEnterpriseDatabaseKeys(string redisEnterpriseName, string resourceGroupName, 
                                                    string databaseName) returns @tainted AccessKey|error {
        string requestPath = RESOURCE_GROUP_PATH + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
        redisEnterpriseName + "/databases/" + databaseName + "/listKeys" + API_VERSION + config:getAsString(
        "ENTERPRISE_API_VERSION");
        http:Request request = new;
        http:Response listResponse = <http:Response>check self.AzureRedisClient->post(requestPath, request);
        json responsePayload = check listResponse.getJsonPayload();
        if (listResponse.statusCode == http:STATUS_OK) {
            AccessKey listKeys = check responsePayload.cloneWithType(AccessKey);
            return listKeys;
        } else {
            return getAzureError(responsePayload.toString());
        }
    }

    # This Function Regenerates Redis Enterprise Cache Database Key
    #
    # + redisEnterpriseName - Redis Enterprise Cache Database Name. 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + databaseName - Name of Database Name
    # + return - If successful, returns AccessKey. Else returns error. 
    remote function regenerateRedisEnterpriseDatabaseKey(string redisEnterpriseName, string resourceGroupName, 
                                                         string databaseName, string keyType) returns @tainted 
                                                         AccessKey|error {
        string requestPath = RESOURCE_GROUP_PATH + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
        redisEnterpriseName + "/databases/" + databaseName + "/regenerateKey" + API_VERSION + config:getAsString(
        "ENTERPRISE_API_VERSION");
        http:Request request = new;
        json regenerateKeyJsonPayload = {"keyType": keyType};
        request.setJsonPayload(regenerateKeyJsonPayload);
        http:Response regenerateResponse = <http:Response>check self.AzureRedisClient->post(requestPath, request);
        json responsePayload = check regenerateResponse.getJsonPayload();
        if (regenerateResponse.statusCode == http:STATUS_OK || regenerateResponse.statusCode == ACCEPTED) {
            AccessKey listKeys = check responsePayload.cloneWithType(AccessKey);
            return listKeys;
        } else {
            return getAzureError(responsePayload.toString());
        }
    }

    //This function is currently not supported at the moment as stated in Azure Redis REST API Documentation.

    # This Function Updates Redis Enterprise Cache Database
    #
    # + redisEnterpriseName - Redis Enterprise Cache Database Name. 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + databaseName - Name of Database Name
    # + clientProtocol - Encrypted or Plaintext
    # + moduleName - The name of the module (RedisBloom, RediSearch, RedisTimeSeries)
    # + evictionPolicy - Redis eviction policy(Default is VolatileLRU)
    # 
    # + return - If successful, returns RedisEnterpriseDatabase. Else returns error. 
    remote function updateRedisEnterpriseDatabase(string redisEnterpriseName, string resourceGroupName, 
                                                  string databaseName, string clientProtocol, string evictionPolicy, 
                                                  string moduleName) returns @tainted RedisEnterpriseDatabase|error {
        string requestPath = RESOURCE_GROUP_PATH + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
        redisEnterpriseName + "/databases/" + databaseName + API_VERSION + config:getAsString(
        "ENTERPRISE_API_VERSION");
        http:Request request = new;
        json updateCacheJsonPayload = {"properties": {
                "clientProtocol": clientProtocol,
                "evictionPolicy": evictionPolicy,
                "modules": [{"name": moduleName}]
            }};
        request.setJsonPayload(updateCacheJsonPayload);
        http:Response updateResponse = <http:Response>check self.AzureRedisClient->patch(requestPath, request);
        json responsePayload = check updateResponse.getJsonPayload();
        if (updateResponse.statusCode == http:STATUS_OK) {
            RedisEnterpriseDatabase updateRedisEnterpriseDatabase = check responsePayload.cloneWithType(RedisEnterpriseDatabase);
            return updateRedisEnterpriseDatabase;
        } else {
            return getAzureError(responsePayload.toString());
        }
    }

    //Operations related to Private Endpoint Connections (requires Premium SKU) Not currently not supported as it is in preview.

    # This Function Add Private Endpoint Connection of Redis Enterprise Cache
    #
    # + redisEnterpriseCacheName - Redis Enterprise Cache Instance Name. 
    # + resourceGroupName - Resource Group Name where Redis Enterprise Cache found.
    # + privateEndpointConnectionName - Name of Private Endpoint Connection
    # + return - If successful, returns PrivateEndpointConnection. Else returns error. 
    remote function putPrivateEndpointConnectionEnterprise(string redisEnterpriseCacheName, string resourceGroupName, 
                                                           string privateEndpointConnectionName, string status, string description) 
                                                           returns @tainted PrivateEndpointConnection|error {
        string requestPath = 
        RESOURCE_GROUP_PATH + resourceGroupName + PROVIDER_PATH + redisEnterpriseCacheName + "/privateEndpointConnections/" + 
        privateEndpointConnectionName + API_VERSION + config:getAsString("ENTERPRISE_API_VERSION");
        http:Request request = new;
        json putPrivateEndpointConnectionJsonPayload = {"properties": {"privateLinkServiceConnectionState": {
                    "status": status,
                    "description": description
                }}};
        request.setJsonPayload(putPrivateEndpointConnectionJsonPayload);
        http:Response putResponse = <http:Response>check self.AzureRedisClient->put(requestPath, request);
        json responsePayload = check putResponse.getJsonPayload();
        log:print(responsePayload.toString());
        if (putResponse.statusCode == http:STATUS_CREATED) {
            log:print(responsePayload.toString());
            PrivateEndpointConnection getPrivateEndpointConnection = check responsePayload.cloneWithType(PrivateEndpointConnection);
            return getPrivateEndpointConnection;
        } else {
            return getAzureError(responsePayload.toString());
        }
    }

    # This Function Fetches Private Endpoint Connection of Redis Enterprise Cache
    #
    # + redisEnterpriseCacheName - Redis Enterprise Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Enterprise Cache found.
    # + privateEndpointConnectionName - Name of Private Endpoint Connection
    # + return - If successful, returns PrivateEndpointConnection. Else returns error. 
    remote function getPrivateEndpointConnectionEnterprise(string redisEnterpriseCacheName, string resourceGroupName, 
                                                           string privateEndpointConnectionName) 
                                                           returns @tainted PrivateEndpointConnection|error {
        string requestPath = 
        RESOURCE_GROUP_PATH + resourceGroupName + PROVIDER_PATH + redisEnterpriseCacheName + "/privateEndpointConnections/" + 
        privateEndpointConnectionName + API_VERSION + config:getAsString("ENTERPRISE_API_VERSION");
        http:Request request = new;
        http:Response getResponse = <http:Response>check self.AzureRedisClient->get(requestPath, request);
        json responsePayload = check getResponse.getJsonPayload();
        if (getResponse.statusCode == http:STATUS_OK) {
            PrivateEndpointConnection getPrivateEndpointConnection = check responsePayload.cloneWithType(PrivateEndpointConnection);
            return getPrivateEndpointConnection;
        } else {
            return getAzureError(responsePayload.toString());
        }
    }

    # This Function Fetches Private Endpoint Connection of Redis Enterprise Cache
    #
    # + redisEnterpriseCacheName - Redis Enterprise Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Enterprise Cache found.
    # + return - If successful, returns PrivateEndpointConnection[]. Else returns error.
    remote function listPrivateEndpointConnectionEnterprise(string redisEnterpriseCacheName, string resourceGroupName) returns @tainted 
    PrivateEndpointConnection[]|error {
        string requestPath = 
        RESOURCE_GROUP_PATH + resourceGroupName + PROVIDER_PATH + redisEnterpriseCacheName + "/privateEndpointConnections" + API_VERSION + 
        config:getAsString("ENTERPRISE_API_VERSION");
        http:Request request = new;
        http:Response listResponse = <http:Response>check self.AzureRedisClient->get(requestPath, request);
        json responsePayload = check listResponse.getJsonPayload();
        if (listResponse.statusCode == http:STATUS_OK) {
            PrivateEndpointConnectionList getPrivateEndpointConnection = check responsePayload.cloneWithType(PrivateEndpointConnectionList);
            PrivateEndpointConnection[] getPrivateEndpointConnectionArray = getPrivateEndpointConnection.value;
            return getPrivateEndpointConnectionArray;
        } else {
            return getAzureError(responsePayload.toString());
        }
    }

    # This Function Deletes Private Endpoint Connection of Redis Enterprise Cache
    #
    # + redisEnterpriseCacheName - Redis Cache Enterprise Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Enterprise Cache found.
    # + privateEndpointConnectionName - Name of Private Endpoint Connection
    # + return - If successful, returns boolean. Else returns error.
    remote function deletePrivateEndpointConnectionEnterprise(string redisEnterpriseCacheName, string resourceGroupName, 
                                                              string privateEndpointConnectionName) 
                                                              returns @tainted boolean|error {
        string requestPath = 
        RESOURCE_GROUP_PATH + resourceGroupName + PROVIDER_PATH + redisEnterpriseCacheName + "/privateEndpointConnections/" + 
        privateEndpointConnectionName + API_VERSION + config:getAsString("ENTERPRISE_API_VERSION");
        http:Request request = new;
        http:Response deleteResponse = <http:Response>check self.AzureRedisClient->delete(requestPath, request);
        json responsePayload = check deleteResponse.getJsonPayload();
        if (deleteResponse.statusCode == http:STATUS_OK || deleteResponse.statusCode == http:STATUS_NO_CONTENT) {
            return true;
        } else {
            return getAzureError(responsePayload.toString());
        }
    }
}
