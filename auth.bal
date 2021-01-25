import ballerina/http;

function generateToken(string clientId, string clientSecret, string tenantId) returns @tainted string|error{
    http:Client clientEndpoint = new ("https://login.microsoftonline.com/"+tenantId);
    http:Request request = new;
    string body ="grant_type=client_credentials&client_id="+clientId+"&client_secret="+clientSecret+"&scope=https://management.azure.com/.default";
    request.setTextPayload(<@untainted> body);
    request.setHeader("Content-Type", "application/x-www-form-urlencoded");
    request.setHeader("Content-Length", body.toString());
    var response = clientEndpoint->post("/oauth2/v2.0/token", request);
        if (response is error) {
            return createError("Response Error");
        }
        else {
            http:Response resp = <http:Response> response;
            var respBody = resp.getJsonPayload();
                if (respBody is error ) {
                    return createError("Not the expected");
                } else {
                    return <string>respBody.access_token;                
                }
        }
}
