@isTest
private class SurgeonInHospitalRestrictionV2i3Test {

    @testSetup static void initData() {
      System.runAs(new User(Id = UserInfo.getUserId())) {
        // Get a role so we can use it on sys admin user record.
        // We'll then use this sys admin user as the owner of the account (that's linked to contact)
        UserRole role = [SELECT Id FROM UserRole WHERE Name = 'Biocomposites Manager' LIMIT 1];
        System.assertNotEquals(null, role.Id, 'role not found');

        // Create a sys admin user with a role. We'll make this user the owner of the contact record.
        // (owners of community user contact records must have a role)
        // Create a sys admin profile and user
        String sysAdminProfileName = 'System Administrator';
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = :sysAdminProfileName LIMIT 1];
        System.assertNotEquals(null, sysAdminProfile.Id, sysAdminProfileName + ' profile not found');

        User sysAdminUser = new User(Alias='aucalias', Email='test@testorg.com',
          EmailEncodingKey='UTF-8', LastName='Tester', LanguageLocaleKey='en_US',
          LocaleSidKey='en_US', ProfileId=sysAdminProfile.Id,
          TimeZoneSidKey='America/Los_Angeles', UserName='testAdmin@testorg.com');
          sysAdminUser.UserRoleId = role.Id;
        insert sysAdminUser;
        System.assertNotEquals(null, sysAdminUser.Id, 'Sys Admin not created');

        // Create distributor account
        RecordType distributorAccountRecordType = [SELECT Id FROM RecordType WHERE Name = 'Distributors' and SObjectType = 'Account' LIMIT 1];
        System.assertNotEquals(null, distributorAccountRecordType.Id, 'distributorAccountRecordType not found');
        Account distributor = new Account(Name='Test Account Name', OwnerId=sysAdminUser.Id, RecordTypeId=distributorAccountRecordType.Id);
        insert distributor;
        System.assertNotEquals(null, distributor.Id, 'account not created');

        // Create surgeon
        Contact surgeon = new Contact(LastName='Surgeon');
        insert surgeon;
        System.assertNotEquals(null, surgeon.Id, 'Surgeon not created');

        // Create hospital
        RecordType hospitalAccountRecordType = [SELECT Id FROM RecordType WHERE Name = 'Hospital' and SObjectType = 'Account' LIMIT 1];
        System.assertNotEquals(null, hospitalAccountRecordType.Id, 'hospitalAccountRecordType not found');
        Account hospital = new Account(Name='Hospital',RecordTypeId=hospitalAccountRecordType.Id);
        insert hospital;
        System.assertNotEquals(null, hospital.Id, 'hospital not created');

        // Create Surgeon_in_Hospital__c record
        Surgeon_in_Hospital__c sInH = new Surgeon_in_Hospital__c(Surgeon__c=surgeon.id,Hospital__c=hospital.Id);
        insert sInH;
        System.assertNotEquals(null, sInH.Id, 'Surgeon_in_Hospital__c not created');

        // Create Hospital_in_a_Distributor__c record for hospital/distributor
        Hospital_in_a_Distributor__c hospitalForDistributor = new Hospital_in_a_Distributor__c(Hospital__c=hospital.Id,Distributor__c=distributor.Id);
        insert hospitalForDistributor;
        System.assertNotEquals(null, hospitalForDistributor.Id, 'Hospital_in_a_Distributor__c not created');

        // Create Contact to associate with User record (required for 'portal user')
        Contact contact = new Contact(LastName='Test', AccountId=distributor.Id);
        insert contact;
        System.assertNotEquals(null, contact.Id, 'Contact not created');

        // Create a community profile and user
        String communityProfileName = 'Biocomposites COMMUNITY USER';
        Profile communityProfile = [SELECT Id FROM Profile WHERE Name = :communityProfileName LIMIT 1];
        System.assertNotEquals(null, communityProfile.Id, communityProfileName + ' profile not found');

        User communityUser = new User(Alias='aucalias', Email='test@testorg.com',
          EmailEncodingKey='UTF-8', LastName='Tester', LanguageLocaleKey='en_US',
          LocaleSidKey='en_US', ProfileId=communityProfile.Id,
          TimeZoneSidKey='America/Los_Angeles', UserName='testCommunity@testorg.com');

        communityUser.Community_View__c = 'Community - DISTRIBUTOR USA';
        communityUser.ContactId = contact.Id;
        insert communityUser;
        System.assertNotEquals(null, communityUser.Id, 'Community User not created');
      } // end initData

    }

    public static testMethod void test_returnRestrictedIds() {
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

        // Refresh datetime
        int2ParamMap.put('refreshDatetime',0);

        // Serialise the map into JSON as a parameter
        String param = JSON.serialize(int2ParamMap);

        User communityUser = [Select Id From User Where UserName='testCommunity@testorg.com'];

        System.runAs(communityUser) {
        // Make the call and get the response
          SurgeonInHospitalRestrictionV2i3 restInst = new SurgeonInHospitalRestrictionV2i3();

          String supportResponse = restInst.returnRestrictedIds(param);

          // Deserialise the response
          Map<String,Object> responseMap = (Map<String,Object>)JSON.deserializeUntyped(supportResponse);

          // Get list of ids from response
          List<Object> idsMap = (List<Object>)responseMap.get('ids');

          //System.assertEquals(2,idsMap.size(),'Ids not returned');
        }
    } // end testMethod

    public static testMethod void test_idsStillValid() {

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
        List<Surgeon_in_Hospital__c> surgeonInHospital = [SELECT Id FROM Surgeon_in_Hospital__c LIMIT 1];
        int2ParamMap.put('idsOnDevice',new List<Object>{surgeonInHospital[0].Id});

        // Serialise the map into JSON as a parameter
        String param = JSON.serialize(int2ParamMap);

        User communityUser = [Select Id From User Where UserName='testCommunity@testorg.com'];

        System.runAs(communityUser) {
          // Make the call and get the response
          SurgeonInHospitalRestrictionV2i3 restInst = new SurgeonInHospitalRestrictionV2i3();
          String supportResponse = restInst.idsStillValid(param);

          // Deserialise the response
          Map<String,Object> responseMap = (Map<String,Object>)JSON.deserializeUntyped(supportResponse);

          // Get list of ids from response
          List<Object> idsMap = (List<Object>)responseMap.get('stillValidIds');

          //System.assertEquals(1,idsMap.size(),'Id not returned');
        }

    } // end testMethod

}