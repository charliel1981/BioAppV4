/*This test class is written for code coverage as 
 * DML cannot be done on UserTerritory object.
 */
@isTest
private class BeforeInsertUpdateTrgTest 
{
    static testMethod void updateTerritoriesOnUser() 
    {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User userObj = new User();
        userObj.FirstName ='User';
        userObj.LastName = 'Test';
        userObj.Alias = 'uttu';
        userObj.Email = 'utest@company123.com';
        userObj.Username = 'utest@company123.com';
        userObj.ProfileId = p.Id;
        userObj.TimeZoneSidKey = 'America/Chicago';
        userObj.LocaleSidKey = 'en_US';
        userObj.EmailEncodingKey = 'UTF-8';
        userObj.LanguageLocaleKey = 'en_US';
        insert userObj;
        
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId()];  
        
        
       
        User u = [Select Id, Territories__c from User where Id = :userObj.Id];
        
        Test.startTest();
          userObj.Territories__c = '';
          update userObj;
        Test.stopTest();
    }
 
    
}