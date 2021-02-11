import ballerinax/azure-cache-redis as azure-cache-redis;

azure-cache-redis:AzureRedisConfiguration config = {oauth2Config: {
        tokenUrl: "https://login.microsoftonline.com/" + config:getAsString("TENANT_ID") + "/oauth2/v2.0/token",
        clientId: config:getAsString("CLIENT_ID"),
        clientSecret: config:getAsString("CLIENT_SECRET"),
        scopes: ["https://management.azure.com/.default"]
    }};

public function main() returns error? {
    azure-cache-redis:Client azureClient = new (config);

    CreateCacheProperty properties = {
        "sku": {
            "name": "Premium",
            "family": "P",
            "capacity": 1
        },
        "enableNonSslPort": true,
        "shardCount": 2,
        "redisConfiguration": {"maxmemory-policy": "allkeys-lru"},
        "minimumTlsVersion " : "1.2"
        };

    azure-cache-redis:RedisCacheInstance|error instance = azureClient->createRedisCache("TestCache", "TestResourceGroup", 
    "southeast asia", properties);

    if (instance is RedisCacheInstance) {
        json state = instance.properties.provisioningState;
        while (state != "Succeeded") {
            var getresponse = azureRedisClient->getRedisCache("TestCache", "TestResourceGroup");
            if (getresponse is json) {
                state = getresponse.properties.provisioningState;
            }
        }
        io:println("Deployed Success");
    } else {
        io:println(instance.message());
    } 

    //Getting host name and port
    azure-cache-redis:RedisCacheInstance|error instance = azureClient->getRedisCache("TestCache", "TestResourceGroup");

    if (instance is RedisCacheInstance) {
        json hostName = instance.properties.hostName;
        json port = instance.properties.port;
        //hostName is the host name used to connect to redis like localhost and port is used as port number(default 6379)
        io:println(hostName);
    } else {
        io:println(instance.message());
    } 

    //Getting Access keys
    azure-cache-redis:RedisCacheInstance|error keys = azureRedisClient->listKeys("TestRedisConnectorCache", "TestRedisConnector");
    if (keys is AccessKey) {
        json primaryKey = keys.primaryKey;
        json secondaryKey = keys.secondaryKey;
        // primaryKey is used as password during making connection using redis clients to handle cache
        io:println(primaryKey);
    } else {
        io:println(keys.message());
    }

    // list redis caches exists in resource group
    azure-cache-redis:RedisCacheInstance|error instances = azureClient->listByResourceGroup("TestRedisConnector");

    if (instances is RedisCacheInstance[]) {
        foreach RedisCacheInstance redisInstance in response {
            io:println(redisInstance.toString());
        }
    } else {
        io:println(instances.message());
    }

    // creating fire wall rule
    azure-cache-redis:FireWallRule|error rule = azureClient->createFirewallRule("TestRedisConnectorCache", "TestRedisConnector", 
    "TestFilewallRule", "192.168.1.1", "192.168.1.4");

    if (rule is FireWallRule) {
        io:println("FireWall rule Created");
    } else {
        io:println(instances.message());
    } 
}
