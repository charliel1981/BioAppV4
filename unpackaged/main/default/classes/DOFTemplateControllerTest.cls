/**
*	@description : Unit tests for DOFTemplateController
**/
@isTest(seeAllData=false)
private with sharing class DOFTemplateControllerTest {

	@testSetup
	private static void setupTestData(){
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
        
        DOF__c newDof = new DOF__c(Hospital__c = hospital.Id,Surgeon__c = surgeon.Id,Signature_Capture__c=EncodingUtil.base64Encode(Blob.valueOf('data:image/png;base64,test')));
        insert newDof;
        newDof.Send_Process_Has_Completed__c=true;
        newDof.Dist_Email__c  = 'raj@ceterna.com';
        newDof.Bio_Email_To_Send_To__c   = 'raj@ceterna.com';
        newDof.Created_By_Email__c   = 'raj@ceterna.com';
        newDof.Hospital_Email_Address__c   = 'raj@ceterna.com';
        update newDof;
	}
	
	/**
	*	@description : Test Method to get the base url
	**/
	@isTest
	static void getSalesforceBaseUrl(){
		System.assertNotEquals(null,new DOFTemplateController().getSalesforceBaseUrl());
	}

	/**
	*	@description : Test Method to get the base url
	**/
	@isTest
	static void test_fetchDof(){
		Test.startTest();

		// query dof 
		List<Dof__c> dofList = [SELECT Id FROM Dof__c LIMIT 1];

		DOFTemplateController cls = new DOFTemplateController();
		
		// check asserts
		System.assertEquals(null,cls.dof,'DOF should be null.');

		// set dof id
		cls.dofId = dofList[0].Id;

		// check asserts
		System.assertNotEquals(null,cls.dof,'DOF should not be null.');

		System.assertEquals(0,SchemaHelper.getAllFieldsForSObject('Test').size(),'Field list should be zero.');

		Test.stopTest();
	}
}