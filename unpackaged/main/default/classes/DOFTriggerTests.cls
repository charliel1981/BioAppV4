/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class DOFTriggerTests {

    static testMethod void myUnitTest() {
    	Test.startTest();
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


        SendDOFEmailController.dofList = new List<Dof__c>{newDof};
        SendDOFEmailController.sendEmail(new Set<Id>{newDof.Id});


        System.assertNotEquals(null, newDof.Id, 'user not created');
        System.assertEquals(1,[SELECT count() FROM Document WHERE FolderId =: DOFHelper.getFolderId()]);


        delete newDof;
        Test.stopTest();


        
    } // end method


    
} // end class