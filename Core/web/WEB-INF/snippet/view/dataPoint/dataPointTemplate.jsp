<%--
    Copyright (C) 2015 Infinite Automation Systems Inc. All rights reserved.
    @author Terry Packer
--%>
<%@ include file="/WEB-INF/jsp/include/tech.jsp"%>
<%@page import="com.serotonin.m2m2.vo.template.DataPointPropertiesTemplateDefinition" %>
<table>
  <tr>
    <td colspan="2"><span class="smallTitle"><fmt:message
          key="pointEdit.template.propertyTemplate" /></span> <tag:help
        id="dataPointTemplate" /></td>
  </tr>
  <tr>
    <td colspan="2">
    <table>
      <tbody id="pointPropertyTemplateMessages" />
    </table></td>
  </tr>
  <tr>
    <td class="formLabel"><fmt:message key="pointEdit.template.usePropertyTemplate" /></td>
    <td class="formField"><input
      data-dojo-type="dijit/form/CheckBox" id="usePointPropertyTemplate"
      name="usePointPropertyTemplate" /> <input
      id="pointPropertyTemplate" />
      <button type="button" id='editDataPointTemplateButton'
        onClick="editDataPointTemplate()">
        <fmt:message key="pointEdit.template.editPropertyTemplate" />
      </button>
      <button type="button" id='cancelEditDataPointTemplateButton' style='display:none'
        onClick="cancelEditDataPointTemplate()">
        <fmt:message key="pointEdit.template.cancelEditPropertyTemplate" />
      </button>
      <button type="button" id='updateDataPointTemplateButton'
        onClick="showUpdateTemplateDialog();" style="display:none">
        <fmt:message key="pointEdit.template.updatePropertyTemplate" />
      </button>
      <button type="button" id='saveNewDataPointTemplateButton' style='display:none'
        onClick="showNewTemplateDialog();">
        <fmt:message key="pointEdit.template.saveNewPropertyTemplate" />
      </button>
    </td>
  </tr>
</table>
<%-- Save New Dialog --%>
<div data-dojo-type="dijit.Dialog" id="newTemplateDialog"
  title="<fmt:message key='template.saveNew'/>" style="width: 300px">
  <div class="dijitDialogPaneContentArea">
    <label for='templateName'>
      <fmt:message key="common.name" />  
    </label><input id='templateName'
      type='text' />
  </div>
  <div class="dijitDialogPaneActionBar">
    <button id='saveNewDataPointTemplateButton' onClick='saveNewDataPointTemplate()'>
      <fmt:message key="common.save" />
    </button>
    <button onClick="dijit.byId('newTemplateDialog').hide()">
      <fmt:message key="common.cancel" />
    </button>
  </div>
</div>
<%-- Update Dialog --%>
<div data-dojo-type="dijit.Dialog" id="updateTemplateDialog"
  title="<fmt:message key='template.update'/>" style="width: 300px">
  <div class="dijitDialogPaneContentArea">
    <span style="color:red">
      <fmt:message key="pointEdit.template.updateWarning" />
    </span>
    <br>
    <!-- INSERT TABLE OF POINTS TO UPDATE HERE -->
    <label for='updateTemplateName'>
        <fmt:message key="common.name" />
    </label>
    <input id='updateTemplateName'type='text' />
  </div>
  <div class="dijitDialogPaneActionBar">
    <button id='confirmUpdateDataPointTemplateButton' onClick='updateDataPointTemplate()'>
      <fmt:message key="common.update" />
    </button>
    <button onClick="dijit.byId('updateTemplateDialog').hide()">
      <fmt:message key="common.cancel" />
    </button>
  </div>
</div>
<script type="text/javascript">
	dojo.require("dijit.Dialog");

	function showNewTemplateDialog() {
		dijit.byId('newTemplateDialog').show();
		$set('templateName',"");
	}
	function showUpdateTemplateDialog() {
		var template = dataPointTemplatePicker.item;
		if(template != null)
			$set('updateTemplateName', template.name);
		dijit.byId('updateTemplateDialog').show();
	}
	//Global variables used on the page
	var NEW_ID = -1;
	var dataPointTemplatesList, dataPointTemplatePicker, newTemplateDialog, usePointPropertyTemplate, dataPointTemplateDataTypeId;
	var savedMessageArray = [ {
		genericMessage : '<fmt:message key="pointEdit.template.templateSaved"/>',
		level : 'error' //So message is RED like the other save messages
	} ];
	var templateNotSavedMessage = {
		genericMessage : '<fmt:message key="pointEdit.template.templateNotSaved"/>',
		level : 'error'
	}

	/**
	 * Initialize the Template Inputs
	 */
	function initDataPointTemplates() {

		//Create the store
		dataPointTemplatesList = new dojo.store.Memory({
			idProperty : "id",
			valueProperty : "name",
			data : []
		});

		//Create the base unit input
		dataPointTemplatePicker = new dijit.form.ComboBox(
				{
					store : dataPointTemplatesList,
					autoComplete : false,
					style : "width: 250px;",
					queryExpr : "*\${0}*",
					highlightMatch : "all",
					required : false,
					placeHolder : '<fmt:message key="pointEdit.template.selectPropertyTemplate"/>',
					onChange : function(templateName) {
						if (dataPointTemplatePicker.item != null){
							loadFromDataPointTemplate(dataPointTemplatePicker.item);
    						//Disable all inputs each time because some of the 
    						// Settings areas re-enable inputs on load of new types
    						disableDataPointInputs();
						}
					}
				}, "pointPropertyTemplate");

		//Setup to watch the checkbox
		usePointPropertyTemplate = dijit.byId('usePointPropertyTemplate');
		usePointPropertyTemplate.watch('checked', function(value) {
			if (usePointPropertyTemplate.checked) {
				//Using a template
				enableTemplateControls();
				if (dataPointTemplatePicker.item != null){
					loadFromDataPointTemplate(dataPointTemplatePicker.item);
					//Disable all inputs each time because some of the 
					// Settings areas re-enable inputs on load of new types
					disableDataPointInputs();
				}
			} else {
				//Not Using Template
				disableTemplateControls();
				enableDataPointInputs();
			}
		});
	}

	/**
	 * Callback to know when the data type has changed
	 */
	function templateDataTypeChanged(newDataTypeId) {
		
		//Reload the template list with only available templates
		dataPointTemplateDataTypeId = newDataTypeId;
		TemplateDwr.getDataPointTemplates(newDataTypeId, function(response) {
			dataPointTemplatesList.setData(response.data.templates);
		});
		//If we are changing data types we must disable our use of a template
		usePointPropertyTemplate.set('checked', false);
		dataPointTemplatePicker.reset(); 
	}
	dataTypeChangedCallbacks.push(templateDataTypeChanged);

	/**
	 * Set the template from the DataPointVO
	 */
	function setDataPointTemplate(vo) {
		//Clear out my messages
		hideGenericMessages("pointPropertyTemplateMessages");
		//Save as reference
		dataPointTemplateDataTypeId = vo.pointLocator.dataTypeId;
		//Reload the template list with only available templates
		TemplateDwr.getDataPointTemplates(vo.pointLocator.dataTypeId, function(
				response) {
			dataPointTemplatesList.setData(response.data.templates);
			if (vo.templateId > 0) {
				enableTemplateControls();
				var template = dataPointTemplatesList.get(vo.templateId);
				//This order is important so that the first check doesn't load the template
				dataPointTemplatePicker.set('_onChangeActive', false);
				dataPointTemplatePicker.set('item', template);
				dataPointTemplatePicker.set('_onChangeActive', true);
				usePointPropertyTemplate.set('checked', true);
			} else {
				if(usePointPropertyTemplate.get('checked')){
					usePointPropertyTemplate.set('checked', false);
				}else{
					//Watch won't fire so just disable the template controls and enable inputs
					//Not Using Template
					disableTemplateControls();
					enableDataPointInputs();
				}
			}
		});

	}

	/**
	 * Add a template to the DataPointVO if necessary
	 */
	function getDataPointTemplate(vo) {
		if (usePointPropertyTemplate.get('checked') == true) {
			if (dataPointTemplatePicker.item != null)
				vo.templateId = dataPointTemplatePicker.item.id;
			else
				vo.templateId = null; //No template in use
		} else {
			vo.templateId = null; //No template in use
		}
	}

	/**
	 * Method to enable template controls
	 */
	 function enableTemplateControls(){
		/* Disable the picker */
		dataPointTemplatePicker.set('disabled', false);
		var updateTemplateButton = dojo.byId('updateDataPointTemplateButton');
		updateTemplateButton.disabled = false;
		var saveTemplateButton = dojo.byId('saveNewDataPointTemplateButton');
		saveTemplateButton.disabled = false;
		show('editDataPointTemplateButton');
		hide('cancelEditDataPointTemplateButton');
		hide('updateDataPointTemplateButton');
		hide('saveNewDataPointTemplateButton');
	}
	
	/**
	 * Method to enable template controls
	 */
	 function disableTemplateControls(){
		/* Disable the picker */
		dataPointTemplatePicker.set('disabled', true);
		var updateTemplateButton = dojo.byId('updateDataPointTemplateButton');
		updateTemplateButton.disabled = true;
		var saveTemplateButton = dojo.byId('saveNewDataPointTemplateButton');
		saveTemplateButton.disabled = true;
		hide('editDataPointTemplateButton');
		hide('cancelEditDataPointTemplateButton');
		hide('updateDataPointTemplateButton');
		hide('saveNewDataPointTemplateButton');
		dataPointTemplatePicker.reset(); 
	}
	
	/**
	 * Method to enable all data point inputs
	 **/
	function enableDataPointInputs() {
		/* Enable all inputs here */
		enablePointProperties(dataPointTemplateDataTypeId);
		enableLoggingProperties(dataPointTemplateDataTypeId);
		textRendererEditor.enableInputs(dataPointTemplateDataTypeId);
		chartRendererEditor.enableInputs(dataPointTemplateDataTypeId);
	}
	
	function disableDataPointInputs(){
		disablePointProperties(dataPointTemplateDataTypeId);
		disableLoggingProperties(dataPointTemplateDataTypeId);
		textRendererEditor.disableInputs(dataPointTemplateDataTypeId);
		chartRendererEditor.disableInputs(dataPointTemplateDataTypeId);
	}

	function editDataPointTemplate(){
		hide('editDataPointTemplateButton');
		show('cancelEditDataPointTemplateButton');
		show('updateDataPointTemplateButton');
		show('saveNewDataPointTemplateButton');
		enableDataPointInputs();
	}
	
	function cancelEditDataPointTemplate(){
		show('editDataPointTemplateButton');
		hide('cancelEditDataPointTemplateButton');
		hide('updateDataPointTemplateButton');
		hide('saveNewDataPointTemplateButton');
		if (dataPointTemplatePicker.item != null)
			loadFromDataPointTemplate(dataPointTemplatePicker.item);
		disableDataPointInputs();
	}
	
	/**
	 * Method to save currently loaded template if it exists
	 **/
	function updateDataPointTemplate() {
		hideContextualMessages("pointDetails");
		//Close Popup
		dijit.byId('updateTemplateDialog').hide();
		//Get currently selected template
		var template = dataPointTemplatePicker.item;
		//Check to see that something is selected
		if (template != null) {
			//Set the name
			template.name = $get('updateTemplateName');
			//Load template info from inputs
			loadIntoDataPointTemplate(template);
			//Save the template
			TemplateDwr.saveDataPointTemplate(template, function(response) {
				if (response.hasMessages) {
					response.messages.push(templateNotSavedMessage);
					showTemplateMessages(response.messages,
							'pointPropertyTemplateMessages');
				} else {
					showTemplateMessages(savedMessageArray,
							'pointPropertyTemplateMessages');
					//TODO Show messages for each XID updated: xidsUpdated
					//TODO Show messages for each XID failed: failedXidMap<xid,why>
					show('editDataPointTemplateButton');
					hide('cancelEditDataPointTemplateButton');
					hide('updateDataPointTemplateButton');
					hide('saveNewDataPointTemplateButton');
					disableDataPointInputs();
				}
			});
		} else {
			//TODO this can happen when someone enters a name into the dropdown and there is no matching template
			var messages = [ templateNotSavedMessage ];
			showTemplateMessages(messages, 'pointPropertyTemplateMessages');
		}

	}

	/**
	 * Method to save currently loaded template if it exists
	 **/
	function saveNewDataPointTemplate() {
		hideContextualMessages("pointDetails");
		//Close Popup
		dijit.byId('newTemplateDialog').hide();

		//Get currently selected template
		//Could create a DWR Call to request a new template of this type
		// then access the module registry and create a new one and return it
		TemplateDwr.getNewDataPointTemplate(function(response){
			var template = response.data.vo;
			template.name = $get('templateName');
			//Load the values into the template from the input
			loadIntoDataPointTemplate(template);

			//Check to see that something is selected
			if (template != null) {
				TemplateDwr.saveDataPointTemplate(template, function(response) {
					if (response.hasMessages) {
						response.messages.push(templateNotSavedMessage);
						showTemplateMessages(response.messages,
								'pointPropertyTemplateMessages');
					} else {
						template.id = response.data.id;
						dataPointTemplatesList.put(template);
						//Select the template in the list
						dataPointTemplatePicker.set('item', template);
						showTemplateMessages(savedMessageArray,
								'pointPropertyTemplateMessages');
						show('editDataPointTemplateButton');
						hide('cancelEditDataPointTemplateButton');
						hide('updateDataPointTemplateButton');
						hide('saveNewDataPointTemplateButton');
						disableDataPointInputs();
					}
				});
			}
		});


	}

	/**
	 *  Load the input values from the page into the template
	 */
	function loadIntoDataPointTemplate(template) {

		//Set the Data Type ID
		template.dataTypeId = dataPointTemplateDataTypeId;

		getPointProperties(template);
		//Some massaging because our members are slightly different to DataPointVO
		template.unit = template.unitString;
		template.renderedUnit = template.renderedUnitString;
		template.integralUnit = template.integralUnitString;

		getLoggingProperties(template);

		getTextRenderer(template);
		getChartRenderer(template);

		//Delete back off the un-necessary properties
		delete template.unitString;
		delete template.renderedUnitString;
		delete template.integralUnitString;
		delete template.pointLocator;
	}

	/**
	 * Load the values from the template into the inputs on the page
	 */
	function loadFromDataPointTemplate(template) {

		//Some massaging because our members are slightly different to DataPointVO
		template.unitString = template.unit;
		template.renderedUnitString = template.renderedUnit;
		template.integralUnitString = template.integralUnit;
		template.pointLocator = {
			dataTypeId : template.dataTypeId
		};
		setPointProperties(template);
		setLoggingProperties(template);
		setTextRenderer(template);
		setChartRenderer(template);
	}

	function showTemplateMessages(/*ProcessResult.messages*/messages, /*tbody*/
			genericMessageNode) {
		var i, m, field, node, next;
		var genericMessages = new Array();
		for (i = 0; i < messages.length; i++) {
			m = messages[i];
			if (m.contextKey) {
				node = $(m.contextKey + "Ctxmsg");
				if (!node) {
					field = $(m.contextKey);
					if (field)
						node = createContextualMessageNode(field, m.contextKey);
					else {
						m.genericMessage = m.contextKey + " - "
								+ m.contextualMessage;
						genericMessages[genericMessages.length] = m;
					}
				}

				if (node) {
					node.innerHTML = m.contextualMessage;
					show(node);
				}
			} else
				genericMessages[genericMessages.length] = m;
		}

		if (genericMessages.length > 0) {
			if (!genericMessageNode) {
				for (i = 0; i < genericMessages.length; i++)
					alert(genericMessages[i].genericMessage);
			} else {
				genericMessageNode = getNodeIfString(genericMessageNode);
				if (genericMessageNode.tagName == "TBODY") {
					dwr.util.removeAllRows(genericMessageNode);
					dwr.util
							.addRows(
									genericMessageNode,
									genericMessages,
									[ function(data) {
										return data.genericMessage;
									} ],
									{
										cellCreator : function(options) {
											var td = document
													.createElement("td");
											if (options.rowData.level == 'error')
												td.className = "formError";
											else if (options.rowData.level == 'warning')
												td.className = "formWarning";
											else if (options.rowData.level == 'info')
												td.className = "formInfo";
											return td;
										}
									});
					show(genericMessageNode);
				} else if (genericMessageNode.tagName == "DIV"
						|| genericMessageNode.tagName == "SPAN") {
					var content = "";
					for (var i = 0; i < genericMessages.length; i++)
						content += genericMessages[i].genericMessage + "<br/>";
					genericMessageNode.innerHTML = content;
				}
			}
		}
	}
</script>

