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
