/*
Author      : Uday/Ankush
Dat         : 10-April-2015
Description : Batch to create campaigns based on Users "Communitt View" fields data.
*/
   global class BatchToCreateCampaignsFromCommunityViews implements Database.Batchable<sObject>
   {

   global Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator('select id from User where isActive = true limit 1');
   }

   global void execute(Database.BatchableContext BC, List<sObject> scope)
   { 
       Set<String> setCommunityViews = new Set<String>();
       
       Schema.DescribeFieldResult fieldResult = User.Community_View__c.getDescribe();
	   List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
	    
	   for( Schema.PicklistEntry f : ple)
	   {
	      setCommunityViews.add(string.valueOf(f.getValue()));
	   }       
       
       Map<String,Campaign> setCampaignNames = new Map<String,Campaign>();
       for(Campaign campObj:[select id,Name from Campaign where Name IN:setCommunityViews])
       {
         setCampaignNames.put(campObj.Name,campObj);        	
       }
         
       system.debug('===setCampaignNames====>>'+setCampaignNames);
       system.debug('===setCommunityViews====>>'+setCommunityViews);
        
       List<String> listCampaigns = new List<String>();
       listCampaigns.addAll(setCommunityViews);
       
       List<Campaign> CampaignsToInsert = new List<Campaign>();
       for(String str : listCampaigns)
       {
         if(setCampaignNames.get(str) != null)
       	 {
       	 	setCampaignNames.get(str).IsActive = true;
       	 	setCampaignNames.get(str).Standard_User_Profile__c = true; //  change on 29-4-2015 - prasannanjaneyulu
       	 	CampaignsToInsert.add(setCampaignNames.get(str));
       	 }
       	 else
       	 {
       	 	Campaign campObj = new Campaign();
       	 	campObj.Name = str;
       	 	//campObj.OwnerId = obj.Id;
       	 	campObj.IsActive = true;//
       	 	//campObj.Status = 'Sent';
       	 	campObj.Type = 'Hub Push';
       	 	campObj.Standard_User_Profile__c = true; //  change on 29-4-2015 - prasannanjaneyulu
       	 	CampaignsToInsert.add(campObj);
       	 }
       }
       
       
       system.debug('===CampaignsToInsert====>>'+CampaignsToInsert);
       if(!CampaignsToInsert.isEmpty())
       {
       	upsert CampaignsToInsert;
       }  
   }

   global void finish(Database.BatchableContext BC)
   {
   	BatchForSyncCampAndMem bb = new BatchForSyncCampAndMem();
   	Database.executeBatch(bb);
   }
}