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
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Platform 1.0

import "../Portal"
import "../XForms"
import "../Controls"
import "../Controls/Singletons"
import "../Models"

import "../template/SurveyHelper.js" as Helper


AppPage {
    id: page

    //--------------------------------------------------------------------------

    property bool downloaded: false
    property int updatesCount: 0

    property var hasSurveysPage
    property Component noSurveysPage
    property bool debug: false

    property Settings settings: app.settings

    readonly property string kSettingsGroup: "DownloadSurveys/"
    readonly property string kSettingSortProperty: kSettingsGroup + "sortProperty"
    readonly property string kSettingSortOrder: kSettingsGroup + "sortOrder"

    property color textColor: "#323232"
    property color iconColor: "#505050"
    property real buttonSize: 30 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    backPage: surveysFolder.forms.length > 0 ? hasSurveysPage : noSurveysPage
    title: qsTr("Download Surveys")

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        readSettings();

        if (portal.signedIn) {
            searchModel.update();
        }
    }

    //--------------------------------------------------------------------------

    Component.onDestruction: {
        writeSettings();

        if (downloaded) {
            surveysFolder.update();
        }
    }

    //--------------------------------------------------------------------------

    Connections {
        target: portal

        onSignedInChanged: {
            if (portal.signedIn) {
                searchModel.update();
            }
        }
    }

    //--------------------------------------------------------------------------

    onTitleClicked: {
        listView.positionViewAtBeginning();
    }

    //--------------------------------------------------------------------------

    contentItem: Item {
        Rectangle {
            id: listArea

            anchors.fill: parent

            color: "transparent" //"#40ffffff"
            radius: 10

            Column {
                anchors {
                    fill: parent
                    margins: 10 * AppFramework.displayScaleFactor
                }

                spacing: 10 * AppFramework.displayScaleFactor
                visible: searchModel.count == 0 && !searchRequest.busy

                AppText {
                    width: parent.width
                    color: textColor
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    text: qsTr('<center>There are no surveys shared with <b>%2</b>, username <b>%1</b>.<br><hr>Please visit <a href="http://survey123.esri.com">http://survey123.esri.com</a> to create a survey or see your system administrator.</center>').arg(portal.user.username).arg(portal.user.fullName)
                    textFormat: Text.RichText

                    onLinkActivated: {
                        Qt.openUrlExternally(link);
                    }
                }

                ConfirmButton {
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: qsTr("Refresh")

                    onClicked: {
                        search();
                    }
                }
            }

            ColumnLayout {
                anchors {
                    fill: parent
                    margins: 2 * AppFramework.displayScaleFactor
                }

                visible: portal.signedIn && searchModel.count > 0

                RowLayout {
                    id: toolsLayout

                    Layout.fillWidth: true

                    spacing: 5 * AppFramework.displayScaleFactor

                    StyledImageButton {
                        Layout.preferredHeight: toolsLayout.height
                        Layout.preferredWidth: Layout.preferredHeight

                        checkable: true
                        checked: searchModel.sortProperty === searchModel.kPropertyDate
                        checkedColor: page.headerBarColor

                        source: Icons.icon("clock-%1".arg(searchModel.sortOrder === "desc" ? "up" : "down"))

                        onClicked: {
                            if (checked) {
                                searchModel.toggleSortOrder();
                            } else {
                                searchModel.sortProperty = searchModel.kPropertyDate;
                                searchModel.sortOrder = searchModel.kSortOrderDesc;
                            }
                            filteredGalleryModel.visualModel.sortItems();
                        }
                    }

                    StyledImageButton {
                        Layout.preferredHeight: toolsLayout.height * 0.8
                        Layout.preferredWidth: Layout.preferredHeight

                        checkable: true
                        checked: searchModel.sortProperty === searchModel.kPropertyTitle
                        checkedColor: page.headerBarColor

                        source: Icons.icon("a-z-%1".arg(searchModel.sortOrder === "desc" ? "up" : "down"))

                        onClicked: {
                            if (checked) {
                                searchModel.toggleSortOrder();
                            } else {
                                searchModel.sortProperty = searchModel.kPropertyTitle;
                                searchModel.sortOrder = searchModel.kSortOrderAsc;
                            }
                            filteredGalleryModel.visualModel.sortItems();
                        }
                    }

                    SearchField {
                        id: searchField

                        Layout.fillWidth: true

                        onEditingFinished: {
                            filteredGalleryModel.filterText = text;
                        }

                        busy: searchRequest.busy

                        progressBar {
                            visible: searchRequest.busy && searchRequest.total > 0
                            value: searchRequest.count
                            from: 0
                            to: searchRequest.total
                        }
                    }
                }

                ScrollView {
                    id: scrollView

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ListView {
                        id: listView

                        width: scrollView.availableWidth
                        height: scrollView.availableHeight

                        model: filteredGalleryModel.visualModel
                        spacing: 10 * AppFramework.displayScaleFactor
                        clip: true

                        delegate: surveyDelegateComponent

                        RefreshHeader {
                            refreshing: searchRequest.busy

                            onRefresh: {
                                search();
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: false //portal.signedIn

                    //                    Button {
                    //                        Layout.alignment: Qt.AlignHCenter

                    //                        text: qsTr("Update all %1 surveys").arg(updatesCount)
                    //                        iconSource: "images/cloud-refresh.png"
                    //                        enabled: false //updatesCount > 0

                    //                        onClicked: {
                    //                        }
                    //                    }
                }
            }

        }

        Rectangle {
            anchors.fill: parent

            visible: searchRequest.busy && searchModel.count == 0
            color: page.backgroundColor

            AppText {
                id: searchingText

                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

                text: qsTr("Searching for surveys")
                color: "darkgrey"
                font {
                    pointSize: 18
                }
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            AppBusyIndicator {
                anchors {
                    top: searchingText.bottom
                    horizontalCenter: parent.horizontalCenter
                    margins: 10 * AppFramework.displayScaleFactor
                }

                running: parent.visible
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    function search() {
        searchModel.update();
    }

    SortedListModel {
        id: searchModel

        signal updated()

        readonly property string kPropertyTitle: "title"
        readonly property string kPropertyDate: "modified"

        sortProperty: kPropertyDate
        sortOrder: kSortOrderDesc
        sortCaseSensitivity: Qt.CaseInsensitive

        function update() {
            updatesCount = 0;
            updateLocalPaths();
            searchRequest.start();
        }

        function updateLocalPaths() {
            for (var i = 0; i < searchModel.count; i++) {
                var item = searchModel.get(i);
                updateLocalPath(item);
            }
        }

        function updateLocalPath(item) {
            item.isLocal = surveysFolder.fileExists(item.id);

            if (item.isLocal) {
                item.path = searchModel.findForm(surveysFolder.folder(item.id));
            }
        }

        function findForm(folder) {
            var path;

            var files = folder.fileNames("*", true);
            files.forEach(function(fileName) {
                if (folder.fileInfo(fileName).suffix === "xml") {
                    path = folder.filePath(fileName);
                }
            });

            return path;
        }

        function sortItems() {
            sort();
        }

        onUpdated: {
            filteredGalleryModel.update();
        }
    }

    FilteredListModel {
        id: filteredGalleryModel

        sourceModel: searchModel
    }


    PortalSearch {
        id: searchRequest

        property bool busy: false

        portal: app.portal
        sortField: searchModel.sortProperty
        sortOrder: searchModel.sortOrder
        num: 25

        Component.onCompleted: {

            var query = portal.user.orgId > ""
                    ? '((NOT access:public) OR orgid:%1)'.arg(portal.user.orgId)
                    : 'NOT access:public';

            query += ' AND ((type:Form AND NOT tags:"draft" AND NOT typekeywords:draft) OR (type:"Code Sample" AND typekeywords:XForms AND tags:"xform"))';

            q = query;
        }

        onSuccess: {
            if (response.start === 1) {
                searchModel.clear();
            }

            response.results.forEach(function (result) {
                result.isLocal = surveysFolder.fileExists(result.id);

                if (result.isLocal) {
                    updatesCount++;

                    result.path = searchModel.findForm(surveysFolder.folder(result.id));
                }

                searchModel.append(Helper.removeArrayProperties(result));
            });

            if (response.nextStart > 0) {
                search(response.nextStart);
            } else {
                searchModel.sortItems();
                searchModel.updated();

                searchRequest.busy = false;
            }
        }

        function start() {
            searchRequest.busy = true;
            search();
        }
    }

    //--------------------------------------------------------------------------

    function readSettings() {
        var value = settings.value(kSettingSortProperty, searchModel.kPropertyDate);
        if ([searchModel.kPropertyTitle, searchModel.kPropertyDate].indexOf(value) < 0) {
            value = searchModel.kPropertyDate;
        }
        searchModel.sortProperty = value;

        value = settings.value(kSettingSortOrder, searchModel.kSortOrderDesc);
        if ([searchModel.kSortOrderAsc, searchModel.kSortOrderDesc].indexOf(value) < 0) {
            value = searchModel.kSortOrderDesc;
        }
        searchModel.sortOrder = value;
    }

    //--------------------------------------------------------------------------

    function writeSettings() {
        settings.setValue(kSettingSortProperty, searchModel.sortProperty);
        settings.setValue(kSettingSortOrder, searchModel.sortOrder);
    }

    //--------------------------------------------------------------------------

    DownloadSurvey {
        id: downloadSurvey

        portal: app.portal
        progressPanel: progressPanel
        debug: debug

        onSucceeded: {
            page.downloaded = true;
            //surveysFolder.update();
            searchModel.update();
        }
    }

    //--------------------------------------------------------------------------

    ProgressPanel {
        id: progressPanel

        progressBar.visible: progressBar.value > 0

        onVisibleChanged: {
            Platform.stayAwake = visible;
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: surveyDelegateComponent

        SwipeLayoutDelegate {
            id: surveyDelegate

            property var surveyPath: index >= 0 ? listView.model.get(index).path : ""
            property var localSurvey: index >= 0 ? listView.model.get(index).isLocal : false

            width: ListView.view.width

            Image {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 100 * AppFramework.displayScaleFactor
                Layout.preferredHeight: Layout.preferredWidth * 133/200

                source: portal.restUrl + "/content/items/" + id + "/info/" + thumbnail + "?token=" + portal.token
                fillMode: Image.PreserveAspectFit

                Rectangle {
                    anchors {
                        fill: parent
                        margins: -1
                    }

                    visible: surveyDelegate.localSurvey && surveyDelegate.surveyPath > ""
                    color: "transparent" //surveyDelegate.hovered ? "#10000000" : "transparent"

                    border {
                        width: 1
                        color: "#20000000"
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true

                AppText {
                    Layout.fillWidth: true

                    text: title
                    font {
                        pointSize: 16 * app.textScaleFactor
                    }
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    color: textColor
                }

                //                                Text {
                //                                    width: parent.width
                //                                    text: modelData.snippet > "" ? modelData.snippet : ""
                //                                    font {
                //                                        pointSize: 12
                //                                    }
                //                                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                //                                    color: textColor
                //                                    visible: text > ""
                //                                }

                AppText {
                    Layout.fillWidth: true

                    text: qsTr("Updated %1").arg(new Date(modified).toLocaleString(undefined, Locale.ShortFormat))
                    font {
                        pointSize: 11 * app.textScaleFactor
                    }
                    textFormat: Text.AutoText
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    color: "#7f8183"
                }
            }

            StyledImageButton {
                id: downloadButton

                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: Layout.preferredWidth

                source: Icons.bigIcon(isLocal ? "refresh" : "download")

                color: iconColor
                onClicked: {
                    downloadSurvey.download(listView.model.get(index));
                }
            }

            StyledImage {
                Layout.preferredWidth: 30 * AppFramework.displayScaleFactor
                Layout.preferredHeight: Layout.preferredWidth

                visible: false //delegate.swipe.position === 0

                source: Icons.icon("ellipsis")
                color: app.textColor
            }

            /*
            behindLayout: SwipeBehindLayout {
                SwipeDelegateButton {
                    Layout.fillHeight: true

                    visible: false
                    image.source: Icons.bigIcon("map")

                    onClicked: {
                    }
                }

                SwipeDelegateButton {
                    Layout.fillHeight: true

                    visible: false
                    image {
                        source: Icons.bigIcon("trash")
                        color: "white"
                    }
                    backgroundColor: "tomato"

                    onClicked: {
                        confirmDelete(index);
                    }
                }
            }
            */
        }
    }

    //--------------------------------------------------------------------------
    /*
    Component {
        id: surveyDelegateComponent

        ItemDelegate {
            id: surveyDelegate

            property var surveyPath: index >= 0 ? listView.model.get(index).path : ""
            property var localSurvey: index >= 0 ? listView.model.get(index).isLocal : false

            width: ListView.view.width

            padding: 5 * AppFramework.displayScaleFactor
            rightInset: 3 * AppFramework.displayScaleFactor
            leftInset: rightInset

            hoverEnabled: true

            background: DropShadowRectangle {
                id: backgroundRectangle

                color: surveyDelegate.pressed
                       ? "#90cdf2"
                       : surveyDelegate.hovered
                         ? "#e1f0fb"
                         : "white"

                border {
                    width: 1 * AppFramework.displayScaleFactor
                    color: "#e5e6e7"
                }
                radius: 2 * AppFramework.displayScaleFactor
            }

            onClicked: {
                downloadSurvey.download(filteredGalleryModel.visualModel.get(index));
            }

//            /*
//            MouseArea {
//                id: surveyMouseArea

//                anchors.fill: parent

//                hoverEnabled: true

//                onClicked: {
//                    if (surveyDelegate.localSurvey) {
//                        page.Stack.view.push([
//                                                 {
//                                                     item: surveyPage,
//                                                     replace: true,
//                                                     properties: {
//                                                         surveyPath: surveyDelegate.surveyPath
//                                                     }
//                                                 },

//                                                 {
//                                                     item: surveyView,
//                                                     replace: true,
//                                                     properties: {
//                                                         surveyPath: surveyDelegate.surveyPath,
//                                                         rowid: null
//                                                     }
//                                                 }
//                                             ]);
//                    } else {
//                    //}
//                }
//            }
//

            contentItem: Item {
                implicitWidth: surveyDelegate.availableWidth
                implicitHeight: rowLayout.height + rowLayout.anchors.margins * 2

                RowLayout {
                    id: rowLayout

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 5 * AppFramework.displayScaleFactor
                    }

                    spacing: 8 * AppFramework.displayScaleFactor

                    Image {
                        Layout.preferredWidth: 100 * AppFramework.displayScaleFactor
                        Layout.preferredHeight: 66 * AppFramework.displayScaleFactor
                        source: portal.restUrl + "/content/items/" + id + "/info/" + thumbnail + "?token=" + portal.token
                        fillMode: Image.PreserveAspectFit

                        Rectangle {
                            anchors.fill: parent

                            visible: surveyDelegate.localSurvey && surveyDelegate.surveyPath > ""
                            color: surveyDelegate.hovered ? "#10000000" : "transparent"
                            border {
                                width: 1
                                color: "#20000000"
                            }
                        }
                    }

                    Column {
                        Layout.fillWidth: true

                        spacing: 3 * AppFramework.displayScaleFactor

                        AppText {
                            width: parent.width
                            text: title
                            font {
                                pointSize: 16 * app.textScaleFactor
                            }
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            color: textColor
                        }

                        //                                Text {
                        //                                    width: parent.width
                        //                                    text: modelData.snippet > "" ? modelData.snippet : ""
                        //                                    font {
                        //                                        pointSize: 12
                        //                                    }
                        //                                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        //                                    color: textColor
                        //                                    visible: text > ""
                        //                                }

                        AppText {
                            width: parent.width
                            text: qsTr("Updated %1").arg(new Date(modified).toLocaleString(undefined, Locale.ShortFormat))
                            font {
                                pointSize: 11 * app.textScaleFactor
                            }
                            textFormat: Text.AutoText
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            color: "#7f8183"
                        }
                    }

                    StyledImageButton {
                        Layout.preferredWidth: buttonSize
                        Layout.preferredHeight: Layout.preferredWidth

                        source: Icons.bigIcon(isLocal ? "refresh" : "download")

                        color: iconColor
                        onClicked: {
                            downloadSurvey.download(listView.model.get(index));
                        }
                    }
                }
            }
        }
    }
*/
    //--------------------------------------------------------------------------
}
