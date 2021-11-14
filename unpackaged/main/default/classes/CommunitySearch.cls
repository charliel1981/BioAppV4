public class CommunitySearch {
    
  @RemoteAction
  public static List<Community_Items__c> searchItems(String query) {
    // get current user
    String userId = UserInfo.getUserId();
    String userProfile = [SELECT Community_View__c FROM User WHERE Id = :userId].Community_View__c;
    // run search query
    query = '*' + query + '*';
    List<List<Community_Items__c>> items = [FIND :query IN ALL FIELDS RETURNING Community_Items__c (Id)];
    List<Community_Items__c> results = items[0];
    // get result ids
    Set<Id> resultIds = new Set<Id>();
    for (Integer i = 0; i < results.size(); i++) {
      resultIds.add(results[i].Id);
    }
    // query full item details checking user profile
    List<Community_Items__c> fullResults = [
      SELECT Id, Name, Description__c, Title__c, Type__c, Video_URL__c, RecordType.Name, 
        Brainshark_URL__c, Subtype__c, ALT_Tag__c,
        (SELECT Id, Button_Link_URL__c, Button_Link_Text__c 
         FROM Community_Item_Permissions_Links__r
         WHERE Profile__c = :userProfile
        )
      FROM Community_Items__c
      WHERE Id IN :resultIds
    ];
    return fullResults;
  }

}