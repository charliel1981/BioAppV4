/**
 * @description This steps through all the formula update settings and for each object it starts a batch and processes the records. Once complete
 * it starts a batch job for the next object
 **/
public with sharing class MCFormulaUpdateCheckBatch implements Database.Batchable<sObject>, Database.Stateful {
	private String query;
	private Set<String> objectsToProcess;	
	private String objToProcess;
	public Integer updatedObjectCount;

	/**
	 * @description This is the starting point for the new batch when the list of source objects is not known
	 **/
	public MCFormulaUpdateCheckBatch(Set<String> objectsLeftToProcess) {

		// Set the updated object count
		updatedObjectCount = 0;

		// If the objects left to process is null then find all of the objects to process
		if (objectsLeftToProcess == null) {
			// Get all the custom meta data and add to the list
			objectsLeftToProcess = new Set<String>();
			for (Formula_Update_Settings__mdt updateSetting : [SELECT Id, Object_Name__c FROM Formula_Update_Settings__mdt]) {
				objectsLeftToProcess.add(updateSetting.Object_Name__c);
			}

		}
	
		// Get the object name that is going to be processed
		if (objectsLeftToProcess.size() > 0) {
			for (String objName : objectsLeftToProcess) {
				this.objToProcess = objName;
				objectsLeftToProcess.remove(objName);
				break;
			}
		}		

		// Set the list of objects left to process
		this.objectsToProcess = objectsLeftToProcess;

		// If there is an object to process then build up a query for this
		query = MCFormulaUpdateCheckService.getUpdateSOQLForObject(this.objToProcess);

	}

	public Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	public void execute(Database.BatchableContext BC, List<sObject> scope) {
   		// Update the records
		MCFormulaUpdateCheckService updateService = new MCFormulaUpdateCheckService();
		updateService.checkFormulaFields(scope, this.objToProcess);

		// Update the count
		updatedObjectCount += updateService.updateCount;

	}
	
	/**
	 * @description Upon completion work out what is the next object to process and call this batch with that process name
	 **/
	public void finish(Database.BatchableContext BC) {

		// Call this batch with the new details
		if (this.objectsToProcess.size() > 0) {
			// If this is a test method, we cannot run another batch so instaed call the relevent code directly
			if (Test.isRunningTest()) {
				// Get the next object to process and remove this one
				String objNameToProcess;
				for (String objName : this.objectsToProcess) {
					objNameToProcess = objName;
					this.objectsToProcess.remove(objName);
					break;
				}

				// Get all of the objects to be processed
				String query = MCFormulaUpdateCheckService.getUpdateSOQLForObject(objNameToProcess);
				List<SObject> sobjectList = Database.query(query);

		   		// Update the records
				MCFormulaUpdateCheckService updateService = new MCFormulaUpdateCheckService();
				updateService.checkFormulaFields(sobjectList, objNameToProcess);

			} else {

				MCFormulaUpdateCheckBatch updateBatch = new MCFormulaUpdateCheckBatch(this.objectsToProcess);
		     	ID batchId = Database.executeBatch(updateBatch, 2000);            					
			}
		}
	}



}