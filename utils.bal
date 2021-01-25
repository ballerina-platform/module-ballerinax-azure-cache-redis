isolated function convertToSKU(json|error jsonToSKUValue) returns SKU {
    SKU sku = {};
    if (jsonToSKUValue is json) {
        sku.name = jsonToSKUValue.name != () ? jsonToSKUValue.name.toString() : EMPTY_STRING;
        sku.family = jsonToSKUValue.family != () ? jsonToSKUValue.family.toString() : EMPTY_STRING;
        sku.capacity = jsonToSKUValue.capacity != () ? convertToInt(jsonToSKUValue.capacity) : 0;
        return sku;
    }
    return sku;
}

isolated function jsonToStatusCode(string statusCodeResponse) returns StatusCode {
    StatusCode statusCode = {};
    statusCode.code = statusCodeResponse != "" ? statusCodeResponse : EMPTY_STRING;
    return statusCode;
}

isolated function jsonToFirewallRule(json payloadResponse) returns FirewallRuleResponse {
    FirewallRuleResponse firewallRuleResponse = {};
    firewallRuleResponse.id = payloadResponse.id != () ? payloadResponse.id.toString() : EMPTY_STRING;
    if (payloadResponse.properties is error) {
        return firewallRuleResponse;
    } else {
        firewallRuleResponse.properties = jsonToFirewallRulePropertyArray(<json[]>payloadResponse.properties);
    }
    return firewallRuleResponse;
}

isolated function createError(string message, error? err = ()) returns error {
    error redisError;
    if (err is error) {
        redisError = AzureRedisError(message, err);
    } else {
        redisError = AzureRedisError(message);
    }
    return redisError;
}

isolated function jsonArrayToStringArray(json[] jsonArray) returns string[] {
    string[] stringArray = [];
    int counter = 0;
    foreach json jsonValue in jsonArray {
        stringArray[counter] = jsonValue.toString();
        counter = counter + 1;
    }
    return stringArray;
}

isolated function jsonToFirewallRulePropertyArray(json payloadResponse) returns FirewallRuleProperty {
    FirewallRuleProperty firewallRuleProperty = {};
    firewallRuleProperty.startIP = payloadResponse.startIP != () ? payloadResponse.startIP.toString() : EMPTY_STRING;
    firewallRuleProperty.endIP = payloadResponse.endIP != () ? payloadResponse.endIP.toString() : EMPTY_STRING;
    return firewallRuleProperty;
}

isolated function convertToInt(json|error jsonToIntValue) returns int {
    if (jsonToIntValue is json) {
        int|error intValue = 'int:fromString(jsonToIntValue.toString());
        if (intValue is int) {
            return intValue;
        }
    }
    return 0;
}

isolated function convertToBoolean(json|error jsonToBooleanValue) returns boolean {
    if (jsonToBooleanValue is json) {
        boolean|error booleanValue = 'boolean:fromString(jsonToBooleanValue.toString());
        if (booleanValue is boolean) {
            return booleanValue;
        }
    }
    return false;
}
