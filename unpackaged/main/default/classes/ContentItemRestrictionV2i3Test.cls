@isTest
private class ContentItemRestrictionV2i3Test {
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
          TimeZoneSidKey='America/Los_Angeles', UserName='testAdmin@testorg1234.com');

        u.Community_View__c = 'System Administrator';
        insert u;
        System.assertNotEquals(null, u.Id, 'User not created');

        // Create Community_Items__c
        Community_Items__c communityItem = new Community_Items__c();
        insert communityItem;
        System.assertNotEquals(null, communityItem.Id, 'Community Item not created');

        // Community_Item_Permission_Link__c
        Community_Item_Permission_Link__c link = new Community_Item_Permission_Link__c();
        link.Community_Item__c = communityItem.Id;
        link.Profile__c = 'System Administrator';
        insert link;
        System.assertNotEquals(null, link.Id, 'Community_Item_Permission_Link__c not created');

        // Create Content Item
        Content_Item__c ci = new Content_Item__c();
        ci.Status__c = 'Active';
        ci.Available_in_Version__c = 'V001;V002';
        ci.Community_Item__c = communityItem.Id;
        insert ci;
        System.assertNotEquals(null, ci.Id, 'Content Item not created');
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
            ContentItemRestrictionV2i3 restInst = new ContentItemRestrictionV2i3();
            String supportResponse = restInst.returnRestrictedIds(param);

            // Deserialise the response
            Map<String,Object> responseMap = (Map<String,Object>)JSON.deserializeUntyped(supportResponse);

            // Get list of ids from response
            List<Object> idsMap = (List<Object>)responseMap.get('ids');

            System.assertEquals(1,idsMap.size(),'Ids not returned');
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
        List<Content_Item__c> contentItem = [SELECT Id FROM Content_Item__c];
        int2ParamMap.put('idsOnDevice',new List<Object>{contentItem[0].Id});

        // Serialise the map into JSON as a parameter
        String param = JSON.serialize(int2ParamMap);

        System.runAs(u) {
            // Make the call and get the response
            ContentItemRestrictionV2i3 restInst = new ContentItemRestrictionV2i3();
            String supportResponse = restInst.idsStillValid(param);

            // Deserialise the response
            Map<String,Object> responseMap = (Map<String,Object>)JSON.deserializeUntyped(supportResponse);

            // Get list of ids from response
            List<Object> idsMap = (List<Object>)responseMap.get('stillValidIds');

            System.assertEquals(1,idsMap.size(),'Id not returned');
        }
    } // end testMethod

} // end class