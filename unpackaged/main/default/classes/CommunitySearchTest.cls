@IsTest
public class CommunitySearchTest {
    
  @IsTest
  public static void testSearchItems() {
    // add item
    Community_Items__c testItem = new Community_Items__c();
    String key = 'test_me_abc_123';
    testItem.Title__c = key;
    testItem.Content__c = 'Content ' + key;
    testItem.Description__c = 'Description ' + key;
    testItem.Type__c = 'Featured Item';
    testItem.Featured_Item_Type__c = 'Other';
    insert testItem;
    // add link
    String userId = UserInfo.getUserId();
    String userProfile = [SELECT Community_View__c FROM User WHERE Id = :userId].Community_View__c;
    Community_Item_Permission_Link__c testLink = new Community_Item_Permission_Link__c();
    testLink.Profile__c = userProfile;
    testLink.Community_Item__c = testItem.Id;
    insert testLink;
    // check search
    Test.startTest();
    List<Community_Items__c> results = CommunitySearch.searchItems(key);
    Test.stopTest();
  }

}