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

    // creating fire wall rule
    FireWallRule|error response = azureClient->createFirewallRule(<SUBSCRIPTION_ID>, "TestRedisConnectorCache", "TestRedisConnector", 
    "TestFilewallRule", "192.168.1.1", "192.168.1.4");
    if (response is FireWallRule) {
        io:println("FireWall rule Created");
    } else {
        io:println(response.message());
    } 
}
