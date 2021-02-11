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
function testCheckeRedisCacheAvailability() {
    log:print("<---Running Checking RedisCacheName availability Test--->");
    var response = azureRedisManagementClient->checkRedisCacheNameAvailability(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache");
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
        test:assertEquals(createSuccess, true, msg = "Error in creating Redis Cache");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisCache"]}
function testGetRedisCache() {
    log:print("<---Running GetRedisCache Test--->");
    var response = azureRedisManagementClient->getRedisCache(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") );
    if (response is RedisCacheInstance) {
        log:print(response.toString());
        boolean getSuccess = true;
        test:assertEquals(getSuccess, true, msg = "Error in fetching Redis Instance");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisCache"]}
function testGetHostName() {
    log:print("<---Running GetHostName Test--->");
    var response = azureRedisManagementClient->getHostName(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") );
    if (response is string) {
        string expectedHostName = "TestRedisConnectorCache.redis.cache.windows.net";
        test:assertEquals(response, expectedHostName, msg = "Error in fetching Redis Cache Host Name");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisCache"]}
function testGetPortNumber() {
    log:print("<---Running GetPortNumber Test--->");
    var response = azureRedisManagementClient->getPortNumber(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") );
    if (response is int) {
        int expectedPortNumber = 6379;
        test:assertEquals(response, expectedPortNumber, msg = "Error in fetching Redis Cache Port Number");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisCache"]}
function testGetgetPrimaryKey() {
    log:print("<---Running GetPortNumber Test--->");
    var response = azureRedisManagementClient->getPrimaryKey(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") );
    if (response is string) {
        test:assertTrue(true, msg = "Error in fetching Redis Cache Primary Key");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisCache"]}
function testListByResourceGroup() {
    log:print("<---Running ListByResourceGroup Test--->");
    var response = azureRedisManagementClient->listRedisCacheInstances(config:getAsString("SUBSCRIPTION_ID"), config:getAsString("RESOURCE_GROUP_NAME") );
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
    var response = azureRedisManagementClient->listRedisCacheInstances(config:getAsString("SUBSCRIPTION_ID"));
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
    var response = azureRedisManagementClient->listKeys(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") );
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
    var response = azureRedisManagementClient->regenerateKey(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") , "Primary");
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

    var response = azureRedisManagementClient->updateRedisCache(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") , "southeastasia", properties);
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

@test:Config {dependsOn: ["testCreateFirewallRule"]}
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

@test:Config {dependsOn: ["testCreateFirewallRule"]}
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

@test:Config {dependsOn: ["testCreateFirewallRule"]}
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

@test:Config {dependsOn: ["testCreatePatchSchedule"]}
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

@test:Config {dependsOn: ["testCreatePatchSchedule"]}
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

@test:Config {dependsOn: ["testCreatePatchSchedule"]}
function testDeletePatchSchedule() {
    log:print("<---Running DeletePatchSchedule Test--->");
    var response = azureRedisManagementClient->deletePatchSchedule(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") );
    if (response is boolean) {
        test:assertEquals(response, true, msg = "Deleting patch schedule test failed");
    } else {
        test:assertFail(response.message());
    }
}

// @test:Config {dependsOn: ["testCreateRedisCache"]}
// function testCreateLinkedServer() {
//     log:print("<---Running CreateLinkedServer Test--->");
//     var response = azureRedisManagementClient->createLinkedServer(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") , 
//     "TestRedisConnectorCacheLinkedServer", 
//     "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/" + config:getAsString("RESOURCE_GROUP_NAME")  + "/providers/Microsoft.Cache/Redis/TestRedisConnectorCacheLinkedServer", 
//     "Southeast Asia", "Secondary");
//     if (response is LinkedServer) {
//         LinkedServer testValue = {
//             "id": 
//             "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/" + config:getAsString("RESOURCE_GROUP_NAME")  + "/providers/Microsoft.Cache/Redis/TestRedisConnectorCache/linkedServers/TestRedisConnectorCacheLinkedServer",
//             "name": "TestRedisConnectorCacheLinkedServer",
//             "type": "Microsoft.Cache/Redis/linkedServers",
//             "properties": 
//             {
//                 "linkedRedisCacheId": 
//                 "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/" + config:getAsString("RESOURCE_GROUP_NAME")  + "/providers/Microsoft.Cache/Redis/TestRedisConnectorCacheLinkedServer",
//                 "linkedRedisCacheLocation": "Southeast Asia",
//                 "provisioningState": "Creating",
//                 "serverRole": "Secondary"
//             }
//         };
//         log:print("Linking...");
//         json state = response.properties.provisioningState;
//         while (state != "Succeeded") {
//             var getresponse = azureRedisManagementClient->getLinkedServer(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") , 
//             "TestRedisConnectorCacheLinkedServer");
//             if (getresponse is LinkedServer) {
//                 state = getresponse.properties.provisioningState;
//             }
//         }
//         test:assertEquals(response, testValue, msg = "Error in creating linked server");
//     } else {
//         test:assertFail(response.message());
//     }
// }

// @test:Config {dependsOn: ["testCreateLinkedServer"]}
// function testGetLinkedServer() {
//     log:print("<---Running GetLinkedServer Test--->");
//     var response = azureRedisManagementClient->getLinkedServer(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") , 
//     "TestRedisConnectorCacheLinkedServer");
//     if (response is LinkedServer) {
//         LinkedServer testValue = {
//             "id": 
//             "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/" + config:getAsString("RESOURCE_GROUP_NAME")  + "/providers/Microsoft.Cache/Redis/TestRedisConnectorCache/linkedServers/TestRedisConnectorCacheLinkedServer",
//             "name": "TestRedisConnectorCacheLinkedServer",
//             "type": "Microsoft.Cache/Redis/linkedServers",
//             "properties": 
//             {
//                 "linkedRedisCacheId": 
//                 "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/" + config:getAsString("RESOURCE_GROUP_NAME")  + "/providers/Microsoft.Cache/Redis/TestRedisConnectorCacheLinkedServer",
//                 "linkedRedisCacheLocation": "Southeast Asia",
//                 "provisioningState": "Succeeded",
//                 "serverRole": "Secondary"
//             }
//         };
//         test:assertEquals(response, testValue, msg = "Error in fetching linked server");
//     } else {
//         test:assertFail(response.message());
//     }
// }

// @test:Config {dependsOn: ["testCreateLinkedServer"]}
// function testListLinkedServer() {
//     log:print("<---Running ListLinkedServer Test--->");
//     var response = azureRedisManagementClient->listLinkedServers(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCacheLinkedServer", config:getAsString("RESOURCE_GROUP_NAME") );
//     if (response is LinkedServer[]) {
//         LinkedServer[] testValue = [{
//                 "id": "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/" + config:getAsString("RESOURCE_GROUP_NAME")  + "/providers/Microsoft.Cache/Redis/TestRedisConnectorCacheLinkedServer/linkedServers/TestRedisConnectorCache",
//                 "name": "TestRedisConnectorCache",
//                 "type": "Microsoft.Cache/Redis/linkedServers",
//                 "properties": 
//                 {
//                     "linkedRedisCacheId": "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/" + config:getAsString("RESOURCE_GROUP_NAME")  + "/providers/Microsoft.Cache/Redis/TestRedisConnectorCache",
//                     "linkedRedisCacheLocation": "Southeast Asia",
//                     "serverRole": "Primary",
//                     "provisioningState": "Succeeded"
//                 }
//             }];
//         test:assertEquals(response, testValue, msg = "Error in listing linked server");
//     } else {
//         test:assertFail(response.message());
//     }
// }

// @test:Config {dependsOn: ["testCreateLinkedServer"]}
// function testDeleteLinkedServer() {
//     log:print("<---Running DeleteLinkedServer Test--->");
//     var response = azureRedisManagementClient->deleteLinkedServer(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") , 
//     "TestRedisConnectorCacheLinkedServer");
//     if (response is boolean) {
//         log:print("Deleting LinkedServer...");
//         runtime:sleep(600000);
//         test:assertEquals(response, true, msg = "Deleting LinkedServer test failed");
//     } else {
//         test:assertFail(response.message());
//     }
// }

// @test:Config {dependsOn: ["testCreateRedisCache"]}
// function testExportRedisCache() {
//     log:print("<---Running ExportRedisCache Test--->");
//     var response = azureRedisManagementClient->exportRedisCache(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") , "datadump1", 
//     "https://teststorageredis.blob.core.windows.net/blobstorage", 
//     "?sv=2019-12-12&ss=bfqt&srt=c&sp=rwdlacupx&se=2021-02-10T22:17:37Z&st=2021-02-10T14:17:37Z&spr=https,http&sig=q%2F3MVsuvPUB69Tkf6NrspZCogoOMeWrgBoCx1c1%2BN%2Fk%3D", 
//     "RDB");
//     if (response is boolean) {
//         test:assertEquals(response, true, msg = "Error in Exporting redis cache");
//     } else {
//         test:assertFail(response.message());
//     }
//     runtime:sleep(6000);
// }

// @test:Config {dependsOn: ["testCreateRedisCache"]}
// function testImportRedisCache() {
//     log:print("<---Running ImportRedisCache Test--->");
//     var response = azureRedisManagementClient->importRedisCache(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") , 
//     ["https://teststorageredis.blob.core.windows.net/blobstorage/datadump1"], "RDB");
//     if (response is boolean) {
//         test:assertEquals(response, true, msg = "Error in Importing redis cache");
//     } else {
//         test:assertFail(response.message());
//     }
// }

// @test:Config {enable: false}
// function testPutPrivateEndpointConnection() {
//     log:print("<---Running PutPrivateEndpointConnection Test--->");
//     var response = azureRedisManagementClient->putPrivateEndpointConnection(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") , 
//     "testPrivateEndpoint", "Approved", "Auto-Approved");
//     if (response is PrivateEndpointConnection) {
//         json testValue = {
//             "id": 
//             "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/" + config:getAsString("RESOURCE_GROUP_NAME")  + "/providers/Microsoft.Cache/Redis/TestRedisConnectorCache/privateEndpointConnections/testPrivateEndpoint",
//             "name": "testPrivateEndpoint",
//             "type": "Microsoft.Cache/Redis/privateEndpointConnections",
//             "properties": 
//             {
//                 "provisioningState": "Succeeded",
//                 "privateEndpoint": 
//                 {"id": 
//                     "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/" + config:getAsString("RESOURCE_GROUP_NAME")  + "/providers/Microsoft.Network/privateEndpoints/testPrivateEndpoint"},
//                 "privateLinkServiceConnectionState": {
//                     "status": "Approved",
//                     "description": "Auto-Approved",
//                     "actionsRequired": "None"
//                 }
//             }
//         };
//         test:assertEquals(response, testValue, msg = "Error in creating PrivateEndpointConnection");
//     } else {
//         test:assertFail(response.message());
//     }
// }

// @test:Config {
//     dependsOn: ["testPutPrivateEndpointConnection"],
//     enable: false
// }
// function testgetPrivateEndpointConnection() {
//     log:print("<---Running GetPrivateEndpointConnection Test--->");
//     var response = azureRedisManagementClient->getPrivateEndpointConnection(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") , 
//     "TestPrivateEndpoint");
//     if (response is PrivateEndpointConnection) {
//         json testValue = {
//             "id": 
//             "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/" + config:getAsString("RESOURCE_GROUP_NAME")  + "/providers/Microsoft.Cache/Redis/cachetest01/privateEndpointConnections/TestPrivateEndpoint",
//             "name": "TestPrivateEndpoint",
//             "type": "Microsoft.Cache/Redis/privateEndpointConnections",
//             "properties": 
//             {
//                 "provisioningState": "Succeeded",
//                 "privateEndpoint": 
//                 {"id": 
//                     "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/" + config:getAsString("RESOURCE_GROUP_NAME")  + "/providers/Microsoft.Network/privateEndpoints/TestPrivateEndpoint"},
//                 "privateLinkServiceConnectionState": {
//                     "status": "Approved",
//                     "description": "Auto-Approved",
//                     "actionsRequired": "None"
//                 }
//             }
//         };
//         test:assertEquals(response, testValue, msg = "Error in getting PrivateEndpointConnection");
//     } else {
//         test:assertFail(response.message());
//     }
// }

// @test:Config {
//     dependsOn: ["testPutPrivateEndpointConnection"],
//     enable: false
// }
// function testListPrivateEndpointConnection() {
//     log:print("<---Running ListPrivateEndpointConnection Test--->");
//     var response = azureRedisManagementClient->listPrivateEndpointConnection(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") );
//     if (response is PrivateEndpointConnection[]) {
//         test:assertTrue(true, msg = "Error in listing private endpoint connection");
//     } else {
//         test:assertFail(response.message());
//     }
// }

// @test:Config {
//     dependsOn: ["testPutPrivateEndpointConnection"],
//     enable: false
// }
// function testDeletePrivateEndpointConnection() {
//     log:print("<---Running DeletePrivateEndpointConnection Test--->");
//     var response = azureRedisManagementClient->deletePrivateEndpointConnection(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") , 
//     "TestPrivateEndpoint");
//     if (response is boolean) {
//         test:assertEquals(response, true, msg = "Deleting private endpoint connection test failed");
//     } else {
//         test:assertFail(response.message());
//     }
// }

// @test:Config {enable: false}
// function testGetPrivateLinkResources() {
//     log:print("<---Running GetPrivateLinkResources Test--->");
//     var response = azureRedisManagementClient->getPrivateLinkResources(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") );
//     if (response is PrivateLinkResource) {
//         test:assertTrue(true, msg = "Error in getting PrivateLinkResources");
//     } else {
//         test:assertFail(response.message());
//     }
// }

// @test:Config {dependsOn: ["testCreateRedisCache"]}
// function testDeleteRedisCache() {
//     log:print("<---Running Delete Redis Cache Test--->");
//     var response = azureRedisManagementClient->deleteRedisCache(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") );
//     if (response is boolean) {
//         var getresponse = azureRedisManagementClient->getRedisCache(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") );
//         json state = ();
//         if (getresponse is RedisCacheInstance) {
//             state = getresponse.properties.provisioningState;
//         }
//         while (state == "Deleting") {
//             var getloopresponse = azureRedisManagementClient->getRedisCache(config:getAsString("SUBSCRIPTION_ID"), "TestRedisConnectorCache", config:getAsString("RESOURCE_GROUP_NAME") );
//             if (getloopresponse is RedisCacheInstance) {
//                 state = getloopresponse.properties.provisioningState;
//             }
//             else {
//             state = "Deleted";
//             }
//         }
//         test:assertEquals(response, true, msg = "Deleting Redis Cache Instance test failed");
//     } else {
//         test:assertFail(response.message());
//     }
// }

