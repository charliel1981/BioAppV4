@isTest
private class SurgeonInHospitalNonCommunityV4i3BTest {
    private static Id hospitalRecordTypeId;
    private static User ukUser;

    static {
      RecordType hospitalRecType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Hospital' AND SobjectType='Account' LIMIT 1];
      hospitalRecordTypeId = hospitalRecType.Id;
    }

    private static void initData() {
      RecordType hospitalRecType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Hospital' AND SobjectType='Account' LIMIT 1];
      hospitalRecordTypeId = hospitalRecType.Id;

      // Get the MDM User profile
      Profile ukMDMProfile = [SELECT Id FROM Profile WHERE Name='UK MDM'];
      System.assertNotEquals(null, ukMDMProfile);

      // Get a UKMDM list of user IDs that are using this profile
      Map<Id, User> usersById = new Map<Id, User>([SELECT Id FROM User WHERE ProfileId=:ukMDMProfile.Id]);
      System.assertNotEquals(0, usersById.size());

      // Get the ID of the UK territory
      Territory2 ukTerritory = [SELECT Id, Name FROM Territory2 WHERE Name='UK' LIMIT 1];
      Id ukTerritoryId = ukTerritory.Id;
      System.assertNotEquals(null, ukTerritoryId);

      // Get a user that belongs to the UK territory
      UserTerritory2Association ukTerritoryUser = [SELECT UserId FROM UserTerritory2Association WHERE IsActive=True AND Territory2Id=:ukTerritoryId AND UserId IN :usersById.keySet() LIMIT 1];
      System.assertNotEquals(null, ukTerritoryUser);

      // Get the user
      List<User> ukUsers = [SELECT Id, Name FROM User WHERE Id=:ukTerritoryUser.UserId];
      System.assertNotEquals(0, ukUsers.size());
      ukUser = ukUsers[0];
      System.assertNotEquals(null, ukUser);

      // Create some hospital accounts
      Map<String, Account> hospitals = new Map<String, Account>();
      hospitals.put('h1',createAccount('Hosp 1', 'UK'));
      hospitals.put('h2',createAccount('Hosp 2', 'UK'));
      hospitals.put('h3',createAccount('Hosp 3', 'USA'));
      hospitals.put('h4',createAccount('Hosp 4', 'Canada'));
      insert hospitals.values();

      // Create some surgeon accounts
      Map<String, Contact> surgeons = new Map<String,Contact>();
      surgeons.put('s1',createContact('surgepon', 'one', hospitals.get('h1').Id));
      surgeons.put('s2',createContact('surgepon', 'two', hospitals.get('h2').Id));
      surgeons.put('s3',createContact('surgepon', 'three', hospitals.get('h3').Id));
      surgeons.put('s4',createContact('surgepon', 'four', hospitals.get('h4').Id));
      insert surgeons.values();

      // Create some hospitals & surgeons
      List<Surgeon_in_Hospital__c> surgeonsInHospitals = new List<Surgeon_in_Hospital__c>();
      surgeonsInHospitals.add(createSurgeonInHospital(hospitals.get('h1').Id,surgeons.get('s1').Id));
      surgeonsInHospitals.add(createSurgeonInHospital(hospitals.get('h2').Id,surgeons.get('s2').Id));
      surgeonsInHospitals.add(createSurgeonInHospital(hospitals.get('h3').Id,surgeons.get('s3').Id));
      surgeonsInHospitals.add(createSurgeonInHospital(hospitals.get('h4').Id,surgeons.get('s4').Id));
      insert surgeonsInHospitals;
    }

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

        System.runAs(ukUser) {
          List<Account> visibleAccounts = [SELECT Id FROM Account];
          System.assertEquals(2, visibleAccounts.size());

          // Make the call and get the response
          String supportResponse = SurgeonInHospitalNonCommunityV4i3B.returnRestrictedIds(param);

          // Deserialise the response
          Map<String,Object> responseMap = (Map<String,Object>)JSON.deserializeUntyped(supportResponse);

          // Get list of ids from response
          List<Object> idsMap = (List<Object>)responseMap.get('ids');

          //System.assertEquals(2,idsMap.size(),'Ids not returned');
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
        List<Surgeon_in_Hospital__c> surgeonInHospital = [SELECT Id FROM Surgeon_in_Hospital__c LIMIT 1];
        int2ParamMap.put('idsOnDevice',new List<Object>{surgeonInHospital[0].Id});

        // Serialise the map into JSON as a parameter
        String param = JSON.serialize(int2ParamMap);

        System.runAs(ukUser) {
          // Make the call and get the response
          String supportResponse = SurgeonInHospitalNonCommunityV4i3B.idsStillValid(param);

          // Deserialise the response
          Map<String,Object> responseMap = (Map<String,Object>)JSON.deserializeUntyped(supportResponse);

          // Get list of ids from response
          List<Object> idsMap = (List<Object>)responseMap.get('stillValidIds');

          //System.assertEquals(1,idsMap.size(),'Id not returned');
        }

    } // end testMethod

    /************************* PRIVATE METHODS ********************/
    private static Account createAccount(String accountName, String country) {
      Account acc = new Account();
      acc.RecordTypeId = hospitalRecordTypeId;
      acc.Name = accountName;
      acc.Country__c = country;
      return acc;
    }

    private static Surgeon_in_Hospital__c createSurgeonInHospital(Id hospitalId, Id surgeonId) {
      Surgeon_in_Hospital__c sih = new Surgeon_in_Hospital__c();
      sih.Hospital__c = hospitalId;
      sih.Surgeon__c = surgeonId;
      return sih;
    }

    private static Contact createContact(String firstName, String lastName, Id accId) {
      Contact c = new Contact();
      c.AccountId = accId;
      c.FirstName = firstName;
      c.LastName = lastName;
      return c;
    }

}