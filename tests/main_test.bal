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
//import ballerina/runtime;

AzureRedisConfiguration config = {oauth2Config: {
        tokenUrl: "https://login.microsoftonline.com/" + config:getAsString("TENANT_ID") + "/oauth2/v2.0/token",
        clientId: config:getAsString("CLIENT_ID"),
        clientSecret: config:getAsString("CLIENT_SECRET"),
        scopes: ["https://management.azure.com/.default"]
    }};

Client azureRedisClient = new (config);

@test:Config {}
function testCheckeRedisCacheAvailability() {
    log:print("<---Running Checking RedisCacheName availability Test--->");
    var response = azureRedisClient->checkRedisCacheNameAvailability("TestRedisConnectorCacheTest");
    if (response is boolean) {
        test:assertEquals(response, true, msg = "Name not available or recently deleted");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {}
function testCreateRedisCache() {
    TlsVersion minimumTlsVersion = {minimumTlsVersion: "1.2"};
    CreateCacheProperty properties = 
    {
        "sku": {
            "name": "Premium",
            "family": "P",
            "capacity": 1
        },
        "enableNonSslPort": true,
        "shardCount": 2,
        "replicasPerMaster": 2,
        "redisConfiguration": {"maxmemory-policy": "allkeys-lru"},
        "subnetId": "/subscriptions/subid/resourceGroups/rg2/providers/Microsoft.Network/virtualNetworks/network1/subnets/subnet1",
        "staticIP": "192.168.0.5",
        "minimumTlsVersion": minimumTlsVersion,
        "publicNetworkAccess": "Enabled"
    };
    log:print("<---Running CreateRedisCache Test--->");
    var response = azureRedisClient->createRedisCache("TestRedisConnectorCache", "TestRedisConnector", "southeastasia", 
    properties);
    if (response is RedisCacheInstance) {
        boolean createSuccess = true;
        log:print("Deployment in progress...");
        json state = response.properties.provisioningState;
        while (state != "Succeeded") {
            var getresponse = azureRedisClient->getRedisCache("TestRedisConnectorCache", "TestRedisConnector");
            if (getresponse is json) {
                state = getresponse.properties.provisioningState;
            }
        }
        test:assertEquals(createSuccess, true, msg = "Error in creating Redis Cache");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisCache"]}
function testGetRedisCache() {
    log:print("<---Running GetRedisCache Test--->");
    var response = azureRedisClient->getRedisCache("TestRedisConnectorCache", "TestRedisConnector");
    if (response is RedisCacheInstance) {
        boolean getSuccess = true;
        test:assertEquals(getSuccess, true, msg = "Error in fetching Redis Instance");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisCache"]}
function testExportRedisCache() {
    log:print("<---Running ExportRedisCache Test--->");
    var response = azureRedisClient->exportRedisCache("TestRedisConnectorCache", "TestRedisConnector", "datadump1", 
    "https://teststorageredis.blob.core.windows.net/blobstorage", 
    "?sv=2019-12-12&ss=bfqt&srt=sco&sp=rwdlacupx&se=2021-02-02T17:47:05Z&st=2021-02-02T09:47:05Z&spr=https&sig=LkHmidalrij7yEE317pI%2FLvaEYb7zOvK9TJsiLLjk4k%3D", 
    "RDB");
    if (response is boolean) {
        test:assertEquals(response, true, msg = "Error in Exporting redis cache");
    } else {
        test:assertFail(response.message());
    }
    runtime:sleep(60000);
}

@test:Config {dependsOn: ["testCreateRedisCache"]}
function testImportRedisCache() {
    log:print("<---Running ImportRedisCache Test--->");
    var response = azureRedisClient->importRedisCache("TestRedisConnectorCache", "TestRedisConnector", 
    ["https://teststorageredis.blob.core.windows.net/blobstorage/datadump1"], "RDB");
    if (response is boolean) {
        test:assertEquals(response, true, msg = "Error in Importing redis cache");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {
    dependsOn: ["testCreateRedisCache"],
    enable: false
}
function testForceRebootRedisCache() {
    log:print("<---Running ForceRebootCache Test--->");
    var response = azureRedisClient->forceRebootRedisCache("TestRedisConnectorCache", "TestRedisConnector", 0, 
    "AllNodes", [13000, 13001]);
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        test:assertEquals(statusCode?.code, 200, msg = "Error in Rebooting Redis Instance");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisCache"]}
function testListByResourceGroup() {
    log:print("<---Running ListByResourceGroup Test--->");
    var response = azureRedisClient->listByResourceGroup("TestRedisConnector");
    if (response is RedisCacheInstance[]) {
        boolean listSuccess = true;
        test:assertEquals(listSuccess, true, msg = "Error in Listing Redis Instances");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisCache"]}
function testListBySubscription() {
    log:print("<---Running ListBySubscription Test--->");
    var response = azureRedisClient->listBySubscription();
    if (response is RedisCacheInstance[]) {
        boolean listSuccess = true;
        test:assertEquals(listSuccess, true, msg = "Error in Listing Redis Instances");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisCache"]}
function testListKeys() {
    log:print("<---Running ListKeys Test--->");
    var response = azureRedisClient->listKeys("TestRedisConnectorCache", "TestRedisConnector");
    if (response is AccessKey) {
        boolean listKey = true;
        test:assertEquals(listKey, true, msg = "Error in Listing Redis Instance Key");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisCache"]}
function testRegenerateKey() {
    log:print("<---Running RegenerateKey Test--->");
    var response = azureRedisClient->regenerateKey("TestRedisConnectorCache", "TestRedisConnector", "Primary");
    if (response is AccessKey) {
        boolean listKey = true;
        test:assertEquals(listKey, true, msg = "Error in regenerating Redis Instance Key");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisCache"]}
function testUpdateRedisCache() {
    log:print("<---Running UpdateRedisCache--->");

    TlsVersion minimumTlsVersion = {minimumTlsVersion: "1.2"};

    CreateCacheProperty properties = 
    {
        "sku": {
            "name": "Premium",
            "family": "P",
            "capacity": 1
        },
        "enableNonSslPort": false,
        "shardCount": 2,
        "replicasPerMaster": 2,
        "redisConfiguration": {"maxmemory-policy": "allkeys-lru"},
        "subnetId": "/subscriptions/subid/resourceGroups/rg2/providers/Microsoft.Network/virtualNetworks/network1/subnets/subnet1",
        "staticIP": "192.168.0.5",
        "minimumTlsVersion": minimumTlsVersion,
        "publicNetworkAccess": "Enabled"
    };

    var response = azureRedisClient->updateRedisCache("TestRedisConnectorCache", "TestRedisConnector", "southeastasia", properties);
    if (response is RedisCacheInstance) {
        boolean updateSuccess = true;
        test:assertEquals(updateSuccess, true, msg = "Error in updating RedisCache");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisCache"]}
function testCreateFirewallRule() {
    log:print("<---Running CreateFireWallRule Test--->");
    var response = azureRedisClient->createFirewallRule("TestRedisConnectorCache", "TestRedisConnector", 
    "TestFilewallRule", "192.168.1.1", "192.168.1.4");
    if (response is FirewallRuleResponse) {
        FirewallRuleResponse testValue = 
        {
            "id": 
            "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/redis/TestRedisConnectorCache/firewallRules/TestFilewallRule",
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

@test:Config {dependsOn: ["testCreateFirewallRule"]}
function testGetFireWallRule() {
    log:print("<---Running GetFireWallRule Test--->");
    var response = azureRedisClient->getFirewallRule("TestRedisConnectorCache", "TestRedisConnector", "TestFilewallRule");
    if (response is FirewallRuleResponse) {
        FirewallRuleResponse testValue = 
        {
            "id": 
            "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/Redis/TestRedisConnectorCache/firewallRules/TestFilewallRule",
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

@test:Config {dependsOn: ["testCreateFirewallRule"]}
function testListFireWallRule() {
    log:print("<---Running ListFireWallRule Test--->");
    var response = azureRedisClient->listFirewallRules("TestRedisConnectorCache", "TestRedisConnector");
    if (response is FirewallRule[]) {
        FirewallRule[] testValue = [
            {
                "id": 
                "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/Redis/TestRedisConnectorCache/firewallRules/TestFilewallRule",
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

@test:Config {dependsOn: ["testCreateFirewallRule"]}
function testDeleteFireWallRule() {
    log:print("<---Running DeleteFireWallRule Test--->");
    var response = azureRedisClient->deleteFirewallRule("TestRedisConnectorCache", "TestRedisConnector", 
    "TestFilewallRule");
    if (response is boolean) {
        test:assertEquals(response, true, msg = "Deleting firewall rule test failed");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisCache"]}
function testCreateLinkedServer() {
    log:print("<---Running CreateLinkedServer Test--->");

    TlsVersion minimumTlsVersion = {minimumTlsVersion: "1.2"};

    CreateCacheProperty properties = 
    {
        "sku": {
            "name": "Premium",
            "family": "P",
            "capacity": 1
        },
        "enableNonSslPort": true,
        "shardCount": 2,
        "replicasPerMaster": 2,
        "redisConfiguration": {"maxmemory-policy": "allkeys-lru"},
        "staticIP": "192.168.0.5",
        "minimumTlsVersion": minimumTlsVersion,
        "publicNetworkAccess": "Enabled"
    };
    var createResponse = azureRedisClient->createRedisCache("TestRedisConnectorCacheLinkedServer", "TestRedisConnector", 
    "Southeast Asia", properties);
    if (createResponse is json) {
        log:print("Deployment of second cache instance for linked server");
        json state = createResponse.properties.provisioningState;
        while (state != "Succeeded") {
            var getresponse = azureRedisClient->getRedisCache("TestRedisConnectorCacheLinkedServer", 
            "TestRedisConnector");
            if (getresponse is json) {
                state = getresponse.properties.provisioningState;
            }
        }
    } else {
        test:assertFail(createResponse.message());
    }
    var response = azureRedisClient->createLinkedServer("TestRedisConnectorCache", "TestRedisConnector", 
    "TestRedisConnectorCacheLinkedServer", 
    "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/Redis/TestRedisConnectorCacheLinkedServer", 
    "Southeast Asia", "Secondary");
    if (response is LinkedServer) {
        LinkedServer testValue = {
            "id": 
            "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/Redis/TestRedisConnectorCache/linkedServers/TestRedisConnectorCacheLinkedServer",
            "name": "TestRedisConnectorCacheLinkedServer",
            "type": "Microsoft.Cache/Redis/linkedServers",
            "properties": 
            {
                "linkedRedisCacheId": 
                "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/Redis/TestRedisConnectorCacheLinkedServer",
                "linkedRedisCacheLocation": "Southeast Asia",
                "provisioningState": "Creating",
                "serverRole": "Secondary"
            }
        };
        log:print("Linking...");
        json state = response.properties.provisioningState;
        while (state != "Succeeded") {
            var getresponse = azureRedisClient->getLinkedServer("TestRedisConnectorCache", "TestRedisConnector", 
            "TestRedisConnectorCacheLinkedServer");
            if (getresponse is json) {
                state = getresponse.properties.provisioningState;
            }
        }
        test:assertEquals(response, testValue, msg = "Error in creating linked server");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateLinkedServer"]}
function testGetLinkedServer() {
    log:print("<---Running GetLinkedServer Test--->");
    var response = azureRedisClient->getLinkedServer("TestRedisConnectorCache", "TestRedisConnector", 
    "TestRedisConnectorCacheLinkedServer");
    if (response is LinkedServer) {
        LinkedServer testValue = {
            "id": 
            "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/Redis/TestRedisConnectorCache/linkedServers/TestRedisConnectorCacheLinkedServer",
            "name": "TestRedisConnectorCacheLinkedServer",
            "type": "Microsoft.Cache/Redis/linkedServers",
            "properties": 
            {
                "linkedRedisCacheId": 
                "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/Redis/TestRedisConnectorCacheLinkedServer",
                "linkedRedisCacheLocation": "Southeast Asia",
                "provisioningState": "Succeeded",
                "serverRole": "Secondary"
            }
        };
        test:assertEquals(response, testValue, msg = "Error in fetching linked server");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateLinkedServer"]}
function testListLinkedServer() {
    log:print("<---Running ListLinkedServer Test--->");
    var response = azureRedisClient->listLinkedServers("TestRedisConnectorCacheLinkedServer", "TestRedisConnector");
    if (response is LinkedServer[]) {
        LinkedServer[] testValue = [{
                "id": "/subscriptions/7241b7fa-c310-4b99-a53e-c5048cf0ec25/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/Redis/TestRedisConnectorCacheLinkedServer/linkedServers/TestRedisConnectorCache",
                "name": "TestRedisConnectorCache",
                "type": "Microsoft.Cache/Redis/linkedServers",
                "properties": 
                {
                    "linkedRedisCacheId": "/subscriptions/7241b7fa-c310-4b99-a53e-c5048cf0ec25/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/Redis/TestRedisConnectorCache",
                    "linkedRedisCacheLocation": "Southeast Asia",
                    "serverRole": "Primary",
                    "provisioningState": "Succeeded"
                }
            }];
        test:assertEquals(response, testValue, msg = "Error in listing linked server");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateLinkedServer"]}
function testDeleteLinkedServer() {
    log:print("<---Running DeleteLinkedServer Test--->");
    var response = azureRedisClient->deleteLinkedServer("TestRedisConnectorCache", "TestRedisConnector", 
    "TestRedisConnectorCacheLinkedServer");
    if (response is boolean) {
        test:assertEquals(response, true, msg = "Deleting LinkedServer test failed");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisCache"]}
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
    var response = azureRedisClient->createPatchSchedule("TestRedisConnectorCache", "TestRedisConnector", properties);
    if (response is PatchSchedule) {
        PatchSchedule testValue = 
        {
            "id": 
            "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/Redis/TestRedisConnectorCache/patchSchedules/default",
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

@test:Config {dependsOn: ["testCreatePatchSchedule"]}
function testGetPatchSchedule() {
    log:print("<---Running GetPatchSchedule Test--->");
    var response = azureRedisClient->getPatchSchedule("TestRedisConnectorCache", "TestRedisConnector");
    if (response is PatchSchedule) {
        PatchSchedule testValue = 
        {
            "id": "/subscriptions/7241b7fa-c310-4b99-a53e-c5048cf0ec25/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/Redis/TestRedisConnectorCache/patchSchedules/default",
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

@test:Config {dependsOn: ["testCreatePatchSchedule"]}
function testListPatchSchedule() {
    log:print("<---Running ListPatchSchedule Test--->");
    var response = azureRedisClient->listPatchSchedules("TestRedisConnectorCache", "TestRedisConnector");
    if (response is PatchSchedule[]) {
        PatchSchedule[] testValue = [
            {
                "id": "/subscriptions/7241b7fa-c310-4b99-a53e-c5048cf0ec25/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/Redis/TestRedisConnectorCache/patchSchedules/default",
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

@test:Config {dependsOn: ["testCreatePatchSchedule"]}
function testDeletePatchSchedule() {
    log:print("<---Running DeletePatchSchedule Test--->");
    var response = azureRedisClient->deletePatchSchedule("TestRedisConnectorCache", "TestRedisConnector");
    if (response is boolean) {
        test:assertEquals(response, true, msg = "Deleting patch schedule test failed");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {enable: false}
function testPutPrivateEndpointConnection() {
    log:print("<---Running PutPrivateEndpointConnection Test--->");
    var response = azureRedisClient->putPrivateEndpointConnection("TestRedisConnectorCache", "TestRedisConnector", 
    "testPrivateEndpoint", "Approved", "Auto-Approved");
    if (response is json) {
        json testValue = {
            "id": 
            "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/Redis/TestRedisConnectorCache/privateEndpointConnections/testPrivateEndpoint",
            "name": "testPrivateEndpoint",
            "type": "Microsoft.Cache/Redis/privateEndpointConnections",
            "properties": 
            {
                "provisioningState": "Succeeded",
                "privateEndpoint": 
                {"id": 
                    "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/TestRedisConnector/providers/Microsoft.Network/privateEndpoints/testPrivateEndpoint"},
                "privateLinkServiceConnectionState": {
                    "status": "Approved",
                    "description": "Auto-Approved",
                    "actionsRequired": "None"
                }
            }
        };
        test:assertEquals(response, testValue, msg = "Error in creating PrivateEndpointConnection");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {
    dependsOn: ["testPutPrivateEndpointConnection"],
    enable: false
}
function testgetPrivateEndpointConnection() {
    log:print("<---Running GetPrivateEndpointConnection Test--->");
    var response = azureRedisClient->getPrivateEndpointConnection("TestRedisConnectorCache", "TestRedisConnector", 
    "TestPrivateEndpoint");
    if (response is json) {
        json testValue = {
            "id": 
            "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/Redis/cachetest01/privateEndpointConnections/TestPrivateEndpoint",
            "name": "TestPrivateEndpoint",
            "type": "Microsoft.Cache/Redis/privateEndpointConnections",
            "properties": 
            {
                "provisioningState": "Succeeded",
                "privateEndpoint": 
                {"id": 
                    "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/TestRedisConnector/providers/Microsoft.Network/privateEndpoints/TestPrivateEndpoint"},
                "privateLinkServiceConnectionState": {
                    "status": "Approved",
                    "description": "Auto-Approved",
                    "actionsRequired": "None"
                }
            }
        };
        test:assertEquals(response, testValue, msg = "Error in getting PrivateEndpointConnection");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {
    dependsOn: ["testPutPrivateEndpointConnection"],
    enable: false
}
function testListPrivateEndpointConnection() {
    log:print("<---Running ListPrivateEndpointConnection Test--->");
    var response = azureRedisClient->listPrivateEndpointConnection("TestRedisConnectorCache", "TestRedisConnector");
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        test:assertEquals(statusCode?.code, "200", msg = "Error in listing private endpoint connection");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {
    dependsOn: ["testPutPrivateEndpointConnection"],
    enable: false
}
function testDeletePrivateEndpointConnection() {
    log:print("<---Running DeletePrivateEndpointConnection Test--->");
    var response = azureRedisClient->deletePrivateEndpointConnection("TestRedisConnectorCache", "TestRedisConnector", 
    "TestPrivateEndpoint");
    if (response is boolean) {
        test:assertEquals(response, true, msg = "Deleting private endpoint connection test failed");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {enable: false}
function testGetPrivateLinkResources() {
    log:print("<---Running GetPrivateLinkResources Test--->");
    var response = azureRedisClient->getPrivateLinkResources("TestRedisConnectorCache", "TestRedisConnector");
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        test:assertEquals(statusCode?.code, "200", msg = "Error in getting PrivateLinkResources");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisCache"]}
function testDeleteRedisCache() {
    log:print("<---Running Delete Redis Cache Test--->");
    var response = azureRedisClient->deleteRedisCache("TestRedisConnectorCache", "TestRedisConnector");
    if (response is boolean) {
        var getresponse = azureRedisClient->getRedisCache("TestRedisConnectorCache", "TestRedisConnector");
        json state = ();
        if (getresponse is json) {
            state = getresponse.properties.provisioningState;
        }
        while (state == "Deleting") {
            var getloopresponse = azureRedisClient->getRedisCache("TestRedisConnectorCache", "TestRedisConnector");
            if (getloopresponse is json) {
                state = getloopresponse.properties.provisioningState;
            }
        }
        test:assertEquals(response, true, msg = "Deleting Redis Cache Instance test failed");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {}
function testCreateRedisEnterprise() {
    log:print("<---Running CreateRedisEnterprise Test--->");
    TlsVersion minimumTlsVersion = {minimumTlsVersion: "1.2"};
    CreateEnterpriseCacheProperty properties = 
    {
        "minimumTlsVersion": minimumTlsVersion
    };
    var response = azureRedisClient->createRedisEnterprise("TestRedisEnterprise", "TestRedisConnector", "southeastasia", 
    "EnterpriseFlash_F300", 3, ["1", "2", "3"], "value1", properties);
    if (response is RedisEnterpriseInstance) {
        boolean createSuccess = true;
        log:print("Deployment in progress...");
        json state = response.properties.provisioningState;
        while (state != "Succeeded") {
            var getresponse = azureRedisClient->getRedisEnterprise("TestRedisEnterprise", "TestRedisConnector");
            if (getresponse is json) {
                state = getresponse.properties.provisioningState;
            }
        }
        test:assertEquals(createSuccess, true, msg = "Error in creating Redis Enterprise");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisEnterprise"]}
function testCreateRedisEnterpriseDatabase() {
    log:print("<---Running CreateRedisEnterpriseDatabase Test--->");
    CreateEnterpriseDBProperty properties = {
                "clientProtocol": "Encrypted",
                "clusteringPolicy": "EnterpriseCluster",
                "evictionPolicy": "AllKeysLRU",
                "port": 10000,
                "modules": []
            };
    var response = azureRedisClient->createRedisEnterpriseDatabase("TestRedisEnterprise", "TestRedisConnector", 
    "default", properties);
    if (response is RedisEnterpriseDatabase) {
        test:assertTrue(true, msg = "Error in creating RedisEnterprise");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisEnterprise", "testCreateRedisEnterpriseDatabase"]}
function testGetRedisEnterpriseDatabase() {
    log:print("<---Running GetRedisEnterpriseDatabase Test--->");
    var response = azureRedisClient->getRedisEnterpriseDatabase("TestRedisEnterprise", "TestRedisConnector", "default");
    if (response is RedisEnterpriseDatabase) {
        test:assertTrue(true, msg = "Error in fetching RedisEnterprise");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisEnterprise", "testCreateRedisEnterpriseDatabase"]}
function testRegenerateRedisEnterpriseDatabaseKey() {
    log:print("<---Running Regenerate Redis Enterprise Cache Database Key Test--->");
    var response = azureRedisClient->regenerateRedisEnterpriseDatabaseKey("TestRedisEnterprise", "TestRedisConnector", 
    "default", "Primary");
    if (response is AccessKey) {
        test:assertTrue(true, msg = "Error in regenerating Redis Enterprise Cache Key");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisEnterprise", "testCreateRedisEnterpriseDatabase"]}
function testListRedisEnterpriseDatabaseByCluster() {
    log:print("<---Running ListRedisEnterpriseDatabaseByCluster Test--->");
    var response = azureRedisClient->listRedisEnterpriseDatabaseByCluster("TestRedisEnterprise", "TestRedisConnector");
    if (response is RedisEnterpriseDatabase[]) {
        test:assertTrue(true, msg = "Error in fetching RedisEnterprise by cluster");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisEnterprise", "testCreateRedisEnterpriseDatabase"]}
function testListRedisEnterpriseDatabaseKeys() {
    log:print("<---Running ListRedisEnterpriseDatabaseKeys Test--->");
    var response = azureRedisClient->listRedisEnterpriseDatabaseKeys("TestRedisEnterprise", "TestRedisConnector", 
    "default");
    if (response is AccessKey) {
        test:assertTrue(true, msg = "Error in listing Redis Enterprise Cache Keys");
    } else {
        test:assertFail(response.message());
    }
}

# Update Redis Enterprise Database Test function(This function not available at the moment of development)
@test:Config {
    dependsOn: ["testCreateRedisEnterprise", "testCreateRedisEnterpriseDatabase"],
    enable: false
}
function testUpdateRedisEnterpriseDatabase() {
    log:print("<---Running UpdateRedisEnterpriseDatabase Test--->");
    var response = azureRedisClient->updateRedisEnterpriseDatabase("TestRedisEnterprise", "TestRedisConnector", 
    "default", "Encrypted", "AllKeysLRU", "RediSearch");
    if (response is RedisEnterpriseDatabase) {
        test:assertTrue(true, msg = "Error in regenerating Redis Enterprise Cache Key");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisEnterprise", "testCreateRedisEnterpriseDatabase"]}
function testDeleteRedisEnterpriseDatabase() {
    log:print("<---Running DeleteRedisEnterpriseDatabase Test--->");
    var response = azureRedisClient->deleteRedisEnterpriseDatabase("TestRedisEnterprise", "TestRedisConnector", 
    "default");
    if (response is boolean) {
        test:assertEquals(response, true, msg = "Error in deleting RedisEnterprise");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisEnterprise"]}
function testGetRedisEnterprise() {
    log:print("<---Running GetRedisEnterprise Test--->");
    log:print("Running Get Redis Enterprise Cache Test");
    var response = azureRedisClient->getRedisEnterprise("TestRedisEnterprise", "TestRedisConnector");
    if (response is RedisEnterpriseInstance) {
        RedisEnterpriseInstance testValue = 
        {
            "location": "Southeast Asia",
            "name": "TestRedisEnterprise",
            "id": 
            "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/redisEnterprise/TestRedisEnterprise",
            "type": "Microsoft.Cache/redisEnterprise",
            "tags": {"tag1": "value1"},
            "sku": {
                "name": "EnterpriseFlash_F300",
                "capacity": 3
            },
            "properties": {
                "provisioningState": "Succeeded",
                "resourceState": "Running",
                "privateEndpointConnections": []
            },
            "zones": ["1", "2", "3"]
        };
        test:assertEquals(response, testValue, msg = "Error in creating RedisEnterprise");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisEnterprise"]}
function testListRedisEnterprise() {
    log:print("<---Running ListRedisEnterprise Test--->");
    var response = azureRedisClient->listRedisEnterprise();
    if (response is RedisEnterpriseInstance[]) {
        RedisEnterpriseInstance[] testValue = [
            {
                "location": "Southeast Asia",
                "name": "TestRedisEnterprise",
                "id": 
                "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/redisEnterprise/TestRedisEnterprise",
                "type": "Microsoft.Cache/redisEnterprise",
                "tags": {"tag1": "value1"},
                "sku": {
                    "name": "EnterpriseFlash_F300",
                    "capacity": 3
                },
                "properties": {
                    "provisioningState": "Succeeded",
                    "resourceState": "Running",
                    "privateEndpointConnections": []
                },
                "zones": ["1", "2", "3"]
            }];
        test:assertEquals(response, testValue, msg = "Error in fetching RedisEnterprise List");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisEnterprise"]}
function testListRedisEnterpriseByResourceGroup() {
    log:print("<---Running ListRedisEnterpriseByResourceGroup Test--->");
    var response = azureRedisClient->listRedisEnterpriseByResourceGroup("TestRedisConnector");
    if (response is RedisEnterpriseInstance[]) {
        RedisEnterpriseInstance[] testValue = [
            {
                "location": "Southeast Asia",
                "name": "TestRedisEnterprise",
                "id": 
                "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/redisEnterprise/TestRedisEnterprise",
                "type": "Microsoft.Cache/redisEnterprise",
                "tags": {"tag1": "value1"},
                "sku": {
                    "name": "EnterpriseFlash_F300",
                    "capacity": 3
                },
                "properties": {
                    "provisioningState": "Succeeded",
                    "resourceState": "Running",
                    "privateEndpointConnections": []
                },
                "zones": ["1", "2", "3"]
            }];
        test:assertEquals(response, testValue, msg = "Error in fetching RedisEnterprise List");
    } else {
        test:assertFail(response.message());
    }
}
# Update Redis Enterprise Test function(This function not available at the moment of development)
@test:Config {
    dependsOn: ["testCreateRedisEnterprise"],
    enable: false
}
function testUpdateRedisEnterprise() {
    log:print("<---Running UpdateRedisEnterprise Test--->");
    TlsVersion minimumTlsVersion = {minimumTlsVersion: "1.2"};
    CreateEnterpriseCacheProperty properties = 
    {
        "minimumTlsVersion": minimumTlsVersion
    };
    var response = azureRedisClient->updateRedisEnterprise("TestRedisEnterprise", "TestRedisConnector", "southeastasia", 
    "EnterpriseFlash_F300", 9, ["1", "2", "3"], "value1", properties);
    if (response is RedisEnterpriseInstance) {
        test:assertTrue(true, msg = "Error in updating RedisEnterprise");
    } else {
        test:assertFail(response.message());
    }
}
@test:Config {dependsOn: ["testCreateRedisEnterprise"]}
function testDeleteRedisEnterprise() {
    log:print("<---Running DeleteRedisEnterprise Test--->");
    var response = azureRedisClient->deleteRedisEnterprise("TestRedisEnterprise", "TestRedisConnector");
    if (response is boolean) {
        test:assertEquals(response, true, msg = "Error in deleting RedisEnterprise");
    } else {
        test:assertFail(response.message());
    }
}
@test:Config {enable: false}
function testPutPrivateEndpointConnectionEnterprise() {
    log:print("<---Running putPrivateEndpointConnectionEnterprise Test--->");
    var response = azureRedisClient->putPrivateEndpointConnectionEnterprise("TestRedisEnterprise", "TestRedisConnector", 
    "testEnterprisePrivateEndpoint", "Approved", "Auto-Approved");
    if (response is json) {
        json testValue = {
            "id": 
            "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/redisEnterprise/TestRedisEnterprise/privateEndpointConnections/testEnterprisePrivateEndpoint",
            "name": "testEnterprisePrivateEndpoint",
            "type": "Microsoft.Cache/redisEnterprise/privateEndpointConnections",
            "properties": 
            {
                "provisioningState": "Succeeded",
                "privateEndpoint": 
                {"id": 
                    "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/TestRedisConnector/providers/Microsoft.Network/privateEndpoints/testEnterprisePrivateEndpoint"},
                "privateLinkServiceConnectionState": {
                    "status": "Approved",
                    "description": "Auto-Approved",
                    "actionsRequired": "None"
                }
            }
        };
        test:assertEquals(response, testValue, msg = "Error in creating PrivateEndpointConnection");
    } else {
        test:assertFail(response.message());
    }
}
@test:Config {
    dependsOn: ["testPutPrivateEndpointConnectionEnterprise"], enable: false
}
function testgetPrivateEndpointConnectionEnterprise() {
    log:print("<---Running GetPrivateEndpointConnectionEnterprise Test--->");
    var response = azureRedisClient->getPrivateEndpointConnectionEnterprise("TestRedisConnectorCache", "TestRedisConnector", 
    "testEnterprisePrivateEndpoint");
    if (response is json) {
        json testValue = {
            "id": 
            "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/Redis/cachetest01/privateEndpointConnections/testEnterprisePrivateEndpoint",
            "name": "testEnterprisePrivateEndpoint",
            "type": "Microsoft.Cache/Redis/privateEndpointConnections",
            "properties": 
            {
                "provisioningState": "Succeeded",
                "privateEndpoint": 
                {"id": 
                    "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/TestRedisConnector/providers/Microsoft.Network/privateEndpoints/testEnterprisePrivateEndpoint"},
                "privateLinkServiceConnectionState": {
                    "status": "Approved",
                    "description": "Auto-Approved",
                    "actionsRequired": "None"
                }
            }
        };
        test:assertEquals(response, testValue, msg = "Error in getting PrivateEndpointConnectionEnterprise");
    } else {
        test:assertFail(response.message());
    }
}
