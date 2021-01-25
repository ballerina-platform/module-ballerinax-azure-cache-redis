import ballerina/io;
import ballerina/test;
import ballerina/config;

string|error token = <@untainted>generateToken(config:getAsString("CLIENT_ID"), config:getAsString("CLIENT_SECRET"), 
config:getAsString("TENANT_ID"));

AzureRedisConfiguration config = {oauth2Config: {
        accessToken: <string>token,
        refreshConfig: {
            clientId: config:getAsString("CLIENT_ID"),
            clientSecret: config:getAsString("CLIENT_SECRET"),
            refreshUrl: "https://login.microsoftonline.com/" + config:getAsString("TENANT_ID") + "/oauth2/v2.0/token",
            refreshToken: ""
        }
    }};

Client azureRedisClient = new (config);

@test:Config {}
function testCheckeRedisCacheAvailability() {
    var response = azureRedisClient->checkRedisCacheNameAvailability("TestRedisConnectorfCacheNew");
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        test:assertEquals(statusCode?.code, "200", msg = "Error in Checking");
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
    io:println("Running CreateRedisCache Test");
    var response = azureRedisClient->createRedisCache("TestRedisConnectorCache", "TestRedisConnector", "South India", 
    properties);
    io:println(response);
    if (response is json) {
        boolean createSuccess = true;
        io:println("Deployment in progress...");
        json state = response.properties.provisioningState;
        while (state != "Succeeded") {
            var getresponse = azureRedisClient->getRedisCache("TestRedisConnectorCache", "TestRedisConnector");
            if (getresponse is json) {
                state = getresponse.properties.provisioningState;
            }
        }
        test:assertEquals(createSuccess, true, msg = "Error in creating RedisCache");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisCache"]}
function testGetRedisCache() {
    io:println("Running GetRedisCache Test");
    var response = azureRedisClient->getRedisCache("TestRedisConnectorCache", "TestRedisConnector");
    if (response is json) {
        RedisCacheInstance testValue = 
        {
            "id": 
            "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/Redis/TestRedisConnectorCache",
            "location": "South India",
            "name": "TestRedisConnectorCache",
            "type": "Microsoft.Cache/Redis",
            "tags": {},
            "properties": {
                "provisioningState": "Succeeded",
                "redisVersion": "4.0.14",
                "sku": {
                    "name": "Premium",
                    "family": "P",
                    "capacity": 1
                },
                "enableNonSslPort": true,
                "instances": [{
                    "sslPort": 15000,
                    "nonSslPort": 13000,
                    "isMaster": true
                }, {
                    "sslPort": 15001,
                    "nonSslPort": 13001,
                    "isMaster": false
                }],
                "publicNetworkAccess": "Enabled",
                "redisConfiguration": {
                    "maxclients": "7500",
                    "maxmemory-reserved": "200",
                    "maxfragmentationmemory-reserved": "300",
                    "maxmemory-delta": "200"
                },
                "accessKeys": null,
                "hostName": "TestRedisConnectorCache.redis.cache.windows.net",
                "port": 6379,
                "sslPort": 6380,
                "linkedServers": []
            }
        };
        test:assertEquals(response, testValue, msg = "Error in fetching Redis Instance");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisCache"]}
function testExportRedisCache() {
    io:println("Running ExportRedisCache Test");
    var response = azureRedisClient->exportRedisCache("TestRedisConnectorCache", "TestRedisConnector", "datadump1", 
    "https://teststorageredis.blob.core.windows.net/blobstorage", 
    "?sv=2019-12-12&ss=bf&srt=c&sp=rwdlacx&se=2023-01-25T16:22:57Z&st=2021-01-25T08:22:57Z&spr=https&sig=DqUgEt5Jny0r1YN0PwQ0v3ebc67MB2t5b9fHMcp6px0%3D", 
    "RDB");
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        boolean exportSuccess = false;
        if (statusCode?.code == "200" || statusCode?.code == "202" || statusCode?.code == "204") {
            exportSuccess = true;
        }
        test:assertEquals(exportSuccess, true, msg = "Error in Exporting redis cache");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {}
function testImportRedisCache() {
    io:println("Running ImportRedisCache Test");
    var response = azureRedisClient->importRedisCache("TestRedisConnectorCache", "TestRedisConnector", 
    "https://teststorageredis.blob.core.windows.net/blobstorage/datadump1", "RDB");
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        boolean importSuccess = false;
        if (statusCode?.code == "200" || statusCode?.code == "202" || statusCode?.code == "204") {
            importSuccess = true;
        }
        test:assertEquals(importSuccess, true, msg = "Error in Importing redis cache");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisCache"]}
function testForceRebootRedisCache() {
    io:println("Running ForceRebootCache Test");
    var response = azureRedisClient->forceRebootRedisCache("TestRedisConnectorCache", "TestRedisConnector", 0, 
    "AllNodes", [13000, 15001]);
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        test:assertEquals(statusCode?.code, "200", msg = "Error in Rebooting Redis Instance");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisCache"]}
function testListByResourceGroup() {
    io:println("Running ListByResourceGroup Test");

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
        io:println(createResponse.properties.provisioningState);
        boolean createSuccess = true;
        io:println(createResponse);
        io:println(createResponse.properties.provisioningState);
        io:println("Deployment of second cache instance");
        json state = createResponse.properties.provisioningState;
        while (state != "Succeeded") {
            var getresponse = azureRedisClient->getRedisCache("TestRedisConnectorCacheLinkedServer", 
            "TestRedisConnector");
            if (getresponse is json) {
                state = getresponse.properties.provisioningState;
            }
        }
        test:assertEquals(createSuccess, true, msg = "Error in creating RedisCache");
    } else {
        test:assertFail(createResponse.message());
    }

    var response = azureRedisClient->listByResourceGroup("TestRedisConnector");
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        test:assertEquals(statusCode?.code, "200", msg = "Error in Listing Redis Instances");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisCache"]}
function testListBySubscription() {
    io:println("Running ListBySubscription Test");
    var response = azureRedisClient->listBySubscription();
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        test:assertEquals(statusCode?.code, "200", msg = "Error in Listing Redis Instances");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisCache"]}
function testListKeys() {
    io:println("Running ListKeys Test");
    var response = azureRedisClient->listKeys("TestRedisConnectorCache", "TestRedisConnector");
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        test:assertEquals(statusCode?.code, "200", msg = "Error in Listing Redis Instance Key");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisCache"]}
function testListUpgradeNotifications() {
    io:println("Running ListUpgradeNotifications Test");
    var response = azureRedisClient->listUpgradeNotifications("TestRedisConnectorCache", "TestRedisConnector", 5000.00);
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        var result = false;
        if (statusCode?.code == "200" || statusCode?.code == "404") {
            result = true;
        } else {
            result = false;
        }
        test:assertTrue(result, msg = "Error in Listing Redis Update Notifications");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisCache"]}
function testRegenerateKey() {
    io:println("Running RegenerateKey Test");
    var response = azureRedisClient->regenerateKey("TestRedisConnectorCacheNew", "TestRedisConnector", "Primary");
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        test:assertEquals(statusCode?.code, "200", msg = "Error in regenerating Key");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisCache"]}
function testUpdateRedisCache() {
    io:println("Running UpdateRedisCache");

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

    json testValue = 
    {
        "id": 
        "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/Redis/TestRedisConnectorCache",
        "location": "South India",
        "name": "TestRedisConnectorCache",
        "type": "Microsoft.Cache/Redis",
        "tags": {},
        "properties": {
            "provisioningState": "Succeeded",
            "redisVersion": "4.0.14",
            "sku": {
                "name": "Premium",
                "family": "P",
                "capacity": 1
            },
            "enableNonSslPort": false,
            "instances": [{"sslPort": 15000, "isMaster": true}, {
                "sslPort": 15001,
                "isMaster": false
            }],
            "publicNetworkAccess": "Enabled",
            "redisConfiguration": {
                "maxclients": "7500",
                "maxmemory-reserved": "200",
                "maxfragmentationmemory-reserved": "300",
                "maxmemory-delta": "200"
            },
            "accessKeys": null,
            "hostName": "TestRedisConnectorCache.redis.cache.windows.net",
            "port": 6379,
            "sslPort": 6380,
            "linkedServers": []
        }
    };

    var response = azureRedisClient->updateRedisCache("TestRedisConnectorCache", "TestRedisConnector", properties);
    if (response is json) {
        test:assertEquals(response, testValue, msg = "Error in updating redis cache");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {
// dependsOn: ["testCreateRedisCache"]
}
function testCreateFirewallRule() {
    io:println("Running CreateFireWallRule Test");
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
    io:println("Running GetFireWallRule Test");
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
    io:println("Running ListFireWallRule Test");
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
    io:println("Running DeleteFireWallRule Test");
    var response = azureRedisClient->deleteFirewallRule("TestRedisConnectorCache", "TestRedisConnector", 
    "TestFilewallRule");
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        test:assertEquals(statusCode?.code, "200", msg = "Error in deleting firewall rule");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {}
function testCreateLinkedServer() {
    io:println("Running CreateLinkedServer Test");
    var response = azureRedisClient->createLinkedServer("TestRedisConnectorCache", "TestRedisConnector", 
    "TestRedisConnectorCacheLinkedServer", 
    "/subscriptions/" + config:getAsString("SUBSCRIPTION_ID") + "/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/Redis/TestRedisConnectorCacheLinkedServer", 
    "South India", "Secondary");
    if (response is json) {
        json testValue = {
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
        io:println(response.properties.provisioningState);
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
    io:println("Running GetLinkedServer Test");
    var response = azureRedisClient->getLinkedServer("TestRedisConnectorCache", "TestRedisConnector", 
    "TestRedisConnectorCacheLinkedServer");
    if (response is json) {
        LinkedServer cacheResponse = <@untainted>response;
        io:println(cacheResponse);
        json testValue = {
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
        test:assertEquals(cacheResponse, testValue, msg = "Error in fetching linked server");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateLinkedServer"]}
function testListLinkedServer() {
    io:println("Running ListLinkedServer Test");
    var response = azureRedisClient->listLinkedServers("TestRedisConnectorCacheLinkedServer", "TestRedisConnector");
    if (response is StatusCode) {
        StatusCode cacheResponse = <@untainted>response;
        io:println(cacheResponse);
    // test:assertEquals(cacheResponse, "200" , msg = "Error in listing linked server");      
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateLinkedServer"]}
function testDeleteLinkedServer() {
    io:println("Running DeleteLinkedServer Test");
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

@test:Config {}
function testCreatePatchSchedule() {
    PatchScheduleProperty properties = {scheduleEntries: [{
            dayOfWeek: "Monday",
            startHourUtc: 12,
            maintenanceWindow: "PT5H"
        }, {
            dayOfWeek: "Tuesday",
            startHourUtc: 12
        }]};

    io:println("Running CreatePatchSchedule Test");
    var response = azureRedisClient->createPatchSchedule("TestRedisConnectorCache", "TestRedisConnector", properties);
    if (response is PatchShedule) {
        PatchShedule testValue = 
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
    io:println("Running GetPatchSchedule Test");
    var response = azureRedisClient->getPatchSchedule("TestRedisConnectorCache", "TestRedisConnector");
    if (response is PatchShedule) {
        PatchShedule testValue = 
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
    io:println("Running ListPatchSchedule Test");
    var response = azureRedisClient->listPatchSchedules("TestRedisConnectorCache", "TestRedisConnector");
    if (response is PatchSheduleList) {
        PatchSheduleList testValue = {"value": [
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
    io:println("Running DeletePatchSchedule Test");
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

@test:Config {}
function testPutPrivateEndpointConnection() {
    io:println("Running PutPrivateEndpointConnection Test");
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

@test:Config {dependsOn: ["testPutPrivateEndpointConnection"]}
function testgetPrivateEndpointConnection() {
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

@test:Config {dependsOn: ["testPutPrivateEndpointConnection"]}
function testListPrivateEndpointConnection() {
    var response = azureRedisClient->listPrivateEndpointConnection("TestRedisConnectorCache", "TestRedisConnector");
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        test:assertEquals(statusCode?.code, "200", msg = "Error in listing private endpoint connection");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testPutPrivateEndpointConnection"]}
function testDeletePrivateEndpointConnection() {
    var response = azureRedisClient->deletePrivateEndpointConnection("TestRedisConnectorCache", "TestRedisConnector", 
    "TestPrivateEndpoint");
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        test:assertEquals(statusCode?.code, "200", msg = "Error in deleting private endpoint connection");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {}
function testGetPrivateLinkResources() {
    var response = azureRedisClient->getPrivateLinkResources("TestRedisConnectorCache", "TestRedisConnector");
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        // FirewallRuleResponse firewallResponse = <@untainted>response;
        test:assertEquals(statusCode?.code, "200", msg = "Error in getting PrivateLinkResources");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {}
function testDeleteRedisCache() {
    io:println("Running Delete Redis Cache Test");
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
            io:println(getresponse1);
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
    var response = azureRedisClient->createRedisEnterprise("TestRedisEnterpriseCache", "TestRedisConnector", 
    "southeastasia", "EnterpriseFlash_F300", 3);
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        boolean createSuccess = false;
        if (statusCode?.code == "200" || statusCode?.code == "201" || statusCode?.code == "204") {
            createSuccess = true;
        }
        RedisEnterpriseCacheInstance testValue = {};
        test:assertEquals(createSuccess, true, msg = "Error in creating RedisEnterpriseCache");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisEnterprise"]}
function testCreateRedisEnterpriseCacheDatabase() {
    var response = azureRedisClient->createRedisEnterpriseCacheDatabase("TestRedisEnterpriseCache", "TestRedisConnector", 
    "default");
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        boolean createSuccess = false;
        if (statusCode?.code == "200" || statusCode?.code == "201") {
            createSuccess = true;
        }
        test:assertEquals(createSuccess, true, msg = "Error in creating RedisEnterpriseCache");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisEnterprise", "testCreateRedisEnterpriseCacheDatabase"]}
function testGetRedisEnterpriseCacheDatabase() {
    var response = azureRedisClient->getRedisEnterpriseCacheDatabase("TestRedisEnterpriseCache", "TestRedisConnector", 
    "default");
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        boolean getSuccess = false;
        if (statusCode?.code == "200") {
            getSuccess = true;
        }
        test:assertEquals(getSuccess, true, msg = "Error in fetching RedisEnterpriseCache");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisEnterprise", "testCreateRedisEnterpriseCacheDatabase"]}
function testListRedisEnterpriseCacheDatabaseByCluster() {
    var response = azureRedisClient->listRedisEnterpriseCacheDatabaseByCluster("TestRedisEnterpriseCache", 
    "TestRedisConnector");
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        boolean getSuccess = false;
        if (statusCode?.code == "200") {
            getSuccess = true;
        }
        test:assertEquals(getSuccess, true, msg = "Error in fetching RedisEnterpriseCache by cluster");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisEnterprise", "testCreateRedisEnterpriseCacheDatabase"]}
function testListRedisEnterpriseCacheDatabaseKeys() {
    io:println("Running List Redis Enterprise Cache Database Keys Test");
    var response = azureRedisClient->listRedisEnterpriseCacheDatabaseKeys("TestRedisEnterpriseCache", 
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

@test:Config {dependsOn: ["testCreateRedisEnterprise", "testCreateRedisEnterpriseCacheDatabase"]}
function testRegenerateRedisEnterpriseCacheDatabaseKey() {
    io:println("Running Regenerate Redis Enterprise Cache Database Key Test");
    var response = azureRedisClient->regenerateRedisEnterpriseCacheDatabaseKey("TestRedisEnterpriseCache", 
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
    dependsOn: ["testCreateRedisEnterprise","testCreateRedisEnterpriseCacheDatabase"], enable: false
}
function testUpdateRedisEnterpriseCacheDatabase() {
    var response = azureRedisClient->updateRedisEnterpriseCacheDatabase("TestRedisEnterpriseCache", "TestRedisConnector", "default", "Encrypted", "AllKeysLRU", "RediSearch");
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        boolean getSuccess = false;
        if(statusCode?.code == "200" || statusCode?.code == "202"){
            getSuccess = true;
        }
        test:assertEquals(getSuccess, true, msg = "Error in regenerating Redis Enterprise Cache Key"); 
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisEnterprise", "testCreateRedisEnterpriseCacheDatabase"]}
function testDeleteRedisEnterpriseCacheDatabase() {
    var response = azureRedisClient->deleteRedisEnterpriseCacheDatabase("TestRedisEnterpriseCache", "TestRedisConnector", 
    "default");
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        boolean deleteSuccess = false;
        if (statusCode?.code == "200" || statusCode?.code == "201" || statusCode?.code == "204") {
            deleteSuccess = true;
        }
        test:assertEquals(deleteSuccess, true, msg = "Error in deleting RedisEnterpriseCache");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisEnterprise"]}
function testGetRedisEnterprise() {
    io:println("Running Get Redis Enterprise Cache Test");
    var response = azureRedisClient->getRedisEnterprise("TestRedisEnterpriseCache", "TestRedisConnector");
    if (response is RedisEnterpriseCacheInstance) {
        RedisEnterpriseCacheInstance testValue = 
        {
            "location": "Southeast Asia",
            "name": "TestRedisEnterpriseCache",
            "id": "/subscriptions/7241b7fa-c310-4b99-a53e-c5048cf0ec25/resourceGroups/TestRedisConnector/providers/Microsoft.Cache/redisEnterprise/TestRedisEnterpriseCache",
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
        test:assertEquals(response, testValue, msg = "Error in creating RedisEnterpriseCache");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisEnterprise"]}
function testListRedisEnterprise() {
    var response = azureRedisClient->listRedisEnterprise();
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        boolean getSuccess = false;
        if (statusCode?.code == "200") {
            getSuccess = true;
        }
        test:assertEquals(getSuccess, true, msg = "Error in fetching RedisEnterpriseCache");
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisEnterprise"]}
function testListRedisEnterpriseByResourceGroup() {
    var response = azureRedisClient->listRedisEnterpriseByResourceGroup("TestRedisConnector");
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        boolean getSuccess = false;
        if (statusCode?.code == "200") {
            getSuccess = true;
        }
        test:assertEquals(getSuccess, true, msg = "Error in fetching RedisEnterpriseCache");
    } else {
        test:assertFail(response.message());
    }
}

# Update Redis Enterprise Test function(This function not available at the moment of development)
@test:Config {
    dependsOn: ["testCreateRedisEnterprise"], enable: false
}
function testUpdateRedisEnterprise() {
    var response = azureRedisClient->updateRedisEnterprise("TestRedisEnterpriseCache", "TestRedisConnector");
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        boolean getSuccess = false;
        if(statusCode?.code == "200"){
            getSuccess = true;
        }
        test:assertEquals(getSuccess, true, msg = "Error in updating RedisEnterpriseCache"); 
    } else {
        test:assertFail(response.message());
    }
}

@test:Config {dependsOn: ["testCreateRedisEnterprise"]}
function testDeleteRedisEnterprise() {
    var response = azureRedisClient->deleteRedisEnterprise("TestRedisEnterpriseCache", "TestRedisConnector");
    if (response is StatusCode) {
        StatusCode statusCode = <@untainted>response;
        boolean deleteSuccess = false;
        if (statusCode?.code == "200" || statusCode?.code == "202" || statusCode?.code == "204") {
            deleteSuccess = true;
        }
        test:assertEquals(deleteSuccess, true, msg = "Error in deleting RedisEnterpriseCache");
    } else {
        test:assertFail(response.message());
    }
}
