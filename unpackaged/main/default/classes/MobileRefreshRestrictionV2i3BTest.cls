@isTest
private class MobileRefreshRestrictionV2i3BTest {
    private static User u;

    private static void initData() {
        // Get profile and create user record
        String profileName = 'System Administrator';
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName];
        System.assertNotEquals(null, p.Id, profileName + ' profile not found');

        // Create user
        u = new User(Alias='aucalias', Email='test@testorg.com',
          EmailEncodingKey='UTF-8', LastName='Tester', LanguageLocaleKey='en_US',
          LocaleSidKey='en_US', ProfileId=p.Id,
          TimeZoneSidKey='America/Los_Angeles', UserName='testAdmin@testorg1234V2i3B.com');

        u.Community_View__c = 'System Administrator';
        insert u;
        System.assertNotEquals(null, u.Id, 'User not created');

        // Create Mobile_Refresh__c menu item for V002
        Mobile_Refresh__c mr1 = new Mobile_Refresh__c();
        mr1.Status__c = 'Active';
        mr1.Available_in_Version__c = 'V001;V002';
        mr1.RecordTypeId = getRecordTypeId('Menu_Item',Mobile_Refresh__c.SObjectType);
        insert mr1;
        System.assertNotEquals(null, mr1.Id, 'Mobile_Refresh__c mr1 not created');

        // Create Mobile_Refresh__c Profile Menu Item (this should be selected)
        Mobile_Refresh__c mr2 = new Mobile_Refresh__c();
        mr2.Status__c = 'Active';
        mr2.RecordTypeId = getRecordTypeId('Profile_Menu_Item',Mobile_Refresh__c.SObjectType);
        mr2.Profile__c = 'System Administrator';
        mr2.Menu_Item__c = mr1.Id;
        insert mr2;
        System.assertNotEquals(null, mr2.Id, 'Mobile_Refresh__c mr2 not created');

        // Create Mobile_Refresh__c Product (this should be selected)
        Mobile_Refresh__c mr3 = new Mobile_Refresh__c();
        mr3.Status__c = 'Active';
        mr3.RecordTypeId = getRecordTypeId('Product',Mobile_Refresh__c.SObjectType);
        insert mr3;
        System.assertNotEquals(null, mr3.Id, 'Mobile_Refresh__c mr3 not created');

        // Create Mobile_Refresh__c Profile Menu Item (this should NOT be selected)
        Mobile_Refresh__c mr4 = new Mobile_Refresh__c();
        mr4.Status__c = 'Active';
        mr4.RecordTypeId = getRecordTypeId('Profile_Menu_Item',Mobile_Refresh__c.SObjectType);
        mr4.Profile__c = 'Unknown Profile';
        mr4.Menu_Item__c = mr1.Id;
        insert mr4;
        System.assertNotEquals(null, mr4.Id, 'Mobile_Refresh__c mr4 not created');
    } // end initData

    public static testMethod void test_returnRestrictedIds() {
        initData();

        mobilecaddy1__Mobile_Table__c mobileTableRec = new mobilecaddy1__Mobile_Table__c(
            mobilecaddy1__Mobile_Table_Version__c = '001',
            mobilecaddy1__Mobile_Table_Status__c = 'Inactive',
            mobilecaddy1__Dev_Status__c = 'Developing',
            mobilecaddy1__Sync_Priority__c = 1,
            mobilecaddy1__Build_Order__c = 1,
            mobilecaddy1__Refresh_Record_Limit__c = 1000,
            mobilecaddy1__Refresh_Record_Limit_Install__c = 1000
            );

        // Prepare map of input parameters to interace 2
        Map<String,Object> int2ParamMap = new Map<String,Object>();

        // Provide entire mobile table record to external class
        int2ParamMap.put('mobileTableRec',mobileTableRec);

        // Mark as a new install
        int2ParamMap.put('isInstall',true);

        // Provide set of ids already processed so that external class may ignore them on a more batch query
        int2ParamMap.put('idsAlreadyProcessed',null);

        // Ids on device
        int2ParamMap.put('idsOnDevice',null);

        // Refresh datetime
        int2ParamMap.put('refreshDatetime',0);

        // Serialise the map into JSON as a parameter
        String param = JSON.serialize(int2ParamMap);

        System.runAs(u) {
            // Make the call and get the response
            MobileRefreshRestrictionV2i3B restInst = new MobileRefreshRestrictionV2i3B();
            String supportResponse = restInst.returnRestrictedIds(param);

            // Deserialise the response
            Map<String,Object> responseMap = (Map<String,Object>)JSON.deserializeUntyped(supportResponse);

            // Get list of ids from response
            List<Object> idsMap = (List<Object>)responseMap.get('ids');

            System.assertEquals(2,idsMap.size(),'Ids not returned');
        }

    } // end testMethod

    public static testMethod void test_idsStillValid() {
        initData();

        mobilecaddy1__Mobile_Table__c mobileTableRec = new mobilecaddy1__Mobile_Table__c(
            mobilecaddy1__Mobile_Table_Version__c = '001',
            mobilecaddy1__Mobile_Table_Status__c = 'Inactive',
            mobilecaddy1__Dev_Status__c = 'Developing',
            mobilecaddy1__Sync_Priority__c = 1,
            mobilecaddy1__Build_Order__c = 1,
            mobilecaddy1__Refresh_Record_Limit__c = 1000,
            mobilecaddy1__Refresh_Record_Limit_Install__c = 1000
            );

        // Prepare map of input parameters to interace 2
        Map<String,Object> int2ParamMap = new Map<String,Object>();

        // Provide entire mobile table record to external class
        int2ParamMap.put('mobileTableRec',mobileTableRec);

        // Add an id to device
        String profileMenuItemRecordTypeId = getRecordTypeId('Profile_Menu_Item',Mobile_Refresh__c.SObjectType);
        List<Mobile_Refresh__c> profileMenuItem = [SELECT Id FROM Mobile_Refresh__c WHERE RecordTypeId = :profileMenuItemRecordTypeId];
        int2ParamMap.put('idsOnDevice',new List<Object>{profileMenuItem[0].Id});

        // Serialise the map into JSON as a parameter
        String param = JSON.serialize(int2ParamMap);

        System.runAs(u) {
            // Make the call and get the response
            MobileRefreshRestrictionV2i3B restInst = new MobileRefreshRestrictionV2i3B();
            String supportResponse = restInst.idsStillValid(param);

            // Deserialise the response
            Map<String,Object> responseMap = (Map<String,Object>)JSON.deserializeUntyped(supportResponse);

            // Get list of ids from response
            List<Object> idsMap = (List<Object>)responseMap.get('stillValidIds');

            System.assertEquals(1,idsMap.size(),'Id not returned');
        }
    } // end testMethod

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

} // end class