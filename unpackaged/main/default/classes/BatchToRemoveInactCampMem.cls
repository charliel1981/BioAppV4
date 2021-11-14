/*
* This batch removes the inactive campaign members from a campaign
* Also clones and deletes the campaign members whose campaign name and user's community view do not match.
*/
global class BatchToRemoveInactCampMem implements Database.Batchable<sObject>
{
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
    	String query = 'Select CampaignId, Campaign.Name, ContactId, Id, Name, Status From CampaignMember';
    	return Database.getQueryLocator(query);
   	}
   	
   global void execute(Database.BatchableContext BC, List<CampaignMember> campMembers)
   {
   		//map is used to store campaign member contact id to its campaign members which will be used to delete inactive members
   		Map<Id, List<CampaignMember>> campMemContactIdtoCampaignMap = new Map<Id, List<CampaignMember>>();
   		for(CampaignMember campMem : campMembers)
   		{
   			if(!campMemContactIdtoCampaignMap.containsKey(campMem.ContactId))
   			{
   				campMemContactIdtoCampaignMap.put(campMem.ContactId, new List<CampaignMember>{campMem});
   			}
   			else
   			{
   				if(campMemContactIdtoCampaignMap.get(campMem.ContactId) != null)
   					campMemContactIdtoCampaignMap.get(campMem.ContactId).add(campMem);  
   				else
   				 	campMemContactIdtoCampaignMap.put(campMem.ContactId, new List<CampaignMember>{campMem});				
   			} 
   		}
   		   		
   		List<CampaignMember> deleteCampaignMembers = new List<CampaignMember>();  //list of campaign members for deletion
   		Set<String> userCommunityViews = new Set<String>();  //list of user's community view
   		Set<Id> contactIds = new Set<Id>();  //list of user's contact ids
   		Map<Id, String> userContactIdToCommunityViewMap = new Map<Id, String>();  //map to store user's contact id to communnity view
   		if(!campMemContactIdtoCampaignMap.isEmpty())
   		{
   			
   			List<User> userRecords = [Select Id, Name, IsActive, ContactId, Community_View__c, Contact_ID_For_batch__c from User where Contact_ID_For_batch__c In :campMemContactIdtoCampaignMap.keySet()];
   			for(User user : userRecords)
   			{
   				if(user.IsActive == false)
   				{
   					deleteCampaignMembers.addAll(campMemContactIdtoCampaignMap.get(user.Contact_ID_For_batch__c)); //in active campaign members for deletion.
   				}
   				else
   				{
   					contactIds.add(user.ContactId);
   					userCommunityViews.add(user.Community_View__c);  //list of user's community view
   					userContactIdToCommunityViewMap.put(user.ContactId, user.Community_View__c);
   				}
   			}
   		}
   		   		
   		//get all the campaign's whose name is same as user's community view.
   		Map<String, Id> campNameToCampIdMap = new Map<String, Id>();
   		if(!userCommunityViews.isEmpty())
   		{
   			List<Campaign> campaignList = [Select Id, Name from Campaign where Name In :userCommunityViews];
   			for(Campaign campaign : campaignList)
   			{
   				campNameToCampIdMap.put(campaign.Name, campaign.Id);
   			}
   		}
   		   		
   		List<CampaignMember> newCampaignMemList = new List<CampaignMember>();   		
   		for(CampaignMember campMem : campMembers)
   		{
   			//check to see if campaign name of a campaign member is different to user's community view associated to the member.
   			if(campMem.Campaign.Name != null
   			&& campMem.ContactId != null && !contactIds.isEmpty() && contactIds.contains(campMem.ContactId)
   			&& !userContactIdToCommunityViewMap.isEmpty() && (campMem.Campaign.Name != userContactIdToCommunityViewMap.get(campMem.ContactId))
   			)
   			{   				
   				//if its differenet then clone and delete the old member.   				
   				Id campId = campNameToCampIdMap.get(userContactIdToCommunityViewMap.get(campMem.ContactId));
   				if(campId != null)
   				{
	   				CampaignMember cloneMember = campMem.clone(false, true);   	//cannot reparent the campaign member as the campaign id of campaign member is not updateable.			
	   				cloneMember.CampaignId = campId;
	   				newCampaignMemList.add(cloneMember);
	   				deleteCampaignMembers.add(campMem);
   				}
   			}
   		}
   		
   		if(!newCampaignMemList.isEmpty())  insert newCampaignMemList;
   		if(!deleteCampaignMembers.isEmpty())  delete deleteCampaignMembers;    		
   }
   
   global void finish(Database.BatchableContext BC)
   {   	
   }
}