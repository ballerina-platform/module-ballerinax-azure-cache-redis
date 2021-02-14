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

//Getting Access keys
    AccessKeys|error response = azureRedisClient->listKeys(<SUBSCRIPTION_ID>, "TestCache", "TestResourceGroup");
    if (response is AccessKey) {
        json primaryKey = response.primaryKey;
        json secondaryKey = response.secondaryKey;
        // primaryKey is used as password during making connection using redis clients to handle cache
        io:println(primaryKey);
    } else {
        io:println(response.message());
    }
}
