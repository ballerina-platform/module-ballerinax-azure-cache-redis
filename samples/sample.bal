import ballerinax/azure_cache_redis as azure_cache_redis;
import ballerina/io;

azure_cache_redis:AzureRedisConfiguration config = {oauth2Config: {
        tokenUrl: "https://login.microsoftonline.com/" + config:getAsString("TENANT_ID") + "/oauth2/v2.0/token",
        clientId: config:getAsString("CLIENT_ID"),
        clientSecret: config:getAsString("CLIENT_SECRET"),
        scopes: ["https://management.azure.com/.default"]
    }};

public function main() returns error? {
    azure_cache_redis:Client azureClient = new (config);

    CreateCacheProperty properties = {
        "sku": {
            "name": "Basic",
            "family": "C",
            "capacity": 1
        },
        "enableNonSslPort": true,
        "redisConfiguration": {"maxmemory-policy": "allkeys-lru"},
        "minimumTlsVersion " : "1.2"
        };

    RedisCacheInstance|error instance = azureClient->createRedisCache(<SUBSCRIPTION_ID>, "TestCache", "TestResourceGroup", 
    "southeast asia", properties);

    if (instance is RedisCacheInstance) {
        json state = instance.properties.provisioningState;
        while (state != "Succeeded") {
            var getresponse = azureRedisClient->getRedisCache("TestCache", "TestResourceGroup");
            if (getresponse is json) {
                state = getresponse.properties.provisioningState;
            }
        }
        io:println("Deployment Success");
    } else {
        io:println(instance.message());
    } 

    //Getting host name
    string|error response = azureClient->getHostName(<SUBSCRIPTION_ID>, "TestCache", "TestResourceGroup");
    if (response is string) {
        //hostName is the host name used to connect to redis like localhost
        io:println(response);
    } else {
        io:println(response.message());
    } 

    //Getting SSL port number
    int|error response = azureClient->getSSLPortNumber(<SUBSCRIPTION_ID>, "TestCache", "TestResourceGroup");
    if (response is int) {
        //portNumber is the number used as port to connect(default 6380)
        io:println(response);
    } else {
        io:println(response.message());
    } 

    //Getting non SSL port number
    int|error portNumber = azureClient->getNonSSLPortNumber(<SUBSCRIPTION_ID>, "TestCache", "TestResourceGroup");
    if (response is int) {
        //Only can be used if Non-SSL port enabled in cache instance(default 6379)
        io:println(response);
    } else {
        io:println(response.message());
    } 

    //Getting Access keys
    AccessKeys|error response = azureRedisClient->listKeys(<SUBSCRIPTION_ID>, "TestRedisConnectorCache", "TestRedisConnector");
    if (response is AccessKey) {
        json primaryKey = response.primaryKey;
        json secondaryKey = response.secondaryKey;
        // primaryKey is used as password during making connection using redis clients to handle cache
        io:println(primaryKey);
    } else {
        io:println(response.message());
    }

    // list redis caches exists in resource group
    RedisCacheInstance[]|error instances = azureClient->listRedisCacheInstances(<SUBSCRIPTION_ID>, "TestRedisConnector");
    if (instances is RedisCacheInstance[]) {
        foreach RedisCacheInstance redisInstance in response {
            io:println(redisInstance.toString());
        }
    } else {
        io:println(instances.message());
    }

    // list redis caches exists in subscription
    RedisCacheInstance[]|error instances = azureClient->listRedisCacheInstances(<SUBSCRIPTION_ID>);

    if (instances is RedisCacheInstance[]) {
        foreach RedisCacheInstance redisInstance in response {
            io:println(redisInstance.toString());
        }
    } else {
        io:println(instances.message());
    }

    // creating fire wall rule
    FireWallRule|error response = azureClient->createFirewallRule(<SUBSCRIPTION_ID>, "TestRedisConnectorCache", "TestRedisConnector", 
    "TestFilewallRule", "192.168.1.1", "192.168.1.4");
    if (response is FireWallRule) {
        io:println("FireWall rule Created");
    } else {
        io:println(response.message());
    } 

    // creating a patch schedule
    PatchScheduleProperty properties = {scheduleEntries: [{
        dayOfWeek: "Monday",
        startHourUtc: 12,
        maintenanceWindow: "PT5H"
    }, {
        dayOfWeek: "Tuesday",
        startHourUtc: 12
    }]};
    PatchSchedule|error response = azureRedisManagementClient->createPatchSchedule(<SUBSCRIPTION_ID>, "TestCache", "TestResourceGroup", "TestPatchSchedule", properties);
    if (response is PatchSchedule) {
        log:print("Patch Schedule created");
    } else {
        log:print(response.message());
    }
}
