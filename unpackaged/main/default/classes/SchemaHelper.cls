/**
*	@description : Helper class used to get the schema
**/
public with sharing class SchemaHelper {
	
	/**
	*	@description : Method to get all the fields for a given sobject
	**/
	public static Set<String> getAllFieldsForSObject(String objectName){
        // Get all the fields 
        if (!String.isBlank(objectName) && Schema.getGlobalDescribe().containsKey(objectName)){
            return Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().keySet();
        }
        return new Set<String>();
    }
}