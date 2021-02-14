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

# Azure Redis Cache REST API version
const string API_VERSION = "2020-06-01";
# Azure Redis Cache REST API Base url
const string BASE_URL = "https://management.azure.com";
# Constant `EMPTY_STRING`.
const string EMPTY_STRING = "";
# Constant `SPACE`.
const string SPACE = " ";
# Response code constants
const int UNAUTHORIZED = 401;
const int OK = 200;
const int CREATED = 201;
const int ACCEPTED = 202;
const int NO_CONTENT = 204;
# Request path constants
const string RESOURCE_GROUP_PATH = "/resourceGroups/";
const string PROVIDER_PATH = "/providers/Microsoft.Cache/redis/";
const string API_VERSION_PATH = "?api-version=";
const string SUBSCRIPTION_PATH = "/subscriptions/";
