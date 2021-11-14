/**
*	@description : This controller to get the images from the document folder
**/
public without sharing class DOFTemplateController {

	public Id dofId {get; set 	{
									if(dofId == null && value != null){
										this.dofId = value;
										fetchDof();
									}
								}
							}
	public DOF__c dof {get; set;}

	/**
	*	@description : Method to get the base url
	*  	@reurn : Current Org Base Url
	**/
	public String getSalesforceBaseUrl(){
		return System.URL.getSalesforceBaseUrl().toExternalForm();
	}


	/**
	*	@description : Method to fetch the dof record
	**/
	private void fetchDof(){
		List<DOF__c> dofList = (List<Dof__c>)Database.query(buildSoql());

		if(!dofList.isEmpty()){
			this.dof = dofList[0];
		}
	}

	/**
	*	@description : Method to build the soql
	*  	@return String Soql String to query.
	**/
	private String buildSoql(){
		String soqlString = 'SELECT ';
		// get fieldslist
		Set<String> fieldList = new Set<String>();

		// add dof fields 
		fieldList.addAll(SchemaHelper.getAllFieldsForSObject(DOF__c.sObjectType.getDescribe().getName()));

		// get account fields 
		Set<String> accountFieldsList = SchemaHelper.getAllFieldsForSObject(Account.sObjectType.getDescribe().getName());

		// add distributor fields list 
		fieldList.addAll(addParentFieldName(accountFieldsList,DOF__c.Distributor__c.getDescribe().getName().replace('__c','__r')));

		// add hospital fields list 
		fieldList.addAll(addParentFieldName(accountFieldsList,DOF__c.Hospital__c.getDescribe().getName().replace('__c','__r')));

		soqlString += String.join(new List<String>(fieldList),',')+
						',(SELECT '+String.join(new List<String>(SchemaHelper.getAllFieldsForSObject(DOF_Item__c.sObjectType.getDescribe().getName())),',')+' FROM DOF_Items__r)'+
							' FROM '+DOF__c.sObjectType.getDescribe().getName()+' WHERE Id = \''+this.dofId+'\' LIMIT 1';

		return soqlString;
	}


	/**
	*	@description : Method to add the parent field name to the fields list
	*  	@return  Set<String> list of modified fields list
	**/
	private Set<String> addParentFieldName(Set<String> fieldsList, String parentFieldName){
		Set<String> modifiedFieldsList = new Set<String>();

		// add parent field name to the start 
		for(String fieldName : fieldsList){
			modifiedFieldsList.add(parentFieldName+'.'+fieldName);
		}
		return modifiedFieldsList;
	}

}