@isTest
private class MobileRefreshRestrictionTest {

    private static void init() {
        // Get Menu Item record type id
        Id menuItemRecordTypeId = getRecordTypeId('Menu_Item',Mobile_Refresh__c.SObjectType);
        System.assertNotEquals(null, menuItemRecordTypeId, 'Cannot find Menu Item record type');

        Mobile_Refresh__c menu1 = new Mobile_Refresh__c(Name__c='Menu Option1',Available_in_Version__c='V001;V002',Status__c='Active',RecordTypeId=menuItemRecordTypeId);
        insert menu1;
        System.assertNotEquals(null, menu1.Id, 'Menu not created');
    }

    @isTest static void testReturnRestrictionIds() {
        init();

        // Start the test
        Test.startTest();

        MobileRefreshRestriction restriction = new MobileRefreshRestriction();
        Set<id> ids = restriction.returnRestrictedIds('');

        // Stop the test
        Test.stopTest();
    }

    /**
     * @description Returns the record type id for a record type developer name
     **/
    private static Id getRecordTypeId(String recordTypeDeveloperName, Schema.SObjectType sObjType) {
        // Get the object name from the sObject parameter
        String sObjectType = sObjType.getDescribe().getName();

        Id returnId = null;
        // Query for record types
        List<RecordType> recordTypes = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = :sObjectType];
        // Check for name match
        for (RecordType rt : recordTypes) {
            if (rt.DeveloperName == recordTypeDeveloperName) {
                returnId = rt.Id;
                break;
            }
        }

        return returnId;
    }

}