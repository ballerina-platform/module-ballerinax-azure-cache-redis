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

    // list redis caches exists in subscription
    RedisCacheInstance[]|error instances = azureClient->listRedisCacheInstances(<SUBSCRIPTION_ID>);
    if (instances is RedisCacheInstance[]) {
        foreach RedisCacheInstance redisInstance in response {
            io:println(redisInstance.toString());
        }
    } else {
        io:println(instances.message());
    }
}
