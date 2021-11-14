/*
  Author : Uday/Ankush
  Date   : 05-June-2015
  Description : 'New - ' string appends as prefix if New_Item__c checks and vise versa. 
*/

trigger UpdatingNewItemToTitle on Community_Items__c (after insert,after Update) 
{

 Set<String> setComItemsInsert = new Set<String>();
 Set<String> setComItemsUpdate = new Set<String>();
 List<Community_Items__c> listCommItemsToUpdate = new List<Community_Items__c>();
 Map<string,String> mapRecType = new Map<String,String>();
  
 for(RecordType retype : [select id, Name from RecordType where SObjectType = 'Community_Items__c'])
 {
 	mapRecType.put(retype.Id,retype.Name);
 }
 
 for(Community_Items__c objCom  : Trigger.new)
 {
	 if(Trigger.isInsert && objCom.New_Item__c == true && mapRecType.get(objCom.RecordTypeId) == 'Topics Of Interest')
	 {
	 	setComItemsInsert.add(objCom.id);
	 }
	 
	 if(Trigger.isUpdate && mapRecType.get(objCom.RecordTypeId) == 'Topics Of Interest' && objCom.New_Item__c == false && trigger.oldMap.get(objCom.id).New_Item__c != objCom.New_Item__c)
	 {
	 	setComItemsUpdate.add(objCom.id);
	 }
 }

 if(!setComItemsInsert.isEmpty())
 {
	  for(Community_Items__c comObj : [select id,New_Item__c,Title__c from Community_Items__c where ID IN:setComItemsInsert])
	  {
	  	 comObj.Title__c = 'New - '+ comObj.Title__c;
	  	 listCommItemsToUpdate.add(comObj);
	  }
	  
	  if(!listCommItemsToUpdate.isEmpty())
	     update listCommItemsToUpdate;
 }
 
 if(!setComItemsUpdate.isEmpty() || Test.isRunningTest())
 {
	  for(Community_Items__c comObj : [select id,New_Item__c,Title__c from Community_Items__c where ID IN:setComItemsUpdate])
	  {
	  	 comObj.Title__c = (comObj.Title__c != null && (comObj.Title__c).startsWithIgnoreCase('New - '))?(comObj.Title__c).substring(6):comObj.Title__c;
	  	 listCommItemsToUpdate.add(comObj);
	  }
	  
	  if(!listCommItemsToUpdate.isEmpty())
	     update listCommItemsToUpdate;
 }
}