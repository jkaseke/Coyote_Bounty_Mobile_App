/* Copyright 2019 Esri
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

import QtQml 2.12
import QtQuick 2.12

import Esri.ArcGISRuntime 100.5

import ArcGIS.AppFramework 1.0

import "../Portal" as AppPortal

Item {
    id: runtimeAuthentication

    //--------------------------------------------------------------------------

    property AppPortal.Portal appPortal: app.portal
    property bool reuseCredential: false

    property bool debug: false
    
    //--------------------------------------------------------------------------

    signal licenseChanged(var licenseInfo)

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        console.log(logCategory, "enabled:", enabled);
        AuthenticationManager.credentialCacheEnabled = false;
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(runtimeAuthentication, true)
    }

    //--------------------------------------------------------------------------

    Credential {
        id: userCredential

        //authenticationType: Enums.AuthenticationTypeToken

        oAuthClientInfo: OAuthClientInfo {
            oAuthMode: Enums.OAuthModeUser
            clientId: appPortal.clientId
        }

        oAuthRefreshToken: appPortal.refreshToken

        referer: appPortal.portalUrl

        //sslRequired: appPortal.sll

        token: appPortal.token
        tokenServiceUrl: appPortal.tokenServicesUrl
        tokenExpiry: appPortal.expires

        /*

        authenticatingHost : url
        oAuthAuthorizationCode : string
        password : string
        pkcs12Info : Pkcs12Info
        username : string
                      */
    }

    //--------------------------------------------------------------------------

    OAuthClientInfo {
        id: clientInfo

        oAuthMode: Enums.OAuthModeUser
        clientId: appPortal.clientId
    }

    //--------------------------------------------------------------------------

    Connections {
        target: AuthenticationManager
        enabled: runtimeAuthentication.enabled

        onAuthenticationChallenge: {
            if (debug) {
                console.log(logCategory, "onAuthenticationChallenge -")
                console.log(logCategory, " - authenticatingHost:", challenge.authenticatingHost );
                console.log(logCategory, " - authenticationChallengeType:", challenge.authenticationChallengeType);
                console.log(logCategory, " - authorizationUrl:", challenge.authorizationUrl);
                console.log(logCategory, " - failureCount:", challenge.failureCount);
                console.log(logCategory, " - requestUrl:", challenge.requestUrl);
            }

            var credential;

            if (reuseCredential) {
                if (debug) {
                    console.log(logCategory, "Reusing credential");
                }

                credential = userCredential;
            } else {
                credential = createCredentialObject();
            }

            if (credential) {
                challenge.continueWithCredential(credential);
            }
        }
    }

    //--------------------------------------------------------------------------

    function createCredentialObject() {
        if (!appPortal.signedIn) {
            console.log(logCategory, arguments.callee.name, "Not signed in");
            return;
        }

        if (debug) {
            console.log(logCategory, arguments.callee.name, "username:", appPortal.user.username);
        }

        var credential = ArcGISRuntimeEnvironment.createObject("Credential",
                                                               {
                                                                   oAuthClientInfo: clientInfo,
                                                                   oAuthRefreshToken: appPortal.refreshToken,
                                                                   referer: appPortal.portalUrl,
                                                                   token: appPortal.token,
                                                                   tokenServiceUrl: appPortal.tokenServicesUrl,
                                                                   tokenExpiry: appPortal.expires,
                                                               });

        return credential;
    }

    //--------------------------------------------------------------------------

    Connections {
        target: appPortal

        onSignedInChanged: {
            if (appPortal.signedIn) {
                licenseUser();
            }
        }
    }

    //--------------------------------------------------------------------------

    function licenseUser() {
        var credential = createCredentialObject();
        var portal = ArcGISRuntimeEnvironment.createObject("Portal",
                                                           {
                                                               url: appPortal.portalUrl,
                                                               credential: credential
                                                           });

        function setRuntimeLicence() {
            if (debug) {
                console.log(logCategory, arguments.callee.name, "portal loadStatus:", portal.loadStatus);
            }

            if (portal.loadStatus === Enums.LoadStatusLoaded) {
                var info = portal.portalInfo;
                var licenseInfo = info.licenseInfo;

//                if (debug) {
//                    console.log(logCategory, arguments.callee.name, "portalInfo:", JSON.stringify(portal.portalInfo.json, undefined, 2));
//                }

                if (licenseInfo) {
                    console.log(logCategory, arguments.callee.name, "licenseInfo:", JSON.stringify(licenseInfo.json, undefined, 2));

                    var result = ArcGISRuntimeEnvironment.setLicense(licenseInfo);

                    console.log(logCategory, arguments.callee.name, "licenceStatus:", result.licenseStatus);

                    licenseChanged(result);
                } else {
                    if (debug) {
                        console.error(logCategory, arguments.callee.name, "No licenseInfo");
                    }
                }
            }
        }

        portal.loadStatusChanged.connect(setRuntimeLicence);

        if (debug) {
            console.log(logCategory, arguments.callee.name, "Loading portal url:", portal.url);
        }

        portal.load();
    }

    //--------------------------------------------------------------------------
}
