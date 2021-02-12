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
import ballerina/log;
import ballerina/test;
import ballerina/config;

AzureRedisConfiguration config = {oauth2Config: {
        tokenUrl: "https://login.microsoftonline.com/" + config:getAsString("TENANT_ID") + "/oauth2/v2.0/token",
        clientId: config:getAsString("CLIENT_ID"),
        clientSecret: config:getAsString("CLIENT_SECRET"),
        scopes: ["https://management.azure.com/.default"]
    }};

Client azureRedisManagementClient = new (config);

@test:Config {}
function testCheckeAzureCacheAvailability() {
    log:print("<---Running Checking RedisCacheName availability Test--->");
    var response = azureRedisManagementClient->checkAzureCacheNameAvailability(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache");
    if (response is boolean) {
        test:assertEquals(response, true, msg = "Name not available or recently deleted");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {}
function testCreateRedisCache() {
    CreateCacheProperty properties = 
    {
        "sku": {
            "name": "Basic",
            "family": "C",
            "capacity": 1
        },
        "enableNonSslPort": true,
        "redisConfiguration": {"maxmemory-policy": "allkeys-lru"},
        "minimumTlsVersion": "1.2",
        "publicNetworkAccess": "Enabled"
    };
    log:print("<---Running CreateRedisCache Test--->");
    var response = azureRedisManagementClient->createRedisCache(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") , "southeastasia", 
    properties);
    if (response is RedisCacheInstance) {
        boolean createSuccess = true;
        log:print("Deployment in progress...");
        json state = response.properties.provisioningState;
        while (state != "Succeeded") {
            var getresponse = azureRedisManagementClient->getRedisCache(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") );
            if (getresponse is RedisCacheInstance) {
                state = getresponse.properties.provisioningState;
            }
        }
        test:assertEquals(createSuccess, true, msg = "Error in creating Azure Cache");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {
    dependsOn: ["testCreateRedisCache"]
}
function testGetRedisCache() {
    log:print("<---Running GetRedisCache Test--->");
    var response = azureRedisManagementClient->getRedisCache(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") );
    if (response is RedisCacheInstance) {
        boolean getSuccess = true;
        test:assertEquals(getSuccess, true, msg = "Error in fetching Azure Instance");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {
    dependsOn: ["testCreateRedisCache"]
}
function testGetHostName() {
    log:print("<---Running GetHostName Test--->");
    var response = azureRedisManagementClient->getHostName(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") );
    if (response is string) {
        string expectedHostName = "TestRedisConnectorCache.redis.cache.windows.net";
        test:assertEquals(response, expectedHostName, msg = "Error in fetching Azure Cache Host Name");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {
    dependsOn: ["testCreateRedisCache"]
}
function testGetSSLPortNumber() {
    log:print("<---Running GetPortNumber Test--->");
    var response = azureRedisManagementClient->getSSLPortNumber(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") );
    if (response is int) {
        int expectedSSLPortNumber = 6380;
        test:assertEquals(response, expectedSSLPortNumber, msg = "Error in fetching Azure Cache SSL Port Number");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {
    dependsOn: ["testCreateRedisCache"]
}
function testGetNonSSLPortNumber() {
    log:print("<---Running GetPortNumber Test--->");
    var response = azureRedisManagementClient->getNonSSLPortNumber(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") );
    if (response is int) {
        int expectedSSLPortNumber = 6379;
        test:assertEquals(response, expectedSSLPortNumber, msg = "Error in fetching Azure Cache Non SSL Port Number");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {
    dependsOn: ["testCreateRedisCache"]
}
function testGetPrimaryKey() {
    log:print("<---Running GetPortNumber Test--->");
    var response = azureRedisManagementClient->getPrimaryKey(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") );
    if (response is string) {
        test:assertTrue(true, msg = "Error in fetching Azure Cache Primary Key");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {
    dependsOn: ["testCreateRedisCache"]
}
function testListByResourceGroup() {
    log:print("<---Running ListByResourceGroup Test--->");
    var response = azureRedisManagementClient->listRedisCacheInstances(config:getAsString("SUBSCRIPTION_ID"), config:getAsString("RESOURCE_GROUP_NAME") );
    if (response is RedisCacheInstance[]) {
        boolean listSuccess = true;
        test:assertEquals(listSuccess, true, msg = "Error in Listing Azure Instances");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {
    dependsOn: ["testCreateRedisCache"]
}
function testListBySubscription() {
    log:print("<---Running ListBySubscription Test--->");
    var response = azureRedisManagementClient->listRedisCacheInstances(config:getAsString("SUBSCRIPTION_ID"));
    if (response is RedisCacheInstance[]) {
        boolean listSuccess = true;
        test:assertEquals(listSuccess, true, msg = "Error in Listing Azure Instances");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {
    dependsOn: ["testCreateRedisCache"]
}
function testListKeys() {
    log:print("<---Running ListKeys Test--->");
    var response = azureRedisManagementClient->listKeys(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") );
    if (response is AccessKey) {
        boolean listKey = true;
        test:assertEquals(listKey, true, msg = "Error in Listing Azure Instance Key");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {
    dependsOn: ["testCreateRedisCache"]
}
function testRegenerateKey() {
    log:print("<---Running RegenerateKey Test--->");
    var response = azureRedisManagementClient->regenerateKey(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") , "Primary");
    if (response is AccessKey) {
        boolean listKey = true;
        test:assertEquals(listKey, true, msg = "Error in regenerating Azure Instance Key");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {
    dependsOn: ["testCreateRedisCache"]
}
function testUpdateRedisCache() {
    log:print("<---Running UpdateRedisCache--->");

    CreateCacheProperty properties = 
    {
        "sku": {
            "name": "Basic",
            "family": "C",
            "capacity": 1
        },
        "enableNonSslPort": false,
        "redisConfiguration": {"maxmemory-policy": "allkeys-lru"},
        "minimumTlsVersion": "1.2",
        "publicNetworkAccess": "Enabled"
    };

    var response = azureRedisManagementClient->updateRedisCache(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME"), properties);
    if (response is RedisCacheInstance) {
        boolean updateSuccess = true;
        test:assertEquals(updateSuccess, true, msg = "Error in updating RedisCache");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {
    dependsOn: ["testCreateRedisCache"]
}
function testCreateFirewallRule() {
    log:print("<---Running CreateFireWallRule Test--->");
    var response = azureRedisManagementClient->createFirewallRule(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") , 
    "TestFilewallRule", "192.168.1.1", "192.168.1.4");
    if (response is FirewallRule) {
        FirewallRule testValue = 
        {
            "id": 
            "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/" + config:getAsString("RESOURCE_GROUP_NAME")  + "/providers/Microsoft.Cache/redis/TestRedisConnectorCache/firewallRules/TestFilewallRule",
            "name": "TestRedisConnectorCache/TestFilewallRule",
            "type": "Microsoft.Cache/redis/firewallRules",
            "properties": {
                "startIP": "192.168.1.1",
                "endIP": "192.168.1.4"
            }
        };

        test:assertEquals(response, testValue, msg = "Error in creating firewall rule");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {
    dependsOn: ["testCreateFirewallRule"]
}
function testGetFireWallRule() {
    log:print("<---Running GetFireWallRule Test--->");
    var response = azureRedisManagementClient->getFirewallRule(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") , "TestFilewallRule");
    if (response is FirewallRule) {
        FirewallRule testValue = 
        {
            "id": 
            "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/" + config:getAsString("RESOURCE_GROUP_NAME")  + "/providers/Microsoft.Cache/Redis/TestRedisConnectorCache/firewallRules/TestFilewallRule",
            "name": "TestRedisConnectorCache/TestFilewallRule",
            "type": "Microsoft.Cache/Redis/firewallRules",
            "properties": {
                "startIP": "192.168.1.1",
                "endIP": "192.168.1.4"
            }
        };
        test:assertEquals(response, testValue, msg = "Error in fetching firewall rule");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {
    dependsOn: ["testCreateFirewallRule"]
}
function testListFireWallRule() {
    log:print("<---Running ListFireWallRule Test--->");
    var response = azureRedisManagementClient->listFirewallRules(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") );
    if (response is FirewallRule[]) {
        FirewallRule[] testValue = [
            {
                "id": 
                "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/" + config:getAsString("RESOURCE_GROUP_NAME")  + "/providers/Microsoft.Cache/Redis/TestRedisConnectorCache/firewallRules/TestFilewallRule",
                "name": "TestRedisConnectorCache/TestFilewallRule",
                "type": "Microsoft.Cache/Redis/firewallRules",
                "properties": {
                    "startIP": "192.168.1.1",
                    "endIP": "192.168.1.4"
                }
            }];
        test:assertEquals(response, testValue, msg = "Error in listing firewall rule");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {
    dependsOn: ["testCreateFirewallRule"]
}
function testDeleteFireWallRule() {
    log:print("<---Running DeleteFireWallRule Test--->");
    var response = azureRedisManagementClient->deleteFirewallRule(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") , 
    "TestFilewallRule");
    if (response is boolean) {
        test:assertEquals(response, true, msg = "Deleting firewall rule test failed");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {
    dependsOn: ["testCreateRedisCache"]
}
function testCreatePatchSchedule() {
    PatchScheduleProperty properties = {scheduleEntries: [{
            dayOfWeek: "Monday",
            startHourUtc: 12,
            maintenanceWindow: "PT5H"
        }, {
            dayOfWeek: "Tuesday",
            startHourUtc: 12
        }]};

    log:print("<---Running CreatePatchSchedule Test--->");
    var response = azureRedisManagementClient->createPatchSchedule(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") , properties);
    if (response is PatchSchedule) {
        PatchSchedule testValue = 
        {
            "id": 
            "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/" + config:getAsString("RESOURCE_GROUP_NAME")  + "/providers/Microsoft.Cache/Redis/TestRedisConnectorCache/patchSchedules/default",
            "location": "Southeast Asia",
            "name": "TestRedisConnectorCache/default",
            "type": "Microsoft.Cache/Redis/PatchSchedules",
            "properties": {"scheduleEntries": [{
                    "dayOfWeek": "Monday",
                    "startHourUtc": 12,
                    "maintenanceWindow": "PT5H"
                }, {
                    "dayOfWeek": "Tuesday",
                    "startHourUtc": 12,
                    "maintenanceWindow": "PT5H"
                }]}
        };
        test:assertEquals(response, testValue, msg = "Error in creating patch schedule");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {
    dependsOn: ["testCreatePatchSchedule"]
}
function testGetPatchSchedule() {
    log:print("<---Running GetPatchSchedule Test--->");
    var response = azureRedisManagementClient->getPatchSchedule(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") );
    if (response is PatchSchedule) {
        PatchSchedule testValue = 
        {
            "id": "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/" + config:getAsString("RESOURCE_GROUP_NAME")  + "/providers/Microsoft.Cache/Redis/TestRedisConnectorCache/patchSchedules/default",
            "location": "Southeast Asia",
            "name": "TestRedisConnectorCache/default",
            "type": "Microsoft.Cache/Redis/PatchSchedules",
            "properties": {"scheduleEntries": [{
                    "dayOfWeek": "Monday",
                    "startHourUtc": 12,
                    "maintenanceWindow": "PT5H"
                }, {
                    "dayOfWeek": "Tuesday",
                    "startHourUtc": 12,
                    "maintenanceWindow": "PT5H"
                }]}
        };
        test:assertEquals(response, testValue, msg = "Error in fetching patch schedule");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {
    dependsOn: ["testCreatePatchSchedule"]
}
function testListPatchSchedule() {
    log:print("<---Running ListPatchSchedule Test--->");
    var response = azureRedisManagementClient->listPatchSchedules(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") );
    if (response is PatchSchedule[]) {
        PatchSchedule[] testValue = [
            {
                "id": "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/" + config:getAsString("RESOURCE_GROUP_NAME")  + "/providers/Microsoft.Cache/Redis/TestRedisConnectorCache/patchSchedules/default",
                "location": "Southeast Asia",
                "name": "TestRedisConnectorCache/default",
                "type": "Microsoft.Cache/Redis/PatchSchedules",
                "properties": {"scheduleEntries": [{
                        "dayOfWeek": "Monday",
                        "startHourUtc": 12,
                        "maintenanceWindow": "PT5H"
                    }, {
                        "dayOfWeek": "Tuesday",
                        "startHourUtc": 12,
                        "maintenanceWindow": "PT5H"
                    }]}
            }];
        test:assertEquals(response, testValue, msg = "Error in listing patch schedule");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {
    dependsOn: ["testCreatePatchSchedule"]
}
function testDeletePatchSchedule() {
    log:print("<---Running DeletePatchSchedule Test--->");
    var response = azureRedisManagementClient->deletePatchSchedule(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") );
    if (response is boolean) {
        test:assertEquals(response, true, msg = "Deleting patch schedule test failed");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {
    dependsOn: ["testCreateRedisCache"]
}
function testDeleteRedisCache() {
    log:print("<---Running Delete Redis Cache Test--->");
    var response = azureRedisManagementClient->deleteRedisCache(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") );
    if (response is boolean) {
        var getresponse = azureRedisManagementClient->getRedisCache(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") );
        json state = ();
        if (getresponse is RedisCacheInstance) {
            state = getresponse.properties.provisioningState;
        }
        while (state == "Deleting") {
            var getloopresponse = azureRedisManagementClient->getRedisCache(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") );
            if (getloopresponse is RedisCacheInstance) {
                state = getloopresponse.properties.provisioningState;
            }
            else {
            state = "Deleted";
            }
        }
        test:assertEquals(response, true, msg = "Deleting Azure Cache Instance test failed");
    } else {
        test:assertFail(response.message());
    }
}

