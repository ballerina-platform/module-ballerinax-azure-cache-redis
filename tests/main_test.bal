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
import ballerina/runtime;

AzureRedisConfiguration config = {oauth2Config: {
        tokenUrl: "https://login.microsoftonline.com/" + config:getAsString("TENANT_ID") + "/oauth2/v2.0/token",
        clientId: config:getAsString("CLIENT_ID"),
        clientSecret: config:getAsString("CLIENT_SECRET"),
        scopes: ["https://management.azure.com/.default"]
    }};

Client azureRedisClient = new (config);

string SubscriptionId = "7241b7fa-c310-4b99-a53e-c5048cf0ec25";
string resourceGroupName = "TestRedisConnector";

@test:BeforeSuite
function beforeSuit() {
    log:print("<---Running BeforeSuite--->");
    CreateCacheProperty properties = 
    {
        "sku": {
            "name": "Premium",
            "family": "P",
            "capacity": 1
        },
        "enableNonSslPort": true,
        "shardCount": 2,
        "redisConfiguration": {"maxmemory-policy": "allkeys-lru"},
        "minimumTlsVersion": "1.2",
        "publicNetworkAccess": "Enabled"
    };
    var createResponse = azureRedisClient->createRedisCache("7241b7fa-c310-4b99-a53e-c5048cf0ec25", "TestRedisConnectorCacheLinkedServer", "TestRedisConnector", 
    "Southeast Asia", properties);
    log:print("<---Setting up Resources--->");
    if (createResponse is RedisCacheInstance) {
        log:print("Deployment of cache instance for linked server");
        json state = createResponse.properties.provisioningState;
        while (state != "Succeeded") {
            var getresponse = azureRedisClient->getRedisCache("7241b7fa-c310-4b99-a53e-c5048cf0ec25", "TestRedisConnectorCacheLinkedServer", 
            "TestRedisConnector");
            if (getresponse is RedisCacheInstance) {
                state = getresponse.properties.provisioningState;
            }
        }
    } else {
        log:print("Setup resources failed");
    }
}

// @test:Config {}
// function testCheckeRedisCacheAvailability() {
//     log:print("<---Running Checking RedisCacheName availability Test--->");
//     var response = azureRedisClient->checkRedisCacheNameAvailability("7241b7fa-c310-4b99-a53e-c5048cf0ec25", "TestRedisConnectorCache");
//     if (response is boolean) {
//         test:assertEquals(response, true, msg = "Name not available or recently deleted");
//     } else {
//         test:assertFail(response.message());
//     }
// }

// @test:Config {}
// function testCreateRedisCache() {
//     CreateCacheProperty properties = 
//     {
//         "sku": {
//             "name": "Premium",
//             "family": "P",
//             "capacity": 1
//         },
//         "enableNonSslPort": true,
//         "shardCount": 2,
//         "redisConfiguration": {"maxmemory-policy": "allkeys-lru"},
//         "minimumTlsVersion": "1.2",
//         "publicNetworkAccess": "Enabled"
//     };
//     log:print("<---Running CreateRedisCache Test--->");
//     var response = azureRedisClient->createRedisCache("7241b7fa-c310-4b99-a53e-c5048cf0ec25", "TestRedisConnectorCache", "TestRedisConnector", "southeastasia", 
//     properties);
//     if (response is RedisCacheInstance) {
//         boolean createSuccess = true;
//         log:print("Deployment in progress...");
//         json state = response.properties.provisioningState;
//         while (state != "Succeeded") {
//             var getresponse = azureRedisClient->getRedisCache("7241b7fa-c310-4b99-a53e-c5048cf0ec25", "TestRedisConnectorCache", "TestRedisConnector");
//             if (getresponse is RedisCacheInstance) {
//                 state = getresponse.properties.provisioningState;
//             }
//         }
//         test:assertEquals(createSuccess, true, msg = "Error in creating Redis Cache");
//     } else {
//         test:assertFail(response.message());
//     }
// }

@test:Config {dependsOn: ["testCreateRedisCache"]}
function testGetRedisCache() {
    log:print("<---Running GetRedisCache Test--->");
    var response = azureRedisClient->getRedisCache("7241b7fa-c310-4b99-a53e-c5048cf0ec25", "TestRedisConnectorCache", "TestRedisConnector");
    if (response is RedisCacheInstance) {
        boolean getSuccess = true;
        test:assertEquals(getSuccess, true, msg = "Error in fetching Redis Instance");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {
    //dependsOn: ["testCreateRedisCache"]
    }
function testExportRedisCache() {
    log:print("<---Running ExportRedisCache Test--->");
    var response = azureRedisClient->exportRedisCache("7241b7fa-c310-4b99-a53e-c5048cf0ec25", "TestRedisConnectorCache", "TestRedisConnector", "datadump1", 
    "https://teststorageredis.blob.core.windows.net/blobstorage", 
    "?sv=2019-12-12&ss=bfqt&srt=c&sp=rwdlacupx&se=2021-02-10T22:17:37Z&st=2021-02-10T14:17:37Z&spr=https,http&sig=q%2F3MVsuvPUB69Tkf6NrspZCogoOMeWrgBoCx1c1%2BN%2Fk%3D", 
    "RDB");
    if (response is boolean) {
        test:assertEquals(response, true, msg = "Error in Exporting redis cache");
    } else {
        test:assertFail(response.message());
    }
    runtime:sleep(6000);
}

@test:Config {dependsOn: ["testCreateRedisCache"]}
function testImportRedisCache() {
    log:print("<---Running ImportRedisCache Test--->");
    var response = azureRedisClient->importRedisCache("7241b7fa-c310-4b99-a53e-c5048cf0ec25", "TestRedisConnectorCache", "TestRedisConnector", 
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
    var response = azureRedisClient->forceRebootRedisCache("7241b7fa-c310-4b99-a53e-c5048cf0ec25", "TestRedisConnectorCache", "TestRedisConnector", 0, 
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
    var response = azureRedisClient->listRedisCacheInstances("7241b7fa-c310-4b99-a53e-c5048cf0ec25", "TestRedisConnector");
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
    var response = azureRedisClient->listRedisCacheInstances("7241b7fa-c310-4b99-a53e-c5048cf0ec25");
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
    var response = azureRedisClient->listKeys("7241b7fa-c310-4b99-a53e-c5048cf0ec25", "TestRedisConnectorCache", "TestRedisConnector");
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
    var response = azureRedisClient->regenerateKey("7241b7fa-c310-4b99-a53e-c5048cf0ec25", "TestRedisConnectorCache", "TestRedisConnector", "Primary");
    if (response is AccessKey) {
        boolean listKey = true;
        test:assertEquals(listKey, true, msg = "Error in regenerating Redis Instance Key");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {
    dependsOn: ["testCreateRedisCache"],
    enable: false
}
function testUpdateRedisCache() {
    log:print("<---Running UpdateRedisCache--->");

    CreateCacheProperty properties = 
    {
        "sku": {
            "name": "Premium",
            "family": "P",
            "capacity": 1
        },
        "enableNonSslPort": false,
        "shardCount": 2,
        "redisConfiguration": {"maxmemory-policy": "allkeys-lru"},
        "minimumTlsVersion": "1.2",
        "publicNetworkAccess": "Enabled"
    };

    var response = azureRedisClient->updateRedisCache("7241b7fa-c310-4b99-a53e-c5048cf0ec25", "TestRedisConnectorCache", "TestRedisConnector", "southeastasia", properties);
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
    var response = azureRedisClient->createFirewallRule("7241b7fa-c310-4b99-a53e-c5048cf0ec25", "TestRedisConnectorCache", "TestRedisConnector", 
    "TestFilewallRule", "192.168.1.1", "192.168.1.4");
    if (response is FirewallRule) {
        FirewallRule testValue = 
        {
            "id": 
            "/subscriptions/7241b7fa-c310-4b99-a53e-c5048cf0ec25/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/redis/TestRedisConnectorCache/firewallRules/TestFilewallRule",
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
    var response = azureRedisClient->getFirewallRule("7241b7fa-c310-4b99-a53e-c5048cf0ec25", "TestRedisConnectorCache", "TestRedisConnector", "TestFilewallRule");
    if (response is FirewallRule) {
        FirewallRule testValue = 
        {
            "id": 
            "/subscriptions/7241b7fa-c310-4b99-a53e-c5048cf0ec25/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/Redis/TestRedisConnectorCache/firewallRules/TestFilewallRule",
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
    var response = azureRedisClient->listFirewallRules("7241b7fa-c310-4b99-a53e-c5048cf0ec25", "TestRedisConnectorCache", "TestRedisConnector");
    if (response is FirewallRule[]) {
        FirewallRule[] testValue = [
            {
                "id": 
                "/subscriptions/7241b7fa-c310-4b99-a53e-c5048cf0ec25/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/Redis/TestRedisConnectorCache/firewallRules/TestFilewallRule",
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
    var response = azureRedisClient->deleteFirewallRule("7241b7fa-c310-4b99-a53e-c5048cf0ec25", "TestRedisConnectorCache", "TestRedisConnector", 
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
    var response = azureRedisClient->createLinkedServer("7241b7fa-c310-4b99-a53e-c5048cf0ec25", "TestRedisConnectorCache", "TestRedisConnector", 
    "TestRedisConnectorCacheLinkedServer", 
    "/subscriptions/7241b7fa-c310-4b99-a53e-c5048cf0ec25/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/Redis/TestRedisConnectorCacheLinkedServer", 
    "Southeast Asia", "Secondary");
    if (response is LinkedServer) {
        LinkedServer testValue = {
            "id": 
            "/subscriptions/7241b7fa-c310-4b99-a53e-c5048cf0ec25/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/Redis/TestRedisConnectorCache/linkedServers/TestRedisConnectorCacheLinkedServer",
            "name": "TestRedisConnectorCacheLinkedServer",
            "type": "Microsoft.Cache/Redis/linkedServers",
            "properties": 
            {
                "linkedRedisCacheId": 
                "/subscriptions/7241b7fa-c310-4b99-a53e-c5048cf0ec25/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/Redis/TestRedisConnectorCacheLinkedServer",
                "linkedRedisCacheLocation": "Southeast Asia",
                "provisioningState": "Creating",
                "serverRole": "Secondary"
            }
        };
        log:print("Linking...");
        json state = response.properties.provisioningState;
        while (state != "Succeeded") {
            var getresponse = azureRedisClient->getLinkedServer("7241b7fa-c310-4b99-a53e-c5048cf0ec25", "TestRedisConnectorCache", "TestRedisConnector", 
            "TestRedisConnectorCacheLinkedServer");
            if (getresponse is LinkedServer) {
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
    var response = azureRedisClient->getLinkedServer("7241b7fa-c310-4b99-a53e-c5048cf0ec25", "TestRedisConnectorCache", "TestRedisConnector", 
    "TestRedisConnectorCacheLinkedServer");
    if (response is LinkedServer) {
        LinkedServer testValue = {
            "id": 
            "/subscriptions/7241b7fa-c310-4b99-a53e-c5048cf0ec25/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/Redis/TestRedisConnectorCache/linkedServers/TestRedisConnectorCacheLinkedServer",
            "name": "TestRedisConnectorCacheLinkedServer",
            "type": "Microsoft.Cache/Redis/linkedServers",
            "properties": 
            {
                "linkedRedisCacheId": 
                "/subscriptions/7241b7fa-c310-4b99-a53e-c5048cf0ec25/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/Redis/TestRedisConnectorCacheLinkedServer",
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
    var response = azureRedisClient->listLinkedServers("7241b7fa-c310-4b99-a53e-c5048cf0ec25", "TestRedisConnectorCacheLinkedServer", "TestRedisConnector");
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
    var response = azureRedisClient->deleteLinkedServer("7241b7fa-c310-4b99-a53e-c5048cf0ec25", "TestRedisConnectorCache", "TestRedisConnector", 
    "TestRedisConnectorCacheLinkedServer");
    if (response is boolean) {
        log:print("Deleting LinkedServer...");
        runtime:sleep(600000);
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
    var response = azureRedisClient->createPatchSchedule("7241b7fa-c310-4b99-a53e-c5048cf0ec25", "TestRedisConnectorCache", "TestRedisConnector", properties);
    if (response is PatchSchedule) {
        PatchSchedule testValue = 
        {
            "id": 
            "/subscriptions/7241b7fa-c310-4b99-a53e-c5048cf0ec25/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/Redis/TestRedisConnectorCache/patchSchedules/default",
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
    var response = azureRedisClient->getPatchSchedule("7241b7fa-c310-4b99-a53e-c5048cf0ec25", "TestRedisConnectorCache", "TestRedisConnector");
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
    var response = azureRedisClient->listPatchSchedules("7241b7fa-c310-4b99-a53e-c5048cf0ec25", "TestRedisConnectorCache", "TestRedisConnector");
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
    var response = azureRedisClient->deletePatchSchedule("7241b7fa-c310-4b99-a53e-c5048cf0ec25", "TestRedisConnectorCache", "TestRedisConnector");
    if (response is boolean) {
        test:assertEquals(response, true, msg = "Deleting patch schedule test failed");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {enable: false}
function testPutPrivateEndpointConnection() {
    log:print("<---Running PutPrivateEndpointConnection Test--->");
    var response = azureRedisClient->putPrivateEndpointConnection("7241b7fa-c310-4b99-a53e-c5048cf0ec25", "TestRedisConnectorCache", "TestRedisConnector", 
    "testPrivateEndpoint", "Approved", "Auto-Approved");
    if (response is PrivateEndpointConnection) {
        json testValue = {
            "id": 
            "/subscriptions/7241b7fa-c310-4b99-a53e-c5048cf0ec25/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/Redis/TestRedisConnectorCache/privateEndpointConnections/testPrivateEndpoint",
            "name": "testPrivateEndpoint",
            "type": "Microsoft.Cache/Redis/privateEndpointConnections",
            "properties": 
            {
                "provisioningState": "Succeeded",
                "privateEndpoint": 
                {"id": 
                    "/subscriptions/7241b7fa-c310-4b99-a53e-c5048cf0ec25/resourceGroups/TestRedisConnector/providers/Microsoft.Network/privateEndpoints/testPrivateEndpoint"},
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
    var response = azureRedisClient->getPrivateEndpointConnection("7241b7fa-c310-4b99-a53e-c5048cf0ec25", "TestRedisConnectorCache", "TestRedisConnector", 
    "TestPrivateEndpoint");
    if (response is PrivateEndpointConnection) {
        json testValue = {
            "id": 
            "/subscriptions/7241b7fa-c310-4b99-a53e-c5048cf0ec25/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/Redis/cachetest01/privateEndpointConnections/TestPrivateEndpoint",
            "name": "TestPrivateEndpoint",
            "type": "Microsoft.Cache/Redis/privateEndpointConnections",
            "properties": 
            {
                "provisioningState": "Succeeded",
                "privateEndpoint": 
                {"id": 
                    "/subscriptions/7241b7fa-c310-4b99-a53e-c5048cf0ec25/resourceGroups/TestRedisConnector/providers/Microsoft.Network/privateEndpoints/TestPrivateEndpoint"},
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
    var response = azureRedisClient->listPrivateEndpointConnection("7241b7fa-c310-4b99-a53e-c5048cf0ec25", "TestRedisConnectorCache", "TestRedisConnector");
    if (response is PrivateEndpointConnection[]) {
        test:assertTrue(true, msg = "Error in listing private endpoint connection");
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
    var response = azureRedisClient->deletePrivateEndpointConnection("7241b7fa-c310-4b99-a53e-c5048cf0ec25", "TestRedisConnectorCache", "TestRedisConnector", 
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
    var response = azureRedisClient->getPrivateLinkResources("7241b7fa-c310-4b99-a53e-c5048cf0ec25", "TestRedisConnectorCache", "TestRedisConnector");
    if (response is PrivateLinkResource) {
        test:assertTrue(true, msg = "Error in getting PrivateLinkResources");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisCache"]}
function testDeleteRedisCache() {
    log:print("<---Running Delete Redis Cache Test--->");
    var response = azureRedisClient->deleteRedisCache("7241b7fa-c310-4b99-a53e-c5048cf0ec25", "TestRedisConnectorCache", "TestRedisConnector");
    if (response is boolean) {
        var getresponse = azureRedisClient->getRedisCache("7241b7fa-c310-4b99-a53e-c5048cf0ec25", "TestRedisConnectorCache", "TestRedisConnector");
        json state = ();
        if (getresponse is RedisCacheInstance) {
            state = getresponse.properties.provisioningState;
        }
        while (state == "Deleting") {
            var getloopresponse = azureRedisClient->getRedisCache("7241b7fa-c310-4b99-a53e-c5048cf0ec25", "TestRedisConnectorCache", "TestRedisConnector");
            if (getloopresponse is RedisCacheInstance) {
                state = getloopresponse.properties.provisioningState;
            }
            else {
            state = "Deleted";
            }
        }
        test:assertEquals(response, true, msg = "Deleting Redis Cache Instance test failed");
    } else {
        test:assertFail(response.message());
    }
}

@test:AfterSuite  {}
function afterFunc() {
    log:print("<---Running AfterSuite--->");
    var response = azureRedisClient->deleteRedisCache("7241b7fa-c310-4b99-a53e-c5048cf0ec25", "TestRedisConnectorCacheLinkedServer", "TestRedisConnector");
    if (response is boolean) {
        log:print("Cleaning up resources...");
        var getresponse = azureRedisClient->getRedisCache("7241b7fa-c310-4b99-a53e-c5048cf0ec25", "TestRedisConnectorCacheLinkedServer", "TestRedisConnector");
        json state = ();
        if (getresponse is RedisCacheInstance) {
            state = getresponse.properties.provisioningState;
        }
        while (state == "Deleting") {
            var getloopresponse = azureRedisClient->getRedisCache("7241b7fa-c310-4b99-a53e-c5048cf0ec25", "TestRedisConnectorCacheLinkedServer", "TestRedisConnector");
            if (getloopresponse is RedisCacheInstance) {
                state = getloopresponse.properties.provisioningState;
            }
            else {
            state = "Deleted";
            }
        }
    } else {
        log:print("Cleaning up resources failed");
    }
}
