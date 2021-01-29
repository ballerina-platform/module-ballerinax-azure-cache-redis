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
import ballerina/io;
import ballerina/oauth2;
import ballerina/config;

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
    # + return - If successful, returns StatusCode. Else returns error. 
    remote function checkRedisCacheNameAvailability(string cacheName) returns @tainted boolean|error {

        if (cacheName == EMPTY_STRING) {
            return createCustomError("Required values not provided");
        }

        string requestPath = "/providers/Microsoft.Cache/CheckNameAvailability?api-version=" + config:getAsString(
        "API_VERSION");
        http:Request request = new;
        json checkPayload = {
            "type": "Microsoft.Cache/Redis",
            "name": cacheName
        };
        request.setJsonPayload(checkPayload);
        http:Response getResponse = <http:Response> check self.AzureRedisClient->post(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        json responsePayload = check getResponse.getJsonPayload();
        if (statusCode == OK) {
            return true;
        } else {
            return createAzureError(responsePayload.toString());
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

        if (redisCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING || location == EMPTY_STRING) {
            return createCustomError("Required values not provided");
        }

        string requestPath = "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + 
        redisCacheName + "?api-version=" + config:getAsString("API_VERSION");
        http:Request request = new;
        json createCachePayload = {
            "location": location,
            "properties": {
                "sku": {
                    "name": properties.sku.name,
                    "family": properties.sku.family,
                    "capacity": properties.sku.capacity
                },
                "enableNonSslPort": properties.enableNonSslPort
            }
        };
        request.setJsonPayload(createCachePayload);
        http:Response createResponse = <http:Response> check self.AzureRedisClient->put(requestPath, request);
        string statusCode = createResponse.statusCode.toString();
        string responsePayloadtest = createResponse.getJsonPayload().toString();
        json responsePayload = check createResponse.getJsonPayload();
        if (statusCode == OK) {
            io:println("Existing Azure Redis Cache Updated");
            RedisCacheInstance getRedisCacheResponse = check responsePayload.cloneWithType(RedisCacheInstance);
            return getRedisCacheResponse;
        } else if (statusCode == CREATED) {
            io:println("New Azure Redis Cache Created");
            RedisCacheInstance getRedisCacheResponse = check responsePayload.cloneWithType(RedisCacheInstance);
            return getRedisCacheResponse;
        } else {
            return createAzureError(responsePayload.toString());
        }
    }

    # This Function Deletes a Redis Cache Instance
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + return - If successful, returns StatusCode. Else returns error. 
    remote function deleteRedisCache(string redisCacheName, string resourceGroupName) returns @tainted StatusCode|error {

        if (redisCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING) {
            return createCustomError("Required values not provided");
        }

        string requestPath = "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + 
        redisCacheName + "?api-version=" + config:getAsString("API_VERSION");
        http:Request request = new;
        http:Response deleteResponse = <http:Response> check self.AzureRedisClient->delete(requestPath, request);
        string statusCode = deleteResponse.statusCode.toString();
        if (statusCode == OK || statusCode == NO_CONTENT) {
            io:println("Redis cache was successfully deleted");
            return jsonToStatusCode(statusCode);
        } else if (statusCode == ACCEPTED) {
            io:println("Redis cache delete operation was successfully enqueued");
            return jsonToStatusCode(statusCode);
        } else {
            return createAzureError(responsePayload.toString());
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
    # + return - If successful, returns StatusCode. Else returns error. 
    remote function exportRedisCache(string redisCacheName, string resourceGroupName, string prefix, 
                                     string blobContainerUrl, string sasKeyParameters, string? format = ()) returns @tainted 
                                     StatusCode|error {

        if (redisCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING || prefix == EMPTY_STRING || 
        blobContainerUrl == EMPTY_STRING) {
            return createAzureError("Required values not provided");
        }

        string requestPath = "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + 
        redisCacheName + "/export?api-version=" + config:getAsString("API_VERSION");
        http:Request request = new;
        json exportCacheJsonPayload = {
            "format": format,
            "prefix": prefix,
            "container": blobContainerUrl + sasKeyParameters
        };
        request.setJsonPayload(exportCacheJsonPayload);
        http:Response exportResponse = <http:Response> check self.AzureRedisClient->post(requestPath, request);
        string statusCode = exportResponse.statusCode.toString();
        json responsePayload = check exportResponse.getJsonPayload();
        if (statusCode == OK || statusCode == NO_CONTENT) {
            io:println("Redis cache was successfully exported");
            return jsonToStatusCode(statusCode);
        } else if (statusCode == ACCEPTED) {
            io:println("Redis cache export operation was successfully enqueued");
            return jsonToStatusCode(statusCode);
        } else {
            return createAzureError(responsePayload.toString());
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
    # + return - If successful, returns StatusCode. Else returns error. 
    remote function importRedisCache(string redisCacheName, string resourceGroupName, string[] files, 
                                     string? format = ()) returns @tainted StatusCode|error {

        if (redisCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING || files[0] == EMPTY_STRING) {
            return createCustomError("Required values not provided");
        }

        string requestPath = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/import?api-version=" + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        json importCacheJsonPayload = {
            "format": format,
            "files": files
        };
        request.setJsonPayload(importCacheJsonPayload);
        http:Response importResponse = <http:Response> check self.AzureRedisClient->post(requestPath, request);
        string statusCode = importResponse.statusCode.toString();
        json responsePayload = check importResponse.getJsonPayload();
        if (statusCode == OK || statusCode == NO_CONTENT) {
            io:println("Redis cache was successfully imported");
            return jsonToStatusCode(statusCode);
        } else if (statusCode == ACCEPTED) {
            io:println("Redis cache import operation was successfully enqueued");
            return jsonToStatusCode(statusCode);
        } else {
            return createAzureError(responsePayload.toString());
        }
    }

    # This Function Fetches a Redis Cache Instance
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + return - If successful, returns RedisCacheInstance. Else returns error. 
    remote function getRedisCache(string redisCacheName, string resourceGroupName) 
    returns @tainted RedisCacheInstance|error {

        if (redisCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING) {
            return createCustomError("Required values not provided");
        }

        string requestPath = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "?api-version=" + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        http:Response getResponse = <http:Response> check self.AzureRedisClient->get(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        json responsePayload = check getResponse.getJsonPayload();
        if (statusCode == OK) {
            io:println("Redis cache was successfully fetched");
            RedisCacheInstance getRedisCacheResponse = check responsePayload.cloneWithType(RedisCacheInstance);
            return getRedisCacheResponse;
        } else {
            return createAzureError(responsePayload.toString());
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

        if (redisCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING) {
            return createAzureError("Required values not provided");
        }

        string requestPath = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/forceReboot?api-version=" + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        json rebootCacheJsonPayload = {
            "shardId": shardId,
            "rebootType": rebootType,
            "ports": ports
        };
        request.setJsonPayload(rebootCacheJsonPayload);
        http:Response rebootResponse = <http:Response> check self.AzureRedisClient->post(requestPath, request);
        string statusCode = rebootResponse.statusCode.toString();
        json responsePayload = check rebootResponse.getJsonPayload();
        if (statusCode == OK) {
            io:println("Reboot operation successfully enqueued");
            return jsonToStatusCode(statusCode);
        } else {
            return createAzureError(responsePayload.toString());
        }
    }

    # This Function Fetches list of Redis Cache Instance in a resource group
    #
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + return - If successful, returns RedisCacheInstanceList. Else returns error. 
    remote function listByResourceGroup(string resourceGroupName) returns @tainted RedisCacheInstanceList|error {

        if (resourceGroupName == EMPTY_STRING) {
            return createCustomError("Required values not provided");
        }

        string requestPath = "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis?api-version=" + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        http:Response getResponse = <http:Response> check self.AzureRedisClient->get(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        json responsePayload = check getResponse.getJsonPayload();
        if (statusCode == OK) {
            io:println("Redis cache list successfully fetched in given resource group");
            RedisCacheInstanceList listRedisCacheInstance = check responsePayload.cloneWithType(RedisCacheInstanceList);
            return listRedisCacheInstance;
        } else {
            return createAzureError(responsePayload.toString());
        }
    }

    # This Function Fetches list of Redis Cache Instance in a subscription
    #
    # + return - If successful, returns RedisCacheInstanceList. Else returns error. 
    remote function listBySubscription() returns @tainted RedisCacheInstanceList|error {

        string requestPath = "/providers/Microsoft.Cache/redis?api-version=" + API_VERSION;
        http:Request request = new;
        http:Response getResponse = <http:Response> check self.AzureRedisClient->get(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        json responsePayload = check getResponse.getJsonPayload();
        if (statusCode == OK) {
            io:println("Redis cache list successfully fetched in given subscription");
            RedisCacheInstanceList listRedisCacheInstance = check responsePayload.cloneWithType(RedisCacheInstanceList);
            return listRedisCacheInstance;
        } else {
            return createAzureError(responsePayload.toString());
        }
    }

    # This Function Fetches list of primary and secondary keys for specific Redis Cache Instance
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + return - If successful, returns AccessKey. Else returns error.
    remote function listKeys(string redisCacheName, string resourceGroupName) returns @tainted AccessKey|error {

        if (redisCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING) {
            return createCustomError("Required values not provided");
        }

        string requestPath = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/listKeys?api-version=" + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        http:Response getResponse = <http:Response> check self.AzureRedisClient->post(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        json responsePayload = check getResponse.getJsonPayload();
        if (statusCode == OK) {
            io:println("Key list for a redis instance is fetched");
            AccessKey listKeys = check responsePayload.cloneWithType(AccessKey);
            return listKeys;
        } else {
            return createAzureError(responsePayload.toString());
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

        if (redisCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING || keyType == EMPTY_STRING) {
            return createCustomError("Required values not provided");
        }

        string requestPath = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/regenerateKey?api-version=" + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        json regenerateKeyJsonPayload = { "keyType": keyType };
        request.setJsonPayload(regenerateKeyJsonPayload);
        http:Response getResponse = <http:Response> check self.AzureRedisClient->post(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        json responsePayload = check getResponse.getJsonPayload();
        if (statusCode == OK) {
            io:println("Keys  for Redis Cache instance the regenerated");
            AccessKey listKeys = check responsePayload.cloneWithType(AccessKey);
            return listKeys;
        } else {
            return createAzureError(responsePayload.toString());
        }
    }

    # This Function Updates an eisting Redis Cache Instance
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + properties - properties Parameter Description including Pricing tier(Basic, Standard, Premium)
    # + return - If successful, returns RedisCacheInstance. Else returns error. 
    remote function updateRedisCache(string redisCacheName, string resourceGroupName, CreateCacheProperty properties) returns @tainted 
    RedisCacheInstance|error {

        if (properties.sku.name == EMPTY_STRING || properties.sku.family == EMPTY_STRING || properties.sku.capacity.
        toString() == EMPTY_STRING) {
            return createCustomError("Required values not provided");
        }

        string requestPath = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "?api-version=" + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        json updateCacheJsonPayload = {"properties": {"enableNonSslPort": false}};
        request.setJsonPayload(updateCacheJsonPayload);
        http:Response getResponse = <http:Response> check self.AzureRedisClient->patch(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        json responsePayload = check getResponse.getJsonPayload();
        if (statusCode == OK) {
            io:println("Existing redis cache was successfully updated.");
            RedisCacheInstance getRedisCacheResponse = check responsePayload.cloneWithType(RedisCacheInstance);
            return getRedisCacheResponse;
        } else {
            return createAzureError(responsePayload.toString());
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
    # + return - If successful, returns FirewallRuleResponse. Else returns error. 
    remote function createFirewallRule(string redisCacheName, string resourceGroupName, string ruleName, string startIP, 
                                       string endIP) returns @tainted FirewallRuleResponse|error {

        if (redisCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING || ruleName == EMPTY_STRING || startIP == 
        EMPTY_STRING || endIP == EMPTY_STRING) {
            return createCustomError("Required values not provided");
        }

        string requestPath = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/firewallRules/" + 
        ruleName + "?api-version=" + config:getAsString("API_VERSION");
        http:Request request = new;
        json createFilewallRuleJsonPayload = {"properties": {
                "startIP": startIP,
                "endIP": endIP
        }};
        request.setJsonPayload(createFilewallRuleJsonPayload);
        http:Response getResponse = <http:Response> check self.AzureRedisClient->put(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        json responsePayload = check getResponse.getJsonPayload();
        if (statusCode == OK) {
            io:println("Existing Firewall rule Updated");
            FirewallRuleResponse createFirewallResponse = check responsePayload.cloneWithType(FirewallRuleResponse);
            return createFirewallResponse;
        } else if (statusCode == CREATED) {
            io:println("New Firewall rule Created");
            FirewallRuleResponse createFirewallResponse = check responsePayload.cloneWithType(FirewallRuleResponse);
            return createFirewallResponse;
        } else {
            return createAzureError(responsePayload.toString());
        }
    }

    # This Function Deletes an existing FireWall Rule
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + ruleName - Name of Firewall Rule Name
    # + return - If successful, returns StatusCode. Else returns error. 
    remote function deleteFirewallRule(string redisCacheName, string resourceGroupName, string ruleName) returns @tainted 
    StatusCode|error {

        if (redisCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING || ruleName == EMPTY_STRING) {
            return createCustomError("Required values not provided");
        }

        string requestPath = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/firewallRules/" + 
        ruleName + "?api-version=" + config:getAsString("API_VERSION");
        http:Request request = new;
        http:Response getResponse = <http:Response> check self.AzureRedisClient->delete(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        if (statusCode == OK || statusCode == NO_CONTENT) {
            io:println("Firewall rule deleted");
            return jsonToStatusCode(statusCode);
        } else {
            return createAzureError(responsePayload.toString());
        }
    }

    # This Function Fetches an FireWall rule
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + ruleName - Name of FirewallRule Name
    # + return - If successful, returns FirewallRuleResponse. Else returns error. 
    remote function getFirewallRule(string redisCacheName, string resourceGroupName, string ruleName) returns @tainted 
    FirewallRuleResponse|error {

        if (redisCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING || ruleName == EMPTY_STRING) {
            return createCustomError("Required values not provided");
        }

        string requestPath = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/firewallRules/" + 
        ruleName + "?api-version=" + config:getAsString("API_VERSION");
        http:Request request = new;
        http:Response getResponse = <http:Response> check self.AzureRedisClient->get(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        json responsePayload = check getResponse.getJsonPayload();
        if (statusCode == OK) {
            io:println("Firewall rule fetched");
            FirewallRuleResponse getFirewallResponse = check responsePayload.cloneWithType(FirewallRuleResponse);
            return getFirewallResponse;
        } else {
            return createAzureError(responsePayload.toString());
        }
    }

    # This Function Fetches list of FireWall rules
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + return - If successful, returns FirewallRuleListResponse. Else returns error. 
    remote function listFirewallRules(string redisCacheName, string resourceGroupName) returns @tainted 
    FirewallRuleListResponse|error {

        if (redisCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING) {
            return createCustomError("Required values not provided");
        }

        string requestPath = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/firewallRules?api-version=" + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        http:Response getResponse = <http:Response> check self.AzureRedisClient->get(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        json responsePayload = check getResponse.getJsonPayload();
        if (statusCode == OK) {
            io:println("Firewall rule list fetched");
            FirewallRuleListResponse getFirewallResponseArray = check responsePayload.cloneWithType(
            FirewallRuleListResponse);
            return getFirewallResponseArray;
        } else {
            return createAzureError(responsePayload.toString());
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

        if (redisCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING || linkedServerName == EMPTY_STRING || 
        linkedRedisCacheId == EMPTY_STRING || linkedRedisCacheLocation == EMPTY_STRING || serverRole == EMPTY_STRING) {
            return createCustomError("Required values not provided");
        }

        string requestPath = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/linkedServers/" + 
        linkedServerName + "?api-version=" + config:getAsString("API_VERSION");
        http:Request request = new;
        json createLinkedServerJsonPayload = {"properties": {
                "linkedRedisCacheId": linkedRedisCacheId,
                "linkedRedisCacheLocation": linkedRedisCacheLocation,
                "serverRole": serverRole
        }};
        request.setJsonPayload(createLinkedServerJsonPayload);
        http:Response getResponse = <http:Response> check self.AzureRedisClient->put(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        json responsePayload = check getResponse.getJsonPayload();
        if (statusCode == OK) {
            io:println("Existing LinkedServer Updated");
            LinkedServer createLinkedServerResponse = check responsePayload.cloneWithType(LinkedServer);
            io:println(createLinkedServerResponse.properties.provisioningState);
            return createLinkedServerResponse;
        } else if (statusCode == CREATED) {
            io:println("New LinkedServer Created");
            LinkedServer createLinkedServerResponse = check responsePayload.cloneWithType(LinkedServer);
            return createLinkedServerResponse;
        } else {
            return createAzureError(responsePayload.toString());
        }
    }

    # This Function Deletes an Linked server
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + linkedServerName - Name of Linked Server Name
    # + return - If successful, returns StatusCode. Else returns error. 
    remote function deleteLinkedServer(string redisCacheName, string resourceGroupName, string linkedServerName) returns @tainted 
    StatusCode|error {

        if (redisCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING || linkedServerName == EMPTY_STRING) {
            return createCustomError("Required values not provided");
        }

        string requestPath = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/linkedServers/" + 
        linkedServerName + "?api-version=" + config:getAsString("API_VERSION");
        http:Request request = new;
        http:Response getResponse = <http:Response> check self.AzureRedisClient->delete(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        if (statusCode == OK || statusCode == NO_CONTENT) {
            io:println("LinkedServer deleted");
            return jsonToStatusCode(statusCode);
        } else {
            return createAzureError(responsePayload.toString());
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

        if (redisCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING || linkedServerName == EMPTY_STRING) {
            return createCustomError("Required values not provided");
        }

        string requestPath = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/linkedServers/" + 
        linkedServerName + "?api-version=" + config:getAsString("API_VERSION");
        http:Request request = new;
        http:Response getResponse = <http:Response> check self.AzureRedisClient->get(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        json responsePayload = check getResponse.getJsonPayload();
        if (statusCode == OK) {
            io:println("LinkedServer fetched");
            LinkedServer getLinkedServerResponse = check responsePayload.cloneWithType(LinkedServer);
            return getLinkedServerResponse;
        } else {
            return createAzureError(responsePayload.toString());
        }
    }

    # This Function Fetches list of Linked Servers
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + return - If successful, returns LinkedServerList. Else returns error. 
    remote function listLinkedServers(string redisCacheName, string resourceGroupName) 
    returns @tainted LinkedServerList|error {

        if (redisCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING) {
            return createCustomError("Required values not provided");
        }

        string requestPath = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/linkedServers?api-version=" + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        http:Response getResponse = <http:Response> check self.AzureRedisClient->get(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        json responsePayload = check getResponse.getJsonPayload();
        if (statusCode == OK) {
            io:println("LinkedServer list fetched");
            LinkedServerList getLinkedServerList = check responsePayload.cloneWithType(LinkedServerList);
            return getLinkedServerList;
        } else {
            return createAzureError(responsePayload.toString());
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

        if (redisCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING) {
            return createCustomError("Required values not provided");
        }

        string requestPath = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/patchSchedules/default?api-version=" + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        json createPayload = {properties: <json>patchScheduleProperties.cloneWithType(json)};
        request.setJsonPayload(createPayload);
        http:Response getResponse = <http:Response> check self.AzureRedisClient->put(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        json responsePayload = check getResponse.getJsonPayload();
        if (statusCode == OK) {
            io:println("Existing Patch Schedule Updated");
            PatchSchedule createPatchResponse = check responsePayload.cloneWithType(PatchSchedule);
            return createPatchResponse;
        } else if (statusCode == CREATED) {
            io:println("New Patch Schedule Created");
            PatchSchedule createPatchResponse = check responsePayload.cloneWithType(PatchSchedule);
            return createPatchResponse;
        } else {
            return createAzureError(responsePayload.toString());
        }
    }

    # This Function Deletes an Patch Schedule
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + return - If successful, returns StatusCode. Else returns error. 
    remote function deletePatchSchedule(string redisCacheName, string resourceGroupName) 
                                     returns @tainted StatusCode|error {

        if (redisCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING) {
            return createCustomError("Required values not provided");
        }

        string requestPath = "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + 
        redisCacheName + "/patchSchedules/default?api-version=" + config:getAsString("API_VERSION");
        http:Request request = new;
        http:Response getResponse = <http:Response>check self.AzureRedisClient->delete(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        json responsePayload = check getResponse.getJsonPayload();
        if (statusCode == OK || statusCode == NO_CONTENT) {
            io:println("Patch Schedule deleted");
            return jsonToStatusCode(statusCode);
        } else {
            return createAzureError(responsePayload.toString());
        }
    }

    # This Function Fetches Patch Schedule
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + return - If successful, returns PatchSchedule. Else returns error. 
    remote function getPatchSchedule(string redisCacheName, string resourceGroupName) 
    returns @tainted PatchSchedule|error {

        if (redisCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING) {
            return createCustomError("Required values not provided");
        }

        string requestPath = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/patchSchedules/default?api-version=" + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        http:Response getResponse = <http:Response> check self.AzureRedisClient->get(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        json responsePayload = check getResponse.getJsonPayload();
        if (statusCode == OK) {
            io:println("Patch Schedule fetched");
            PatchSchedule getPatchResponse = check responsePayload.cloneWithType(PatchSchedule);
            return getPatchResponse;
        } else {
            return createAzureError(responsePayload.toString());
        }
    }

    # This Function Fetches Patch Schedule
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + return - If successful, returns PatchSheduleList. Else returns error. 
    remote function listPatchSchedules(string redisCacheName, string resourceGroupName) returns @tainted 
    PatchScheduleList|error {

        if (redisCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING) {
            return createCustomError("Required values not provided");
        }

        string requestPath = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/patchSchedules?api-version=" + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        http:Response getResponse = <http:Response> check self.AzureRedisClient->get(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        json responsePayload = check getResponse.getJsonPayload();
        if (statusCode == OK) {
            io:println("Patch Schedule list fetched");
            PatchScheduleList getPatchSheduleArray = check responsePayload.cloneWithType(PatchScheduleList);
            return getPatchSheduleArray;
        } else {
            return createAzureError(responsePayload.toString());
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
                                                 string privateEndpointConnectionName) returns @tainted json|error {

        if (redisCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING || privateEndpointConnectionName == 
        EMPTY_STRING) {
            return createCustomError("Required values not provided");
        }

        string requestPath = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/privateEndpointConnections/" + 
        privateEndpointConnectionName + "?api-version=" + config:getAsString("API_VERSION");
        http:Request request = new;
        json putPrivateEndpointConnectionJsonPayload = {"properties": {"privateLinkServiceConnectionState": {
                    "status": "Approved",
                    "description": "Auto-Approved"
        }}};
        request.setJsonPayload(putPrivateEndpointConnectionJsonPayload);
        http:Response getResponse = <http:Response> check self.AzureRedisClient->put(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        json responsePayload = check getResponse.getJsonPayload();
        // io:println(statusCode);
        // io:println(responsePayload);
        if (statusCode == OK) {
            io:println("Existing LinkedServer Updated");
            return responsePayload;
        } else if (statusCode == CREATED) {
            io:println("New PrivateEndpointConnection Created");
            return responsePayload;
        } else {
            return createAzureError(responsePayload.toString());
        }
    }

    # This Function Fetches Private Endpoint Connection
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + privateEndpointConnectionName - Name of Private Endpoint Connection
    # + return - If successful, returns PrivateEndpointConnection. Else returns error. 
    remote function getPrivateEndpointConnection(string redisCacheName, string resourceGroupName, 
                                                 string privateEndpointConnectionName) returns @tainted json|error {

        if (redisCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING || privateEndpointConnectionName == 
        EMPTY_STRING) {
            return createCustomError("Required values not provided");
        }

        string requestPath = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/privateEndpointConnections/" + 
        privateEndpointConnectionName + "?api-version=" + config:getAsString("API_VERSION");
        http:Request request = new;
        http:Response getResponse = <http:Response> check self.AzureRedisClient->get(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        json responsePayload = check getResponse.getJsonPayload();
        // io:println(statusCode);
        // io:println(responsePayload);
        if (statusCode == OK) {
            io:println("PrivateEndpointConnection fetched");
            return responsePayload;
        } else {
            return createAzureError(responsePayload.toString());
        }
    }

    # This Function Fetches Private Endpoint Connection
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + return - If successful, returns PrivateEndpointConnectionList. Else returns error.
    remote function listPrivateEndpointConnection(string redisCacheName, string resourceGroupName) returns @tainted 
    StatusCode|error {

        if (redisCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING) {
            return createCustomError("Required values not provided");
        }

        string requestPath = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/privateEndpointConnections?api-version=" + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        http:Response getResponse = <http:Response> check self.AzureRedisClient->get(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        json responsePayload = check getResponse.getJsonPayload();
        // io:println(statusCode);
        // io:println(responsePayload);
        if (statusCode == OK) {
            io:println("Fetching PrivateEndpointConnection list");
            return jsonToStatusCode(statusCode);
        } else {
            return createAzureError(responsePayload.toString());
        }
    }

    # This Function Deletes Private Endpoint Connection
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + privateEndpointConnectionName - Name of Private Endpoint Connection
    # + return - If successful, returns StatusCode. Else returns error.
    remote function deletePrivateEndpointConnection(string redisCacheName, string resourceGroupName, 
                                    string privateEndpointConnectionName) 
                                    returns @tainted StatusCode|error {

        if (redisCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING || privateEndpointConnectionName == 
        EMPTY_STRING) {
            return createCustomError("Required values not provided");
        }

        string requestPath = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/privateEndpointConnections/" + 
        privateEndpointConnectionName + "?api-version=" + config:getAsString("API_VERSION");
        http:Request request = new;
        http:Response getResponse = <http:Response> check self.AzureRedisClient->delete(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        json responsePayload = check getResponse.getJsonPayload();
        // io:println(statusCode);
        // io:println(responsePayload);
        if (statusCode == OK || statusCode == NO_CONTENT) {
            io:println("PrivateEndpointConnection deleted");
            return jsonToStatusCode(statusCode);
        } else {
            return createAzureError(responsePayload.toString());
        }
    }

    //Function related to Private Link Resources

    # This Function Fetches Private Link Resource
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + return - If successful, returns PrivateLinkResource. Else returns error.
    remote function getPrivateLinkResources(string redisCacheName, string resourceGroupName) 
    returns @tainted StatusCode|error {

        string requestPath = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/privateLinkResources?api-version=" + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        http:Response getResponse = <http:Response> check self.AzureRedisClient->get(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        json responsePayload = check getResponse.getJsonPayload();
        // io:println(statusCode);
        // io:println(responsePayload);
        if (statusCode == OK) {
            io:println("PrivateLinkResources fetched");
            return jsonToStatusCode(statusCode);
        } else {
            return createAzureError(responsePayload.toString());
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
                                                       string databaseName) returns @tainted StatusCode|error {

        string requestPath = "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
        redisEnterpriseName + "/databases/" + databaseName + "?api-version=" + config:getAsString(
        "ENTERPRISE_API_VERSION");
        http:Request request = new;
        json createEnterpriseCacheDBJsonPayload = {"properties": {
                "clientProtocol": "Encrypted",
                "clusteringPolicy": "EnterpriseCluster",
                "evictionPolicy": "AllKeysLRU",
                "port": 10000,
                "modules": []
        }};
        request.setJsonPayload(createEnterpriseCacheDBJsonPayload);
        http:Response getResponse = <http:Response> check self.AzureRedisClient->put(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        string responsePayload = getResponse.getJsonPayload().toString();
        // io:println(statusCode);
        // io:println(responsePayload);
        if (statusCode == OK) {
            io:println("Redis Enterprise Cache Database created");
            return jsonToStatusCode(statusCode);
        } else if (statusCode == CREATED) {
            io:println("Redis Enterprise Cache Database created");
            return jsonToStatusCode(statusCode);
        } else {
            return createAzureError(responsePayload.toString());
        }
    }

    # This Function Deletes Redis Enterprise Cache Database
    #
    # + redisEnterpriseName - Redis Enterprise Cache Database Name. 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + databaseName - Name of Database Name
    # + return - If successful, returns StatusCode. Else returns error. 
    remote function deleteRedisEnterpriseDatabase(string redisEnterpriseName, string resourceGroupName, 
                                                       string databaseName) returns @tainted StatusCode|error {

        if (redisEnterpriseName == EMPTY_STRING || resourceGroupName == EMPTY_STRING) {
            return createCustomError("Required values not provided");
        }

        string requestPath = "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
        redisEnterpriseName + "/databases/" + databaseName + "?api-version=" + config:getAsString(
        "ENTERPRISE_API_VERSION");
        http:Request request = new;
        http:Response getResponse = <http:Response> check self.AzureRedisClient->delete(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        string responsePayload = getResponse.getJsonPayload().toString();
        // io:println(statusCode);
        // io:println(responsePayload);
        if (statusCode == OK || statusCode == NO_CONTENT) {
            io:println("Redis cache was successfully deleted");
            return jsonToStatusCode(statusCode);
        } else if (statusCode == ACCEPTED) {
            io:println("Redis cache delete operation was successfully enqueued");
            return jsonToStatusCode(statusCode);
        } else {
            return createAzureError(responsePayload.toString());
        }
    }

    # This Function exports Redis Enterprise Cache Database
    #
    # + redisEnterpriseName - Redis Enterprise Cache Database Name. 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + databaseName - Name of Database Name
    # + blobContainerUrl - path to bolb container 
    # + sasKeyParameters - SAS key
    # + return - If successful, returns StatusCode. Else returns error. 
    remote function exportRedisEnterpriseDatabase(string redisEnterpriseName, string resourceGroupName, 
                                    string databaseName, string blobContainerUrl, 
                                    string sasKeyParameters) returns @tainted StatusCode|error {

        if (redisEnterpriseName == EMPTY_STRING || resourceGroupName == EMPTY_STRING || sasKeyParameters == 
        EMPTY_STRING || blobContainerUrl == EMPTY_STRING) {
            return createCustomError("Required values not provided");
        }

        string requestPath = "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
        redisEnterpriseName + "/databases/" + databaseName + "/export?api-version=" + config:getAsString(
        "ENTERPRISE_API_VERSION");
        http:Request request = new;
        json exportCacheJsonPayload = {"sasUri": blobContainerUrl + "?" + sasKeyParameters};
        request.setJsonPayload(exportCacheJsonPayload);
        http:Response getResponse = <http:Response> check self.AzureRedisClient->post(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        string responsePayload = getResponse.getJsonPayload().toString();
        // io:println(statusCode);
        // io:println(responsePayload);
        if (statusCode == OK || statusCode == NO_CONTENT) {
            io:println("Redis cache was successfully exported");
            return jsonToStatusCode(statusCode);
        } else if (statusCode == ACCEPTED) {
            io:println("Redis cache export operation was successfully enqueued");
            return jsonToStatusCode(statusCode);
        } else {
            return createAzureError(responsePayload.toString());
        }
    }

    # This Function imports Redis Enterprise Cache Database
    #
    # + redisEnterpriseName - Redis Enterprise Cache Database Name. 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + databaseName - Name of Database Name
    # + blobFileUrl - path to bolb file storage 
    # + sasKeyParameters - SAS key
    # + return - If successful, returns StatusCode. Else returns error. 
    remote function importRedisEnterpriseDatabase(string redisEnterpriseName, string resourceGroupName, 
                                    string databaseName, string blobFileUrl, string sasKeyParameters) returns @tainted 
                                    StatusCode|error {

        if (redisEnterpriseName == EMPTY_STRING || resourceGroupName == EMPTY_STRING) {
            return createCustomError("Required values not provided");
        }

        string requestPath = "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
        redisEnterpriseName + "/databases/" + databaseName + "/import?api-version=" + config:getAsString(
        "ENTERPRISE_API_VERSION");
        http:Request request = new;
        json importCacheJsonPayload = {"sasUri": blobFileUrl + "?" + sasKeyParameters};
        request.setJsonPayload(importCacheJsonPayload);
        http:Response getResponse = <http:Response> check self.AzureRedisClient->post(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        string responsePayload = getResponse.getJsonPayload().toString();
        // io:println(statusCode);
        // io:println(responsePayload);
        if (statusCode == OK || statusCode == NO_CONTENT) {
            io:println("Redis cache was successfully imported");
            return jsonToStatusCode(statusCode);
        } else if (statusCode == ACCEPTED) {
            io:println("Redis cache import operation was successfully enqueued");
            return jsonToStatusCode(statusCode);
        } else {
            return createAzureError(responsePayload.toString());
        }
    }

    # This Function Fetches Redis Enterprise Cache Database
    #
    # + redisEnterpriseName - Redis Enterprise Cache Database Name. 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + databaseName - Name of Database Name
    # + return - If successful, returns RedisEnterpriseDatabase. Else returns error. 
    remote function getRedisEnterpriseDatabase(string redisEnterpriseName, string resourceGroupName, 
                                                    string databaseName) returns @tainted StatusCode|error {

        if (redisEnterpriseName == EMPTY_STRING || resourceGroupName == EMPTY_STRING) {
            return createCustomError("Required values not provided");
        }

        string requestPath = "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
        redisEnterpriseName + "/databases/" + databaseName + "?api-version=" + config:getAsString(
        "ENTERPRISE_API_VERSION");
        http:Request request = new;
        http:Response getResponse = <http:Response> check self.AzureRedisClient->get(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        json responsePayload = check getResponse.getJsonPayload();
        // io:println(statusCode);
        // io:println(responsePayload);
        if (statusCode == OK) {
            io:println("Redis cache was successfully found");
            return jsonToStatusCode(statusCode);
        } else {
            return createAzureError(responsePayload.toString());
        }
    }

    # This Function lists Redis Enterprise Cache Database
    #
    # + redisEnterpriseName - Redis Enterprise Cache Database Name. 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + return - If successful, returns RedisEnterpriseDatabase[]. Else returns error. 
    remote function listRedisEnterpriseDatabaseByCluster(string redisEnterpriseName, string resourceGroupName) returns @tainted 
    StatusCode|error {

        if (redisEnterpriseName == EMPTY_STRING || resourceGroupName == EMPTY_STRING) {
            return createCustomError("Required values not provided");
        }

        string requestPath = "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
        redisEnterpriseName + "/databases?api-version=" + config:getAsString("ENTERPRISE_API_VERSION");
        http:Request request = new;
        http:Response getResponse = <http:Response> check self.AzureRedisClient->get(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        string responsePayload = getResponse.getJsonPayload().toString();
        // io:println(statusCode);
        // io:println(responsePayload);
        if (statusCode == OK) {
            io:println("Redis cache list under resource group was successfully found");
            return jsonToStatusCode(statusCode);
        } else {
            return createAzureError(responsePayload.toString());
        }
    }

    # This Function lists Redis Enterprise Cache Database Keys
    #
    # + redisEnterpriseName - Redis Enterprise Cache Database Name. 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + return - If successful, returns RedisEnterpriseDatabaseKeys. Else returns error. 
    remote function listRedisEnterpriseDatabaseKeys(string redisEnterpriseName, string resourceGroupName, 
                                                         string databaseName) returns @tainted StatusCode|error {

        if (redisEnterpriseName == EMPTY_STRING || resourceGroupName == EMPTY_STRING) {
            return createCustomError("Required values not provided");
        }

        string requestPath = "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
        redisEnterpriseName + "/databases/" + databaseName + "/listKeys?api-version=" + config:getAsString(
        "ENTERPRISE_API_VERSION");
        http:Request request = new;
        http:Response getResponse = <http:Response> check self.AzureRedisClient->post(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        string responsePayload = getResponse.getJsonPayload().toString();
        // io:println(statusCode);
        // io:println(responsePayload);
        if (statusCode == OK) {
            io:println("Keys of Redis cache was successfully found");
            return jsonToStatusCode(statusCode);
        } else {
            return createAzureError(responsePayload.toString());
        }
    }

    # This Function Regenerates Redis Enterprise Cache Database Key
    #
    # + redisEnterpriseName - Redis Enterprise Cache Database Name. 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + databaseName - Name of Database Name
    # + return - If successful, returns StatusCode. Else returns error. 
    remote function regenerateRedisEnterpriseDatabaseKey(string redisEnterpriseName, string resourceGroupName, 
                                                              string databaseName, string keyType) returns @tainted 
                                                              StatusCode|error {

        if (redisEnterpriseName == EMPTY_STRING || resourceGroupName == EMPTY_STRING || keyType == EMPTY_STRING) {
            return createCustomError("Required values not provided");
        }

        string requestPath = "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
        redisEnterpriseName + "/databases/" + databaseName + "/regenerateKey?api-version=" + config:getAsString(
        "ENTERPRISE_API_VERSION");
        http:Request request = new;
        json regenerateKeyJsonPayload = {"keyType": keyType};
        request.setJsonPayload(regenerateKeyJsonPayload);
        http:Response getResponse = <http:Response> check self.AzureRedisClient->post(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        string responsePayload = getResponse.getJsonPayload().toString();
        // io:println(statusCode);
        // io:println(responsePayload);
        if (statusCode == OK) {
            io:println("Lists the regenerated keys for Redis Cache");
            return jsonToStatusCode(statusCode);
        } else if (statusCode == ACCEPTED) {
            io:println("Lists the regenerated keys for Redis Cache");
            return jsonToStatusCode(statusCode);
        } else {
            return createAzureError(responsePayload.toString());
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
                                                       string moduleName) returns @tainted StatusCode|error {

        if (redisEnterpriseName == EMPTY_STRING || resourceGroupName == EMPTY_STRING) {
            return createCustomError("Required values not provided");
        }

        string requestPath = "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
        redisEnterpriseName + "/databases/" + databaseName + "?api-version=" + config:getAsString(
        "ENTERPRISE_API_VERSION");
        http:Request request = new;
        json updateCacheJsonPayload = {"properties": {
                "clientProtocol": clientProtocol,
                "evictionPolicy": evictionPolicy,
                "modules": [{"name": moduleName}]
        }};
        request.setJsonPayload(updateCacheJsonPayload);
        http:Response getResponse = <http:Response> check self.AzureRedisClient->patch(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        string responsePayload = getResponse.getJsonPayload().toString();
        // io:println(statusCode);
        // io:println(responsePayload);
        if (statusCode == OK) {
            io:println("Existing redis cache was successfully updated.");
            return jsonToStatusCode(statusCode);
        } else {
            return createAzureError(responsePayload.toString());
        }
    }

    //Functions related to Redis enterprise

    # This Function Creates a new Redis Enterprise Cluster
    #
    # + redisEnterpriseClusterName - Redis Enterprise ClusterName. 
    # + resourceGroupName - Resource Group Name where Redis Enterprise found.
    # + location - Location specifies Server Location. 
    # + skuName - provide information about Enterprise Allowed Names Only.
    # + skuCapacity - provide information about capacity.
    # + return - If successful, returns RedisEnterpriseInstance. Else returns error. 
    remote function createRedisEnterprise(string redisEnterpriseClusterName, string resourceGroupName, 
                                               string location, string skuName, int skuCapacity) returns @tainted 
                                               RedisEnterpriseInstance|error {

        string requestPath = "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
        redisEnterpriseClusterName + "?api-version=" + config:getAsString("ENTERPRISE_API_VERSION");
        http:Request request = new;
        json createEnterpriseCacheJsonPayload = {
            "location": location,
            "sku": {
                "name": skuName,
                "capacity": skuCapacity
            },
            "zones": ["1", "2", "3"],
            "properties": {"minimumTlsVersion": "1.2"},
            "tags": {"tag1": "value1"}
        };
        request.setJsonPayload(createEnterpriseCacheJsonPayload);
        http:Response getResponse = <http:Response> check self.AzureRedisClient->put(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        json responsePayload = check getResponse.getJsonPayload();
        if (statusCode == OK) {
            io:println("Existing Redis Enterprise Cache Updated");
            RedisEnterpriseInstance redisEnterpriseResponse = check responsePayload.cloneWithType(
            RedisEnterpriseInstance);
            return redisEnterpriseResponse;
        } else if (statusCode == CREATED) {
            io:println("New Redis Enterprise Cache created");
            RedisEnterpriseInstance redisEnterpriseResponse = check responsePayload.cloneWithType(
            RedisEnterpriseInstance);
            return redisEnterpriseResponse;
        } else {
            return createAzureError(responsePayload.toString());
        }
    }

    # This Function Fetches a Redis Enterprise Cluster
    #
    # + redisEnterpriseClusterName - Redis Enterprise ClusterName 
    # + resourceGroupName - Resource Group Name where Redis Enterprise found.
    # + return - If successful, returns RedisEnterpriseInstance. Else returns error. 
    remote function getRedisEnterprise(string redisEnterpriseClusterName, string resourceGroupName) returns @tainted 
    RedisEnterpriseInstance|error {

        string requestPath = "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
        redisEnterpriseClusterName + "?api-version=" + config:getAsString("ENTERPRISE_API_VERSION");
        http:Request request = new;
        http:Response getResponse = <http:Response> check self.AzureRedisClient->get(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        json responsePayload = check getResponse.getJsonPayload();
        if (statusCode == OK) {
            RedisEnterpriseInstance getRedisEnterprise = check responsePayload.cloneWithType(
            RedisEnterpriseInstance);
            return getRedisEnterprise;
        } else {
            return createAzureError(responsePayload.toString());
        }
    }

    # This Function Deletes a Redis Enterprise Cluster
    #
    # + redisEnterpriseClusterName - Redis Enterprise ClusterName 
    # + resourceGroupName - Resource Group Name where Redis Enterprise found.
    # + return - If successful, returns StatusCode. Else returns error. 
    remote function deleteRedisEnterprise(string redisEnterpriseClusterName, string resourceGroupName) returns @tainted 
    StatusCode|error {

        if (redisEnterpriseClusterName == EMPTY_STRING || resourceGroupName == EMPTY_STRING) {
            return createAzureError("Required values not provided");
        }

        string requestPath = "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
        redisEnterpriseClusterName + "?api-version=" + config:getAsString("ENTERPRISE_API_VERSION");
        http:Request request = new;
        http:Response getResponse = <http:Response> check self.AzureRedisClient->delete(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        string responsePayload = getResponse.getJsonPayload().toString();
        if (statusCode == OK || statusCode == NO_CONTENT) {
            io:println("Redis Enterprise cache was successfully deleted");
            return jsonToStatusCode(statusCode);
        } else if (statusCode == ACCEPTED) {
            io:println("Redis Enterprise cache delete operation was successfully enqueued");
            return jsonToStatusCode(statusCode);
        } else {
            io:println("Error in deleting Azure Redis Cache");
            return jsonToStatusCode(statusCode);
        }
    }

    # This Function Fetches a list of Redis Enterprise Cluster in a subscription
    # 
    # + return - If successful, returns RedisEnterpriseInstanceList. Else returns error. 
    remote function listRedisEnterprise() returns @tainted RedisEnterpriseInstanceList|error {

        string requestPath = "/providers/Microsoft.Cache/redisEnterprise?api-version=" + config:getAsString(
        "ENTERPRISE_API_VERSION");
        http:Request request = new;
        http:Response getResponse = <http:Response> check self.AzureRedisClient->get(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        json responsePayload = check getResponse.getJsonPayload();
        if (statusCode == OK) {
            io:println("RedisEnterprise cache list was successfully found");
            RedisEnterpriseInstanceList getRedisEnterpriseList = check responsePayload.cloneWithType(
            RedisEnterpriseInstanceList);
            return getRedisEnterpriseList;
        } else {
            return createAzureError(responsePayload.toString());
        }
    }

    # This Function Fetches a Redis Enterprise Cluster in a subscription within a specific resource group
    # 
    # + resourceGroupName - Resource Group Name where Redis Enterprise found.
    # + return - If successful, returns RedisEnterpriseInstanceList. Else returns error. 
    remote function listRedisEnterpriseByResourceGroup(string resourceGroupName) returns @tainted 
    RedisEnterpriseInstanceList|error {

        if (resourceGroupName == EMPTY_STRING) {
            return createAzureError("Required values not provided");
        }

        string requestPath = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise?api-version=" + 
        config:getAsString("ENTERPRISE_API_VERSION");
        http:Request request = new;
        http:Response getResponse = <http:Response> check self.AzureRedisClient->get(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        json responsePayload = check getResponse.getJsonPayload();
        if (statusCode == OK) {
            io:println("List of RedisEnterprise cache in resource group was successfully found");
            RedisEnterpriseInstanceList getRedisEnterpriseList = check responsePayload.cloneWithType(
            RedisEnterpriseInstanceList);
            return getRedisEnterpriseList;
        } else {
            return createAzureError(responsePayload.toString());
        }
    }

    //This function is currently not supported at the moment as stated in Azure Redis REST API Documentation.

    # This Function Updates the Redis Enterprise Cluster
    #  
    # + redisEnterpriseClusterName - Redis Enterprise ClusterName 
    # + resourceGroupName - Resource Group Name where Redis Enterprise found.
    # + return - If successful, returns RedisEnterpriseInstance. Else returns error. 
    remote function updateRedisEnterprise(string redisEnterpriseClusterName, string resourceGroupName) returns @tainted 
    StatusCode|error {

        if (redisEnterpriseClusterName == EMPTY_STRING || resourceGroupName == EMPTY_STRING) {
            return createCustomError("Required values not provided");
        }

        string requestPath = "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
        redisEnterpriseClusterName + "?api-version=" + config:getAsString("ENTERPRISE_API_VERSION");
        http:Request request = new;
        json updateCacheJsonPayload = {
            "sku": {
                "name": "EnterpriseFlash_F300",
                "capacity": 9
            },
            "properties": {"minimumTlsVersion": "1.2"},
            "tags": {"tag1": "value1"}
        };
        request.setJsonPayload(updateCacheJsonPayload);
        http:Response getResponse = <http:Response> check self.AzureRedisClient->patch(requestPath, request);
        string statusCode = getResponse.statusCode.toString();
        string responsePayload = getResponse.getJsonPayload().toString();
        if (statusCode == OK) {
            io:println("Existing redis cache was successfully updated.");
            return jsonToStatusCode(statusCode);
        } else {
            return createAzureError(responsePayload.toString());
        }
    }
}
