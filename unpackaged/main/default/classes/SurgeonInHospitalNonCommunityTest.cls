/**
 * @description This tests the restriction code in the SurgeonInHospitalNonCommunity class
 **/
 @isTest
public class SurgeonInHospitalNonCommunityTest {
	private static Id hospitalRecordTypeId;

	static {
		RecordType hospitalRecType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Hospital' AND SobjectType='Account' LIMIT 1];
		hospitalRecordTypeId = hospitalRecType.Id;
	}

	private static void init() {
	}

	/**
	 * @description Test that a query against surgeon in hospitals only retutrns records where the user can see the account
	 **/
	static testMethod void testFindSurgeonsInHospitalForUser() {

		RecordType hospitalRecType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Hospital' AND SobjectType='Account' LIMIT 1];
		hospitalRecordTypeId = hospitalRecType.Id;

		// Get the MDM User profile
		Profile ukMDMProfile = [SELECT Id FROM Profile WHERE Name='UK MDM'];
		System.assertNotEquals(null, ukMDMProfile);

		// Get a UKMDM list of user IDs that are using this profile
		Map<Id, User> usersById = new Map<Id, User>([SELECT Id FROM User WHERE ProfileId=:ukMDMProfile.Id]);
		System.assertNotEquals(0, usersById.size());

		// Get the ID of the UK territory
		Territory ukTerritory = [SELECT Id, Name FROM Territory WHERE Name='UK' LIMIT 1];
		Id ukTerritoryId = ukTerritory.Id;
		System.assertNotEquals(null, ukTerritoryId);

		// Get a user that belongs to the UK terrirory
		UserTerritory ukTerritoryUser = [SELECT UserId FROM UserTerritory WHERE IsActive=True AND TerritoryId=:ukTerritoryId AND UserId IN :usersById.keySet() LIMIT 1];
		System.assertNotEquals(null, ukTerritoryUser);

		// Get the user
		List<User> ukUsers = [SELECT Id, Name FROM User WHERE Id=:ukTerritoryUser.UserId];
		System.assertNotEquals(0, ukUsers.size());
		User ukUser = ukUsers[0];
		//User ukUser = [SELECT Id, Name FROM User WHERE Id='005U0000003K5Qt'];
		System.assertNotEquals(null, ukUser);

		System.debug('@@@ ukUser ' + ukUser);

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

		// Start the test
		Test.startTest();

		// Get the ID and use this to test the data
		System.runAs(ukUser) {
			List<Account> visibleAccounts = [SELECT Id FROM Account];
			System.assertEquals(2, visibleAccounts.size());

			// Get the surgeons in hospitals where the user can see the account
			Set<Id> sihIds = SurgeonInHospitalNonCommunity.returnRestrictedIds();
			//System.assertEquals(2, sihIds.size());

		}

		// Stop the Test
		Test.stopTest();

	}

    //@isTest static void testReturnRestrictionIdsForSysAdmin() {
    //  // Create surgeon
    //  Contact surgeon = new Contact(LastName='Surgeon');
    //  insert surgeon;
    //  System.assertNotEquals(null, surgeon.Id, 'Surgeon not created');

    //  // Create hospital
    //  RecordType hospitalAccountRecordType = [SELECT Id FROM RecordType WHERE Name = 'Hospital' and SObjectType = 'Account' LIMIT 1];
    //  System.assertNotEquals(null, hospitalAccountRecordType.Id, 'hospitalAccountRecordType not found');
    //  Account hospital = new Account(Name='Hospital',RecordTypeId=hospitalAccountRecordType.Id);
    //  insert hospital;
    //  System.assertNotEquals(null, hospital.Id, 'hospital not created');

    //  // Create Surgeon_in_Hospital__c record
    //  Surgeon_in_Hospital__c sInH = new Surgeon_in_Hospital__c(Surgeon__c=surgeon.id,Hospital__c=hospital.Id);
    //  insert sInH;
    //  System.assertNotEquals(null, sInH.Id, 'Surgeon_in_Hospital__c not created');

    //  // Get profile and create user record
    //  String profileName = 'System Administrator';
    //  Profile p = [SELECT Id FROM Profile WHERE Name = :profileName];
    //  System.assertNotEquals(null, p.Id, profileName + ' profile not found');

    //  User u = new User(Alias='aucalias', Email='test@testorg.com',
    //    EmailEncodingKey='UTF-8', LastName='Tester', LanguageLocaleKey='en_US',
    //    LocaleSidKey='en_US', ProfileId=p.Id,
    //    TimeZoneSidKey='America/Los_Angeles', UserName='testAdmin@testorg.com');

    //  u.Community_View__c = 'System Administrator';
    //  insert u;
    //  System.assertNotEquals(null, u.Id, 'User not created');

    //  System.runAs(u) {
    //    SurgeonInHospitalRestriction restriction = new SurgeonInHospitalRestriction();
    //    Set<id> ids = restriction.returnRestrictedIds('');
    //    System.assertEquals(1, ids.size(), 'Incorrect returned ids');
    //  }
    //}

    //@isTest static void testReturnRestrictionIdsForNoneCommunityUser() {
    //  // Get distributor account record type
    //  RecordType distributorAccountRecordType = [SELECT Id FROM RecordType WHERE Name = 'Distributors' and SObjectType = 'Account' LIMIT 1];
    //  System.assertNotEquals(null, distributorAccountRecordType.Id, 'distributorAccountRecordType not found');

    //  // Create profile and user
    //  String standardProfileName = 'Standard User';
    //  Profile communityProfile = [SELECT Id FROM Profile WHERE Name = :standardProfileName LIMIT 1];
    //  System.assertNotEquals(null, communityProfile.Id, standardProfileName + ' profile not found');

    //  User standardUser = new User(Alias='aucalias', Email='test@testorg.com',
    //    EmailEncodingKey='UTF-8', LastName='Tester', LanguageLocaleKey='en_US',
    //    LocaleSidKey='en_US', ProfileId=communityProfile.Id,
    //    TimeZoneSidKey='America/Los_Angeles', UserName='testCommunity@testorg.com');

    //  insert standardUser;
    //  System.assertNotEquals(null, standardUser.Id, 'User not created');

    //  System.runAs(standardUser) {
    //    // Create distributor account
    //    Account distributor = new Account(Name='Test Account Name', RecordTypeId=distributorAccountRecordType.Id);
    //    insert distributor;
    //    System.assertNotEquals(null, distributor.Id, 'account not created');

    //    // Create Contact with same email as user
    //    Contact contact = new Contact(LastName='Test', AccountId=distributor.Id, Email='test@testorg.com');
    //    insert contact;
    //    System.assertNotEquals(null, contact.Id, 'Contact not created');

    //    // Execute the restriction method
    //    SurgeonInHospitalRestriction restriction = new SurgeonInHospitalRestriction();
    //    Set<id> ids = restriction.returnRestrictedIds('');
    //  }
    //}

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