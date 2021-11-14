@isTest
private class ContentItemRestrictionTest {

    @isTest static void testValidTestingDynamicSOQL() {
      // Create Content Item record
      Content_Item__c ci = new Content_Item__c();
      ci.Status__c = 'Active';
      ci.Available_in_Version__c = 'V001;V002';
      insert ci;
      System.assertNotEquals(null, ci.Id, 'Content Item not created');

      String userName = 'testAdmin@testorg.com';

      // Get profile and create user record
      String profileName = 'System Administrator';
      Profile p = [SELECT Id FROM Profile WHERE Name = :profileName];
      System.assertNotEquals(null, p.Id, profileName + ' profile not found');

      User u = new User(Alias='aucalias', Email='test@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Tester', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId=p.Id,
        TimeZoneSidKey='America/Los_Angeles', UserName=userName);

      u.Community_View__c = 'System Administrator';
      insert u;
      System.assertNotEquals(null, u.Id, 'User not created');

      // Create Dynamic SOQL in Mobile Refresh
      Mobile_Refresh__c mr = new Mobile_Refresh__c();
      mr.Name__c = userName;
      mr.Status__c = 'Active';
      mr.Object_Reference__c = 'Content_Item__c';
      mr.Dynamic_SOQL__c = 'SELECT Id FROM Content_Item__c WHERE Status__c = \'Active\' AND Available_in_Version__c INCLUDES (\'V001\')';
      insert mr;
      System.assertNotEquals(null, mr.Id, 'Mobile Refresh not created');

      System.runAs(u) {
        ContentItemRestriction restriction = new ContentItemRestriction();
        Set<id> ids = restriction.returnRestrictedIds('');
      }
    }

    @isTest static void testInvalidTestingDynamicSOQL() {
      String userName = 'testAdmin@testorg.com';

      // Get profile and create user record
      String profileName = 'System Administrator';
      Profile p = [SELECT Id FROM Profile WHERE Name = :profileName];
      System.assertNotEquals(null, p.Id, profileName + ' profile not found');

      User u = new User(Alias='aucalias', Email='test@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Tester', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId=p.Id,
        TimeZoneSidKey='America/Los_Angeles', UserName=userName);

      u.Community_View__c = 'System Administrator';
      insert u;
      System.assertNotEquals(null, u.Id, 'User not created');

      // Create Dynamic SOQL (invalid) in Mobile Refresh
      Mobile_Refresh__c mr = new Mobile_Refresh__c();
      mr.Name__c = userName;
      mr.Status__c = 'Active';
      mr.Object_Reference__c = 'Content_Item__c';
      mr.Dynamic_SOQL__c = 'SELECT ???invalid??? FROM Content_Item__c WHERE Status__c = \'Active\'';
      insert mr;
      System.assertNotEquals(null, mr.Id, 'Mobile Refresh not created');

      System.runAs(u) {
        ContentItemRestriction restriction = new ContentItemRestriction();
        Set<id> ids = restriction.returnRestrictedIds('');
      }
    }

    @isTest static void testDefaultDynamicSOQL() {
      // Create Content Item record
      Content_Item__c ci = new Content_Item__c();
      ci.Status__c = 'Active';
      ci.Available_in_Version__c = 'V001;V002';
      insert ci;
      System.assertNotEquals(null, ci.Id, 'Content Item not created');

      ContentItemRestriction restriction = new ContentItemRestriction();
      Set<id> ids = restriction.returnRestrictedIds('');
    }

}