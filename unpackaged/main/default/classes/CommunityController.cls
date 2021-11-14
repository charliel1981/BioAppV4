//The class is global to be accessable by Salesforce1 for mobile app.
global class CommunityController 
{
  public final static String featuredtype = 'Featured Item';
  public final static String publicationType = 'Publication Library';
  
  public CommunityController() {}
    
    //common method to get the community items.
    public static List<Community_Items__c> getCommunityItems(String commType, Integer num, Integer offset)
    {

     //line 14 to line 29 was added to solve the permission issue for featured items type
     //This method could have been refactored to query parent from child to achieve the results, in which case we should have to refactor most the controller.Due to time constraint
     //to resolve this issue line 14 to line 29 has been added. 
      String userCommnityView = '';
      List<Id> communityIds = new List<Id>();
      List<Community_Items__c> communityList = new List<Community_Items__c>();
      User currentUser = [Select id, Community_View__c from User where Id = :UserInfo.getUserId() limit 1];


      if(currentUser.Community_View__c != null && currentUser.Community_View__c != '')
           userCommnityView = currentUser.Community_View__c;

     List<Community_Item_Permission_Link__c> commPermssionLinkRecords = [Select Community_Item__c From Community_Item_Permission_Link__c 
                    Where Community_Item__r.Type__c = :commType and Profile__c=:userCommnityView];

     for(Community_Item_Permission_Link__c cp : commPermssionLinkRecords)
     {
        communityIds.add(cp.Community_Item__c);
     }
      
      if(commType != null && commType != '' && communityIds!=null && communityIds.size() > 0)
      {
        String query = 'Select Id, DO_NOT_SHOW__c, Title__c, ALT_Tag__c, Sort_Number__c, Type__c, New_Item__c ,Content__c, Video_URL__c';
        query += ' ,Abstract__c, Author__c, Description__c, Marketing_Resources_URL__c, Our_View__c, Publishers__c, Subtype__c, Use_this_as_featured_item__c';
        query += ' ,Brainshark_URL__c, Text_For_Brainshark_Tile__c, URL_For_Image__c, Video_thumbnail_URL__c, Video_Server_URL__c, Featured_Item_Type__c , URL_for_Document__c '; 
        query += ' , (Select Name, Community_Item__c, Profile__c, Button_Link_URL__c From Community_Item_Permissions_Links__r )';
        
        query += ' from Community_Items__c';
        query += ' where Id In :communityIds and DO_NOT_SHOW__c = false and ( Type__c = \''+commType+'\''; 
        
        if(commType.equalsIgnoreCase(featuredtype))
          query += ' OR Use_this_as_featured_item__c != null';
          
        query += ' )';
          
        query += ' order by Sort_Number__c';
        
        if(num > 0 && num < 90000)
          query += ' limit '+num;
                
        communityList = Database.query(query);      
      }                                
      return communityList;                    
     }
     
     //This method gets 'Topic of Interest' community items for home page.
     public static List<CommunityItemWrapper> getTOIForHomePage(String commType, Integer num, Integer offset)
     {
       String userCommnityView = '';
       List<CommunityItemWrapper> itemWrapperList = new List<CommunityItemWrapper>();
       List<Community_Item_Permission_Link__c> commPermItemList= new List<Community_Item_Permission_Link__c>();
       
       if(commType != null && commType != '')
      {       
         User currentUser = [Select id, Community_View__c from User where Id = :UserInfo.getUserId() limit 1];
         if(currentUser.Community_View__c != null && currentUser.Community_View__c != '')
           userCommnityView = currentUser.Community_View__c;
         
         String query = 'Select c.Community_Item__r.DO_NOT_SHOW__c, c.Community_Item__r.Title__c, c.Community_Item__r.ALT_Tag__c, c.Community_Item__r.Sort_Number__c, c.Community_Item__r.Type__c';       
          query += ' ,c.Community_Item__r.New_Item__c, c.Community_Item__r.Content__c, c.Community_Item__r.Video_URL__c, c.Community_Item__c, c.Community_Item__r.Brainshark_URL__c';
          query += ' ,c.Community_Item__r.Description__c, c.Community_Item__r.Marketing_Resources_URL__c, c.Community_Item__r.Subtype__c, c.Community_Item__r.Use_this_as_featured_item__c';
          query += ' ,c.Community_Item__r.Text_For_Brainshark_Tile__c, c.Community_Item__r.URL_For_Image__c, c.Community_Item__r.Video_thumbnail_URL__c, c.Community_Item__r.Video_Server_URL__c';
         query += ' From Community_Item_Permission_Link__c c ';
          query += ' where c.Profile__c = :userCommnityView and c.Community_Item__r.DO_NOT_SHOW__c = false and c.Community_Item__r.Type__c = :commType';
          query += ' order by c.Community_Item__r.Sort_Number__c limit :num';
         
         commPermItemList = Database.query(query);
         
         if(commPermItemList != null && commPermItemList.size() > 0)
         {
           for(Community_Item_Permission_Link__c commPermItem : commPermItemList)
           {
             CommunityItemWrapper itemWrapSObj = new CommunityItemWrapper();
            itemWrapSObj.recordId = commPermItem.Community_Item__c;
            if(commPermItem.Community_Item__r.Title__c != null) itemWrapSObj.title = commPermItem.Community_Item__r.Title__c;
            if(commPermItem.Community_Item__r.ALT_Tag__c != null) itemWrapSObj.altTag = commPermItem.Community_Item__r.ALT_Tag__c;
            if(commPermItem.Community_Item__r.Type__c != null) itemWrapSObj.commType = commPermItem.Community_Item__r.Type__c;
            itemWrapSObj.newItem = commPermItem.Community_Item__r.New_Item__c;
            if(commPermItem.Community_Item__r.Sort_Number__c != null) itemWrapSObj.sortNumber = commPermItem.Community_Item__r.Sort_Number__c;
            if(commPermItem.Community_Item__r.Content__c != null) itemWrapSObj.content = commPermItem.Community_Item__r.Content__c;
            if(commPermItem.Community_Item__r.Video_URL__c != null) itemWrapSObj.videoURL = commPermItem.Community_Item__r.Video_URL__c;
            if(commPermItem.Community_Item__r.Brainshark_URL__c != null) itemWrapSObj.brainsharkURL = commPermItem.Community_Item__r.Brainshark_URL__c;
            if(commPermItem.Community_Item__r.URL_For_Image__c != null) itemWrapSObj.urlForImage = commPermItem.Community_Item__r.URL_For_Image__c;          
            if(commPermItem.Community_Item__r.Description__c != null) itemWrapSObj.description = commPermItem.Community_Item__r.Description__c;
            if(commPermItem.Community_Item__r.Marketing_Resources_URL__c != null) itemWrapSObj.marketingResourceURL = commPermItem.Community_Item__r.Marketing_Resources_URL__c;
            if(commPermItem.Community_Item__r.Use_this_as_featured_item__c != null) itemWrapSObj.useThisasFeturedItem = commPermItem.Community_Item__r.Use_this_as_featured_item__c;
            if(commPermItem.Community_Item__r.Subtype__c != null) itemWrapSObj.subType = commPermItem.Community_Item__r.Subtype__c;
            if(commPermItem.Community_Item__r.Text_For_Brainshark_Tile__c != null) itemWrapSObj.textForBrainsharkTitle = commPermItem.Community_Item__r.Text_For_Brainshark_Tile__c;
            if(commPermItem.Community_Item__r.Video_thumbnail_URL__c != null) itemWrapSObj.videoThumbnailURL = commPermItem.Community_Item__r.Video_thumbnail_URL__c;
            if(commPermItem.Community_Item__r.Video_Server_URL__c != null) itemWrapSObj.videoServerURL = commPermItem.Community_Item__r.Video_Server_URL__c;
            itemWrapperList.add(itemWrapSObj);
           }
         }
      }
      return itemWrapperList;       
     }
     
     //This method gets all the publication lib records per page.
     public static List<CommunityItemWrapper> getPublicationLibItemRecords(String commType, Integer limitNo, Integer offset)
     {
       String userCommnityView = '';
       List<CommunityItemWrapper> itemWrapperList = new List<CommunityItemWrapper>();
       List<Community_Item_Permission_Link__c> commPermItemList= new List<Community_Item_Permission_Link__c>();
       
       User currentUser = [Select id, Community_View__c from User where Id = :UserInfo.getUserId() limit 1];
       if(currentUser.Community_View__c != null && currentUser.Community_View__c != '')
         userCommnityView = currentUser.Community_View__c;
       
       String query = 'Select c.Community_Item__r.DO_NOT_SHOW__c, c.Community_Item__r.Publishers__c, c.Community_Item__r.Our_View__c, c.Community_Item__r.Abstract__c, c.Community_Item__r.Author__c,';       
        query += ' c.Community_Item__r.Title__c, c.Community_Item__r.Type__c, c.Community_Item__r.Name, c.Community_Item__c';
       query += ' From Community_Item_Permission_Link__c c ';
        query += ' where c.Profile__c = :userCommnityView and c.Community_Item__r.DO_NOT_SHOW__c = false and c.Community_Item__r.Type__c = :commType';
        query += ' order by c.Community_Item__r.Sort_Number__c limit :limitNo OFFSET :offset';
       
       commPermItemList = Database.query(query);
       
       if(commPermItemList != null && commPermItemList.size() > 0)
       {
         for(Community_Item_Permission_Link__c commPermItem : commPermItemList)
         {
           CommunityItemWrapper itemWrapSObj = new CommunityItemWrapper();
          itemWrapSObj.recordId = commPermItem.Community_Item__c;
          if(commPermItem.Community_Item__r.Title__c != null) itemWrapSObj.title = commPermItem.Community_Item__r.Title__c;
          if(commPermItem.Community_Item__r.Abstract__c != null) itemWrapSObj.abstractPub = commPermItem.Community_Item__r.Abstract__c;
          if(commPermItem.Community_Item__r.Author__c != null) itemWrapSObj.authorPub = commPermItem.Community_Item__r.Author__c;
          if(commPermItem.Community_Item__r.Our_View__c != null) itemWrapSObj.ourView = commPermItem.Community_Item__r.Our_View__c;
          if(commPermItem.Community_Item__r.Publishers__c != null) itemWrapSObj.publishers = commPermItem.Community_Item__r.Publishers__c;
                    
          itemWrapperList.add(itemWrapSObj);
         }        
       }
       
       return itemWrapperList;
     }
    
    
    //Common method to build the data to pass it to front end.
    public static List<CommunityItemWrapper> buildWrapperList(List<Community_Items__c> commList, Map<Id, String> commPermLinkToCommIdMap, String commType)
    {
      List<CommunityItemWrapper> itemWrapperList = new List<CommunityItemWrapper>();
      if(commList != null && commList.size() > 0)
      {
        for(Community_Items__c commItem : commList)
        {
          if(commType == publicationType)
          {
            CommunityItemWrapper itemWrapSObj = new CommunityItemWrapper();
            itemWrapSObj.recordId = commItem.Id;
            if(commItem.Title__c != null) itemWrapSObj.title = commItem.Title__c;
            if(commItem.Abstract__c != null) itemWrapSObj.abstractPub = commItem.Abstract__c;
            if(commItem.Author__c != null) itemWrapSObj.authorPub = commItem.Author__c;
            if(commItem.Our_View__c != null) itemWrapSObj.ourView = commItem.Our_View__c;
            if(commItem.Publishers__c != null) itemWrapSObj.publishers = commItem.Publishers__c;
                    
            itemWrapperList.add(itemWrapSObj);
          }
          else
          {
            CommunityItemWrapper itemWrapSObj = new CommunityItemWrapper();
            itemWrapSObj.recordId = commItem.Id;
            if(commItem.Title__c != null) itemWrapSObj.title = commItem.Title__c;
            if(commItem.ALT_Tag__c != null) itemWrapSObj.altTag = commItem.ALT_Tag__c;
            if(commItem.Type__c != null) itemWrapSObj.commType = commItem.Type__c;
            itemWrapSObj.newItem = commItem.New_Item__c;
            if(commItem.Sort_Number__c != null) itemWrapSObj.sortNumber = commItem.Sort_Number__c;
            if(commItem.Content__c != null) itemWrapSObj.content = commItem.Content__c;
            if(commItem.Video_URL__c != null) itemWrapSObj.videoURL = commItem.Video_URL__c;
            //if(commItem.Brainshark_URL__c != null) itemWrapSObj.brainsharkURL = commItem.Brainshark_URL__c;
            if(commItem.URL_For_Image__c != null) itemWrapSObj.urlForImage = commItem.URL_For_Image__c;          
            if(commItem.Abstract__c != null) itemWrapSObj.abstractPub = commItem.Abstract__c;
            if(commItem.Author__c != null) itemWrapSObj.authorPub = commItem.Author__c;
            if(commItem.Description__c != null) itemWrapSObj.description = commItem.Description__c;
            if(commItem.Marketing_Resources_URL__c != null) itemWrapSObj.marketingResourceURL = commItem.Marketing_Resources_URL__c;
            if(commItem.Our_View__c != null) itemWrapSObj.ourView = commItem.Our_View__c;
            if(commItem.Publishers__c != null) itemWrapSObj.publishers = commItem.Publishers__c;
            if(commItem.Use_this_as_featured_item__c != null) itemWrapSObj.useThisasFeturedItem = commItem.Use_this_as_featured_item__c;
            if(commItem.Subtype__c != null) itemWrapSObj.subType = commItem.Subtype__c;
            if(commItem.Text_For_Brainshark_Tile__c != null) itemWrapSObj.textForBrainsharkTitle = commItem.Text_For_Brainshark_Tile__c;
            if(commItem.Video_thumbnail_URL__c != null) itemWrapSObj.videoThumbnailURL = commItem.Video_thumbnail_URL__c;
                    
                    if(commType == featuredtype && commItem.Featured_Item_Type__c  == 'Other')
                    {
                       if(commItem.URL_for_Document__c  != null) itemWrapSObj.urlForDocument = commItem.URL_for_Document__c ;                       
                    }
                    else
                    {
                        if(commItem.Brainshark_URL__c != null) itemWrapSObj.brainsharkURL = commItem.Brainshark_URL__c;
                    }
            
            if(commPermLinkToCommIdMap != null && commPermLinkToCommIdMap.size() > 0 && commPermLinkToCommIdMap.containsKey(commItem.Id))
            {
              if(commPermLinkToCommIdMap.get(commItem.Id) != null) itemWrapSObj.buttonLinkURL = commPermLinkToCommIdMap.get(commItem.Id);
            }          
            itemWrapperList.add(itemWrapSObj);
          }
        }        
      }
      return itemWrapperList;
    }
    
    @RemoteAction
    global static List<CommunityItemWrapper> getCommunityItemRecords(String commType, Integer num)
    {
      if(commType == 'Topic of Interest / Notices' && num == 5)
        return getTOIForHomePage(commType, num, 0);
      else
        return getCommunityItemRecordsByCommType(commType, num, 0);
    }
    
    @RemoteAction
    global static List<CommunityItemWrapper> getPublisherLibRecords(String commType, Integer limitPub, Integer offset)
    {
      return getPublicationLibItemRecords(commType, limitPub, offset);
    }
    
    //The below method gets all the community items and builds the list of wrapper data.
    public static List<CommunityItemWrapper> getCommunityItemRecordsByCommType(String commType, Integer num, Integer offset)
    {
      List<Community_Items__c> permCommunityList = new List<Community_Items__c>();
      Map<Id, String> commPermLinkToCommIdMap = new Map<Id, String>();
      
      User currentUser = [Select id, Community_View__c from User where Id = :UserInfo.getUserId() limit 1];
            
      List<Community_Items__c> communityList = getCommunityItems(commType, num, offset);
      
        for(Community_Items__c commItemSObj : communityList)
      {
        for(Community_Item_Permission_Link__c commLink:commItemSObj.Community_Item_Permissions_Links__r)
        {
          if((currentUser != null) && (commLink.Profile__c != null) && (currentUser.Community_View__c != null) && (currentUser.Community_View__c.toLowerCase() == commLink.Profile__c.toLowerCase()))
          {
            permCommunityList.add(commItemSObj);
            
            if(commLink.Button_Link_URL__c != null && commLink.Button_Link_URL__c != '')
              commPermLinkToCommIdMap.put(commItemSObj.Id, commLink.Button_Link_URL__c);
          }
        }
      }
      
      return buildWrapperList(permCommunityList, commPermLinkToCommIdMap, commType);
    }
    
    @RemoteAction
    global static String getLogoURLForUser()
    {
      String logoURL = '';
      User currentUser = [Select id, Community_View__c from User where Id = :UserInfo.getUserId() limit 1];
      Id recordTypeId = [Select Id from RecordType where SObjectType='Community_Items__c' and DeveloperName='Logo'].Id;
      
      if(currentUser!= null && currentUser.Community_View__c != null && recordTypeId != null)
      {
        List<Community_Items__c> commLogoItems = [Select Id, Profile__c, URL_For_Image__c 
                              from Community_Items__c 
                              where RecordTypeId=:recordTypeId and Profile__c=:currentUser.Community_View__c];
                            
        if(commLogoItems != null && commLogoItems.size() > 0)
        {
          logoURL = commLogoItems[0].URL_For_Image__c;
        }
      }
      return logoURL;
    }
    
    @RemoteAction
    global static Map<String, String> getColorCodes()
    {
      Map<String, String> typeColorCodeMap = new Map<String, String>();
      
      for(CommunityColorMapWithType__c custcolors : CommunityColorMapWithType__c.getAll().values())
      {
        typeColorCodeMap.put(custcolors.Type__c +'-'+custcolors.SubType__c, custcolors.Color_code__c);
      }
      return typeColorCodeMap;      
    }
    
    @RemoteAction
    global static Boolean checkCommunityItemExists(String commType)
    {
      Integer numberOfRecords = getCountOfRecordsByCommType(commType);
      
      if(numberOfRecords > 0)      
        return true;
      else
        return false;
    }
    
    //this method returns the total community item records per community type
    public static Integer getCountOfRecordsByCommType(String commType)
    {
      User currentUser = [Select id, Community_View__c from User where Id = :UserInfo.getUserId() limit 1];
      Integer numberOfRecords = 0;
      
      if(currentUser != null && currentUser.Community_View__c != null)
      {
        List<AggregateResult> countRecordsResult = [Select count(Id) num From Community_Item_Permission_Link__c Where Community_Item__r.Type__c = :commType and Profile__c=:currentUser.Community_View__c ];
        
        if(countRecordsResult != null && countRecordsResult.size() > 0)
        {
          numberOfRecords = (Integer)countRecordsResult[0].get('num');
        }
      }
      return numberOfRecords;
    }
    
    @RemoteAction
    global static Integer getPublisherTotalItems()
    {
      return getCountOfRecordsByCommType(publicationType);
    }
    
    //for searching publiction lib records based on keywords.
    
    @RemoteAction
    global static List<CommunityItemWrapper> searchPublications(List<String> keywordList)
    {
      String queryString = '';
      List<List<SObject>> resultsListOfListCommItem = null;
      List<Community_Items__c> resultList = new List<Community_Items__c>();
      Map<Id, Community_Items__c> commIdstoItemMap = new Map<Id, Community_Items__c>();
      List<CommunityItemWrapper> returnSearchResults = new List<CommunityItemWrapper>();
      User currentUser = [Select id, Community_View__c from User where Id = :UserInfo.getUserId() limit 1];
      
      for(Integer i=0;i < keywordList.size(); i++)
      {
        if(i == 0)        
          queryString = keywordList[i];
        else        
          queryString += ' OR '+keywordList[i];
      }
      
      if(queryString != '')
      {
        String escapedQueryStr = escapeSOSLTerm(queryString);
      
      String query = 'Find {'+escapedQueryStr+'} IN ALL FIELDS RETURNING Community_Items__c (Abstract__c, Title__c, Publishers__c , Author__c, Our_View__c  WHERE Type__c = :publicationType and DO_NOT_SHOW__c = false)';
      resultsListOfListCommItem = search.query(query);
      }
      
      if(resultsListOfListCommItem != null && resultsListOfListCommItem.size() > 0)
      {
        resultList = resultsListOfListCommItem[0];
      }
      
      for(Community_Items__c commItem : resultList)
      {
        commIdstoItemMap.put(commItem.Id, commItem);
      }
      
      if(commIdstoItemMap != null && commIdstoItemMap.size() > 0)
      {
        List<Community_Items__c> perCommItems = new List<Community_Items__c>();
        List<Community_Item_Permission_Link__c> commPermssionLinkRecords = [Select Community_Item__c From Community_Item_Permission_Link__c Where Community_Item__r.Type__c = :publicationType and Profile__c=:currentUser.Community_View__c and Community_Item__c IN :commIdstoItemMap.keyset()];
        for(Community_Item_Permission_Link__c commLink : commPermssionLinkRecords)
        {
          Community_Items__c perCommItem = commIdstoItemMap.get(commLink.Community_Item__c);
          perCommItems.add(perCommItem);          
        }
        returnSearchResults = buildWrapperList(perCommItems, null, publicationType);
      }
      return returnSearchResults;      
    }
    
    @RemoteAction
    global static void createCommunityStatRemote(String commId)
    {
        createCommunityStat(commId);
    }
    
    @RemoteAction
    global static List<Community_Items__c> searchCommunityItems(String query) 
    {
       return CommunitySearch.searchItems(query);
    }
    
    @future
    global static void createCommunityStat(String commId)
    {
        if(commId != null && commId != '')
        {
            try
            {
                Community_Stat__c comState = new Community_Stat__c();
              comState.User__c = UserInfo.getUserId();
              comState.Community_Item__c = commId;
              insert comState;
            }
            catch(Exception e)
            {
                System.debug('exception while saving community stat: '+e);
            }
        }
    }
    
    //this method returns escaped string for special characters.
    public static String escapeSOSLTerm(String term) 
    {
      final String specialChars = '& | ! ( ) { } [ ] ^ " ~ * ? : \' - £ $ @ ; + = % #';
  
      String cleansedTerm = term.replaceAll('\\\\', '');
      for (String sc: specialChars.split(' ')) {
          cleansedTerm = cleansedTerm.replaceAll('\\' + sc, '\\\\' + sc);
      }
      return cleansedTerm;
  }
}