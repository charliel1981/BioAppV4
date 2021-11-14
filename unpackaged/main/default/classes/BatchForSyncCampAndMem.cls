global class BatchForSyncCampAndMem implements Database.Batchable<sObject>{

   global Database.QueryLocator start(Database.BatchableContext BC)
   {
      return Database.getQueryLocator('select id,UserName,Email,Community_View__c from User where Community_View__c != null and IsActive  = true');
   }

   global void execute(Database.BatchableContext BC, List<User> UsersList)
   {
     if(UsersList != null && !UsersList.isEmpty())
     {
       Set<String> setUserEmails = new Set<String>();
       Map<String,List<User>> MapUserEmailWithCommunityViews = new Map<String,List<User>>();
       
       for(User obj:UsersList)
       {
       	 setUserEmails.add(obj.Email);
       	 
       	 if(MapUserEmailWithCommunityViews.get(obj.Community_View__c) != null)
       	 {
       	 	 List<user> userList = new List<user>();
       	 	 userList.addAll(MapUserEmailWithCommunityViews.get(obj.Community_View__c));
       	 	 userList.add(obj);
       	 	 MapUserEmailWithCommunityViews.put(obj.Community_View__c,userList);
       	 }else
       	 {
       	 	List<user> userList = new List<user>();
       	 	userList.add(obj);
       	 	MapUserEmailWithCommunityViews.put(obj.Community_View__c,userList);
       	 }
       }
       system.debug('===setUserEmails===>>'+setUserEmails);
       system.debug('===MapUserEmailWithCommunityViews===>>'+MapUserEmailWithCommunityViews);
       
       Map<String,Contact> MapEmailWithContact = new Map<String,Contact>();
       
       for(Contact con:[select id,Email from Contact where Email IN:setUserEmails and HasOptedOutOfEmail = false])
       {
     	  MapEmailWithContact.put(con.Email,con);
       }
       
       system.debug('===MapEmailWithContact===>>'+MapEmailWithContact);
       
       List<CampaignMember> ListCampMembersToInsert = new List<CampaignMember>();
       Map<String,Set<String>> mapMembersWithContactId = new Map<String,Set<String>>();
       
       for(Campaign campObj:[select id,Name,(Select CampaignId, ContactId, Status From CampaignMembers) from Campaign where Name IN:MapUserEmailWithCommunityViews.keySet()])
       {
         for(CampaignMember mem:campObj.CampaignMembers)
         {
         	if(mapMembersWithContactId.get(campObj.Name) != null)
         	  {
         	  	Set<String> SetOfMembers = new Set<String>();
         	  	SetOfMembers.addAll(mapMembersWithContactId.get(campObj.Name));
         	  	SetOfMembers.add(mem.ContactId);
         	  	mapMembersWithContactId.put(campObj.Name,SetOfMembers);
         	  }else
         	  {
         	  	Set<String> SetOfMembers = new Set<String>();
         	  	SetOfMembers.add(mem.ContactId);
         	  	mapMembersWithContactId.put(campObj.Name,SetOfMembers);
         	  }
         }	
       }
       
       for(Campaign campObj:[select id,Name from Campaign where Name IN:MapUserEmailWithCommunityViews.keySet()])
       {
       	 if(MapUserEmailWithCommunityViews.get(campObj.Name) != null)
       	 {
       	 	for(User usr:MapUserEmailWithCommunityViews.get(campObj.Name))
       	 	{
       	 		if(MapEmailWithContact.get(usr.Email) != null)
       	 		{
       	 			if( (mapMembersWithContactId.get(campObj.Name) == null || !mapMembersWithContactId.get(campObj.Name).Contains(MapEmailWithContact.get(usr.Email).id)))
       	 			{
	       	 			CampaignMember menberObj = new CampaignMember();
	       	 			menberObj.CampaignId = campObj.id;
	       	 			menberObj.ContactId = MapEmailWithContact.get(usr.Email).id;
	       	 			menberObj.Status = 'Sent';
	       	 			ListCampMembersToInsert.add(menberObj);
       	 			}
       	 		}
       	 	}
       	 }
       }
       
       system.debug('===ListCampMembersToInsert===>>'+ListCampMembersToInsert);
       if(!ListCampMembersToInsert.isEmpty())
       {
       	insert ListCampMembersToInsert;
       }
     }
   }

   global void finish(Database.BatchableContext BC)
   {
   	
   }
   
   
   
   
   
    static testMethod void myUnitTest() {
        // TO DO: implement unit test
        
         Profile p = [SELECT id from profile WHERE name = 'Standard User'];
         
         list<user> lstuser = new list<user>(); 
         User u = new User (lastname = 'testlast', alias = 'tst456', email = 'testgmail@yahoo.com',
         username = 'testhmaki@yahoo.com',profileid = p.Id, timezonesidkey = 'America/Chicago', 
         localesidkey = 'en_US', emailencodingkey = 'UTF-8', languagelocalekey = 'en_US',Community_View__c = 'TestView');
         //insert u;
                
         lstuser.add(u);
          
         insert lstuser;
          
         Account objAcc = new Account();
         objAcc.name = 'Test';
         objAcc.Update_date__c = system.today();
         insert objAcc;
         
         Contact objCon = new Contact();
         objCon.LastName = 'test';
         objCon.Email ='testgmail@yahoo.com';
         objCon.HasOptedOutOfEmail = true;
         insert objCon;
         
         Campaign objcam = new Campaign();
         objcam.Name = 'TestView';
       	 insert objcam;
       
         Test.startTest();
         
           BatchForSyncCampAndMem  objCom = new BatchForSyncCampAndMem ();
           Database.BatchableContext BC;
           objCom.start(BC);      
		   objCom.execute(BC,[select id,email,lastname,Community_View__c,userName from User where isActive = true limit 10]);
           objCom.finish(BC);
        
         
	      
          Test.stopTest();
        
    }
   
   
   
   
   
   
   
   
   
   
   
   
}