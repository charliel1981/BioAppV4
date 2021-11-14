/***
 * Author : Uday/ Prasannanjaneyulu 
 * Date:  20-MAR-2015
 * Description : 
***/ 
 
global with sharing class EmailToComunityTypeCon {
    
    WebService static string SendNotification(string strID){

      if(strID != '' && strID != null ){
             Community_Items__c    objCom = [select id,Name,Title__c,Type__c,ALT_Tag__c,Brainshark_9_Digit_Number__c,recordtypeid from Community_Items__c where id =: strID limit 1];
              map<string,string> mapProfile = new map<string,string>();
              for(CustomProfilePermissions__c objPro : CustomProfilePermissions__c.getAll().values()){
                  mapProfile.put(objPro.Name,objPro.Name);
              }
                 system.debug('mapProfile::::'+mapProfile);
                 //Profile ProfileName = [select id,Name from profile where id = :userinfo.getProfileId()limit 1];
                 string str = UserInfo.getUserName();
                 //system.debug('ProfileName ::::'+ProfileName );
                      if(mapProfile.get(str) != UserInfo.getUserName()){
                            return 'Fail';
                      }else if(objCom.Type__c  == null){
       
                               return'TypeNO';
                      }else if(objCom.Type__c  != null){
                              Map<string,string> MapTemp = new map<string,string>();
                                 for(ComunityItemTypeTemplate__c objTemp : ComunityItemTypeTemplate__c.getAll().values()){
                                     MapTemp.put(objTemp.CommunityItemRecordType__c,objTemp.Template_Name__c);
                                 }
                                  if(MapTemp.get(objCom.Type__c)  ==  null){
                                       return 'NOTYPE';
                                   } else{
            
                                        return 'Sucess';
                                     }
                              }
                            return null; 
        }
        return null;
    }

}