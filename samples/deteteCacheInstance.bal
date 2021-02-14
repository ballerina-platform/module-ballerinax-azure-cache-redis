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

    boolean|error response = azureRedisManagementClient->deleteRedisCache(SUBSCRIPTION_ID>, "TestCache", "TestResourceGroup");
    if (response is boolean) {
        var getresponse = azureRedisManagementClient->getRedisCache(SUBSCRIPTION_ID>, "TestCache", "TestResourceGroup");
        json state = ();
        if (getresponse is RedisCacheInstance) {
            state = getresponse.properties.provisioningState;
        }
        while (state == "Deleting") {
            var getresponse = azureRedisManagementClient->getRedisCacheSUBSCRIPTION_ID>, "TestCache", "TestResourceGroup");
            if (getresponse is RedisCacheInstance) {
                state = getresponse.properties.provisioningState;
            }
            else {
            state = "Deleted";
            }
        }
        log:print("Azure cache instance deleted");
    } else {
        log:print(response.message());
    }
}
