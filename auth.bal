
// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;

function generateToken(string clientId, string clientSecret, string tenantId) returns @tainted string|error {
    http:Client clientEndpoint = new ("https://login.microsoftonline.com/" + tenantId);
    http:Request request = new;
    string body = 
    "grant_type=client_credentials&client_id=" + clientId + "&client_secret=" + clientSecret + "&scope=https://management.azure.com/.default";
    request.setTextPayload(<@untainted>body);
    request.setHeader("Content-Type", "application/x-www-form-urlencoded");
    request.setHeader("Content-Length", body.toString());
    var response = clientEndpoint->post("/oauth2/v2.0/token", request);
    if (response is error) {
        return createError("Response Error");
    } else {
        http:Response resp = <http:Response>response;
        var respBody = resp.getJsonPayload();
        if (respBody is error) {
            return createError("Not the expected");
        } else {
            return <string>respBody.access_token;
        }
    }
}
