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
@isTest(seeAllData = true)
private class Test_BatchToCreateCampaignsFromCommunity {

    static testMethod void myUnitTest() {
        // TO DO: implement unit test
          
         
          list<user> lstuser = new list<user>(); 
          Map<Id,Profile> profileIds = new Map<id,profile>([SELECT Id,UserLicenseId FROM Profile where UserLicenseId  in (SELECT Id FROM UserLicense where name ='Salesforce')]);

         List<user> standardProfileUsers = [select id,UserName,Email,Community_View__c from user where profileId in:profileIds.Keyset() and Community_View__c != null and isActive =true limit 180];
         Campaign objcam = new Campaign();
         objcam.Name = standardProfileUsers[0].Community_View__c;
       	 insert objcam;
       	 
       	 Campaign objcam1 = new Campaign();
         objcam1.Name = standardProfileUsers[1].Community_View__c;
       	 insert objcam1;
       	
         
         Test.startTest();
           
         BatchToCreateCampaignsFromCommunityViews bb = new BatchToCreateCampaignsFromCommunityViews();
         Database.Batchablecontext BC;
         bb.start(BC);
         bb.execute(BC, [select id from user limit 1]);
         bb.finish(BC);
         
         schedule_BatchToCreateCampaignsFromCommu.start();
         
         Test.stopTest();
        
    }
}