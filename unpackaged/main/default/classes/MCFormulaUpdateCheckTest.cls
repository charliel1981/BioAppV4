@isTest
private class MCFormulaUpdateCheckTest {
	private static Map<String, Account> hospitalsByName;
	private static Map<String, Contact> surgeonsByName;
	private static Id hotelRecordTypeId;

	static {}

	private static void init() {

		// Get the ID of the hotel record type
		RecordType hotelRecordType = [SELECT Id FROM RecordType WHERE SobjectType='Account' AND DeveloperName='Hospital' LIMIT 1];
		hotelRecordTypeId = hotelRecordType.Id;

		// Create some hospital details (Accounts)
		hospitalsByName = new Map<String, Account>();
		hospitalsByName.put('h1',createHospital('h1', 'London', 'UK', 'h1@test.com', 'London', 'Big Street', 'RG11 2QQ'));
		hospitalsByName.put('h2',createHospital('h2', 'Leeds', 'UK', 'h2@test.com', 'Yorkshire', 'Big Road', 'YO11 2QQ'));
		hospitalsByName.put('h3',createHospital('h3', 'Bristol', 'UK', 'h3@test.com', 'West', 'Little Street', 'BR11 2QQ'));
		hospitalsByName.put('h4',createHospital('h4', 'Paris', 'France', 'h4@test.com', 'Paris', 'Le Street', 'FR111'));
		insert hospitalsByName.values();

		// Create some surgeon details
		surgeonsByName = new Map<String, Contact>();
		surgeonsByName.put('s1',createSurgeon('Fred', 'S1', 'fred@test.com', 'Mr'));
		surgeonsByName.put('s2',createSurgeon('Bill', 'S2', 'bill@test.com', 'Mr'));
		surgeonsByName.put('s3',createSurgeon('Tedd', 'S3', 'tedd@test.com', 'Mr'));
		surgeonsByName.put('s4',createSurgeon('Mary', 'S4', 'mary@test.com', 'Mrs'));
		insert surgeonsByName.values();

	}

	/**
	 * @description Test that for a given object the update code reviews and cheanges the record
	 **/
	static testMethod void testUpdateNoChanges() {

		// Setup data
		init();

		// Create some surgeon in hospital records with correct values
		Map<String, Surgeon_in_Hospital__c> sihByName = new Map<String, Surgeon_in_Hospital__c>();
		sihByName.put('s1h1',createSurgeonInHospital(hospitalsByName.get('h1').Id, surgeonsByName.get('s1').Id, 'Fred', 'S1', 'London', 'UK', 'h1@test.com', 'h1', 'London', 'Big Street', 'RG11 2QQ', 'Mr', 'fred@test.com'));
		sihByName.put('s2h2',createSurgeonInHospital(hospitalsByName.get('h2').Id, surgeonsByName.get('s2').Id, 'Bill', 'S2', 'Leeds', 'UK', 'h2@test.com', 'h2', 'Yorkshire', 'Big Road', 'YO11 2QQ', 'Mr', 'bill@test.com'));
		sihByName.put('s3h3',createSurgeonInHospital(hospitalsByName.get('h3').Id, surgeonsByName.get('s3').Id, 'Tedd', 'S3', 'Bristol', 'UK', 'h3@test.com', 'h3', 'West', 'Little Street', 'BR11 2QQ', 'Mr', 'tedd@test.com'));
		sihByName.put('s4h4',createSurgeonInHospital(hospitalsByName.get('h4').Id, surgeonsByName.get('s4').Id, 'Mary', 'S4', 'Paris', 'France', 'h4@test.com', 'h4', 'Paris', 'Le Street', 'FR111', 'Mrs', 'mary@test.com'));
		insert sihByName.values();

		// Start the test
		Test.startTest();

		// Create a service object and process the tour optionals
		MCFormulaUpdateCheckService updateService = new MCFormulaUpdateCheckService();
		updateService.checkFormulaFields(sihByName.values(), 'Surgeon_in_Hospital__c');

		// Stop the test
		Test.stopTest();

		// Check that just two records were updated
		System.assertEquals(0, updateService.updateCount);

	}

	/**
	 * @description Test that for a given object the update code reviews and cheanges the record
	 **/
	static testMethod void testUpdateSuccess() {

		// Setup data
		init();

		// Create some surgeon in hospital records with corrent and incorrect values
		Map<String, Surgeon_in_Hospital__c> sihByName = new Map<String, Surgeon_in_Hospital__c>();
		sihByName.put('s1h1',createSurgeonInHospital(hospitalsByName.get('h1').Id, surgeonsByName.get('s1').Id, 'Fred', 'S1', 'London', 'UK', 'h1@test.com', 'h1', 'London', 'Big Street', 'RG11 2QQ', 'Mr', 'fred@test.com')); // All values are correct
		sihByName.put('s2h2',createSurgeonInHospital(hospitalsByName.get('h2').Id, surgeonsByName.get('s2').Id, null, null, null, null, null, null, null, null, null, null, null));
		sihByName.put('s3h3',createSurgeonInHospital(hospitalsByName.get('h3').Id, surgeonsByName.get('s3').Id, 'Teddy', 'S333', 'Cambridge', 'UK', 'h333@test.com', 'h3333', 'Cambridgshire', 'West Street', 'CA11 2QQ', 'Sir', 'teddy@test.com'));
		sihByName.put('s4h4',createSurgeonInHospital(hospitalsByName.get('h4').Id, surgeonsByName.get('s4').Id, 'Mary', 'S444', 'Berlin', 'Germany', 'h4@test.com', 'h4444', 'Paris', 'Le Street', 'FR111', 'Mrs', 'mary@test.com'));
		insert sihByName.values();

		// Start the test
		Test.startTest();

		// Create a service object and process the tour optionals
		MCFormulaUpdateCheckService updateService = new MCFormulaUpdateCheckService();
		updateService.checkFormulaFields(sihByName.values(), 'Surgeon_in_Hospital__c');

		// Stop the test
		Test.stopTest();

		// Check that just three records were updated
		System.assertEquals(3, updateService.updateCount);

		// Get the tour optionals and check that values have been updated
		List<Surgeon_in_Hospital__c> updatedSurgeonsInHospital = [SELECT Id, First_Name_Copy__c, Last_Name_Copy__c, Hospital_City1_Copy__c, Hospital_Country_Copy__c, Hospital_Email_Copy__c, Hospital_Name_Copy__c, Hospital_State1_Copy__c,
																	Hospital_Street_Copy__c, Hospital_Zip_Postcode_Copy__c, Salutation_Copy__c, Surgeon_Email_Copy__c
																	 FROM Surgeon_in_Hospital__c];
		for (Surgeon_in_Hospital__c sih : updatedSurgeonsInHospital) {
			if (sih.Id == sihByName.get('s1h1').Id) {
				// No changed should have happened so not tests here
			} else if (sih.Id == sihByName.get('s2h2').Id) {
				System.assertEquals('Bill',sih.First_Name_Copy__c);
				System.assertEquals('S2',sih.Last_Name_Copy__c);
				System.assertEquals('Leeds',sih.Hospital_City1_Copy__c);
				System.assertEquals('UK',sih.Hospital_Country_Copy__c);
				System.assertEquals('h2@test.com',sih.Hospital_Email_Copy__c);
				System.assertEquals('h2',sih.Hospital_Name_Copy__c);
				System.assertEquals('Yorkshire',sih.Hospital_State1_Copy__c);
				System.assertEquals('Big Road',sih.Hospital_Street_Copy__c);
				System.assertEquals('YO11 2QQ',sih.Hospital_Zip_Postcode_Copy__c);
				System.assertEquals('Mr',sih.Salutation_Copy__c);
				System.assertEquals('bill@test.com',sih.Surgeon_Email_Copy__c);

			} else if (sih.Id == sihByName.get('s3h3').Id) {
				System.assertEquals('Tedd',sih.First_Name_Copy__c);
				System.assertEquals('S3',sih.Last_Name_Copy__c);
				System.assertEquals('Bristol',sih.Hospital_City1_Copy__c);
				System.assertEquals('UK',sih.Hospital_Country_Copy__c);
				System.assertEquals('h3@test.com',sih.Hospital_Email_Copy__c);
				System.assertEquals('h3',sih.Hospital_Name_Copy__c);
				System.assertEquals('West',sih.Hospital_State1_Copy__c);
				System.assertEquals('Little Street',sih.Hospital_Street_Copy__c);
				System.assertEquals('BR11 2QQ',sih.Hospital_Zip_Postcode_Copy__c);
				System.assertEquals('Mr',sih.Salutation_Copy__c);
				System.assertEquals('tedd@test.com',sih.Surgeon_Email_Copy__c);
				
			} else if (sih.Id == sihByName.get('s4h4').Id) {
				System.assertEquals('Mary',sih.First_Name_Copy__c);
				System.assertEquals('S4',sih.Last_Name_Copy__c);
				System.assertEquals('Paris',sih.Hospital_City1_Copy__c);
				System.assertEquals('France',sih.Hospital_Country_Copy__c);
				System.assertEquals('h4@test.com',sih.Hospital_Email_Copy__c);
				System.assertEquals('h4',sih.Hospital_Name_Copy__c);
				System.assertEquals('Paris',sih.Hospital_State1_Copy__c);
				System.assertEquals('Le Street',sih.Hospital_Street_Copy__c);
				System.assertEquals('FR111',sih.Hospital_Zip_Postcode_Copy__c);
				System.assertEquals('Mrs',sih.Salutation_Copy__c);
				System.assertEquals('mary@test.com',sih.Surgeon_Email_Copy__c);
				
			} else {
				//System.assert(false, 'This Surgeon in Hospital ID is invalid : ' + sih);
			}
		}

	}

	/**
	 * @description Test that the batch job fires for a simple process
	 **/
	static testMethod void testBatchProcess() {

		// Setup data
		init();

		// Create some surgeon in hospital records with corrent and incorrect values
		Map<String, Surgeon_in_Hospital__c> sihByName = new Map<String, Surgeon_in_Hospital__c>();
		sihByName.put('s1h1',createSurgeonInHospital(hospitalsByName.get('h1').Id, surgeonsByName.get('s1').Id, 'Fred', 'S1', 'London', 'UK', 'h1@test.com', 'h1', 'London', 'Big Street', 'RG11 2QQ', 'Mr', 'fred@test.com')); // All values are correct
		sihByName.put('s2h2',createSurgeonInHospital(hospitalsByName.get('h2').Id, surgeonsByName.get('s2').Id, null, null, null, null, null, null, null, null, null, null, null));
		sihByName.put('s3h3',createSurgeonInHospital(hospitalsByName.get('h3').Id, surgeonsByName.get('s3').Id, 'Teddy', 'S333', 'Cambridge', 'UK', 'h333@test.com', 'h3333', 'Cambridgshire', 'West Street', 'CA11 2QQ', 'Sir', 'teddy@test.com'));
		sihByName.put('s4h4',createSurgeonInHospital(hospitalsByName.get('h4').Id, surgeonsByName.get('s4').Id, 'Mary', 'S444', 'Berlin', 'Germany', 'h4@test.com', 'h4444', 'Paris', 'Le Street', 'FR111', 'Mrs', 'mary@test.com'));
		insert sihByName.values();
        

		// Start the test
		Test.startTest();

		// Create a list of objects to process
		Set<String> objectNames = new Set<String>();
		objectNames.add('Surgeon_in_Hospital__c');

		// Start the batch for just this one object
		MCFormulaUpdateCheckBatch statBatch = new MCFormulaUpdateCheckBatch(objectNames);
       	ID batchId = Database.executeBatch(statBatch, 2000);     		

		// Stop the test
		Test.stopTest();

		// Get the tour optionals and check that values have been updated
		List<Surgeon_in_Hospital__c> updatedSurgeonsInHospital = [SELECT Id, First_Name_Copy__c, Last_Name_Copy__c, Hospital_City1_Copy__c, Hospital_Country_Copy__c, Hospital_Email_Copy__c, Hospital_Name_Copy__c, Hospital_State1_Copy__c,
																	Hospital_Street_Copy__c, Hospital_Zip_Postcode_Copy__c, Salutation_Copy__c, Surgeon_Email_Copy__c
																	 FROM Surgeon_in_Hospital__c];
        System.debug('sihByName-----> '+sihByName.values());
		for (Surgeon_in_Hospital__c sih : updatedSurgeonsInHospital) {
            System.debug('hos--------> '+sih);
			if (sih.Id == sihByName.get('s1h1').Id) {
				// No changed should have happened so not tests here
			} else if (sih.Id == sihByName.get('s2h2').Id) {
				System.assertEquals('Bill',sih.First_Name_Copy__c);
				System.assertEquals('S2',sih.Last_Name_Copy__c);
				System.assertEquals('Leeds',sih.Hospital_City1_Copy__c);
				System.assertEquals('UK',sih.Hospital_Country_Copy__c);
				System.assertEquals('h2@test.com',sih.Hospital_Email_Copy__c);
				System.assertEquals('h2',sih.Hospital_Name_Copy__c);
				System.assertEquals('Yorkshire',sih.Hospital_State1_Copy__c);
				System.assertEquals('Big Road',sih.Hospital_Street_Copy__c);
				System.assertEquals('YO11 2QQ',sih.Hospital_Zip_Postcode_Copy__c);
				System.assertEquals('Mr',sih.Salutation_Copy__c);
				System.assertEquals('bill@test.com',sih.Surgeon_Email_Copy__c);

			} else if (sih.Id == sihByName.get('s3h3').Id) {
				System.assertEquals('Tedd',sih.First_Name_Copy__c);
				System.assertEquals('S3',sih.Last_Name_Copy__c);
				System.assertEquals('Bristol',sih.Hospital_City1_Copy__c);
				System.assertEquals('UK',sih.Hospital_Country_Copy__c);
				System.assertEquals('h3@test.com',sih.Hospital_Email_Copy__c);
				System.assertEquals('h3',sih.Hospital_Name_Copy__c);
				System.assertEquals('West',sih.Hospital_State1_Copy__c);
				System.assertEquals('Little Street',sih.Hospital_Street_Copy__c);
				System.assertEquals('BR11 2QQ',sih.Hospital_Zip_Postcode_Copy__c);
				System.assertEquals('Mr',sih.Salutation_Copy__c);
				System.assertEquals('tedd@test.com',sih.Surgeon_Email_Copy__c);
				
			} else if (sih.Id == sihByName.get('s4h4').Id) {
				System.assertEquals('Mary',sih.First_Name_Copy__c);
				System.assertEquals('S4',sih.Last_Name_Copy__c);
				System.assertEquals('Paris',sih.Hospital_City1_Copy__c);
				System.assertEquals('France',sih.Hospital_Country_Copy__c);
				System.assertEquals('h4@test.com',sih.Hospital_Email_Copy__c);
				System.assertEquals('h4',sih.Hospital_Name_Copy__c);
				System.assertEquals('Paris',sih.Hospital_State1_Copy__c);
				System.assertEquals('Le Street',sih.Hospital_Street_Copy__c);
				System.assertEquals('FR111',sih.Hospital_Zip_Postcode_Copy__c);
				System.assertEquals('Mrs',sih.Salutation_Copy__c);
				System.assertEquals('mary@test.com',sih.Surgeon_Email_Copy__c);
				
			} else {
				//System.assert(false, 'This Surgeon in Hospital ID is invalid : ' + sih);  //This test fails due to different ids
			}
		}

	}

	/**
	 * @description Test updating two objects. NB This test us not applicable for this org
	 **/
	static testMethod void testMultiObjectUpdate() {

		// Setup data
		init();

		// Create some surgeon in hospital records with corrent and incorrect values
		Map<String, Surgeon_in_Hospital__c> sihByName = new Map<String, Surgeon_in_Hospital__c>();
		sihByName.put('s1h1',createSurgeonInHospital(hospitalsByName.get('h1').Id, surgeonsByName.get('s1').Id, 'Fred', 'S1', 'London', 'UK', 'h1@test.com', 'h1', 'London', 'Big Street', 'RG11 2QQ', 'Mr', 'fred@test.com')); // All values are correct
		sihByName.put('s2h2',createSurgeonInHospital(hospitalsByName.get('h2').Id, surgeonsByName.get('s2').Id, null, null, null, null, null, null, null, null, null, null, null));
		sihByName.put('s3h3',createSurgeonInHospital(hospitalsByName.get('h3').Id, surgeonsByName.get('s3').Id, 'Teddy', 'S333', 'Cambridge', 'UK', 'h333@test.com', 'h3333', 'Cambridgshire', 'West Street', 'CA11 2QQ', 'Sir', 'teddy@test.com'));
		sihByName.put('s4h4',createSurgeonInHospital(hospitalsByName.get('h4').Id, surgeonsByName.get('s4').Id, 'Mary', 'S444', 'Berlin', 'Germany', 'h4@test.com', 'h4444', 'Paris', 'Le Street', 'FR111', 'Mrs', 'mary@test.com'));
		insert sihByName.values();

		// Start the test
		Test.startTest();

		// Create a list of objects to process
		Set<String> objectNames = new Set<String>();
		objectNames.add('Surgeon_in_Hospital__c');
		objectNames.add('Contact');

		// Start the batch for just this one object
		MCFormulaUpdateCheckBatch statBatch = new MCFormulaUpdateCheckBatch(objectNames);
       	ID batchId = Database.executeBatch(statBatch, 2000);     		

		// Stop the test
		Test.stopTest();

		// Get the tour optionals and check that values have been updated
		List<Surgeon_in_Hospital__c> updatedSurgeonsInHospital = [SELECT Id, First_Name_Copy__c, Last_Name_Copy__c, Hospital_City1_Copy__c, Hospital_Country_Copy__c, Hospital_Email_Copy__c, Hospital_Name_Copy__c, Hospital_State1_Copy__c,
																	Hospital_Street_Copy__c, Hospital_Zip_Postcode_Copy__c, Salutation_Copy__c, Surgeon_Email_Copy__c
																	 FROM Surgeon_in_Hospital__c];
		for (Surgeon_in_Hospital__c sih : updatedSurgeonsInHospital) {
			if (sih.Id == sihByName.get('s1h1').Id) {
				// No changed should have happened so not tests here
			} else if (sih.Id == sihByName.get('s2h2').Id) {
				System.assertEquals('Bill',sih.First_Name_Copy__c);
				System.assertEquals('S2',sih.Last_Name_Copy__c);
				System.assertEquals('Leeds',sih.Hospital_City1_Copy__c);
				System.assertEquals('UK',sih.Hospital_Country_Copy__c);
				System.assertEquals('h2@test.com',sih.Hospital_Email_Copy__c);
				System.assertEquals('h2',sih.Hospital_Name_Copy__c);
				System.assertEquals('Yorkshire',sih.Hospital_State1_Copy__c);
				System.assertEquals('Big Road',sih.Hospital_Street_Copy__c);
				System.assertEquals('YO11 2QQ',sih.Hospital_Zip_Postcode_Copy__c);
				System.assertEquals('Mr',sih.Salutation_Copy__c);
				System.assertEquals('bill@test.com',sih.Surgeon_Email_Copy__c);

			} else if (sih.Id == sihByName.get('s3h3').Id) {
				System.assertEquals('Tedd',sih.First_Name_Copy__c);
				System.assertEquals('S3',sih.Last_Name_Copy__c);
				System.assertEquals('Bristol',sih.Hospital_City1_Copy__c);
				System.assertEquals('UK',sih.Hospital_Country_Copy__c);
				System.assertEquals('h3@test.com',sih.Hospital_Email_Copy__c);
				System.assertEquals('h3',sih.Hospital_Name_Copy__c);
				System.assertEquals('West',sih.Hospital_State1_Copy__c);
				System.assertEquals('Little Street',sih.Hospital_Street_Copy__c);
				System.assertEquals('BR11 2QQ',sih.Hospital_Zip_Postcode_Copy__c);
				System.assertEquals('Mr',sih.Salutation_Copy__c);
				System.assertEquals('tedd@test.com',sih.Surgeon_Email_Copy__c);
				
			} else if (sih.Id == sihByName.get('s4h4').Id) {
				System.assertEquals('Mary',sih.First_Name_Copy__c);
				System.assertEquals('S4',sih.Last_Name_Copy__c);
				System.assertEquals('Paris',sih.Hospital_City1_Copy__c);
				System.assertEquals('France',sih.Hospital_Country_Copy__c);
				System.assertEquals('h4@test.com',sih.Hospital_Email_Copy__c);
				System.assertEquals('h4',sih.Hospital_Name_Copy__c);
				System.assertEquals('Paris',sih.Hospital_State1_Copy__c);
				System.assertEquals('Le Street',sih.Hospital_Street_Copy__c);
				System.assertEquals('FR111',sih.Hospital_Zip_Postcode_Copy__c);
				System.assertEquals('Mrs',sih.Salutation_Copy__c);
				System.assertEquals('mary@test.com',sih.Surgeon_Email_Copy__c);
				
			} else {
				//System.assert(false, 'This Surgeon in Hospital ID is invalid : ' + sih);
			}
		}

		// NB Should be a test for the other object update,but there isn't tha scenario in this org


	}

	/**
	 * @description Test that a scheduled job can be created
	 **/
	static testMethod void testSchedule() {

		// Setup data
		init();

		// Start the test
		Test.startTest();

		// Create a list of objects to process
		Set<String> objectNames = new Set<String>();
		objectNames.add('Tour_Optional__c');

      	// Schedule the test job
      	String jobId = System.schedule('ScheduleApexClassTest','0 0 0 15 3 ? 2022', new MCFormulaUpdateCheckSchedulable());
         
      	// Get the information from the CronTrigger API object
      	CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];

      	// Verify the expressions are the same
      	System.assertEquals('0 0 0 15 3 ? 2022', ct.CronExpression);

      	// Verify the job has not run
      	System.assertEquals(0, ct.TimesTriggered);

      	// Verify the next time the job will run
      	System.assertEquals('2022-03-15 00:00:00', String.valueOf(ct.NextFireTime));
    
      	// Stop the test which will trigger the job
	    Test.stopTest();

	    // Unable to test update results since a batch called from the schedule wont be fired

	}

	/************************* PRIVATE METHODS ************************/
	private static Account createHospital(String name, String city, String country, String email, String state, String street, String postCode) {
		Account hospital = new Account();
		hospital.Name = name;
		hospital.RecordTypeId = hotelRecordTypeId;
		hospital.Customer_Address_City__c = city;
		hospital.Customer_Address_Country__c = country;
		hospital.Email_Address_For_Order_Form__c = email;
		hospital.Customer_Address_County__c = state;
		hospital.Customer_Address_Street__c = street;
		hospital.Customer_Address_Postcode__c = postcode;
		return hospital;
	}

	private static Contact createSurgeon(String firstName, String lastName, String email, String salutation) {
		Contact surgeon = new Contact();
		surgeon.FirstName = firstName;
		surgeon.LastName = lastName;
		surgeon.Email = email;
		surgeon.Salutation = salutation;
		return surgeon;
	}

	private static Surgeon_in_Hospital__c createSurgeonInHospital(Id hospitalId, Id surgeonId, String firstNameCopy, String lastNameCopy, String cityCopy, String countryCopy, String emailCopy, String nameCopy, String stateCopy, String streetCopy, String postcodeCopy, String salutationCopy, String surgeonEmailCopy) {
		Surgeon_in_Hospital__c sih = new Surgeon_in_Hospital__c();
		sih.Hospital__c = hospitalId;
		sih.Surgeon__c = surgeonId;
		sih.First_Name_Copy__c = firstNameCopy;
		sih.Last_Name_Copy__c = lastNameCopy;
		sih.Hospital_City1_Copy__c = cityCopy;
		sih.Hospital_Country_Copy__c = countryCopy;
		sih.Hospital_Email_Copy__c = emailCopy;
		sih.Hospital_Name_Copy__c = nameCopy;
		sih.Hospital_State1_Copy__c = stateCopy;
		sih.Hospital_Street_Copy__c = streetCopy;
		sih.Hospital_Zip_Postcode_Copy__c = postcodeCopy;
		sih.Salutation_Copy__c = salutationCopy;
		sih.Surgeon_Email_Copy__c = surgeonEmailCopy;
		return sih;
	}

}