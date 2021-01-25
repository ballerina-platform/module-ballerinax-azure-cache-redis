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
    oauth2:DirectTokenConfig oauth2Config;
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
    remote function checkRedisCacheNameAvailability(string cacheName) returns @tainted StatusCode|error {

        if (cacheName == EMPTY_STRING) {
            return createError("Required values not provided");
        }

        var path = "/providers/Microsoft.Cache/CheckNameAvailability?api-version=" + config:getAsString("API_VERSION");
        http:Request request = new;
        json checkPayload = {
            "type": "Microsoft.Cache/Redis",
            "name": cacheName
        };
        request.setJsonPayload(checkPayload);
        var response = self.AzureRedisClient->post(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            string payload = response.getJsonPayload().toString();
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("Name Available");
                return jsonToStatusCode(statusCode);
            } else {
                io:println(
                "DNS name for the cache instance not available or Temporary not available due to recently deleted");
                return jsonToStatusCode(statusCode);
            }
        } else {
            return createError("Not an Http Response");
        }
    }

    # This Function Creates a new Redis Cache Instance
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + location - location Parameter Description 
    # + zones - zones Parameter Description 
    # + properties - properties Parameter Description including Pricing tier(Basic, Standard, Premium)
    # + return - If successful, returns RedisCacheInstance. Else returns error. 
    remote function createRedisCache(string redisCacheName, string resourceGroupName, string location, 
                                     CreateCacheProperty properties, string[]? zones = ()) returns @tainted 
                                     RedisCacheInstance|error {

        if (location == EMPTY_STRING || properties.sku.name == EMPTY_STRING || properties.sku.family == EMPTY_STRING || 
        properties.sku.capacity.toString() == EMPTY_STRING) {
            return createError("Required values not provided");
        }

        var path = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "?api-version=" + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        json createCacheJsonPayload = {
            "location": location,
            "properties": {
                "sku": {
                    "name": properties.sku.name,
                    "family": properties.sku.family,
                    "capacity": properties.sku.capacity
                },
                "enableNonSslPort": true
            }
        };
        request.setJsonPayload(createCacheJsonPayload);
        var response = self.AzureRedisClient->put(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            string payloadtest = response.getJsonPayload().toString();
            io:println(payloadtest);
            json|error payload = response.getJsonPayload();
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("Existing Azure Redis Cache Updated");
                if (payload is json) {
                    RedisCacheInstance getRedisCacheResponse = check <@untainted>payload.cloneWithType(
                    RedisCacheInstance);
                    io:println(getRedisCacheResponse.properties.provisioningState);
                    return getRedisCacheResponse;
                } else {
                    return createError("Error in creating RedisCacheResponse");
                }
            } else if (statusCode == "201") {
                io:println("New Azure Redis Cache Created");
                if (payload is json) {
                    io:println(payload.id);
                    RedisCacheInstance getRedisCacheResponse = check <@untainted>payload.cloneWithType(
                    RedisCacheInstance);
                    io:println(getRedisCacheResponse.properties.provisioningState);
                    return getRedisCacheResponse;
                } else {
                    return createError("Error in creating RedisCacheResponse");
                }
            } else {
                return createError("Error in creating or Updating Azure Redis Cache");
            }
        } else {
            return createError("Not an Http Response");
        }
    }

    # This Function Deletes a Redis Cache Instance
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + return - If successful, returns StatusCode. Else returns error. 
    remote function deleteRedisCache(string redisCacheName, string resourceGroupName) returns @tainted StatusCode|error {

        if (redisCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING) {
            return createError("Required values not provided");
        }

        var path = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "?api-version=" + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        var response = self.AzureRedisClient->delete(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("Redis cache was successfully deleted");
                return jsonToStatusCode(statusCode);
            } else if (statusCode == "202") {
                io:println("Redis cache delete operation was successfully enqueued");
                return jsonToStatusCode(statusCode);
            } else if (statusCode == "204") {
                io:println("Redis cache was successfully deleted");
                return jsonToStatusCode(statusCode);
            } else {
                return createError("Error in deleting Azure Redis Cache");
            }
        } else {
            return createError("Not an Http Response");
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
            return createError("Required values not provided");
        }

        var path = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/export?api-version=" + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        json exportCacheJsonPayload = {
            "format": format,
            "prefix": prefix,
            "container": blobContainerUrl + sasKeyParameters
        };
        request.setJsonPayload(exportCacheJsonPayload);
        var response = self.AzureRedisClient->post(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            string getPayload = response.getJsonPayload().toString();
            io:println(statusCode);
            io:println(getPayload);
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("Redis cache was successfully exported");
                return jsonToStatusCode(statusCode);
            } else if (statusCode == "202") {
                io:println("Redis cache export operation was successfully enqueued");
                return jsonToStatusCode(statusCode);
            } else if (statusCode == "204") {
                io:println("Redis cache was successfully exported");
                return jsonToStatusCode(statusCode);
            } else {
                return createError("Error in exporting Azure Redis Cache");
            }
        } else {
            return createError("Not an Http Response");
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
    remote function importRedisCache(string redisCacheName, string resourceGroupName, string files, string? format = ()) returns @tainted 
    StatusCode|error {

        if (redisCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING || files == EMPTY_STRING) {
            return createError("Required values not provided");
        }

        var path = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/import?api-version=" + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        json importCacheJsonPayload = {
            "format": format,
            "files": [files]
        };
        request.setJsonPayload(importCacheJsonPayload);
        var response = self.AzureRedisClient->post(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            string getPayload = response.getJsonPayload().toString();
            io:println(statusCode);
            io:println(getPayload);
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("Redis cache was successfully imported");
                return jsonToStatusCode(statusCode);
            } else if (statusCode == "202") {
                io:println("Redis cache import operation was successfully enqueued");
                return jsonToStatusCode(statusCode);
            } else if (statusCode == "204") {
                io:println("Redis cache was successfully imported");
                return jsonToStatusCode(statusCode);
            } else {
                return createError("Error in importing Azure Redis Cache");
            }
        } else {
            return createError("Not an Http Response");
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
            return createError("Required values not provided");
        }

        var path = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "?api-version=" + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        var response = self.AzureRedisClient->get(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            json|error payload = response.getJsonPayload();
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                if (payload is json) {
                    RedisCacheInstance getRedisCacheResponse = check <@untainted>payload.cloneWithType(
                    RedisCacheInstance);
                    return getRedisCacheResponse;
                } else {
                    return createError("Error in fetching RedisCacheResponse");
                }
            } else {
                return createError("Error in fetching Azure Redis Cache");
            }
        } else {
            return createError("Not an Http Response");
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
    remote function forceRebootRedisCache(string redisCacheName, string resourceGroupName, int? shardId = (), 
                                          string? rebootType = (), int[]? ports = ()) returns @tainted StatusCode|error {

        if (redisCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING) {
            return createError("Required values not provided");
        }

        var path = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/forceReboot?api-version=" + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        json rebootCacheJsonPayload = {
            "shardId": shardId,
            "rebootType": rebootType,
            "ports": ports
        };
        request.setJsonPayload(rebootCacheJsonPayload);
        var response = self.AzureRedisClient->post(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            string payload = response.getJsonPayload().toString();
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("Reboot operation successfully enqueued");
                return jsonToStatusCode(statusCode);
            } else {
                io:println("Error in Rebooting Azure Redis Cache");
                return jsonToStatusCode(statusCode);
            }
        } else {
            return createError("Not an Http Response");
        }
    }

    # This Function Fetches list of Redis Cache Instance in a resource group
    #
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + return - If successful, returns RedisCacheInstance[]. Else returns error. 
    remote function listByResourceGroup(string resourceGroupName) returns @tainted StatusCode|error {

        if (resourceGroupName == EMPTY_STRING) {
            return createError("Required values not provided");
        }

        var path = "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis?api-version=" + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        var response = self.AzureRedisClient->get(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            json|error payload = response.getJsonPayload();
            io:println(statusCode);
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                if (payload is json) {
                    //RedisCacheInstance getRedisCacheResponse = check <@untainted>payload.cloneWithType(RedisCacheInstance);
                    json[] redisCacheList = <json[]>payload.value;
                    foreach var redisCache in redisCacheList {
                        io:println(redisCache);
                    }
                    return jsonToStatusCode(statusCode);
                } else {
                    return createError("Error in fetching RedisCacheResponse");
                }
            } else {
                io:println("Error in fetching Azure Redis Cache list by resource group");
                return jsonToStatusCode(statusCode);
            }
        } else {
            return createError("Not an Http Response");
        }
    }

    # This Function Fetches list of Redis Cache Instance in a subscription
    #
    # + return - If successful, returns RedisCacheInstance[]. Else returns error. 
    remote function listBySubscription() returns @tainted StatusCode|error {

        var path = "/providers/Microsoft.Cache/redis?api-version=" + API_VERSION;
        http:Request request = new;
        var response = self.AzureRedisClient->get(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            string reason = response.getJsonPayload().toString();
            io:println(statusCode);
            io:println(reason);
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("Redis cache list under subscription was successfully found");
                return jsonToStatusCode(statusCode);
            } else {
                io:println("Error in fetching Azure Redis Cache list by subscription");
                return jsonToStatusCode(statusCode);
            }
        } else {
            return createError("Not an Http Response");
        }
    }

    # This Function Fetches list of primary and secondary keys for specific Redis Cache Instance
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + return - Return Value Description
    remote function listKeys(string redisCacheName, string resourceGroupName) returns @tainted StatusCode|error {

        if (redisCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING) {
            return createError("Required values not provided");
        }

        var path = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/listKeys?api-version=" + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        var response = self.AzureRedisClient->post(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            string reason = response.getJsonPayload().toString();
            io:println(statusCode);
            io:println(reason);
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("Keys of Redis cache was successfully found");
                return jsonToStatusCode(statusCode);
            } else {
                io:println("Error in fetching Keys of Azure Redis Cache");
                return jsonToStatusCode(statusCode);
            }
        } else {
            return createError("Not an Http Response");
        }
    }

    # This Function Fetches list of upgrade notifications for a Redis Cache Instance
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + history - history Parameter Description 
    # + return - Return Value Description
    remote function listUpgradeNotifications(string redisCacheName, string resourceGroupName, float history) returns @tainted 
    StatusCode|error {

        if (redisCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING || history.toString() == EMPTY_STRING) {
            return createError("Required values not provided");
        }

        var path = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/listUpgradeNotifications?api-version=" + 
        config:getAsString("API_VERSION") + "&history=" + history.toString();
        http:Request request = new;
        var response = self.AzureRedisClient->get(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            string reason = response.getJsonPayload().toString();
            io:println(statusCode);
            io:println(reason);
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("Notifications list in given time range was successfully found");
                return jsonToStatusCode(statusCode);
            } else {
                io:println("Error in fetching Notifications list");
                return jsonToStatusCode(statusCode);
            }
        } else {
            return createError("Not an Http Response");
        }
    }

    # This Function regenerates primary and secondary keys
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + keyType - keyType Parameter Description 
    # + return - Return Value Description
    remote function regenerateKey(string redisCacheName, string resourceGroupName, string keyType) returns @tainted 
    StatusCode|error {

        if (redisCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING || keyType == EMPTY_STRING) {
            return createError("Required values not provided");
        }

        var path = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/regenerateKey?api-version=" + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        json regenerateKeyJsonPayload = {"keyType": keyType};
        request.setJsonPayload(regenerateKeyJsonPayload);
        var response = self.AzureRedisClient->post(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            string reason = response.getJsonPayload().toString();
            io:println(statusCode);
            io:println(reason);
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("Lists the regenerated keys for Redis Cache found");
                return jsonToStatusCode(statusCode);
            } else {
                io:println("Error in regenerating keys for Redis Cache");
                return jsonToStatusCode(statusCode);
            }
        } else {
            return createError("Not an Http Response");
        }
    }

    # This Function Updates an eisting Redis Cache Instance
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + properties - properties Parameter Description
    # + return - If successful, returns RedisCacheInstance. Else returns error. 
    remote function updateRedisCache(string redisCacheName, string resourceGroupName, CreateCacheProperty properties) 
    returns @tainted json|error {

        if (properties.sku.name == EMPTY_STRING || properties.sku.family == EMPTY_STRING || properties.sku.capacity.
        toString() == EMPTY_STRING) {
            return createError("Required values not provided");
        }

        var path = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "?api-version=" + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        json updateCacheJsonPayload = {"properties": {"enableNonSslPort": false}};
        request.setJsonPayload(updateCacheJsonPayload);
        var response = self.AzureRedisClient->patch(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            string reason = response.getJsonPayload().toString();
            json|error updateRedisCacheResponse = response.getJsonPayload();
            io:println(statusCode);
            io:println(reason);
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("Existing redis cache was successfully updated.");
                return updateRedisCacheResponse;
            } else {
                return createError("Error in Updating Azure Redis Cache");
            }
        } else {
            return createError("Not an Http Response");
        }
    }

    //Operations related to Firewall Rules (Contiguous range of IP addresses permitted to connect)

    # This Function Creates an FireWall rule
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + ruleName - Name of Rule Name
    # + startIP - Start IP of permitted range
    # + endIP - End IP of permitted range
    # + return - If successful, returns FirewallRuleResponse. Else returns error. 
    remote function createFirewallRule(string redisCacheName, string resourceGroupName, string ruleName, string startIP, 
                                       string endIP) returns @tainted FirewallRuleResponse|error {

        if (redisCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING || ruleName == EMPTY_STRING || startIP == 
        EMPTY_STRING || endIP == EMPTY_STRING) {
            return createError("Required values not provided");
        }

        var path = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/firewallRules/" + 
        ruleName + "?api-version=" + config:getAsString("API_VERSION");
        http:Request request = new;
        json createFilewallRuleJsonPayload = {"properties": {
                "startIP": startIP,
                "endIP": endIP
            }};
        request.setJsonPayload(createFilewallRuleJsonPayload);
        var response = self.AzureRedisClient->put(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            json|error createFirewallJsonResponse = response.getJsonPayload();
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("Existing Firewall rule Updated");
                if (createFirewallJsonResponse is json) {
                    FirewallRuleResponse createFirewallResponse = check <@untainted>createFirewallJsonResponse.
                    cloneWithType(FirewallRuleResponse);
                    return createFirewallResponse;
                } else {
                    return createError("Error in creating or updating Firewall rule");
                }
            } else if (statusCode == "201") {
                if (createFirewallJsonResponse is json) {
                    FirewallRuleResponse createFirewallResponse = check <@untainted>createFirewallJsonResponse.
                    cloneWithType(FirewallRuleResponse);
                    return createFirewallResponse;
                } else {
                    return createError("Error in creating or updating Firewall rule");
                }
            } else {
                return createError("Error in creating or updating Firewall rule");
            }
        } else {
            return createError("Not an Http Response");
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
            return createError("Required values not provided");
        }

        var path = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/firewallRules/" + 
        ruleName + "?api-version=" + config:getAsString("API_VERSION");
        http:Request request = new;
        var response = self.AzureRedisClient->delete(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("Firewall rule deleted");
                return jsonToStatusCode(statusCode);
            } else if (statusCode == "204") {
                io:println("Firewall rule deleted");
                return jsonToStatusCode(statusCode);
            } else {
                return createError("Error in deleting Firewall rule");
            }
        } else {
            return createError("Not an Http Response");
        }
    }

    # This Function Fetches an FireWall rule
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + ruleName - Name of Rule Name
    # + return - If successful, returns FirewallRuleResponse. Else returns error. 
    remote function getFirewallRule(string redisCacheName, string resourceGroupName, string ruleName) returns @tainted 
    FirewallRuleResponse|error {

        if (redisCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING || ruleName == EMPTY_STRING) {
            return createError("Required values not provided");
        }

        var path = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/firewallRules/" + 
        ruleName + "?api-version=" + config:getAsString("API_VERSION");
        http:Request request = new;
        var response = self.AzureRedisClient->get(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            json|error getFirewallJsonResponse = response.getJsonPayload();
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("Firewall rule fetched");
                if (getFirewallJsonResponse is json) {
                    FirewallRuleResponse getFirewallResponse = check <@untainted>getFirewallJsonResponse.cloneWithType(
                    FirewallRuleResponse);
                    return getFirewallResponse;
                } else {
                    return createError("Error in fetching Firewall rule");
                }
            } else {
                return createError("Error in fetching Firewall rule");
            }
        } else {
            return createError("Not an Http Response");
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
            return createError("Required values not provided");
        }

        var path = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/firewallRules?api-version=" + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        var response = self.AzureRedisClient->get(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            json|error listFirewallJsonResponse = response.getJsonPayload();
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("Firewall rule list fetched");
                if (listFirewallJsonResponse is json) {
                    FirewallRuleListResponse getFirewallResponseArray = check <@untainted>listFirewallJsonResponse.
                    cloneWithType(FirewallRuleListResponse);
                    return getFirewallResponseArray;
                } else {
                    return createError("Error in fetching Firewall rule list");
                }
            } else {
                return createError("Error in fetching Firewall rule list");
            }
        } else {
            return createError("Not an Http Response");
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
            return createError("Required values not provided");
        }

        var path = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/linkedServers/" + 
        linkedServerName + "?api-version=" + config:getAsString("API_VERSION");
        http:Request request = new;
        json createLinkedServerJsonPayload = {"properties": {
                "linkedRedisCacheId": linkedRedisCacheId,
                "linkedRedisCacheLocation": linkedRedisCacheLocation,
                "serverRole": serverRole
            }};
        request.setJsonPayload(createLinkedServerJsonPayload);
        var response = self.AzureRedisClient->put(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            json|error createLinkedServer = response.getJsonPayload();
            io:println(statusCode);
            io:println(createLinkedServer);
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("Existing LinkedServer Updated");
                if (createLinkedServer is json) {
                    io:println(createLinkedServer.id);
                    LinkedServer createLinkedServerResponse = check <@untainted>createLinkedServer.cloneWithType(
                    LinkedServer);
                    io:println(createLinkedServerResponse.properties.provisioningState);
                    return createLinkedServerResponse;
                } else {
                    return createError("Error in creating Linked server");
                }
            } else if (statusCode == "201") {
                io:println("New LinkedServer Created");
                if (createLinkedServer is json) {
                    io:println(createLinkedServer.id);
                    LinkedServer createLinkedServerResponse = check <@untainted>createLinkedServer.cloneWithType(
                    LinkedServer);
                    io:println(createLinkedServerResponse.properties.provisioningState);
                    return createLinkedServerResponse;
                } else {
                    return createError("Error in creating Linked server");
                }
            } else {
                return createError("Error in creating or Updating LinkedServer");
            }
        } else {
            return createError("Not an Http Response");
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
            return createError("Required values not provided");
        }

        var path = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/linkedServers/" + 
        linkedServerName + "?api-version=" + config:getAsString("API_VERSION");
        http:Request request = new;
        var response = self.AzureRedisClient->delete(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            string reason = response.getJsonPayload().toString();
            io:println(statusCode);
            io:println(reason);
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("LinkedServer deleted");
                return jsonToStatusCode(statusCode);
            } else if (statusCode == "204") {
                io:println("LinkedServer deleted");
                return jsonToStatusCode(statusCode);
            } else {
                io:println("Error in deleting LinkedServer");
                return jsonToStatusCode(statusCode);
            }
        } else {
            return createError("Not an Http Response");
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
            return createError("Required values not provided");
        }

        var path = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/linkedServers/" + 
        linkedServerName + "?api-version=" + config:getAsString("API_VERSION");
        http:Request request = new;
        var response = self.AzureRedisClient->get(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            json|error payload = response.getJsonPayload();
            io:println(statusCode);
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("LinkedServer fetched");
                if (payload is json) {
                    LinkedServer getLinkedServerResponse = check <@untainted>payload.cloneWithType(LinkedServer);
                    return getLinkedServerResponse;
                } else {
                    return createError("Error in fetching RedisCacheResponse");
                }
            } else {
                return createError("Error in fetching LinkedServer");
            }
        } else {
            return createError("Not an Http Response");
        }
    }

    # This Function Fetches list of Linked Servers
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found. 
    # + return - If successful, returns LinkedServer[]. Else returns error. 
    remote function listLinkedServers(string redisCacheName, string resourceGroupName) 
    returns @tainted StatusCode|error {

        if (redisCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING) {
            return createError("Required values not provided");
        }

        var path = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/linkedServers?api-version=" + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        var response = self.AzureRedisClient->get(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            string reason = response.getJsonPayload().toString();
            io:println(statusCode);
            io:println(reason);
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("LinkedServer list fetched");
                return jsonToStatusCode(statusCode);
            } else {
                io:println("Error in fetching LinkedServers");
                return jsonToStatusCode(statusCode);
            }
        } else {
            return createError("Not an Http Response");
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
    returns @tainted PatchShedule|error {

        if (redisCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING) {
            return createError("Required values not provided");
        }

        var path = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/patchSchedules/default?api-version=" + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        json payload = {properties: <json>patchScheduleProperties.cloneWithType(json)};
        request.setJsonPayload(payload);
        var response = self.AzureRedisClient->put(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            json|error createPatchJsonResponse = response.getJsonPayload();
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("Existing Patch Schedule Updated");
                if (createPatchJsonResponse is json) {
                    PatchShedule createPatchResponse = check <@untainted>createPatchJsonResponse.cloneWithType(
                    PatchShedule);
                    return createPatchResponse;
                } else {
                    return createError("Error in creating or updating Firewall rule");
                }
            } else if (statusCode == "201") {
                io:println("New Patch Schedule Created");
                if (createPatchJsonResponse is json) {
                    PatchShedule createPatchResponse = check <@untainted>createPatchJsonResponse.cloneWithType(
                    PatchShedule);
                    return createPatchResponse;
                } else {
                    return createError("Error in creating or updating Firewall rule");
                }
            } else {
                return createError("Error in creating or updating Patch Schedule");
            }
        } else {
            return createError("Not an Http Response");
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
            return createError("Required values not provided");
        }

        var path = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/patchSchedules/default?api-version=" + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        var response = self.AzureRedisClient->delete(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200" || statusCode == "204") {
                io:println("Patch Schedule deleted");
                return jsonToStatusCode(statusCode);
            } else {
                return createError("Error in deleting Patch Schedule");
            }
        } else {
            return createError("Not an Http Response");
        }
    }

    # This Function Fetches Patch Schedule
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + return - If successful, returns PatchSchedule. Else returns error. 
    remote function getPatchSchedule(string redisCacheName, string resourceGroupName) 
    returns @tainted PatchShedule|error {

        if (redisCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING) {
            return createError("Required values not provided");
        }

        var path = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/patchSchedules/default?api-version=" + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        var response = self.AzureRedisClient->get(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            json|error getPatchJsonResponse = response.getJsonPayload();
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("Patch Schedule fetched");
                if (getPatchJsonResponse is json) {
                    PatchShedule getPatchResponse = check <@untainted>getPatchJsonResponse.cloneWithType(PatchShedule);
                    return getPatchResponse;
                } else {
                    return createError("Error in fetching Patch Schedule");
                }
            } else {
                return createError("Error in fetching Patch Schedule");
            }
        } else {
            return createError("Not an Http Response");
        }
    }

    # This Function Fetches Patch Schedule
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + return - If successful, returns PatchSchedule[]. Else returns error. 
    remote function listPatchSchedules(string redisCacheName, string resourceGroupName) returns @tainted 
    PatchSheduleList|error {

        if (redisCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING) {
            return createError("Required values not provided");
        }

        var path = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/patchSchedules?api-version=" + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        var response = self.AzureRedisClient->get(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            json|error PatchSheduleJsonResponse = response.getJsonPayload();
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("Patch Schedule list fetched");
                if (PatchSheduleJsonResponse is json) {
                    PatchSheduleList getPatchSheduleArray = check <@untainted>PatchSheduleJsonResponse.cloneWithType(
                    PatchSheduleList);
                    return getPatchSheduleArray;
                } else {
                    return createError("Error in fetching Patch Schedule");
                }
            } else {
                return createError("Error in fetching Patch Schedule");
            }
        } else {
            return createError("Not an Http Response");
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
            return createError("Required values not provided");
        }

        var path = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/privateEndpointConnections/" + 
        privateEndpointConnectionName + "?api-version=" + config:getAsString("API_VERSION");
        http:Request request = new;
        json putPrivateEndpointConnectionJsonPayload = {"properties": {"privateLinkServiceConnectionState": {
                    "status": "Approved",
                    "description": "Auto-Approved"
                }}};
        request.setJsonPayload(putPrivateEndpointConnectionJsonPayload);
        var response = self.AzureRedisClient->put(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            string payload = response.getJsonPayload().toString();
            io:println(statusCode);
            io:println(payload);
            json|error privateEndpointConnection = response.getJsonPayload();
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("Existing LinkedServer Updated");
                //return jsonToStatusCode(statusCode);
                return privateEndpointConnection;
            } else if (statusCode == "201") {
                io:println("New PrivateEndpointConnection Created");
                //return jsonToStatusCode(statusCode);
                return privateEndpointConnection;
            } else {
                return createError("Error in creating or Updating PrivateEndpointConnection");
            //return jsonToStatusCode(statusCode);
            }
        } else {
            return createError("Not an Http Response");
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
            return createError("Required values not provided");
        }

        var path = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/privateEndpointConnections/" + 
        privateEndpointConnectionName + "?api-version=" + config:getAsString("API_VERSION");
        http:Request request = new;
        var response = self.AzureRedisClient->get(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            json|error privateEndpointConnection = response.getJsonPayload();
            io:println(statusCode);
            io:println(privateEndpointConnection);
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("PrivateEndpointConnection fetched");
                //return jsonToStatusCode(statusCode);
                return privateEndpointConnection;
            } else {
                return createError("Error in fetching PrivateEndpointConnection");
            }
        } else {
            return createError("Not an Http Response");
        }
    }

    # This Function Fetches Private Endpoint Connection
    #
    # + redisCacheName - Redis Cache Instance Name 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + return - If successful, returns PrivateEndpointConnection[]. Else returns error.
    remote function listPrivateEndpointConnection(string redisCacheName, string resourceGroupName) returns @tainted 
    StatusCode|error {

        if (redisCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING) {
            return createError("Required values not provided");
        }

        var path = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/privateEndpointConnections?api-version=" + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        var response = self.AzureRedisClient->get(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            json|error privateEndpointConnection = response.getJsonPayload();
            io:println(statusCode);
            io:println(privateEndpointConnection);
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("Fetching PrivateEndpointConnection list");
                //return jsonToStatusCode(statusCode);
                //return privateEndpointConnection;
                return jsonToStatusCode(statusCode);
            } else {
                io:println("Error in fetching PrivateEndpointConnection list");
                return jsonToStatusCode(statusCode);
            }
        } else {
            return createError("Not an Http Response");
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
            return createError("Required values not provided");
        }

        var path = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/privateEndpointConnections/" + 
        privateEndpointConnectionName + "?api-version=" + config:getAsString("API_VERSION");
        http:Request request = new;
        var response = self.AzureRedisClient->delete(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            json|error privateEndpointConnection = response.getJsonPayload();
            io:println(statusCode);
            io:println(privateEndpointConnection);
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("PrivateEndpointConnection deleted");
                return jsonToStatusCode(statusCode);
            } else if (statusCode == "204") {
                io:println("PrivateEndpointConnection deleted");
                return jsonToStatusCode(statusCode);
            } else {
                return createError("Error in deleting PrivateEndpointConnection");
            }
        } else {
            return createError("Not an Http Response");
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

        var path = 
        "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redis/" + redisCacheName + "/privateLinkResources?api-version=" + 
        config:getAsString("API_VERSION");
        http:Request request = new;
        var response = self.AzureRedisClient->get(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            string payload = response.getJsonPayload().toString();
            io:println(statusCode);
            io:println(payload);
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("PrivateLinkResources fetched");
                return jsonToStatusCode(statusCode);
            } else {
                io:println("Error in fetching PrivateLinkResources");
                return jsonToStatusCode(statusCode);
            }
        } else {
            return createError("Not an Http Response");
        }
    }

    //Function related to Redis enterprise cache Databases

    # This Function Creates Redis Enterprise Cache Database
    #
    # + redisEnterpriseCacheName - Redis Enterprise Cache Database Name
    # + resourceGroupName - Resource Group Name where Redis Cache found
    # + databaseName - Name of Database Name
    # + return - If successful, returns RedisEnterpriseCacheDatabase. Else returns error 
    remote function createRedisEnterpriseCacheDatabase(string redisEnterpriseCacheName, string resourceGroupName, 
                                                       string databaseName) returns @tainted StatusCode|error {

        var path = "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
        redisEnterpriseCacheName + "/databases/" + databaseName + "?api-version=" + config:getAsString(
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
        var response = self.AzureRedisClient->put(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            string payload = response.getJsonPayload().toString();
            io:println(statusCode);
            io:println(payload);
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("Redis Enterprise Cache Database created");
                return jsonToStatusCode(statusCode);
            } else if (statusCode == "201") {
                io:println("Redis Enterprise Cache Database created");
                return jsonToStatusCode(statusCode);
            } else {
                io:println("Error in creating Redis Enterprise Cache Database");
                return jsonToStatusCode(statusCode);
            }
        } else {
            return createError("Not an Http Response");
        }
    }

    # This Function Deletes Redis Enterprise Cache Database
    #
    # + redisEnterpriseCacheName - Redis Enterprise Cache Database Name. 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + databaseName - Name of Database Name
    # + return - If successful, returns StatusCode. Else returns error. 
    remote function deleteRedisEnterpriseCacheDatabase(string redisEnterpriseCacheName, string resourceGroupName, 
                                                       string databaseName) returns @tainted StatusCode|error {

        if (redisEnterpriseCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING) {
            return createError("Required values not provided");
        }

        var path = "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
        redisEnterpriseCacheName + "/databases/" + databaseName + "?api-version=" + config:getAsString(
        "ENTERPRISE_API_VERSION");
        http:Request request = new;
        var response = self.AzureRedisClient->delete(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            string payload = response.getJsonPayload().toString();
            io:println(statusCode);
            io:println(payload);
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("Redis cache was successfully deleted");
                return jsonToStatusCode(statusCode);
            } else if (statusCode == "202") {
                io:println("Redis cache delete operation was successfully enqueued");
                return jsonToStatusCode(statusCode);
            } else if (statusCode == "204") {
                io:println("Redis cache was successfully deleted");
                return jsonToStatusCode(statusCode);
            } else {
                io:println("Error in deleting Azure Redis Cache");
                return jsonToStatusCode(statusCode);
            }
        } else {
            return createError("Not an Http Response");
        }
    }

    # This Function exports Redis Enterprise Cache Database
    #
    # + redisEnterpriseCacheName - Redis Enterprise Cache Database Name. 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + databaseName - Name of Database Name
    # + blobContainerUrl - path to bolb container 
    # + sasKeyParameters - SAS key
    # + return - If successful, returns StatusCode. Else returns error. 
    remote function exportRedisEnterpriseCacheDatabase(string redisEnterpriseCacheName, string resourceGroupName, 
                                                       string databaseName, string blobContainerUrl, 
                                                       string sasKeyParameters) returns @tainted StatusCode|error {

        if (redisEnterpriseCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING || sasKeyParameters == 
        EMPTY_STRING || blobContainerUrl == EMPTY_STRING) {
            return createError("Required values not provided");
        }

        var path = "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
        redisEnterpriseCacheName + "/databases/" + databaseName + "/export?api-version=" + config:getAsString(
        "ENTERPRISE_API_VERSION");
        http:Request request = new;
        json exportCacheJsonPayload = {"sasUri": blobContainerUrl + "?" + sasKeyParameters};
        request.setJsonPayload(exportCacheJsonPayload);
        var response = self.AzureRedisClient->post(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            string payload = response.getJsonPayload().toString();
            io:println(statusCode);
            io:println(payload);
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("Redis cache was successfully exported");
                return jsonToStatusCode(statusCode);
            } else if (statusCode == "202") {
                io:println("Redis cache export operation was successfully enqueued");
                return jsonToStatusCode(statusCode);
            } else if (statusCode == "204") {
                io:println("Redis cache was successfully exported");
                return jsonToStatusCode(statusCode);
            } else {
                io:println("Error in exporting Azure Redis Cache");
                return jsonToStatusCode(statusCode);
            }
        } else {
            return createError("Not an Http Response");
        }
    }

    # This Function imports Redis Enterprise Cache Database
    #
    # + redisEnterpriseCacheName - Redis Enterprise Cache Database Name. 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + databaseName - Name of Database Name
    # + blobFileUrl - path to bolb file storage 
    # + sasKeyParameters - SAS key
    # + return - If successful, returns StatusCode. Else returns error. 
    remote function importRedisEnterpriseCacheDatabase(string redisEnterpriseCacheName, string resourceGroupName, 
                                                       string databaseName, string blobFileUrl, string sasKeyParameters) returns @tainted 
    StatusCode|error {

        if (redisEnterpriseCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING) {
            return createError("Required values not provided");
        }

        var path = "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
        redisEnterpriseCacheName + "/databases/" + databaseName + "/import?api-version=" + config:getAsString(
        "ENTERPRISE_API_VERSION");
        http:Request request = new;
        json importCacheJsonPayload = {"sasUri": blobFileUrl + "?" + sasKeyParameters};
        request.setJsonPayload(importCacheJsonPayload);
        var response = self.AzureRedisClient->post(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            string payload = response.getJsonPayload().toString();
            io:println(statusCode);
            io:println(payload);
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("Redis cache was successfully imported");
                return jsonToStatusCode(statusCode);
            } else if (statusCode == "202") {
                io:println("Redis cache import operation was successfully enqueued");
                return jsonToStatusCode(statusCode);
            } else if (statusCode == "204") {
                io:println("Redis cache was successfully imported");
                return jsonToStatusCode(statusCode);
            } else {
                io:println("Error in importing Azure Redis Cache");
                return jsonToStatusCode(statusCode);
            }
        } else {
            return createError("Not an Http Response");
        }
    }

    # This Function Fetches Redis Enterprise Cache Database
    #
    # + redisEnterpriseCacheName - Redis Enterprise Cache Database Name. 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + databaseName - Name of Database Name
    # + return - If successful, returns RedisEnterpriseCacheDatabase. Else returns error. 
    remote function getRedisEnterpriseCacheDatabase(string redisEnterpriseCacheName, string resourceGroupName, 
                                                    string databaseName) returns @tainted StatusCode|error {

        if (redisEnterpriseCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING) {
            return createError("Required values not provided");
        }

        var path = "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
        redisEnterpriseCacheName + "/databases/" + databaseName + "?api-version=" + config:getAsString(
        "ENTERPRISE_API_VERSION");
        http:Request request = new;
        var response = self.AzureRedisClient->get(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            json|error payload = response.getJsonPayload();
            io:println(statusCode);
            io:println(payload);
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("Redis cache was successfully found");
                return jsonToStatusCode(statusCode);
            } else {
                return createError("Error in fetching Azure Redis Cache");
            }
        } else {
            return createError("Not an Http Response");
        }
    }

    # This Function lists Redis Enterprise Cache Database
    #
    # + redisEnterpriseCacheName - Redis Enterprise Cache Database Name. 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + return - If successful, returns RedisEnterpriseCacheDatabase[]. Else returns error. 
    remote function listRedisEnterpriseCacheDatabaseByCluster(string redisEnterpriseCacheName, string resourceGroupName) returns @tainted 
    StatusCode|error {

        if (redisEnterpriseCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING) {
            return createError("Required values not provided");
        }

        var path = "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
        redisEnterpriseCacheName + "/databases?api-version=" + config:getAsString("ENTERPRISE_API_VERSION");
        http:Request request = new;
        var response = self.AzureRedisClient->get(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            string payload = response.getJsonPayload().toString();
            io:println(statusCode);
            io:println(payload);
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("Redis cache list under resource group was successfully found");
                return jsonToStatusCode(statusCode);
            } else {
                io:println("Error in fetching Azure Redis Cache list by resource group");
                return jsonToStatusCode(statusCode);
            }
        } else {
            return createError("Not an Http Response");
        }
    }

    # This Function lists Redis Enterprise Cache Database Keys
    #
    # + redisEnterpriseCacheName - Redis Enterprise Cache Database Name. 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + return - If successful, returns RedisEnterpriseCacheDatabaseKeys. Else returns error. 
    remote function listRedisEnterpriseCacheDatabaseKeys(string redisEnterpriseCacheName, string resourceGroupName, 
                                                         string databaseName) returns @tainted StatusCode|error {

        if (redisEnterpriseCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING) {
            return createError("Required values not provided");
        }

        var path = "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
        redisEnterpriseCacheName + "/databases/" + databaseName + "/listKeys?api-version=" + config:getAsString(
        "ENTERPRISE_API_VERSION");
        http:Request request = new;
        var response = self.AzureRedisClient->post(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            string payload = response.getJsonPayload().toString();
            io:println(statusCode);
            io:println(payload);
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("Keys of Redis cache was successfully found");
                return jsonToStatusCode(statusCode);
            } else {
                io:println("Error in fetching Keys of Azure Redis Cache");
                return jsonToStatusCode(statusCode);
            }
        } else {
            return createError("Not an Http Response");
        }
    }

    # This Function Regenerates Redis Enterprise Cache Database Key
    #
    # + redisEnterpriseCacheName - Redis Enterprise Cache Database Name. 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + databaseName - Name of Database Name
    # + return - If successful, returns StatusCode. Else returns error. 
    remote function regenerateRedisEnterpriseCacheDatabaseKey(string redisEnterpriseCacheName, string resourceGroupName, 
                                                              string databaseName, string keyType) returns @tainted 
    StatusCode|error {

        if (redisEnterpriseCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING || keyType == EMPTY_STRING) {
            return createError("Required values not provided");
        }

        var path = "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
        redisEnterpriseCacheName + "/databases/" + databaseName + "/regenerateKey?api-version=" + config:getAsString(
        "ENTERPRISE_API_VERSION");
        http:Request request = new;
        json regenerateKeyJsonPayload = {"keyType": keyType};
        request.setJsonPayload(regenerateKeyJsonPayload);
        var response = self.AzureRedisClient->post(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            string payload = response.getJsonPayload().toString();
            io:println(statusCode);
            io:println(payload);
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("Lists the regenerated keys for Redis Cache");
                return jsonToStatusCode(statusCode);
            } else if (statusCode == "202") {
                io:println("Lists the regenerated keys for Redis Cache");
                return jsonToStatusCode(statusCode);
            } else {
                io:println("Error in regenerating keys for Redis Cache");
                return jsonToStatusCode(statusCode);
            }
        } else {
            return createError("Not an Http Response");
        }
    }

    //This function is currently not supported at the moment as stated in Azure Redis REST API Documentation.

    # This Function Updates Redis Enterprise Cache Database
    #
    # + redisEnterpriseCacheName - Redis Enterprise Cache Database Name. 
    # + resourceGroupName - Resource Group Name where Redis Cache found.
    # + databaseName - Name of Database Name
    # + clientProtocol - Encrypted or Plaintext
    # + moduleName - The name of the module (RedisBloom, RediSearch, RedisTimeSeries)
    # + evictionPolicy - Redis eviction policy(Default is VolatileLRU)
    # 
    # + return - If successful, returns RedisEnterpriseCacheDatabase. Else returns error. 
    remote function updateRedisEnterpriseCacheDatabase(string redisEnterpriseCacheName, string resourceGroupName, 
                                                       string databaseName, string clientProtocol, string evictionPolicy, 
                                                       string moduleName) returns @tainted StatusCode|error {

        if (redisEnterpriseCacheName == EMPTY_STRING || resourceGroupName == EMPTY_STRING) {
            return createError("Required values not provided");
        }

        var path = "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
        redisEnterpriseCacheName + "/databases/" + databaseName + "?api-version=" + config:getAsString(
        "ENTERPRISE_API_VERSION");
        http:Request request = new;
        json updateCacheJsonPayload = {"properties": {
                "clientProtocol": clientProtocol,
                "evictionPolicy": evictionPolicy,
                "modules": [{"name": moduleName}]
            }};
        request.setJsonPayload(updateCacheJsonPayload);
        var response = self.AzureRedisClient->patch(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            string payload = response.getJsonPayload().toString();
            io:println(statusCode);
            io:println(payload);
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("Existing redis cache was successfully updated.");
                return jsonToStatusCode(statusCode);
            } else {
                io:println("Error in Updating Azure Redis Cache");
                return jsonToStatusCode(statusCode);
            }
        } else {
            return createError("Not an Http Response");
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
    # + return - If successful, returns EnterpriseClusterInstance. Else returns error. 
    remote function createRedisEnterprise(string redisEnterpriseClusterName, string resourceGroupName, string location, 
                                          string skuName, int skuCapacity) returns @tainted StatusCode|error {

        var path = "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
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
        var response = self.AzureRedisClient->put(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            string payload = response.getJsonPayload().toString();
            io:println(statusCode);
            io:println(payload);
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("Redis Enterprise Cache created or updated");
                return jsonToStatusCode(statusCode);
            } else if (statusCode == "201") {
                io:println("Redis Enterprise Cache created or updated");
                return jsonToStatusCode(statusCode);
            } else if (statusCode == "204") {
                io:println("Redis Enterprise Cache created or updated");
                return jsonToStatusCode(statusCode);
            } else {
                io:println("Error in fetching Redis Enterprise Cache");
                return jsonToStatusCode(statusCode);
            }
        } else {
            return createError("Not an Http Response");
        }
    }

    # This Function Fetches a Redis Enterprise Cluster
    #
    # + redisEnterpriseClusterName - Redis Enterprise ClusterName 
    # + resourceGroupName - Resource Group Name where Redis Enterprise found.
    # + return - If successful, returns EnterpriseClusterInstance. Else returns error. 
    remote function getRedisEnterprise(string redisEnterpriseClusterName, string resourceGroupName) returns @tainted 
    RedisEnterpriseCacheInstance|error {

        var path = "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
        redisEnterpriseClusterName + "?api-version=" + config:getAsString("ENTERPRISE_API_VERSION");
        http:Request request = new;
        var response = self.AzureRedisClient->get(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            json|error payload = response.getJsonPayload();
            io:println(statusCode);
            io:println(payload);
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                if (payload is json) {
                    RedisEnterpriseCacheInstance getRedisEnterpriseCacheResponse = check <@untainted>payload.
                    cloneWithType(RedisEnterpriseCacheInstance);
                    return getRedisEnterpriseCacheResponse;
                } else {
                    return createError("Error in fetching Redis Enterprise Cache");
                }
            } else {
                return createError("Error in fetching Redis Enterprise Cache");
            }
        } else {
            return createError("Not an Http Response");
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
            return createError("Required values not provided");
        }

        var path = "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
        redisEnterpriseClusterName + "?api-version=" + config:getAsString("ENTERPRISE_API_VERSION");
        http:Request request = new;
        var response = self.AzureRedisClient->delete(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            string payload = response.getJsonPayload().toString();
            io:println(statusCode);
            io:println(payload);
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("Redis Enterprise cache was successfully deleted");
                return jsonToStatusCode(statusCode);
            } else if (statusCode == "202") {
                io:println("Redis Enterprise cache delete operation was successfully enqueued");
                return jsonToStatusCode(statusCode);
            } else if (statusCode == "204") {
                io:println("Redis Enterprise cache was successfully deleted");
                return jsonToStatusCode(statusCode);
            } else {
                io:println("Error in deleting Azure Redis Cache");
                return jsonToStatusCode(statusCode);
            }
        } else {
            return createError("Not an Http Response");
        }
    }

    # This Function Fetches a list of Redis Enterprise Cluster in a subscription
    # 
    # + return - If successful, returns EnterpriseClusterInstance[]. Else returns error. 
    remote function listRedisEnterprise() returns @tainted StatusCode|error {

        var path = "/providers/Microsoft.Cache/redisEnterprise?api-version=" + config:getAsString(
        "ENTERPRISE_API_VERSION");
        http:Request request = new;
        var response = self.AzureRedisClient->get(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            string payload = response.getJsonPayload().toString();
            io:println(statusCode);
            io:println(payload);
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("Redis cache list was successfully found");
                return jsonToStatusCode(statusCode);
            } else {
                io:println("Error in fetching Azure Redis Enterprise Cache list");
                return jsonToStatusCode(statusCode);
            }
        } else {
            return createError("Not an Http Response");
        }
    }

    # This Function Fetches a Redis Enterprise Cluster in a subscription within a specific resource group
    # 
    # + resourceGroupName - Resource Group Name where Redis Enterprise found.
    # + return - If successful, returns EnterpriseClusterInstance[]. Else returns error. 
    remote function listRedisEnterpriseByResourceGroup(string resourceGroupName) returns @tainted StatusCode|error {

        if (resourceGroupName == EMPTY_STRING) {
            return createError("Required values not provided");
        }

        var path = "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise?api-version=" + 
        config:getAsString("ENTERPRISE_API_VERSION");
        http:Request request = new;
        var response = self.AzureRedisClient->get(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            string payload = response.getJsonPayload().toString();
            io:println(statusCode);
            io:println(payload);
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("Keys of Redis cache  by resource group was successfully found");
                return jsonToStatusCode(statusCode);
            } else {
                io:println("Error in fetching of Azure Redis Enterprise Cache by resource group");
                return jsonToStatusCode(statusCode);
            }
        } else {
            return createError("Not an Http Response");
        }
    }

    //This function is currently not supported at the moment as stated in Azure Redis REST API Documentation.

    # This Function Updates the Redis Enterprise Cluster
    #  
    # + redisEnterpriseClusterName - Redis Enterprise ClusterName 
    # + resourceGroupName - Resource Group Name where Redis Enterprise found.
    # + return - If successful, returns EnterpriseClusterInstance. Else returns error. 
    remote function updateRedisEnterprise(string redisEnterpriseClusterName, string resourceGroupName) returns @tainted 
    StatusCode|error {

        if (redisEnterpriseClusterName == EMPTY_STRING || resourceGroupName == EMPTY_STRING) {
            return createError("Required values not provided");
        }

        var path = "/resourceGroups/" + resourceGroupName + "/providers/Microsoft.Cache/redisEnterprise/" + 
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
        var response = self.AzureRedisClient->patch(<@untainted>path, request);
        if (response is http:Response) {
            string statusCode = response.statusCode.toString();
            string payload = response.getJsonPayload().toString();
            io:println(statusCode);
            io:println(payload);
            if (statusCode == "401") {
                return createError("Authentication failed");
            } else if (statusCode == "200") {
                io:println("Existing redis cache was successfully updated.");
                return jsonToStatusCode(statusCode);
            } else {
                io:println("Error in Updating Azure Redis Enterprise Cache");
                return jsonToStatusCode(statusCode);
            }
        } else {
            return createError("Not an Http Response");
        }
    }
}
