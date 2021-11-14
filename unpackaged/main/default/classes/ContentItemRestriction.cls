/**
* @description Class used to restrict data returned to app via mc utils syncMobileTable.
*   To implement in Salesforce:
*     - Create a MobileCaddy 'Support Component' record with field mobilecaddy1__Name__c = ContentItemRestriction
*     - On the MobileCaddy 'Mobile Table' record, set field 'Platform Object Support' to record created above
**/
global class ContentItemRestriction implements mobilecaddy1.RestrictionInterface001_mc {

  global Set<Id> returnRestrictedIds(String jsonParams) {
    // Get community profile name from the user's User record
    User user = [SELECT Community_View__c, UserName FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

    // Check to see if we have any dynamic soql used in testing,
    // to restrict amount of data for individual users (helps with memory size issues in Chrome codeflow testing)
    List<Mobile_Refresh__c> mr = [SELECT Dynamic_SOQL__c
                                  FROM Mobile_Refresh__c
                                  WHERE Name__c = :user.UserName
                                  AND Object_Reference__c = 'Content_Item__c'
                                  AND Status__c = 'Active' LIMIT 1];

    String testingDynamicSOQL = '';
    if (!mr.isEmpty()) {
      if (mr[0].Dynamic_SOQL__c != null && mr[0].Dynamic_SOQL__c != '') {
        testingDynamicSOQL = mr[0].Dynamic_SOQL__c;
      }
    }

    // Build the default soql to select records from Content_Item__c - based on the user's 'community profile' on User record
    String defaultDynamicSOQL = 'SELECT Id FROM Content_Item__c WHERE Community_Item__c IN ';
    defaultDynamicSOQL += '(SELECT Community_Item__c FROM Community_Item_Permission_Link__c WHERE Profile__c = \'' + user.Community_View__c + '\') ';
    defaultDynamicSOQL += 'AND Status__c = \'Active\'';
    defaultDynamicSOQL += 'AND Available_in_Version__c INCLUDES (\'V001\')';

    List<Content_Item__c> queryResults = new List<Content_Item__c>();
    if (testingDynamicSOQL != '') {
      // If we do have some dynamic soql from Mobile_Refresh__c then attempt to execute it.
      // Run the default soql if we have any exceptions
      try {
        queryResults = Database.query(testingDynamicSOQL);
      } catch (Exception e) {
        queryResults = Database.query(defaultDynamicSOQL);
      }
    } else {
      // Select records based on the user's community profile
      queryResults = Database.query(defaultDynamicSOQL);
    }

    // Return set of ids
    if (queryResults.isEmpty()) {
      return new Set<Id>();
    } else {
      return (new Map<Id,SObject>(queryResults)).keySet();
    }
  }

}