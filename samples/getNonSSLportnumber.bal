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

    //Getting non SSL port number
    int|error portNumber = azureClient->getNonSSLPortNumber(<SUBSCRIPTION_ID>, "TestCache", "TestResourceGroup");
    if (response is int) {
        //Only can be used if Non-SSL port enabled in cache instance(default 6379)
        io:println(response);
    } else {
        io:println(response.message());
    } 
}
