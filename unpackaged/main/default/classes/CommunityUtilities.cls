public class CommunityUtilities 
{
	public static Community_Items__c createTopicOfInterestCommunityItem(String title, String content)
	{
		Id recordTypeId = [Select Id from RecordType where SObjectType='Community_Items__c' and DeveloperName='Topics_Of_Interest'].Id;
		Community_Items__c toiRecord = new Community_Items__c(Type__c='Topic of Interest / Notices', 
        														RecordTypeId = recordTypeId,
        														Title__c =  title,
        														Content__c = content,
        														ALT_Tag__c = 'sample text',
        														Sort_Number__c = 1,
        														Text_For_Brainshark_Tile__c = 'brainshark text',
        														URL_For_Image__c = 'https://biocomposites.force.com/servlet/servlet.ImageServer?id=015U0000003Dual&oid=00DU0000000Levb',
        														Video_Server_URL__c = 'https://biocomposites.force.com/servlet/servlet.ImageServer?id=015U0000003Dual&oid=00DU0000000Levb',
        														Video_thumbnail_URL__c = 'https://biocomposites.force.com/servlet/servlet.ImageServer?id=015U0000003Dual&oid=00DU0000000Levb',
        														Video_URL__c = 'https://biocomposites.force.com/servlet/servlet.ImageServer?id=015U0000003Dual&oid=00DU0000000Levb',
        														Description__c = 'Test description',
        														Subtype__c = '',
        														Marketing_Resources_URL__c = 'https://biocomposites.force.com/servlet/servlet.ImageServer?id=015U0000003Dual&oid=00DU0000000Levb'
        														);
        return toiRecord;														
	}
	
	public static Community_Item_Permission_Link__c createPermissionLink(String commId, String buttonURL)
	{
		User currentUser = [Select id, Community_View__c from User where Id = :UserInfo.getUserId() limit 1];
		Community_Item_Permission_Link__c commLink = new Community_Item_Permission_Link__c(Community_Item__c = commId, Profile__c = currentUser.Community_View__c);
		if(buttonURL != '')
		{
			commLink.Button_Link_URL__c = buttonURL;
		}
		return commLink;
	}
	
	public static Community_Items__c createPublishersLibCommunityItem(String title, String authorPub, String ourView, String publishers, String abstractPub)
	{
		Id recordTypeId = [Select Id from RecordType where SObjectType='Community_Items__c' and DeveloperName='Publication_Library'].Id;
		Community_Items__c pubLibRecord = new Community_Items__c(Type__c='Publication Library', 
        														RecordTypeId = recordTypeId,
        														Title__c =  title,
        														Author__c = authorPub,
        														Our_View__c = ourView,
        														Publishers__c = publishers,
        														Abstract__c = abstractPub        														
        														);
        return pubLibRecord;														
	}
	
	public static Community_Items__c createInternalOnlyCommunityItem(String title, String altTag)
	{
		Id recordTypeId = [Select Id from RecordType where SObjectType='Community_Items__c' and DeveloperName='Left_Panel'].Id;
		Community_Items__c internalRecord = new Community_Items__c(Type__c='Internal only', 
        														RecordTypeId = recordTypeId,
        														Title__c =  title,
        													    ALT_Tag__c = altTag   														
        														);
        return internalRecord;														
	}
}