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

import ArcGIS.AppFramework 1.0

import "../XForms"
import "../template/SurveyHelper.js" as Helper
import "../Models"

SortedListModel {
    id: surveysModel

    property bool enabled: true

    property bool newSurvey: false
    property string newKey: "*NEW*"
    property string newName: qsTr("New Survey")
    property string newThumbnail: "images/new-thumbnail.png"

    property string customKey
    property string customName
    property string customThumbnail

    property int skipCount: 0

    property XFormsFolder formsFolder

    property var uniqueTags: []

    readonly property string kTagSeparator: "^"

    //--------------------------------------------------------------------------

    signal updated();

    //--------------------------------------------------------------------------

    readonly property string kPropertyTitle: "title"
    readonly property string kPropertyModified: "modified"

    //--------------------------------------------------------------------------

    sortProperty: kPropertyTitle
    sortOrder: "asc"
    sortCaseSensitivity: Qt.CaseInsensitive

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        update();
    }

    //--------------------------------------------------------------------------

    readonly property Connections _connections: Connections {
        target: formsFolder

        onFormsChanged: {
            surveysModel.update();
        }
    }

    //--------------------------------------------------------------------------

    readonly property LoggingCategory logCategory: LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(surveysModel, true)
    }

    //--------------------------------------------------------------------------

    function update() {
        console.log("Updating surveys model");

        clear();
        uniqueTags = [];
        skipCount = 0;

        if (!enabled) {
            return;
        }

        if (newSurvey) {
            append({
                       survey: newKey,
                       name: newName,
                       title: newName,
                       description: "",
                       path: "",
                       thumbnail: newThumbnail,
                       modified: 0,
                       owner: ""
                   });

            skipCount++;
        }

        if (customKey > "") {
            append({
                       title: "",
                       description: "",
                       survey: customKey,
                       name: customName,
                       path: "",
                       thumbnail: customThumbnail,
                       modified: 0,
                       owner: ""
                   });
            skipCount++;
        }

        formsFolder.forms.forEach(function (survey) {

            var fileInfo = formsFolder.fileInfo(survey);
            var name = fileInfo.baseName;
            var itemInfo = fileInfo.folder.readJsonFile(name + ".itemInfo");

            var thumbnail = Helper.findThumbnail(fileInfo.folder, name, "images/form-thumbnail.png", itemInfo.thumbnail);
            var upgradeRequired = !fileInfo.folder.fileExists("forminfo.json");

            var title = itemInfo.title > "" ? itemInfo.title : name;
            var published = itemInfo.id > "";
            var description = itemInfo.description > "" ? itemInfo.description : "";
            var itemId = itemInfo.id > "" ? itemInfo.id : "";
            var owner = itemInfo.owner > "" ? itemInfo.owner : "";
            var tags = Array.isArray(itemInfo.tags) ? itemInfo.tags : []

            var surveyItem = {
                itemId: itemId,
                survey: survey,
                title: title,
                description: description,
                name: name,
                path: fileInfo.filePath,
                folderPath: fileInfo.folder.path,
                folderUrl: fileInfo.folder.url,
                thumbnail: thumbnail,
                upgradeRequired: upgradeRequired,
                published: published,
                modified: fileInfo.lastModified.valueOf(),
                owner: owner,
                tags: tags.join(kTagSeparator).toUpperCase()
            }

            append(surveyItem);

            addTags(uniqueTags, itemInfo.tags);

            //console.log("surveyItem:", JSON.stringify(surveyItem, undefined, 2));
            //console.log("surveyItem.modified:", surveyItem.modified);
        });

        sortItems();

        uniqueTags.sort(function (a, b) {
            return a.toLowerCase().localeCompare(b.toLowerCase());
        });
        surveysModel.uniqueTags = uniqueTags;

        console.log("Updated surveys model:", count, "uniqueTags:", JSON.stringify(uniqueTags, undefined, 2));

        updated();
    }

    //--------------------------------------------------------------------------

    function sortItems() {
        //console.log("Sort:", count, "skip:", skipCount, "sortProperty:", sortProperty, "sortOrder:", sortOrder, "sortCaseSensitivity:", sortCaseSensitivity);
        sort(skipCount);
    }

    //--------------------------------------------------------------------------

    function addTags(uniqueTags, tags) {
        if (!Array.isArray(tags)) {
            return;
        }

        for (const tag of tags) {
            if (uniqueTags.findIndex(uniqueTag => tag.toUpperCase() === uniqueTag.toUpperCase()) < 0) {
                uniqueTags.push(tag);
            }
        }
    }

    //--------------------------------------------------------------------------
}
