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
import QtQuick.Layouts 1.3

import ArcGIS.AppFramework 1.0

import "XForm.js" as XFormJS
import "XFormSingletons"
import "../Controls"

Column {
    id: selectControl

    property var formElement
    property XFormBinding binding
    property XFormData formData

    readonly property var bindElement: binding.element

    property var groupLabel
    readonly property string imageMapSource: mediaValue(groupLabel, "image", language)

    property var label
    property var items
    property var constraint

    property bool relevant: parent.relevant
    readonly property bool editable: parent.editable

    property alias columns: selectPanel.columns
    property alias controlsGrid: selectPanel.controlsGrid
    property string valuesLabel
    property var currentValues
    readonly property bool isReadOnly: !editable || binding.isReadOnly

    property string appearance

    property var calculatedValue

    readonly property bool minimal: Appearance.contains(appearance, Appearance.kMinimal)
    readonly property real padding: 4 * AppFramework.displayScaleFactor
    readonly property bool isImageMap: Appearance.contains(appearance, Appearance.kImageMap)
    readonly property bool showControls: !isImageMap
    property bool showImageMapLabel: debug

    property alias checkControls: selectPanel.controls
    property alias selectField: selectFieldLoader.item

    property string valueSeparator: ","

    property bool debug: false

    property bool ensureVisibleOnHeightChange

    //--------------------------------------------------------------------------

    signal valueModified(var control)

    //--------------------------------------------------------------------------

    spacing: 0

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        constraint = formData.createConstraint(this, bindElement);

        addControls();
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(selectControl, true)
    }

    //--------------------------------------------------------------------------
    // Clear values when not relevant

    onRelevantChanged: {
        if (formData.isInitializing(binding)) {
            return;
        }

        if (relevant) {
            setValue(binding.defaultValue);
            formData.triggerCalculate(bindElement);
        } else {
            setValue(undefined, 3);
        }
    }

    //--------------------------------------------------------------------------

    onHeightChanged: {
        if (ensureVisibleOnHeightChange && selectField && selectPanel.visible) {
            ensureVisibleOnHeightChange = false;
            ensureVisible();
        }
    }

    //--------------------------------------------------------------------------

    function ensureVisible() {
        function _ensureVisible() {
            xform.ensureItemVisible(selectControl);
        }

        Qt.callLater(_ensureVisible);
    }

    //--------------------------------------------------------------------------

    Loader {
        anchors {
            left: parent.left
            right: parent.right
        }

        sourceComponent: imageMapComponent
        active: isImageMap
    }

    Loader {
        id: selectFieldLoader

        anchors {
            left: parent.left
            right: parent.right
        }

        sourceComponent: selectFieldComponent
        active: minimal
        enabled: !isReadOnly
    }

    Component {
        id: selectFieldComponent

        XFormSelectField {
            visible: minimal
            text: valuesLabel
        }
    }

    XFormSelectPanel {
        id: selectPanel

        anchors {
            left: parent.left
            right: parent.right
            leftMargin: minimal ? padding * 3 : 0
        }

        enabled: !isReadOnly
        visible: (!minimal || (selectField && selectField.dropdownVisible)) && showControls
        padding: selectControl.padding
        radius : minimal ? selectField.radius : 0
        color: minimal ? selectField.color : "transparent"
        border {
            width: minimal ? selectField.border.width : 0
            color: minimal ? selectField.border.color : "transparent"
        }

        onVisibleChanged: {
            if (visible) {
                ensureVisibleOnHeightChange = true;
            }
        }
    }

    Component {
        id: checkControl

        XFormCheckControl {
            checkBox {
                onCheckedChanged: {
                    checkValue(checkBox.checked, value);
                }

                onVisualFocusChanged: {
                    if (checkBox.visualFocus && !minimal) {
                        xform.ensureItemVisible(checkBox);
                    }
                }
            }

            onClicked: {
                valueModified(selectControl);
            }
        }
    }

    Connections {
        target: xform

        onLanguageChanged: {
            if (selectControl.minimal) {
                var values = formData.value(selectControl.bindElement);
                selectControl.valuesLabel = selectControl.createLabel(values);
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: imageMapComponent

        ColumnLayout {
            XFormText {
                Layout.fillWidth: true

                visible: showImageMapLabel
                text: valuesLabel
                horizontalAlignment: Text.AlignHCenter
                color: xform.style.labelColor
                font {
                    pointSize: xform.style.valuePointSize
                }
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            ImageMap {
                id: imageMap

                Layout.fillWidth: true
                Layout.preferredHeight: xform.height / 2

                property bool selecting
                property bool initializing: true

                source: imageMapSource
                multipleSelection: true
                onSelectedIdsChanged: {
                    if (initializing) {
                        return;
                    }

                    selecting = true;
                    setValue(selectedIds, 1);
                    selecting = false;
                }

                Component.onCompleted: {
                    imageMap.select(currentValues);
                    initializing = false;
                }

                Connections {
                    target: selectControl

                    onCurrentValuesChanged: {
                        if (imageMap.selecting) {
                            return;
                        }

                        imageMap.select(currentValues);
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    function addControls() {
        if (!Array.isArray(items)) {
            return;
        }

        for (var i = 0; i < items.length; i++) {
            var item = items[i];

            checkControl.createObject(controlsGrid,
                                      {
                                          width: controlsGrid.columnWidth,
                                          bindElement: bindElement,
                                          formData: formData,
                                          label: item.label,
                                          value: item.value,
                                          appearance: appearance
                                      });
        }
    }

    //--------------------------------------------------------------------------

    function setValue(value, reason) {
        var values = valueToArray(value);

        if (debug) {
            console.log(logCategory, arguments.callee.name, "reason:", reason, "#controls:", checkControls.length, "value:", JSON.stringify(value), "values:", JSON.stringify(values));
        }

        for (var i = 0; i < checkControls.length; i++) {
            checkControls[i].setValue(values);
        }

        currentValues = values;
        valuesLabel = createLabel(values);
    }

    //--------------------------------------------------------------------------

    function checkValue(checked, value) {
        var checkedValues = valueToArray(formData.value(bindElement));

        var valueIndex = checkedValues.indexOf(value);
        if (checked) {
            if (valueIndex < 0) {
                checkedValues.push(value);
            }
        } else {
            if (valueIndex >= 0) {
                // delete checkedValues[valueIndex];
                checkedValues[valueIndex] = undefined;
            }
        }

        var newValues = checkedValues.filter(function(element) {
            return !XFormJS.isNullOrUndefined(element) && element > "";
        });

        if (newValues.length == 0) {
            newValues = undefined;
        }

        valuesLabel = createLabel(newValues);

        //console.log("newValues:", JSON.stringify(newValues));

        currentValues = newValues;

        formData.setValue(bindElement, newValues);
    }

    //--------------------------------------------------------------------------

    function valueToArray(values) {
        if (XFormJS.isNullOrUndefined(values)) {
            return [];
        }

        if (Array.isArray(values)) {
            return values;
        }

        return values.toString().split(valueSeparator).filter(function(value) {
            return !XFormJS.isNullOrUndefined(value) && value > "";
        });
    }

    //--------------------------------------------------------------------------

    function createLabel(values) {
        var label = "";

        if (!values) {
            return label;
        }

        for (var i = 0; i < checkControls.length; i++) {
            if (values.indexOf(checkControls[i].value) >= 0) {
                if (label > "") {
                    label += ",";
                }

                label += textValue(checkControls[i].label);
            }
        }

        return label;
    }

    //--------------------------------------------------------------------------

    function lookupLabel(value) {
        var label = "";

        if (XFormJS.isEmpty(value)) {
            return label;
        }

        for (var i = 0; i < items.length; i++) {
            var item = items[i];
            if (item.value == value) {
                label = item.label;
                break;
            }
        }

        return textValue(label);
    }

    //--------------------------------------------------------------------------
}
