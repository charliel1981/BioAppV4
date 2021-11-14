/**
*	@description : Unit tests for DOF Helper
**/
@isTest(seeAllData=false)
private with sharing class DOFHelperTest {
	
	@isTest
	static void upsertSignatureInDocuments(){
		Test.startTest();
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

        // Call DOF Helper 
        DOFHelper.upsertSignatureInDocuments(new List<DOF__c>{newDof},null,true);
        System.assertEquals(2,[SELECT count() FROM Document WHERE FolderId =: DOFHelper.getFolderId()]);

		Test.stopTest();
	}

	@isTest
	static void deleteDocuments(){
		Test.startTest();
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

        // Call DOF Helper 
        DOFHelper.upsertSignatureInDocuments(new List<DOF__c>{newDof},null,true);
        System.assertEquals(2,[SELECT count() FROM Document WHERE FolderId =: DOFHelper.getFolderId()]);

        // Call dof helper to delete
        DOFHelper.deleteDocuments(new List<Dof__c>{newDof});

        System.assertEquals(1,[SELECT count() FROM Document WHERE FolderId =: DOFHelper.getFolderId()]);


		Test.stopTest();
	}
}