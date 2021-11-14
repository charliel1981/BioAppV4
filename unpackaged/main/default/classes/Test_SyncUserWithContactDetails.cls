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
private class Test_SyncUserWithContactDetails {

    static testMethod void myUnitTest() 
    {
        User u;
        Account a;  
        Contact con;    
        
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        
        System.runAs ( thisUser ) 
        {
            Profile p = [select id from profile where name='Biocomposites COMMUNITY USER'];
                
            a = new Account(Name='Testperson');
            insert a;
            
              con = new Contact();
              con.FirstName = 'test FName';
              con.LastName = 'test LName';
              con.Email = 'test@test.com';
              con.AccountId = a.id;  
              con.Department = 'Management';
              con.Job_Title__c = 'CEO';  
              insert con;
              
              u = new User(alias = 'standt', email='standarduser@testorg.com', 
                emailencodingkey='UTF-8', lastname='Testing', 
                languagelocalekey='en_US', 
                localesidkey='en_US', profileid = p.Id,
                timezonesidkey='America/Los_Angeles', 
                username='standarduser@testorg.com',ContactId = con.id);
        }
        
        System.runAs(u) 
        {
           con.Job_Title__c = 'Managing Director';
           update con;  
        }
    }
}