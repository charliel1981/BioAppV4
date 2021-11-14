@isTest
private class BatchToRemoveInactCampMemTest 
{
    static testMethod void testBatch() 
	{
		 Profile p = [SELECT id from profile WHERE name = 'System Administrator'];
		 
		 User u2 = new User (lastname = 'testlast2', alias = 'tst987', email = 'testgmail467@yahoo.com',
         username = 'testuserggggggggg123@yahoo.com.dev',profileid = p.Id, timezonesidkey = 'America/Chicago', 
         localesidkey = 'en_US', emailencodingkey = 'UTF-8', languagelocalekey = 'en_US',Community_View__c = 'TestView', IsActive = true);                
         insert u2;
         
		 Account objAcc = new Account();
         objAcc.name = 'Test';
         objAcc.Update_date__c = system.today();
         insert objAcc;
         
         Contact objCon = new Contact();
         objCon.AccountId = objAcc.Id;
         objCon.LastName = 'test';
         objCon.Email ='testgmail@yahoo.com';
         objCon.HasOptedOutOfEmail = true;
         
         Contact objCon1 = new Contact();
         objCon1.AccountId = objAcc.Id;
         objCon1.LastName = 'test';
         objCon1.Email ='testgmail123@yahoo.com';
         objCon1.HasOptedOutOfEmail = true;
         insert new List<Contact>{objCon, objCon1};
         
         System.runAs(u2)
         {
         	 Profile p1 = [SELECT id from profile WHERE name = 'Biocomposites COMMUNITY USER'];
         	 list<user> lstuser = new list<user>(); 
         	 User u = new User (lastname = 'testlast', alias = 'tst456', email = 'testgmail@yahoo.com',
	         username = 'testuserxkxjjxkxjjxjx@yahoo.com.dev', ProfileId = p1.Id, timezonesidkey = 'America/Chicago', 
	         localesidkey = 'en_US', emailencodingkey = 'UTF-8', languagelocalekey = 'en_US',Community_View__c = 'TestView', IsActive = true, ContactId = objCon.Id);
	         User u1 = new User (lastname = 'testlast1', alias = 'tst567', email = 'testgmail123@yahoo.com',
	         username = 'testusereeeeeeeee123@yahoo.com.dev', ProfileId = p1.Id, timezonesidkey = 'America/Chicago', 
	         localesidkey = 'en_US', emailencodingkey = 'UTF-8', languagelocalekey = 'en_US',Community_View__c = 'TestView', IsActive = false, ContactId = objCon1.Id);                   
	         lstuser.add(u);
	         lstuser.add(u1);
	         insert lstuser;	         
         }
      
         Campaign objcam = new Campaign( Name = 'TestView');         
       	 insert objcam;
       	 
       	 CampaignMember campMem1 = new CampaignMember(CampaignId = objcam.Id, ContactId = objCon.Id, Status = 'Sent');
       	 CampaignMember campMem2 = new CampaignMember(CampaignId = objcam.Id, ContactId = objCon1.Id, Status = 'Sent');
       	 insert new List<CampaignMember>{campMem1, campMem2};
       	 
       	 Test.startTest();       	 
       	 	Database.executeBatch(new BatchToRemoveInactCampMem());
       	 Test.stopTest();
       	 
       	 List<CampaignMember> campaignMemRecords = [Select id, ContactId, CampaignId from CampaignMember];
       	 System.assertEquals(1, campaignMemRecords.size());     	 
	}  
	
	static testMethod void testBatch1() 
	{
		 Profile p = [SELECT id from profile WHERE name = 'System Administrator'];
		 
		 User u2 = new User (lastname = 'testlast2', alias = 'tst987', email = 'testgmail467@yahoo.com',
         username = 'testuserggggggggg123@yahoo.com.dev',profileid = p.Id, timezonesidkey = 'America/Chicago', 
         localesidkey = 'en_US', emailencodingkey = 'UTF-8', languagelocalekey = 'en_US',Community_View__c = 'TestView', IsActive = true);                
         insert u2;
         
		 Account objAcc = new Account();
         objAcc.name = 'Test';
         objAcc.Update_date__c = system.today();
         insert objAcc;
         
         Contact objCon = new Contact();
         objCon.AccountId = objAcc.Id;
         objCon.LastName = 'test';
         objCon.Email ='testgmail@yahoo.com';
         objCon.HasOptedOutOfEmail = true;
         
         Contact objCon1 = new Contact();
         objCon1.AccountId = objAcc.Id;
         objCon1.LastName = 'test';
         objCon1.Email ='testgmail123@yahoo.com';
         objCon1.HasOptedOutOfEmail = true;
         insert new List<Contact>{objCon, objCon1};
         
         Profile p1 = [SELECT id from profile WHERE name = 'Biocomposites COMMUNITY USER'];
     	 list<user> lstuser = new list<user>(); 
     	 User u = new User (lastname = 'testlast', alias = 'tst456', email = 'testgmail@yahoo.com',
         username = 'testuserxkxjjxkxjjxjx@yahoo.com.dev', ProfileId = p1.Id, timezonesidkey = 'America/Chicago', 
         localesidkey = 'en_US', emailencodingkey = 'UTF-8', languagelocalekey = 'en_US',Community_View__c = 'TestView', IsActive = true, ContactId = objCon.Id);
         User u1 = new User (lastname = 'testlast1', alias = 'tst567', email = 'testgmail123@yahoo.com',
         username = 'testusereeeeeeeee123@yahoo.com.dev', ProfileId = p1.Id, timezonesidkey = 'America/Chicago', 
         localesidkey = 'en_US', emailencodingkey = 'UTF-8', languagelocalekey = 'en_US',Community_View__c = 'TestView', IsActive = true, ContactId = objCon1.Id);                   
         lstuser.add(u);
         lstuser.add(u1);
         
         System.runAs(u2)
         {
	         insert lstuser;	         
         }
      
         Campaign objcam = new Campaign( Name = 'TestView'); 
         Campaign objcam1 = new Campaign( Name = 'TestViewDifferent');         
       	 insert new List<Campaign>{objcam, objcam1};
       	 
       	 CampaignMember campMem1 = new CampaignMember(CampaignId = objcam.Id, ContactId = objCon.Id, Status = 'Sent');
       	 CampaignMember campMem2 = new CampaignMember(CampaignId = objcam.Id, ContactId = objCon1.Id, Status = 'Sent');
       	 insert new List<CampaignMember>{campMem1, campMem2};
       	 
       	 
       	 System.runAs(u2)
         {
         	u1.Community_View__c = 'TestViewDifferent';
         	update u1;
         }
       	 
       	 Test.startTest();       	 
       	 	Database.executeBatch(new BatchToRemoveInactCampMem());
       	 Test.stopTest();
       	 
       	 List<CampaignMember> campaignMemRecords = [Select id, ContactId, CampaignId from CampaignMember];
       	 System.assertEquals(2, campaignMemRecords.size());     	 
	}
	
	static testMethod void testBatchScheduler() 
	{
		 Profile p = [SELECT id from profile WHERE name = 'System Administrator'];
		 
		 User u2 = new User (lastname = 'testlast2', alias = 'tst987', email = 'testgmail467@yahoo.com',
         username = 'testuserggggggggg123@yahoo.com.dev',profileid = p.Id, timezonesidkey = 'America/Chicago', 
         localesidkey = 'en_US', emailencodingkey = 'UTF-8', languagelocalekey = 'en_US',Community_View__c = 'TestView', IsActive = true);                
         insert u2;
         
		 Account objAcc = new Account();
         objAcc.name = 'Test';
         objAcc.Update_date__c = system.today();
         insert objAcc;
         
         Contact objCon = new Contact();
         objCon.AccountId = objAcc.Id;
         objCon.LastName = 'test';
         objCon.Email ='testgmail@yahoo.com';
         objCon.HasOptedOutOfEmail = true;
         
         Contact objCon1 = new Contact();
         objCon1.AccountId = objAcc.Id;
         objCon1.LastName = 'test';
         objCon1.Email ='testgmail123@yahoo.com';
         objCon1.HasOptedOutOfEmail = true;
         insert new List<Contact>{objCon, objCon1};
         
         System.runAs(u2)
         {
         	 Profile p1 = [SELECT id from profile WHERE name = 'Biocomposites COMMUNITY USER'];
         	 list<user> lstuser = new list<user>(); 
         	 User u = new User (lastname = 'testlast', alias = 'tst456', email = 'testgmail@yahoo.com',
	         username = 'testuserxkxjjxkxjjxjx@yahoo.com.dev', ProfileId = p1.Id, timezonesidkey = 'America/Chicago', 
	         localesidkey = 'en_US', emailencodingkey = 'UTF-8', languagelocalekey = 'en_US',Community_View__c = 'TestView', IsActive = true, ContactId = objCon.Id);
	         User u1 = new User (lastname = 'testlast1', alias = 'tst567', email = 'testgmail123@yahoo.com',
	         username = 'testusereeeeeeeee123@yahoo.com.dev', ProfileId = p1.Id, timezonesidkey = 'America/Chicago', 
	         localesidkey = 'en_US', emailencodingkey = 'UTF-8', languagelocalekey = 'en_US',Community_View__c = 'TestView', IsActive = false, ContactId = objCon1.Id);                   
	         lstuser.add(u);
	         lstuser.add(u1);
	         insert lstuser;	         
         }
      
         Campaign objcam = new Campaign( Name = 'TestView');         
       	 insert objcam;
       	 
       	 CampaignMember campMem1 = new CampaignMember(CampaignId = objcam.Id, ContactId = objCon.Id, Status = 'Sent');
       	 CampaignMember campMem2 = new CampaignMember(CampaignId = objcam.Id, ContactId = objCon1.Id, Status = 'Sent');
       	 insert new List<CampaignMember>{campMem1, campMem2};
       	 
       	 Test.startTest();       	 
       	 	BatchToRemoveInactCampMemScheduler.batchScheduler();
       	 Test.stopTest(); 	 
	}
}