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
import ballerina/io;
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
    io:println("<---Running Checking RedisCacheName availability Test--->");
    var response = azureRedisClient->checkRedisCacheNameAvailability("TestRedisConnectorCache");
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
        "minimumTlsVersion": minimumTlsVersion
    };
    io:println("<---Running CreateRedisCache Test--->");
    var response = azureRedisClient->createRedisCache("TestRedisConnectorCache", "TestRedisConnector", "South India", 
    properties);
    if (response is RedisCacheInstance) {
        boolean createSuccess = true;
        io:println("Deployment in progress...");
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
    io:println("<---Running GetRedisCache Test--->");
    var response = azureRedisClient->getRedisCache("TestRedisConnectorCache", "TestRedisConnector");
    if (response is RedisCacheInstance) {
        boolean getSuccess = true;
        test:assertEquals(getSuccess, true, msg = "Error in fetching Redis Instance");
    } else {
        test:assertFail(response.message());
    }
}

// @test:Config {dependsOn: ["testCreateRedisCache"]}
// function testExportRedisCache() {
//     io:println("<---Running ExportRedisCache Test--->");
//     var response = azureRedisClient->exportRedisCache("TestRedisConnectorCache", "TestRedisConnector", "datadump1", 
//     "https://teststorageredis.blob.core.windows.net/blobstorage", 
//     "?sv=2019-12-12&ss=bfqt&srt=sco&sp=rwdlacupx&se=2021-01-31T15:50:18Z&st=2021-01-06T07:50:18Z&spr=https&sig=N1hgjLaGeapkRRWTLk8McG%2BZPa4S6tG0F%2BkyZ5Rh0yw%3D", 
//     "RDB");
//     if (response is StatusCode) {
//         StatusCode statusCode = <@untainted>response;
//         boolean exportSuccess = false;
//         if (statusCode?.code == "200" || statusCode?.code == "202" || statusCode?.code == "204") {
//             exportSuccess = true;
//         }
//         test:assertEquals(exportSuccess, true, msg = "Error in Exporting redis cache");
//     } else {
//         test:assertFail(response.message());
//     }
//     runtime:sleep(60000);
// }

// @test:Config {dependsOn: ["testCreateRedisCache"]}
// function testImportRedisCache() {
//     io:println("<---Running ImportRedisCache Test--->");
//     var response = azureRedisClient->importRedisCache("TestRedisConnectorCache", "TestRedisConnector", 
//     ["https://teststorageredis.blob.core.windows.net/blobstorage/datadump1"], "RDB");
//     if (response is StatusCode) {
//         StatusCode statusCode = <@untainted>response;
//         boolean importSuccess = false;
//         if (statusCode?.code == "200" || statusCode?.code == "202" || statusCode?.code == "204") {
//             importSuccess = true;
//         }
//         test:assertEquals(importSuccess, true, msg = "Error in Importing redis cache");
//     } else {
//         test:assertFail(response.message());
//     }
// }

@test:Config {
    dependsOn: ["testCreateRedisCache"],
    enable: false
}
function testForceRebootRedisCache() {
    io:println("<---Running ForceRebootCache Test--->");
    var response = azureRedisClient->forceRebootRedisCache("TestRedisConnectorCache", "TestRedisConnector", 0, 
    "AllNodes", [13000, 13001]);
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        test:assertEquals(statusCode?.code, "200", msg = "Error in Rebooting Redis Instance");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisCache"]}
function testListByResourceGroup() {
    io:println("<---Running ListByResourceGroup Test--->");
    var response = azureRedisClient->listByResourceGroup("TestRedisConnector");
    if (response is RedisCacheInstanceList) {
        boolean listSuccess = true;
        test:assertEquals(listSuccess, true, msg = "Error in Listing Redis Instances");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisCache"]}
function testListBySubscription() {
    io:println("<---Running ListBySubscription Test--->");
    var response = azureRedisClient->listBySubscription();
    if (response is RedisCacheInstanceList) {
        boolean listSuccess = true;
        test:assertEquals(listSuccess, true, msg = "Error in Listing Redis Instances");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisCache"]}
function testListKeys() {
    io:println("<---Running ListKeys Test--->");
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
    io:println("<---Running RegenerateKey Test--->");
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
    io:println("<---Running UpdateRedisCache--->");

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
        "minimumTlsVersion": minimumTlsVersion
    };

    var response = azureRedisClient->updateRedisCache("TestRedisConnectorCache", "TestRedisConnector", properties);
    if (response is RedisCacheInstance) {
        boolean updateSuccess = true;
        test:assertEquals(updateSuccess, true, msg = "Error in updating RedisCache");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisCache"]}
function testCreateFirewallRule() {
    io:println("<---Running CreateFireWallRule Test--->");
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
    io:println("<---Running GetFireWallRule Test--->");
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
    io:println("<---Running ListFireWallRule Test--->");
    var response = azureRedisClient->listFirewallRules("TestRedisConnectorCache", "TestRedisConnector");
    if (response is FirewallRuleListResponse) {
        FirewallRuleListResponse testValue = {"value": [
            {
                "id": 
                "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/Redis/TestRedisConnectorCache/firewallRules/TestFilewallRule",
                "name": "TestRedisConnectorCache/TestFilewallRule",
                "type": "Microsoft.Cache/Redis/firewallRules",
                "properties": {
                    "startIP": "192.168.1.1",
                    "endIP": "192.168.1.4"
                }
            }]};
        test:assertEquals(response, testValue, msg = "Error in listing firewall rule");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateFirewallRule"]}
function testDeleteFireWallRule() {
    io:println("<---Running DeleteFireWallRule Test--->");
    var response = azureRedisClient->deleteFirewallRule("TestRedisConnectorCache", "TestRedisConnector", 
    "TestFilewallRule");
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        boolean deleteSuccess = false;
        if (statusCode?.code == "200" || statusCode?.code == "204") {
            deleteSuccess = true;
        }
        test:assertEquals(deleteSuccess, true, msg = "Error in deleting firewall rule");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisCache"]}
function testCreateLinkedServer() {
    io:println("<---Running CreateLinkedServer Test--->");

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
        "minimumTlsVersion": minimumTlsVersion
    };
    var createResponse = azureRedisClient->createRedisCache("TestRedisConnectorCacheLinkedServer", "TestRedisConnector", 
    "South India", properties);
    if (createResponse is json) {
        io:println("Deployment of second cache instance");
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
    "South India", "Secondary");
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
                "linkedRedisCacheLocation": "South India",
                "provisioningState": "Creating",
                "serverRole": "Secondary"
            }
        };
        io:println("Linking");
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
    io:println("<---Running GetLinkedServer Test--->");
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
                "linkedRedisCacheLocation": "South India",
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
    io:println("<---Running ListLinkedServer Test--->");
    var response = azureRedisClient->listLinkedServers("TestRedisConnectorCacheLinkedServer", "TestRedisConnector");
    if (response is LinkedServerList) {
        LinkedServerList testValue = {"value": [{
                "id": "/subscriptions/7241b7fa-c310-4b99-a53e-c5048cf0ec25/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/Redis/TestRedisConnectorCacheLinkedServer/linkedServers/TestRedisConnectorCache",
                "name": "TestRedisConnectorCache",
                "type": "Microsoft.Cache/Redis/linkedServers",
                "properties": 
                {
                    "linkedRedisCacheId": "/subscriptions/7241b7fa-c310-4b99-a53e-c5048cf0ec25/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/Redis/TestRedisConnectorCache",
                    "linkedRedisCacheLocation": "South India",
                    "serverRole": "Primary",
                    "provisioningState": "Succeeded"
                }
            }]};
        test:assertEquals(response, testValue, msg = "Error in listing linked server");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateLinkedServer"]}
function testDeleteLinkedServer() {
    io:println("<---Running DeleteLinkedServer Test--->");
    var response = azureRedisClient->deleteLinkedServer("TestRedisConnectorCache", "TestRedisConnector", 
    "TestRedisConnectorCacheLinkedServer");
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        boolean deleteSuccess = false;
        if (statusCode?.code == "200" || statusCode?.code == "204") {
            deleteSuccess = true;
        }
        test:assertEquals(deleteSuccess, true, msg = "Error in deleting LinkedServer");
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

    io:println("<---Running CreatePatchSchedule Test--->");
    var response = azureRedisClient->createPatchSchedule("TestRedisConnectorCache", "TestRedisConnector", properties);
    if (response is PatchSchedule) {
        PatchSchedule testValue = 
        {
            "id": 
            "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/Redis/TestRedisConnectorCache/patchSchedules/default",
            "location": "South India",
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
    io:println("<---Running GetPatchSchedule Test--->");
    var response = azureRedisClient->getPatchSchedule("TestRedisConnectorCache", "TestRedisConnector");
    if (response is PatchSchedule) {
        PatchSchedule testValue = 
        {
            "id": "/subscriptions/7241b7fa-c310-4b99-a53e-c5048cf0ec25/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/Redis/TestRedisConnectorCache/patchSchedules/default",
            "location": "South India",
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
    io:println("<---Running ListPatchSchedule Test--->");
    var response = azureRedisClient->listPatchSchedules("TestRedisConnectorCache", "TestRedisConnector");
    if (response is PatchScheduleList) {
        PatchScheduleList testValue = {"value": [
            {
                "id": "/subscriptions/7241b7fa-c310-4b99-a53e-c5048cf0ec25/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/Redis/TestRedisConnectorCache/patchSchedules/default",
                "location": "South India",
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
            }]};
        test:assertEquals(response, testValue, msg = "Error in listing patch schedule");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreatePatchSchedule"]}
function testDeletePatchSchedule() {
    io:println("<---Running DeletePatchSchedule Test--->");
    var response = azureRedisClient->deletePatchSchedule("TestRedisConnectorCache", "TestRedisConnector");
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        boolean deleteSuccess = false;
        if (statusCode?.code == "200" || statusCode?.code == "204") {
            deleteSuccess = true;
        }
        test:assertEquals(deleteSuccess, true, msg = "Error in deleting patch schedule");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {enable: false}
function testPutPrivateEndpointConnection() {
    io:println("<---Running PutPrivateEndpointConnection Test--->");
    var response = azureRedisClient->putPrivateEndpointConnection("TestRedisConnectorCache", "TestRedisConnector", 
    "testPrivateEndpoint");
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
    io:println("<---Running GetPrivateEndpointConnection Test--->");
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
    io:println("<---Running ListPrivateEndpointConnection Test--->");
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
    io:println("<---Running DeletePrivateEndpointConnection Test--->");
    var response = azureRedisClient->deletePrivateEndpointConnection("TestRedisConnectorCache", "TestRedisConnector", 
    "TestPrivateEndpoint");
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        test:assertEquals(statusCode?.code, "200", msg = "Error in deleting private endpoint connection");
    } else {
        test:assertFail(response.message());
    }
}
@test:Config {enable: false}
function testGetPrivateLinkResources() {
    io:println("<---Running GetPrivateLinkResources Test--->");
    var response = azureRedisClient->getPrivateLinkResources("TestRedisConnectorCache", "TestRedisConnector");
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        test:assertEquals(statusCode?.code, "200", msg = "Error in getting PrivateLinkResources");
    } else {
        test:assertFail(response.message());
    }
}
@test:Config {}
function testDeleteRedisCache() {
    io:println("<---Running Delete Redis Cache Test--->");
    var response = azureRedisClient->deleteRedisCache("TestRedisConnectorCache", "TestRedisConnector");
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        boolean deleteSuccess = false;
        if (statusCode?.code == "200" || statusCode?.code == "202" || statusCode?.code == "204") {
            deleteSuccess = true;
        }
        var getresponse = azureRedisClient->getRedisCache("TestRedisConnectorCache", "TestRedisConnector");
        json state = ();
        if (getresponse is json) {
            state = getresponse.properties.provisioningState;
        }
        while (state == "Deleting") {
            var getresponse1 = azureRedisClient->getRedisCache("TestRedisConnectorCache", "TestRedisConnector");
            if (getresponse1 is json) {
                state = getresponse1.properties.provisioningState;
                io:println(getresponse1.properties.provisioningState);
            }
        }
        test:assertEquals(deleteSuccess, true, msg = "Error in deleting Redis Cache Instance");
    } else {
        test:assertFail(response.message());
    }
}
@test:Config {}
function testCreateRedisEnterprise() {
    io:println("<---Running CreateRedisEnterprise Test--->");
    var response = azureRedisClient->createRedisEnterprise("TestRedisEnterprise", "TestRedisConnector", 
    "southeastasia", "EnterpriseFlash_F300", 3);
    if (response is RedisEnterpriseInstance) {
        RedisEnterpriseInstance testValue = 
        {
            "location": "Southeast Asia",
            "name": "TestRedisEnterprise",
            "id": "/subscriptions/7241b7fa-c310-4b99-a53e-c5048cf0ec25/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/redisEnterprise/TestRedisEnterprise",
            "type": "Microsoft.Cache/redisEnterprise",
            "tags": {"tag1": "value1"},
            "sku": {
                "name": "EnterpriseFlash_F300",
                "capacity": 3
            },
            "properties": {
                "provisioningState": "Creating",
                "resourceState": "Creating"
            },
            "zones": ["1", "2", "3"]
        };
        test:assertEquals(response, testValue, msg = "Error in creating RedisEnterprise");
    } else {
        test:assertFail(response.message());
    }
}
@test:Config {
    dependsOn: ["testCreateRedisEnterprise"],
    enable: false
}
function testCreateRedisEnterpriseDatabase() {
    var response = azureRedisClient->createRedisEnterpriseDatabase("TestRedisEnterprise", "TestRedisConnector", 
    "default");
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        boolean createSuccess = false;
        if (statusCode?.code == "200" || statusCode?.code == "201") {
            createSuccess = true;
        }
        test:assertEquals(createSuccess, true, msg = "Error in creating RedisEnterprise");
    } else {
        test:assertFail(response.message());
    }
}
@test:Config {
    dependsOn: ["testCreateRedisEnterprise", "testCreateRedisEnterpriseDatabase"],
    enable: false
}
function testGetRedisEnterpriseDatabase() {
    var response = azureRedisClient->getRedisEnterpriseDatabase("TestRedisEnterprise", "TestRedisConnector", 
    "default");
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        boolean getSuccess = false;
        if (statusCode?.code == "200") {
            getSuccess = true;
        }
        test:assertEquals(getSuccess, true, msg = "Error in fetching RedisEnterprise");
    } else {
        test:assertFail(response.message());
    }
}
@test:Config {
    dependsOn: ["testCreateRedisEnterprise", "testCreateRedisEnterpriseDatabase"],
    enable: false
}
function testListRedisEnterpriseDatabaseByCluster() {
    var response = azureRedisClient->listRedisEnterpriseDatabaseByCluster("TestRedisEnterprise", 
    "TestRedisConnector");
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        boolean getSuccess = false;
        if (statusCode?.code == "200") {
            getSuccess = true;
        }
        test:assertEquals(getSuccess, true, msg = "Error in fetching RedisEnterprise by cluster");
    } else {
        test:assertFail(response.message());
    }
}
@test:Config {
    dependsOn: ["testCreateRedisEnterprise", "testCreateRedisEnterpriseDatabase"],
    enable: false
}
function testListRedisEnterpriseDatabaseKeys() {
    io:println("Running List Redis Enterprise Cache Database Keys Test");
    var response = azureRedisClient->listRedisEnterpriseDatabaseKeys("TestRedisEnterprise", 
    "TestRedisConnector", "default");
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        boolean getSuccess = false;
        if (statusCode?.code == "200") {
            getSuccess = true;
        }
        test:assertEquals(getSuccess, true, msg = "Error in listing Redis Enterprise Cache Keys");
    } else {
        test:assertFail(response.message());
    }
}
@test:Config {
    dependsOn: ["testCreateRedisEnterprise", "testCreateRedisEnterpriseDatabase"],
    enable: false
}
function testRegenerateRedisEnterpriseDatabaseKey() {
    io:println("Running Regenerate Redis Enterprise Cache Database Key Test");
    var response = azureRedisClient->regenerateRedisEnterpriseDatabaseKey("TestRedisEnterprise", 
    "TestRedisConnector", "default", "Primary");
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        boolean getSuccess = false;
        if (statusCode?.code == "200" || statusCode?.code == "202") {
            getSuccess = true;
        }
        test:assertEquals(getSuccess, true, msg = "Error in regenerating Redis Enterprise Cache Key");
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
    var response = azureRedisClient->updateRedisEnterpriseDatabase("TestRedisEnterprise", "TestRedisConnector", 
    "default", "Encrypted", "AllKeysLRU", "RediSearch");
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        boolean getSuccess = false;
        if (statusCode?.code == "200" || statusCode?.code == "202") {
            getSuccess = true;
        }
        test:assertEquals(getSuccess, true, msg = "Error in regenerating Redis Enterprise Cache Key");
    } else {
        test:assertFail(response.message());
    }
}
@test:Config {
    dependsOn: ["testCreateRedisEnterprise", "testCreateRedisEnterpriseDatabase"],
    enable: false
}
function testDeleteRedisEnterpriseDatabase() {
    var response = azureRedisClient->deleteRedisEnterpriseDatabase("TestRedisEnterprise", "TestRedisConnector", 
    "default");
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        boolean deleteSuccess = false;
        if (statusCode?.code == "200" || statusCode?.code == "201" || statusCode?.code == "204") {
            deleteSuccess = true;
        }
        test:assertEquals(deleteSuccess, true, msg = "Error in deleting RedisEnterprise");
    } else {
        test:assertFail(response.message());
    }
}
@test:Config {dependsOn: ["testCreateRedisEnterprise"]}
function testGetRedisEnterprise() {
    io:println("Running Get Redis Enterprise Cache Test");
    var response = azureRedisClient->getRedisEnterprise("TestRedisEnterprise", "TestRedisConnector");
    if (response is RedisEnterpriseInstance) {
        RedisEnterpriseInstance testValue = 
        {
            "location": "Southeast Asia",
            "name": "TestRedisEnterprise",
            "id": "/subscriptions/7241b7fa-c310-4b99-a53e-c5048cf0ec25/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/redisEnterprise/TestRedisEnterprise",
            "type": "Microsoft.Cache/redisEnterprise",
            "tags": {"tag1": "value1"},
            "sku": {
                "name": "EnterpriseFlash_F300",
                "capacity": 3
            },
            "properties": {
                "provisioningState": "Creating",
                "resourceState": "Creating",
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
    var response = azureRedisClient->listRedisEnterprise();
    if (response is RedisEnterpriseInstanceList) {
        RedisEnterpriseInstanceList testValue = {"value": [
            {
                "location": "Southeast Asia",
                "name": "TestRedisEnterprise",
                "id": "/subscriptions/7241b7fa-c310-4b99-a53e-c5048cf0ec25/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/redisEnterprise/TestRedisEnterprise",
                "type": "Microsoft.Cache/redisEnterprise",
                "tags": {"tag1": "value1"},
                "sku": {
                    "name": "EnterpriseFlash_F300",
                    "capacity": 3
                },
                "properties": {
                    "provisioningState": "Creating",
                    "resourceState": "Creating",
                    "privateEndpointConnections": []
                },
                "zones": ["1", "2", "3"]
            }]};
        test:assertEquals(response, testValue, msg = "Error in fetching RedisEnterprise List");
    } else {
        test:assertFail(response.message());
    }
}
@test:Config {dependsOn: ["testCreateRedisEnterprise"]}
function testListRedisEnterpriseByResourceGroup() {
    var response = azureRedisClient->listRedisEnterpriseByResourceGroup("TestRedisConnector");
    if (response is RedisEnterpriseInstanceList) {
        RedisEnterpriseInstanceList testValue = {"value": [
            {
                "location": "Southeast Asia",
                "name": "TestRedisEnterprise",
                "id": "/subscriptions/7241b7fa-c310-4b99-a53e-c5048cf0ec25/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/redisEnterprise/TestRedisEnterprise",
                "type": "Microsoft.Cache/redisEnterprise",
                "tags": {"tag1": "value1"},
                "sku": {
                    "name": "EnterpriseFlash_F300",
                    "capacity": 3
                },
                "properties": {
                    "provisioningState": "Creating",
                    "resourceState": "Creating",
                    "privateEndpointConnections": []
                },
                "zones": ["1", "2", "3"]
            }]};
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
    var response = azureRedisClient->updateRedisEnterprise("TestRedisEnterprise", "TestRedisConnector");
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        boolean getSuccess = false;
        if (statusCode?.code == "200") {
            getSuccess = true;
        }
        test:assertEquals(getSuccess, true, msg = "Error in updating RedisEnterprise");
    } else {
        test:assertFail(response.message());
    }
}
@test:Config {dependsOn: ["testCreateRedisEnterprise"]}
function testDeleteRedisEnterprise() {
    var response = azureRedisClient->deleteRedisEnterprise("TestRedisEnterprise", "TestRedisConnector");
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        boolean deleteSuccess = false;
        if (statusCode?.code == "200" || statusCode?.code == "202" || statusCode?.code == "204") {
            deleteSuccess = true;
        }
        test:assertEquals(deleteSuccess, true, msg = "Error in deleting RedisEnterprise");
    } else {
        test:assertFail(response.message());
    }
}
