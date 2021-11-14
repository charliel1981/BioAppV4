/**
 * @description This is used to monitor and update records that contain formula fields. It does this by comparing a formula fields with editable fields and if there is a difference
 * it populates the editable field with the formula field. This in turn triggers the modified date to change which will enure that the record will be synched to any mobile devices
 * @author MobileCaddy
 **/
public with sharing class MCFormulaUpdateCheckService {
	public Integer updateCount {get; private set;}

	/**
	 * @constructor
	 **/
	public MCFormulaUpdateCheckService() {
	}

	/**
	 * @description This takes an object name that is being queries and a list of records that are to be checked. The 
	 **/
	public void checkFormulaFields(List<sObject> sObjectList, String objectName) {

		// Get all of the process field update details
		List<Formula_Update_Settings__mdt> updateSettings = [SELECT Copy_Field_Name__c, Formula_Field_Name__c FROM Formula_Update_Settings__mdt WHERE Object_Name__c =:objectName];

		// Get the Ids
		Set<Id> objectIds = new Set<Id>();
		for (sObject sobj : sObjectList) {
			objectIds.add(sObj.Id);
		}

		// Get all of the fields required for this procedure
		String soql = 'SELECT Id';
		for (Formula_Update_Settings__mdt updateSetting : updateSettings) {
			soql += ',' + updateSetting.Copy_Field_Name__c;
			soql += ',' + updateSetting.Formula_Field_Name__c;
		}
		soql += ' FROM ' + objectName + ' WHERE Id IN:objectIds';
		List<sObject> sObjects = Database.Query(soql);

		// Build up a list of sObjects that should be saved
		List<sObject> updatedObjects = new List<sObject>();

		// Loop through the found records and compare values, update and save
		for (sObject obj : sObjects) {
			// For each record loop through the update values
			Boolean recUpdated = false;
			for (Formula_Update_Settings__mdt updateSetting : updateSettings) {
				object formulaValue = obj.get(updateSetting.Formula_Field_Name__c);
				object copyValue = obj.get(updateSetting.Copy_Field_Name__c);
				if (formulaValue != copyValue) {
					recUpdated = true;
					obj.put(updateSetting.Copy_Field_Name__c, formulaValue);
				}
			}

			if (recUpdated == true) {
				updatedObjects.add(obj);
			}

		}

		// Save the updated records
		update updatedObjects;

		// Record the update count
		updateCount = updatedObjects.size();


	}

	/**
	 * @description This returns a soql for all of the related objects given an object name
	 * @param String The object name
	 * @return String The soql
	 **/
	public static String getUpdateSOQLForObject(String objectName) {

		// Get meta data details for the object
		List<Formula_Update_Settings__mdt> updateSettings = [SELECT Copy_Field_Name__c, Formula_Field_Name__c, Comparison_Field__c FROM Formula_Update_Settings__mdt WHERE Object_Name__c =:objectName];

		// Create the soql
		Set<String> comparisonFields = new Set<String>();
		String selectStatement = 'SELECT Id';
		String whereClause;
		for (Formula_Update_Settings__mdt updateSetting : updateSettings) {
			selectStatement += ',' + updateSetting.Copy_Field_Name__c + ',' + updateSetting.Formula_Field_Name__c;

			// Add a where statement to select only records where the formula has changed
			if (updateSetting.Comparison_Field__c != null && comparisonFields.contains(updateSetting.Comparison_Field__c) == false) {
				if (whereClause == null) {
					whereClause = 'WHERE ' + updateSetting.Comparison_Field__c + '=false';
				} else {
					whereClause += ' OR ' + updateSetting.Comparison_Field__c + '=false';
				}

				// Add to list of comp fields
				comparisonFields.add(updateSetting.Comparison_Field__c);

			}
		}

		// Build and return the soql
		String soql = selectStatement + ' FROM ' + objectName;
		soql += whereClause != null ? ' ' + whereClause : '';
		return soql;

	}

}