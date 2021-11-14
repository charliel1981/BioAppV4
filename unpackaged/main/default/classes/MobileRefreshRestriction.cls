/**
* @description Class used to restrict data returned to app via mc utils syncMobileTable.
*   To implement in Salesforce:
*     - Create a MobileCaddy 'Support Component' record with field mobilecaddy1__Name__c = MobileRefreshRestriction
*     - On the MobileCaddy 'Mobile Table' record, set field 'Platform Object Support' to record created above
**/
global class MobileRefreshRestriction implements mobilecaddy1.RestrictionInterface001_mc {

  global Set<Id> returnRestrictedIds(String jsonParams) {
    // Get community profile name from the user's User record
    User user = [SELECT Community_View__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

    // Get all menus
    List<Mobile_Refresh__c> menus = [SELECT Id, Available_in_Version__c
                                     FROM Mobile_Refresh__c
                                     WHERE RecordType.Name IN ('Menu Item', 'Sub Menu Item')
                                     AND Status__c = 'Active'];

    // Determine whether the menus are applicable for the version
    Set<Id> menusToInclude = new Set<Id>();
    for (Mobile_Refresh__c menu : menus) {
        Boolean includeMenu = false;
        if (menu.Available_in_Version__c != null) {
            if (menu.Available_in_Version__c.contains('V001')) {
                includeMenu = true;
            }
        }
        if (includeMenu) {
            menusToInclude.add(menu.Id);
        }
    }

    // Select:
    //  - menu profile items for the user's community profile (and version)
    //  - active products
    //  - active record type references (record type ids for org)
    //  - active lot numbers
    List<Mobile_Refresh__c> queryResults = [SELECT Id
                                            FROM Mobile_Refresh__c
                                            WHERE (RecordType.Name = 'Profile Menu Item'
                                                    AND Profile__c = :user.Community_View__c
                                                    AND Status__c = 'Active'
                                                    AND Menu_Item__c IN :menusToInclude)
                                            OR (RecordType.Name IN ('Product', 'Record Type Reference', 'Lot Numbers')
                                                    AND Status__c = 'Active')
                                            ];

    // Return set of ids
    return (new Map<Id,SObject>(queryResults)).keySet();
  }

}