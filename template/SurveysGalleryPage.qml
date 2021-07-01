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

import QtQuick 2.12
import QtQuick.Controls 1.4
import QtQuick.Controls 2.5 as QC2
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.2

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Networking 1.0

import "../Controls/Singletons"
import "SurveyHelper.js" as Helper

AppPage {
    id: page

    signal selected(string surveyPath, bool pressAndHold, int indicator, var parameters)

    Component.onCompleted: {
        app.openParameters = JSON.parse('{"itemID":"4823d53c70934a19ad5b961d8d5d3e8c"}');
    }

    backButton {
        visible: mainStackView.depth > 1
    }

    actionButton {
        //        visible: Networking.isOnline
        //        source: "images/cloud-download.png"

        //        onClicked: {
        //            showDownloadPage();
        //        }

        visible: true

        menu: Menu {
            MenuItem {
                text: qsTr("Download Surveys")
                iconSource: Icons.icon("download")
                visible: false
                enabled: visible
                onTriggered: {
                    showSignInOrDownloadPage();
                }
            }

            MenuItem {
                text: qsTr("Settings")
                iconSource: Icons.icon("gear")

                onTriggered: {
                    page.Stack.view.push(settingsPage);
                }
            }

//            MenuItem {
//                property bool noColorOverlay: portal.signedIn

//                visible: portal.signedIn || Networking.isOnline
//                enabled: visible

//                text: portal.signedIn ? qsTr("Sign out %1").arg(portal.user ? portal.user.fullName : "") : qsTr("Sign in")
//                iconSource: portal.signedIn ? portal.userThumbnailUrl : Icons.icon("sign-in")

//                onTriggered: {
//                    if (portal.signedIn) {
//                        portal.signOut();
//                    } else {
//                        portal.signIn(undefined, true);
//                    }
//                }
//            }

            MenuItem {
                text: qsTr("About")
                iconSource: Icons.icon("information")

                onTriggered: {
                    page.Stack.view.push(aboutPage);
                }
            }
        }
    }

    title: qsTr("Coyote Bounty Reporter")

    contentItem: Item {
        Layout.fillHeight: true

        ColumnLayout {
            anchors.fill: parent

            QC2.ScrollView {
                id: scrollView

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 100 * AppFramework.displayScaleFactor

                visible: galleryView.model.count
                clip: true

                SurveysGalleryView {
                    id: galleryView

                    width: scrollView.availableWidth
                    model: surveysModel

                    delegate: galleryDelegateComponent

                    onClicked: {
                        if (currentSurvey) {
                            selected(app.surveysFolder.filePath(currentSurvey), false, -1, null);
                        }
                    }

                    onPressAndHold: {
                        if (currentSurvey) {
                            selected(app.surveysFolder.filePath(currentSurvey), true, -1, null);
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true

                visible: !galleryView.model.count && !app.openParameters
                spacing: 20 * AppFramework.displayScaleFactor

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                Text {
                    Layout.fillWidth: true

                    font {
                        pointSize: 20
                        family: app.fontFamily
                    }
                    color: app.textColor
                    text: qsTr("No surveys on device")
                    textFormat: Text.RichText
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                }

                Text {
                    Layout.fillWidth: true

                    visible: !Networking.isOnline && !app.openParameters
                    font {
                        pointSize: 20
                        family: app.fontFamily
                    }
                    color: app.textColor
                    text: qsTr("Please connect to a network to download surveys")
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                }

                ConfirmButton {
                    Layout.alignment: Qt.AlignHCenter

                    visible: Networking.isOnline && !app.openParameters
                    text: qsTr("Get Surveys")

                    onClicked: {
                        showSignInOrDownloadPage();
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }

            OpenParametersPanel {
                id: openParametersPanel

                Layout.fillWidth: true
                Layout.margins: 5 * AppFramework.displayScaleFactor

                progressPanel: progressPanel

                onDownloaded: {
                    surveysFolder.update();
                    checkOpenParameters();
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    SurveysModel {
        id: surveysModel

        formsFolder: surveysFolder

        onUpdated: {
            galleryView.forceLayout();
            checkOpenParameters();
        }
    }

    //--------------------------------------------------------------------------

    function showSignInOrDownloadPage() {
        portal.signInAction(qsTr("Please sign in to download surveys"), showDownloadPage);
    }

    function showDownloadPage() {
        page.Stack.view.push({
                                 item: downloadSurveysPage
                             });
    }

    //--------------------------------------------------------------------------

    Connections {
        target: app

        onOpenParametersChanged: {
            checkOpenParameters();
        }
    }

    function checkOpenParameters() {
        console.log("Checking openParameters", JSON.stringify(app.openParameters, undefined, 2));

        if (app.openParameters) {
            var parameters = app.openParameters;
            var surveyItem = findSurveyItem(parameters);
            if (surveyItem) {
                app.openParameters = null;
                parameters.itemId = surveyItem.itemId;
                selected(app.surveysFolder.filePath(surveyItem.survey), true, -1, parameters);
            } else {
                openParametersPanel.enabled = true;
            }
        }
    }

    function findSurveyItem(parameters) {
        var itemId = Helper.getPropertyValue(parameters, "itemId");
        if (!itemId) {
            return undefined;
        }

        console.log("Searching for survey itemId:", itemId);

        for (var i = 0; i < galleryView.model.count; i++) {
            var surveyItem = galleryView.getSurveyItem(i);
            if (surveyItem.itemId === itemId) {
                return surveyItem;
            }
        }

        return null;
    }

    //--------------------------------------------------------------------------

    Component {
        id: aboutPage

        AboutPage {
        }
    }

    Component {
        id: settingsPage

        SettingsPage {
        }
    }

    Component {
        id: galleryDelegateComponent

        SurveysGalleryDelegate {
            id: galleryDelegate
        }
    }

    //--------------------------------------------------------------------------

    ProgressPanel {
        id: progressPanel

        progressBar.visible: progressBar.value > 0
    }

    //--------------------------------------------------------------------------
}
