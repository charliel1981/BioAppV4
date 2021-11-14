global class MobileRefreshRestrictionV2i3B implements mobilecaddy1.RestrictionInterface003_mc {

  // Restriction clause used in both methods
  private final static String RESTRICTION = ' (    (RecordType.Name = \'Profile Menu Item\'' +
                                            '        AND Profile__c = :userCommunityView' +
                                            '        AND Status__c = \'Active\'' +
                                            '        AND Menu_Item__c IN :menusToInclude)' +
                                            '    OR (RecordType.Name IN (\'Product\', \'Record Type Reference\', \'Lot Numbers\')' +
                                            '        AND Status__c = \'Active\')  ) ';

  global String returnRestrictedIds(String jsonParams) {

    // Deserialise the incoming parameters
    Map<String,Object> int2ParamMap = (Map<String,Object>)JSON.deserializeUntyped(jsonParams);

    // Retrieve the mobile table record.  This map will look like this example:
    // {Id=a0W6E000000CYO2UAO, RecordTypeId=0126E0000004n78QAA, attributes={type=mobilecaddy1__Mobile_Table__c, url=/services/data/v41.0/sobjects/mobilecaddy1__Mobile_Table__c/a0W6E000000CYO2UAO},
    // mobilecaddy1__Boolean_Restriction_Field__c=mobilecaddy1__MC12001R_0001__c, mobilecaddy1__Conflict_Resolution_Logging__c=On - Log per Record,
    // mobilecaddy1__Create_Failure_Behaviour__c=Per Record Failure (delete device records), mobilecaddy1__Create_Failure_Logging__c=On - Log per Record,
    // mobilecaddy1__Device_Create_Failure_Behaviour__c=Retain/Retry, mobilecaddy1__Device_Hard_Deleted_Behaviour__c=Delete, mobilecaddy1__Device_Soft_Deleted_Behaviour__c=Delete, ...}
    Map<String,Object> recNameValuePairsMap = (Map<String,Object>)int2ParamMap.get('mobileTableRec');

    // Are we installing MobileCaddy or is this a subsequent refresh?
    Boolean isInstall = (Boolean)int2ParamMap.get('isInstall');

    // This is automatically set to the epoch (1st Jan 1970) for initial refreshes and
    // non paging refreshes (which don't use it) and to the last refresh date time when
    // subsequent paging refreshes.  The developer does not need to worry about this and
    // should merely use it as shown in the query below
    Long refreshDatetimeEpoch = (Long)int2ParamMap.get('refreshDatetime');
    Datetime refreshDatetime = Datetime.newInstance(refreshDatetimeEpoch);

    // Obtain the maximum number of records we are allowed to query n this class we must not query more than this.
    // This value comes through from settings on the Mobile Table which may be tuned according to actual data volumes.
    Integer refreshRecordLimit = (Integer)recNameValuePairsMap.get('mobilecaddy1__Refresh_Record_Limit__c');

    // We have a different config value for refresh limit on an initial install (when MC is doing more work!)
    if (isInstall) refreshRecordLimit = (Integer)recNameValuePairsMap.get('mobilecaddy1__Refresh_Record_Limit_Install__c');

    // Set of ids that have already been processed
    Set<Id> idsAlreadyProcessed = objectToIdSet((List<Object>)int2ParamMap.get('idsAlreadyProcessed'));

    // Pull out the ids already on the device
    Set<Id> idsOnDevice = objectToIdSet((List<Object>)int2ParamMap.get('idsOnDevice'));

    // Get the sObject name for our query (could hard code but shows we have it mobile table) and enables
    // us to reuse this class across multiple objects
    String sObjectName = (String)recNameValuePairsMap.get('mobilecaddy1__SObject_Name__c');
    if (Test.isRunningTest()) sObjectName = 'Mobile_Refresh__c';

    // Get community profile name from the user's User record
    User user = [SELECT Community_View__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    String userCommunityView = user.Community_View__c;

    // Get the V002 menus to include in the query
    Set<Id> menusToInclude = getMenusToInclude();

    // Build the soql to select records from Mobile_Refresh__c - based on the user's 'community profile' on User record
    String queryString = 'SELECT Id, SystemModstamp ' +
                        ' FROM ' + sObjectName +
                        ' WHERE ' + RESTRICTION +
                        ' AND (NOT (Id IN :idsAlreadyProcessed)) AND ((SystemModstamp > :refreshDatetime) OR (Id NOT IN :idsOnDevice)) LIMIT ' + refreshRecordLimit;

    // Query in records and ignore those already process
    Map<Id,SObject> restMap = new Map<Id,SObject>(Database.query(queryString));

    // If we have hit our refresh record limit then we must assume there are more batches equired.  Tell MobileCaddy.
    Boolean moreBatches;
    if (restMap.size() == refreshRecordLimit) {
      moreBatches = true;
    }
    else {
      moreBatches = false;
    }

    // Create our sysmodstamp and id lists
    List<Datetime> systemModstampList = new List<Datetime>();
    List<Id> idList = new List<Id>();
    for (SObject obj : restMap.values()) {
      systemModstampList.add((Datetime)obj.get('SystemModstamp'));
      idList.add((Id)obj.get('Id'));
    }

    // Now create the response map
    Map<String,Object> responseMap = new Map<String,Object>();
    responseMap.put('sysmodstamps',systemModstampList);
    responseMap.put('ids',idList);
    responseMap.put('moreBatches',moreBatches);
    return JSON.serialize(responseMap);
  }

  // This method is given the full list of ids that are sat on the device.  This method has to
  // tell MobileCaddy if those ids are still available for the restriction that this class is providing.
  global String idsStillValid(String jsonParams) {

    // Deserialise the incoming parameters
    Map<String,Object> int2ParamMap = (Map<String,Object>)JSON.deserializeUntyped(jsonParams);

    // Get the mobile table record.  We need the Refresh Record Limit.  The developer may need other
    // fields off mobile table for their own restriction/logic too
    Map<String,Object> recNameValuePairsMap = (Map<String,Object>)int2ParamMap.get('mobileTableRec');

    // Get set of ids that are on the device
    List<Object> idsOnDeviceList = (List<Object>)int2ParamMap.get('idsOnDevice');
    Set<Id> idsOnDeviceSet = new Set<Id>();
    for (Object idOnDevice : idsOnDeviceList) {
      idsOnDeviceSet.add((Id)idOnDevice);
    }

    // Get the larger limit (the install one)
    Integer refreshRecordLimit = (Integer)recNameValuePairsMap.get('mobilecaddy1__Refresh_Record_Limit_Install__c');

    // Here get the sobject name.  The dev may have hardcoded the object name and may not need this
    String sObjectName = (String)recNameValuePairsMap.get('mobilecaddy1__SObject_Name__c');
    if (Test.isRunningTest()) sObjectName = 'Mobile_Refresh__c';

    // Get community profile name from the user's User record
    User user = [SELECT Community_View__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    String userCommunityView = user.Community_View__c;

    // Get the V002 menus to include in the query
    Set<Id> menusToInclude = getMenusToInclude();

    // Build the soql to select records from Mobile_Refresh__c - based on the user's 'community profile' on User record
    // Note that we restrict on the ids being passed up and limit by the larger limit
    // In English we see if the records on the device are still present and still respect the
    // restriction while not blowing the governor limits.
    String queryString = 'SELECT Id ' +
                        ' FROM ' + sObjectName +
                        ' WHERE ' + RESTRICTION +
                        ' AND Id IN :idsOnDeviceSet LIMIT ' + refreshRecordLimit;

    // Issue the query
    Map<Id,SObject> restMap = new Map<Id,SObject>(Database.query(queryString));

    // MobileCaddy needs to know if we hit the limit and therefore could not check all the given ids
    Boolean moreBatches;
    if (restMap.size() == refreshRecordLimit) {
      moreBatches = true;
    }
    else {
      moreBatches = false;
    }

    // Prepare the response
    Map<String,Object> responseMap = new Map<String,Object>();

    // Send the ids still valid back to MobileCaddy
    responseMap.put('stillValidIds',restMap.keySet());

    // Tell MobileCaddy there are more batches
    responseMap.put('moreBatches',moreBatches);
    return JSON.serialize(responseMap);
  } // end isStillValid method

  // Convenience methods

  private static Set<Id> objectToIdSet(List<Object> objList) {
    Set<Id> retIds = new Set<Id>();
    if (objList != null) {
      for (Object idOnDevice : objList) {
        retIds.add((Id)idOnDevice);
      }
    }
    return retIds;
  }

  private static Set<Id> getMenusToInclude() {
    Set<Id> menusToInclude = new Set<Id>();
    // Get all menus
    List<Mobile_Refresh__c> menus = [SELECT Id, Available_in_Version__c
                                     FROM Mobile_Refresh__c
                                     WHERE RecordType.Name IN ('Menu Item', 'Sub Menu Item')
                                     AND Status__c = 'Active'];

    // Determine whether the menus are applicable for the version
    for (Mobile_Refresh__c menu : menus) {
        Boolean includeMenu = false;
        if (menu.Available_in_Version__c != null) {
            if (menu.Available_in_Version__c.contains('V002')) {
                includeMenu = true;
            }
        }
        if (includeMenu) {
            menusToInclude.add(menu.Id);
        }
    }

    return menusToInclude;
  }

}