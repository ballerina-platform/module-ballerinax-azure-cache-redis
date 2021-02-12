import ballerinax/azure_cache_redis as azure_cache_redis;
import ballerina/io;

public function main() returns error? {
    azure_cache_redis:AzureRedisConfiguration config = {oauth2Config: {
        tokenUrl: "https://login.microsoftonline.com/" + config:getAsString("TENANT_ID") + "/oauth2/v2.0/token",
        clientId: config:getAsString("CLIENT_ID"),
        clientSecret: config:getAsString("CLIENT_SECRET"),
        scopes: ["https://management.azure.com/.default"]
    }};

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
}
