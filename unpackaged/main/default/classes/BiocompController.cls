/*
Author      : Uday/Ankush
Date        :
Description : This controller for Bio-composit community page.Its Manupulates the community Items and Links based on users profiles.
*/

public class BiocompController {
public List<wrapperBiocomp> CommunityItemsList{set;get;}
public string indexAssigned{set;get;}
public List<Community_Items__c> leftContents{set;get;} // To storee the left panel content.
public List<string> listCommsToQuery = new List<string>();
public Map<string,List<wrapperLeftBiocomp>> leftContentsMap ;
public Map<string,List<wrapperLeftBiocomp>> leftContentsMapRes ;
public Map<string,List<wrapperLeftBiocomp>> leftContentsMapInternal ;
public Decimal TotalSize{set;get;}
public string leftPanelRecordId{set;get;}
public string CommLogoURL{set;get;} // To store URL for Logo image.
public string CommBannerLogoURL{set;get;} //To store URL for Header image
public string CommBannerLogoURLTemp{set;get;}
public Map<string,List<wrapperLeftBiocomp>> leftContentsMapTemp ;
public Map<string,List<wrapperLeftBiocomp>> leftContentsMapTempRes ;
public Map<string,List<wrapperLeftBiocomp>> leftContentsMapTempInternal ;
public Map<string,List<wrapperLeftBiocomp>> leftContentsMapForContactUs{set;get;}
public List<Integer> ForContactUsCount{set;get;}
public List<String> listStringsForrLeft = new List<String>();
public User UserObj{set;get;}
public string EmailText{set;get;}
public string EmailSubject{set;get;}
public List<Community_Items__c> ElerningsLists{set;get;} 
public string elernid{set;get;}
public integer iElrnCount{set;get;}
public Boolean IsSysAdmin{set;get;}
public Map<string,string> leftContentsHeadersMap{set;get;}
public Map<string,string> leftContentsHeadersMapInternal{set;get;}
public string contactUsString{set;get;}

public Map<String,String> mapTypeWithColorCode{set;get;}
//public Map<String,Community_Items__c> mapCommItemsForVideobox{set;get;}
public string selectedPage{get;set{selectedPage=value;}}
    
    //Constructor
    public BiocompController() 
    {
       leftContentsHeadersMap = new map<string,string>();
       leftContentsHeadersMapInternal = new map<string,string>();
       ElerningsLists = new List<Community_Items__c>();         
         CommLogoURL ='';
         CommBannerLogoURL ='';
         iElrnCount = 0;
         pageNumber = 0;
         totalPageNumber = 0;
         pageSize = 6;
         CommBannerLogoURLTemp ='';
         contactUsString ='';
         videoURL = '';
         mapTypeWithColorCode = new Map<String,String>();
         
         List<Profile> profObj =[select name,id from Profile where id=:UserInfo.getProfileId()];
         List<User> userList = [select id,Community_View__c from User where id=:UserInfo.getUserId()];
         
         CommunityItemsList = new List<wrapperBiocomp>();
         TotalSize = 0;
         
         List<Community_Items__c> listCommLogos = new List<Community_Items__c>();
         List<Community_Items__c> listCommBannerimages = new List<Community_Items__c>();
          
             mapTypeWithColorCode.put('Topics of interest','black');
             mapTypeWithColorCode.put('1Marketing collateral','black');
             mapTypeWithColorCode.put('2Sales tools','black');
             mapTypeWithColorCode.put('3Account management','black');
             mapTypeWithColorCode.put('4Personas','black');
             mapTypeWithColorCode.put('4Internal only','black');
             mapTypeWithColorCode.put('Contact us','black');
             mapTypeWithColorCode.put('5Training tools','black');
             mapTypeWithColorCode.put('5Internal only','black');
             mapTypeWithColorCode.put('Internal only','black');
             mapTypeWithColorCode.put('1Internal only','black');
              
         //Quering customsetting for color codes with types.
         for(CommunityColorMapWithType__c custcolors : CommunityColorMapWithType__c.getAll().values())
         {
           if(custcolors.Type__c .equalsignoreCase('Topics of interest'))
               mapTypeWithColorCode.put(custcolors.Type__c,custcolors.Color_code__c);
           else if(custcolors.Type__c.equalsignoreCase('Marketing collateral'))
              mapTypeWithColorCode.put('1'+custcolors.Type__c,custcolors.Color_code__c);
            else if(custcolors.Type__c.equalsignoreCase('Sales tools'))
              mapTypeWithColorCode.put('2'+custcolors.Type__c,custcolors.Color_code__c);
            else if(custcolors.Type__c.equalsignoreCase('Account management'))
             mapTypeWithColorCode.put('3'+custcolors.Type__c,custcolors.Color_code__c);
           else if(custcolors.Type__c.equalsignoreCase('Personas'))
              mapTypeWithColorCode.put('4'+custcolors.Type__c,custcolors.Color_code__c);
            else if(custcolors.Type__c.equalsignoreCase('Contact us'))
              mapTypeWithColorCode.put(custcolors.Type__c,custcolors.Color_code__c);
            else if(custcolors.Type__c.equalsignoreCase('Training tools'))
              mapTypeWithColorCode.put('5'+custcolors.Type__c,custcolors.Color_code__c);
            else if(custcolors.Type__c.equalsignoreCase('Internal only')){
              mapTypeWithColorCode.put('5'+custcolors.Type__c,custcolors.Color_code__c);
              mapTypeWithColorCode.put('4'+custcolors.Type__c,custcolors.Color_code__c);
              mapTypeWithColorCode.put(custcolors.Type__c,custcolors.Color_code__c);
              mapTypeWithColorCode.put('1'+custcolors.Type__c,custcolors.Color_code__c);
              }
            else
             mapTypeWithColorCode.put(custcolors.Type__c,custcolors.Color_code__c);
         }
          
          system.debug('==mapTypeWithColorCode===>>'+mapTypeWithColorCode);         
         //Quering the Logo and Heder Images records for URL's.
         if(userList != null && userList.size() >0)
         {
            if(profObj != null && profObj.size() >0){
             if(profObj[0].Name == 'System Administrator' || profObj[0].Name == 'Biocomposites Manager User' || profObj[0].Name == 'Biocomposites Standard User')
               IsSysAdmin = true;
             else
               IsSysAdmin = false;
            }
               listCommLogos = [Select c.Type__c,c.URL_For_Image__c, c.Title__c, c.RecordTypeId, c.OwnerId, c.Profile__c,c.Name, c.Id, c.DO_NOT_SHOW__c, c.Content__c, c.ALT_Tag__c From Community_Items__c c where c.RecordType.Name ='Logo' and c.DO_NOT_SHOW__c =false and c.Profile__c =:userList[0].Community_View__c  limit 1];
               listCommBannerimages = [Select c.Type__c,c.URL_For_Image__c, c.Title__c, c.RecordTypeId, c.OwnerId, c.Profile__c,c.Name, c.Id, c.DO_NOT_SHOW__c, c.Content__c, c.ALT_Tag__c From Community_Items__c c where c.RecordType.Name ='Header Image' and c.DO_NOT_SHOW__c =false and c.Profile__c =:userList[0].Community_View__c  limit 1];
         }
         //Assiging the logo image URL
         if(listCommLogos != null && listCommLogos.size() > 0)
               CommLogoURL = listCommLogos[0].URL_For_Image__c;
         
         //Assiging the header image URL
         if(listCommBannerimages != null && listCommBannerimages.size() > 0)
               CommBannerLogoURL = listCommBannerimages[0].URL_For_Image__c;
             
             //Quering the all communities  which has recordtype name  like "Topics Of Interest" and assignig to a list.
             for(Community_Items__c comm:[Select c.Type__c,c.Sort_Number__c,c.Brainshark_URL__c,c.Text_For_Brainshark_Tile__c ,c.URL_For_Image__c , c.Title__c, c.Profile__c, c.RecordTypeId,c.RecordType.Name, c.OwnerId, c.Name, c.Id, c.DO_NOT_SHOW__c, c.Content__c, c.ALT_Tag__c,c.New_Item__c, (Select Name, Community_Item__c, Profile__c, Button_Link_Text__c, Button_Link_URL__c From Community_Item_Permissions_Links__r) From Community_Items__c c where c.DO_NOT_SHOW__c =false Order By c.Sort_Number__c])
             {   
                for(Community_Item_Permission_Link__c commLink:comm.Community_Item_Permissions_Links__r)
                {
                    if(userList != null && userList.size() >0)
                    {
                      if(commLink.Profile__c == userList[0].Community_View__c && comm.RecordType.Name =='Topics Of Interest')
                      {
                        listCommsToQuery.add(comm.id);
                      }
                      
                      if(commLink.Profile__c == userList[0].Community_View__c && comm.RecordType.Name =='Brainshark Training')
                      {
                        ElerningsLists.add(comm);
                      }
                    }
                }
                 
                 if(ElerningsLists != null && ElerningsLists.size()>0){
                    iElrnCount = ElerningsLists.size();
                 }
                 system.debug('===ElerningsLists===>>'+ElerningsLists);
                
             }  
                         
             PrepareListStrings(); //Preparing the Leftpanel sorting orders string.
             ViewData();//loading the content.
              
                                      
              UserObj = new User();
              UserObj = [select id,Name,Email,phone,profileId,Profile.Name,ContactId,CompanyName,title,mobilePhone,Street, State, PostalCode, Country,CountryCode,City from User where Id=:UserInfo.getUserId() limit 1];
              
             system.debug('====listCommsToQuery in constr==>>'+listCommsToQuery);
    }
       
    //Getting the Left panel video data
    
    public boolean displayPopup {get; set;}     
    
    public void closePopup() {        
        displayPopup = false;    
    }     
    public void showPopup() {
                
        displayPopup = true;    
    }
    
    public string videoURL{set;get;}
    public List<Community_Items__c> getMapleftPanelsVideos()
    { 
        //
        List<Community_Items__c> mapCommItemsForVideobox = new List<Community_Items__c>();
        List<Profile> profObj =[select name,id from Profile where id=:UserInfo.getProfileId()];
        List<User> userList = [select id,Community_View__c from User where id=:UserInfo.getUserId()];
         
         for(Community_Items__c comItms:[Select c.Video_Server_URL__c,c.Video_thumbnail_URL__c,c.Video_Url__c,c.Type__c,c.Sort_Number__c, c.Title__c,c.New_Item__c,c.RecordTypeId,c.OwnerId, c.Name, c.Id,(Select Name, Community_Item__c, Profile__c, Button_Link_Text__c, Button_Link_URL__c From Community_Item_Permissions_Links__r), c.DO_NOT_SHOW__c, c.Content__c, c.ALT_Tag__c From Community_Items__c c where c.RecordType.Name ='Left Panel' and c.Type__c = 'Video box' and c.DO_NOT_SHOW__c =false])
         {
            for(Community_Item_Permission_Link__c comLink :comItms.Community_Item_Permissions_Links__r)
            {
               if(userList != null && userList.size() >0 && userList[0].Community_View__c == comLink.Profile__c)
                {
                  mapCommItemsForVideobox.add(comItms);    
                }
            }
          }
         
         system.debug('===mapCommItemsForVideobox==>>'+mapCommItemsForVideobox);
        return mapCommItemsForVideobox;
    } 
    
    //Getting the Left panel data without Internal only
    public Map<string,List<wrapperLeftBiocomp>> getlistleftPanels() 
    {
         leftContentsMap = new Map<string,List<wrapperLeftBiocomp>>();
         leftContentsMapTemp = new Map<string,List<wrapperLeftBiocomp>>();
         leftContentsMapForContactUs = new Map<string,List<wrapperLeftBiocomp>>();
         ForContactUsCount = new List<Integer>();
         list<wrapperLeftBiocomp> listStrings;
         
         List<Profile> profObj =[select name,id from Profile where id=:UserInfo.getProfileId()];
         List<User> userList = [select id,Community_View__c from User where id=:UserInfo.getUserId()];
         
         for(Community_Items__c comItms:[Select c.Type__c,c.Sort_Number__c, c.Title__c,c.New_Item__c,c.RecordTypeId,c.OwnerId, c.Name, c.Id,(Select Name, Community_Item__c, Profile__c, Button_Link_Text__c, Button_Link_URL__c From Community_Item_Permissions_Links__r), c.DO_NOT_SHOW__c, c.Content__c, c.ALT_Tag__c From Community_Items__c c where c.RecordType.Name ='Left Panel' and c.DO_NOT_SHOW__c = false and c.Type__c != 'Internal only' and c.Type__c != 'Account management' Order By c.Type__c])
         {
            for(Community_Item_Permission_Link__c comLink :comItms.Community_Item_Permissions_Links__r)
            {
               if(userList != null && userList.size() >0 && userList[0].Community_View__c == comLink.Profile__c)
                {
                   if(comItms.Type__c != null && leftContentsMap.get(comItms.Type__c) != null)
                   {
                       listStrings = new List<wrapperLeftBiocomp>();
                       listStrings.addAll(leftContentsMap.get(comItms.Type__c));
                       listStrings.add(new wrapperLeftBiocomp(comItms.Title__c,comLink.Button_Link_URL__c,comItms.id,comItms.Sort_Number__c,comItms.New_Item__c));
                       listStrings.sort();
                       leftContentsMap.put(comItms.Type__c,listStrings);  
                   }
                   else 
                   {
                       listStrings = new List<wrapperLeftBiocomp>();
                       listStrings.add(new wrapperLeftBiocomp(comItms.Title__c,comLink.Button_Link_URL__c,comItms.id,comItms.Sort_Number__c,comItms.New_Item__c));
                       listStrings.sort();
                       leftContentsMap.put(comItms.Type__c,listStrings);
                   }
               }
            }
         }
         
         integer k =1; 
         for(String str:listStringsForrLeft)
         {
            system.debug('===str===>>'+str);
            system.debug('===leftContentsMap.get(str)===>>'+leftContentsMap.get(str));
            
            if(leftContentsMap != null && leftContentsMap.size() > 0 && leftContentsMap.get(str) != null && str != 'Contact us')
            {
                leftContentsMapTemp.put(k+str,leftContentsMap.get(str));
                leftContentsHeadersMap.put(k+str,str);
            }
            
            if(leftContentsMap != null && leftContentsMap.size() > 0 && leftContentsMap.get(str) != null && str== 'Contact us')
            {
                leftContentsMapForContactUs.put(str,leftContentsMap.get(str));
                contactUsString = leftContentsMap.get(str) != null?(leftContentsMap.get(str))[0].ALtTagName:'';
                ForContactUsCount.add(k);
            }
            
            k++;
         }
         
         system.debug('===leftContentsMap====>>'+leftContentsMap);
         system.debug('===leftContentsHeadersMap====>>'+leftContentsHeadersMap);
         
         system.debug('===leftContentsMapTemp====>>'+leftContentsMapTemp);
         return leftContentsMapTemp;
    }
     
    //Getting the Left panel data only "Internal only" Type
    public Map<string,List<wrapperLeftBiocomp>> getlistleftPanelsInternalOnly() 
    {
         leftContentsMapInternal = new Map<string,List<wrapperLeftBiocomp>>();
         leftContentsMapTempInternal = new Map<string,List<wrapperLeftBiocomp>>();
         list<wrapperLeftBiocomp> listStrings;
         
         List<Profile> profObj =[select name,id from Profile where id=:UserInfo.getProfileId()];
         List<User> userList = [select id,Community_View__c from User where id=:UserInfo.getUserId()];
         
         for(Community_Items__c comItms:[Select c.Type__c,c.Sort_Number__c, c.Title__c,c.New_Item__c,c.RecordTypeId,c.OwnerId, c.Name, c.Id,(Select Name, Community_Item__c, Profile__c, Button_Link_Text__c, Button_Link_URL__c From Community_Item_Permissions_Links__r), c.DO_NOT_SHOW__c, c.Content__c, c.ALT_Tag__c From Community_Items__c c where c.RecordType.Name ='Left Panel' and c.DO_NOT_SHOW__c = false and (c.Type__c = 'Internal only' or c.Type__c = 'Account management') Order By c.Type__c])
         {
            for(Community_Item_Permission_Link__c comLink :comItms.Community_Item_Permissions_Links__r)
            {
               if(userList != null && userList.size() >0 && userList[0].Community_View__c == comLink.Profile__c)
                {
                   if(comItms.Type__c != null && leftContentsMapInternal.get(comItms.Type__c) != null)
                   {
                       listStrings = new List<wrapperLeftBiocomp>();
                       listStrings.addAll(leftContentsMapInternal.get(comItms.Type__c));
                       listStrings.add(new wrapperLeftBiocomp(comItms.Title__c,comLink.Button_Link_URL__c,comItms.id,comItms.Sort_Number__c,comItms.New_Item__c));
                       listStrings.sort();
                       leftContentsMapInternal.put(comItms.Type__c,listStrings);  
                   }
                   else 
                   {
                       listStrings = new List<wrapperLeftBiocomp>();
                       listStrings.add(new wrapperLeftBiocomp(comItms.Title__c,comLink.Button_Link_URL__c,comItms.id,comItms.Sort_Number__c,comItms.New_Item__c));
                       listStrings.sort();
                       leftContentsMapInternal.put(comItms.Type__c,listStrings);
                   }
               }
            }
         }
         
         integer k = 1; 
         for(String str:listStringsForrLeft)
         {
            system.debug('==str ###&&&&&&&&&&====>>'+str);
            if(leftContentsMapInternal != null && leftContentsMapInternal.size() > 0 && leftContentsMapInternal.get(str) != null && (str == 'Internal only' || str == 'Account management'))
            {
                 system.debug('==str ###&&&&&***********&&&&&====>>');
                leftContentsMapTempInternal.put(k+str,leftContentsMapInternal.get(str));
                leftContentsHeadersMapInternal.put(k+str,str);
            }
            k++;
         }
         
         system.debug('====leftContentsMapTempInternal==>>'+leftContentsMapTempInternal);
         system.debug('====leftContentsHeadersMapInternal==>>'+leftContentsHeadersMapInternal);
         return leftContentsMapTempInternal;
    }
    
    
     //Getting the Left panel data to display at righr side(Resource section)
    public Map<string,List<wrapperLeftBiocomp>> getlistleftPanelsRes() 
    {
         leftContentsMapRes = new Map<string,List<wrapperLeftBiocomp>>();
         leftContentsMapTempRes = new Map<string,List<wrapperLeftBiocomp>>();
         list<wrapperLeftBiocomp> listStrings;
         
         List<Profile> profObj =[select name,id from Profile where id=:UserInfo.getProfileId()];
         List<User> userList = [select id,Community_View__c from User where id=:UserInfo.getUserId()];
         
         for(Community_Items__c comItms:[Select c.Type__c,c.Sort_Number__c, c.Title__c,c.New_Item__c,c.RecordTypeId,c.OwnerId, c.Name, c.Id,(Select Name, Community_Item__c, Profile__c, Button_Link_Text__c, Button_Link_URL__c From Community_Item_Permissions_Links__r), c.DO_NOT_SHOW__c, c.Content__c, c.ALT_Tag__c From Community_Items__c c where c.RecordType.Name ='Left Panel' and c.DO_NOT_SHOW__c = false Order By c.Type__c])
         {
            for(Community_Item_Permission_Link__c comLink :comItms.Community_Item_Permissions_Links__r)
            {
               if(userList != null && userList.size() >0 && userList[0].Community_View__c == comLink.Profile__c)
                {
                   if(comItms.Type__c != null && leftContentsMapRes.get(comItms.Type__c) != null)
                   {
                       listStrings = new List<wrapperLeftBiocomp>();
                       listStrings.addAll(leftContentsMapRes.get(comItms.Type__c));
                       listStrings.add(new wrapperLeftBiocomp(comItms.Title__c,comLink.Button_Link_URL__c,comItms.id,comItms.Sort_Number__c,comItms.New_Item__c));
                       listStrings.sort();
                       leftContentsMapRes.put(comItms.Type__c,listStrings);  
                   }
                   else 
                   {
                       listStrings = new List<wrapperLeftBiocomp>();
                       listStrings.add(new wrapperLeftBiocomp(comItms.Title__c,comLink.Button_Link_URL__c,comItms.id,comItms.Sort_Number__c,comItms.New_Item__c));
                       listStrings.sort();
                       leftContentsMapRes.put(comItms.Type__c,listStrings);
                   }
               }
            }
         }
         
         integer k =1; 
         for(String str:listStringsForrLeft)
         {
            system.debug('===str===>>'+str);
            system.debug('===leftContentsMapRes.get(str)===>>'+leftContentsMapRes.get(str));
            
            if(leftContentsMapRes != null && leftContentsMapRes.size() > 0 && leftContentsMapRes.get(str) != null && str != 'Contact us')
            {
                leftContentsMapTempRes.put(k+str,leftContentsMapRes.get(str));
                leftContentsHeadersMap.put(k+str,str);
            }
            k++;
         }
         
         system.debug('===leftContentsMap====>>'+leftContentsMap);
         system.debug('===leftContentsHeadersMap====>>'+leftContentsHeadersMap);
         
         system.debug('===leftContentsMapTempRes====>>'+leftContentsMapTempRes);
         return leftContentsMapTempRes;
    }
    
    //After clicks on "Red more" creating the "Community_Stat__c" record for that Communuty Item.
    public void createlinkRecord()
    {
        system.debug('=====indexAssigned===>>'+indexAssigned);
        
        if(indexAssigned != null && indexAssigned !='')
        {
            Community_Stat__c comState = new Community_Stat__c();
            comState.User__c = UserInfo.getUserId();
            comState.Community_Item__c = indexAssigned;
            insert comState;
        }
    }
    
    //After clicks on "Left panel link" creating the "Community_Stat__c" record for that Communuty Item.
    public void createLeftRecord()
    {
        system.debug('====leftPanelRecordId=====>>'+leftPanelRecordId);
        if(leftPanelRecordId != null && leftPanelRecordId !='')
        {
            Community_Stat__c comState = new Community_Stat__c();
            comState.User__c = UserInfo.getUserId();
            comState.Community_Item__c = leftPanelRecordId;
            insert comState;
        }
    }
    
    //After clicks on "Left panel link" creating the "Community_Stat__c" record for that Communuty Item.
    public void createElearnRecord()
    {
        system.debug('====elernid=====>>'+elernid);
        if(elernid != null && elernid !='')
        {
            Community_Stat__c comState = new Community_Stat__c();
            comState.User__c = UserInfo.getUserId();
            comState.Community_Item__c = elernid;
            insert comState;
        }
    }
    
    
    //To send contact us email.
    public void SendMessage()
    {
        system.debug('===EmailText==='+EmailText);
        system.debug('===EmailSubject==='+EmailSubject);
        
      if(EmailText != null && EmailSubject != null && EmailText !='' && EmailSubject !='')
        {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
       List<String> listEmails = new List<String>();
       if((System.Label.ToAddresssesForContactUs).contains('*'))
       {
         listEmails = (System.Label.ToAddresssesForContactUs).split('*');
       }
       else
       { 
         listEmails = new List<String>();
         listEmails.add(System.Label.ToAddresssesForContactUs);
       }
      // Strings to hold the email addresses to which you are sending the email.
      //String[] toAddresses = new String[] {listEmails}; 
      //String[] ccAddresses = new String[] {System.Label.CCAddresssesForContactUs};
        
      
      // Assign the addresses for the To and CC lists to the mail object.
      mail.setToAddresses(listEmails);
      //mail.setCcAddresses(ccAddresses);
      
      // Specify the subject line for your email address.
      mail.setSubject('Hub:'+EmailSubject);
      
      // Set to True if you want to BCC yourself on the email.
      mail.setBccSender(false);
      
      // Optionally append the salesforce.com email signature to the email.
      // The email address of the user executing the Apex Code will be used.
      mail.setUseSignature(false);
      
      // Specify the text content of the email.
      //mail.setPlainTextBody(EmailText);
      string cName =userObj.CompanyName == null?'':userObj.CompanyName;
      string cTitle =userObj.Title == null?'':userObj.Title;
      string cCntry =userObj.Country == null?'':userObj.Country;
      string cStat =userObj.State == null?'':userObj.State;
      string cPhone =userObj.Phone == null?'':userObj.Phone;
      string cEmail =userObj.Email == null?'':userObj.Email;
      
      
      mail.setHtmlBody(
      '<table>'+
          '<tr><td><b>Name :</b></td><td>'+userObj.Name+'</td></tr>'+
          
          '<tr><td><b>Distributor :</b></td><td>'+cName+'</td></tr>'+
          '<tr><td><b>Job title :</b></td><td>'+cTitle+'</td></tr>'+
          '<tr><td><b>Country :</b></td><td>'+cCntry+'</td></tr>'+
          '<tr><td><b>Sub region :</b></td><td>'+cStat+'</td></tr>'+
          
          '<tr><td><b>Phone :</b></td><td>'+cPhone+'</td></tr>'+ 
          '<tr><td><b>Email :</b></td><td>'+cEmail+'</td></tr>'+
          '<tr><td><b>Profile :</b></td><td>'+userObj.profile.Name+'</td></tr>'+
          '<tr><td><b>Message Body :</b></td><td>'+EmailText+'</td></tr>'+          
      '</table>');
      
      // Send the email you have created.
      Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });    
      
      EmailSubject = '';
      EmailText = '';
      
      ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM,'Message sent successfully.'); 
      ApexPages.addMessage(myMsg);
     }
   }
    
    //To save Edited User details
    public void svaeUserDetails()
    {
      try{
        update userObj;
        system.debug('===userObj.ContactId===>>'+userObj.ContactId);
        if(userObj != null && userObj.ContactId != null)
        {
          Contact con = new Contact();
          con.Id = userObj.ContactId;
          con.Phone = userObj.Phone;
          con.Email = userObj.Email;
          con.Job_Title__c = userObj.Title;
          con.MobilePhone = userObj.MobilePhone;
          con.MailingCity = userObj.City;
          con.MailingStreet = userObj.Street;
          con.MailingCountry = userObj.Country;
          con.MailingPostalCode =userObj.PostalCode;
          con.MailingState = userObj.State;
      
              update con;
          ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM,'User details saved Successfully.'); 
          ApexPages.addMessage(myMsg);
        }
      }Catch(Exception ex)
      {
        system.debug('===exception while user update==>>'+ex.getMessage());
      }
    }
    
    //Preparing the Leftpanel sorting orders string.
    public void PrepareListStrings()
    {
         listStringsForrLeft.add('Marketing collateral');
         listStringsForrLeft.add('Sales tools');
         listStringsForrLeft.add('Account management');
         listStringsForrLeft.add('Contact us');
         //listStringsForrLeft.add('Training tools');
         listStringsForrLeft.add('Internal only');
    }
    
    //Wrapper class for hold cotnt of Right panel on page
    public class wrapperBiocomp implements Comparable
    {
        public string maxcontent{set;get;}
        public string mincontent{set;get;}
        public string title{set;get;}
        public string indexval{set;get;}
        public decimal sortNumber{set;get;}
        public Boolean isNew{set;get;}
        
            public Integer compareTo(Object Wrp)
            {
                wrapperBiocomp compareToRec = (wrapperBiocomp)Wrp;
                
                system.debug('====sortNumber====>>'+sortNumber);
                system.debug('====compareToRec.sortNumber====>>'+compareToRec.sortNumber);
                
                 if (sortNumber > compareToRec.sortNumber) {
                    return 1;
                 } else if (sortNumber < compareToRec.sortNumber) {
                    return -1;
                 }
                 else {
                    return 0;
                 } 
            }
    }
    
    //Wrapper class for hold cotnt of Left panel on page
    public class wrapperLeftBiocomp implements Comparable
    {
        public string ALtTagName{set;get;}
        public string URLToGo{set;get;}
        public string indexLeft{set;get;}
        public boolean isNew{set;get;}
        public decimal sortNO{set;get;}
        public wrapperLeftBiocomp(string alt,string URLs,String index,decimal sortNumbr,boolean newone)
        {
            ALtTagName =alt;
            URLToGo = URLs;
            indexLeft = index;
            sortNO = sortNumbr;
            isNew = newone;
        }
        
        public Integer compareTo(Object Wrp)
        {
            //return sortNO.CompareTo(((wrapperLeftBiocomp)wrp).sortNO);
            
            wrapperLeftBiocomp compareToRec = (wrapperLeftBiocomp)Wrp;
            
            system.debug('====sortNO====>>'+sortNO);
            system.debug('====compareToRec.sortNO====>>'+compareToRec.sortNO);
            
             if (sortNO > compareToRec.sortNO) {
                return 1;
             } else if (sortNO < compareToRec.sortNO) {
                return -1;
             }
             else {
                return 0;
             } 
        }
    }
    
    /**************This code for pageination*********************************/

    private List<wrapperBiocomp> pageAccounts{set;get;}
    private Integer pageNumber;
    private Integer pageSize;
    private Integer totalPageNumber;
    
    //For getting the current page Number.
    public Integer getPageNumber()
    {
        return pageNumber;
    }
    
    //For getting the content (to display on page.).
    public List<wrapperBiocomp> getwrapperBiocompRecs()
    {
        return pageAccounts;
    }
    
    //For getting the Pages size.
    public Integer getPageSize()
    {
        return pageSize;
    }
    
    //For disbling the Previous button.
    public Boolean getPreviousButtonEnabled()
    {
        return !(pageNumber > 1);
    }
    
    //For disbling the Next button.
    public Boolean getNextButtonDisabled()
    {
        if (CommunityItemsList == null) 
            return true;
        else
            return ((pageNumber * pageSize) >= CommunityItemsList.size());
    }
    
    //Getting the Total number of pages we dispaly pages on pagination.
    public Integer getTotalPageNumber()
    {
        if (totalPageNumber == 0 && CommunityItemsList !=null)
        {
            totalPageNumber = CommunityItemsList.size() / pageSize;
            Integer mod = CommunityItemsList.size() - (totalPageNumber * pageSize);
            
            if (mod > 0)
                totalPageNumber++; 
        }
        return totalPageNumber;
    }
    
    //For First page display.   
    public PageReference ViewData()
    {
        CommunityItemsList = null;
        totalPageNumber = 0;
        BindData(1);
        system.debug('====CommunityItemsList====>>'+CommunityItemsList);
        return null;
    }
    
    //Preparing the Right panel data with wrapperclass.
    private void BindData(Integer newPageIndex)
    {
        try
        {
        if (CommunityItemsList == null)
          {
             system.debug('====listCommsToQuery==>>'+listCommsToQuery);
             
              CommunityItemsList = new List<wrapperBiocomp>();
              integer i =1;
              for(Community_Items__c comm:[Select c.Type__c, c.Title__c, c.Sort_Number__c,c.RecordTypeId, c.OwnerId, c.Name, c.Id, c.DO_NOT_SHOW__c, c.Content__c, c.ALT_Tag__c,c.New_Item__c From Community_Items__c c where c.Id IN:listCommsToQuery and  c.RecordType.Name ='Topics Of Interest' and c.DO_NOT_SHOW__c =false Order By c.Sort_Number__c])
              {  
                wrapperBiocomp wrap = new wrapperBiocomp();
                wrap.maxcontent = comm.Content__c;
                wrap.title = comm.Title__c;
                wrap.isNew = comm.New_Item__c;
                wrap.mincontent = ((comm.Content__c != null && (comm.Content__c).length() >= 170)?(comm.Content__c).substring(0,170):comm.Content__c)+'...';
                wrap.indexval = comm.id;
                wrap.sortNumber = comm.Sort_Number__c;
                i++;
                CommunityItemsList.add(wrap);
              }
          }
        
        pageAccounts = new List<wrapperBiocomp>();
        
        Transient Integer counter = 0;
        Transient Integer min = 0;
        Transient Integer max = 0;
        
        if (newPageIndex > pageNumber)
        {
            min = pageNumber * pageSize;
            max = newPageIndex * pageSize;
        }
        else
        {
            max = newPageIndex * pageSize;
            min = max - pageSize;
        }
        
        for(wrapperBiocomp a : CommunityItemsList)
        {
            counter++;
            if (counter> min && counter<= max)
            pageAccounts.add(a);
        }
        
        pageNumber = newPageIndex;
        
        if (pageAccounts == null || pageAccounts.size() <= 0)
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'Data not available for this view.'));
        
        }
         catch(Exception ex)
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,ex.getMessage()));
        }
     }
    
    //For Next button click
    public PageReference nextBtnClick() 
    {
       BindData(pageNumber + 1);
       return null;
    }
    
    //For Previous button click
    public PageReference previousBtnClick() {
        BindData(pageNumber - 1);
        return null;
    }

    /*********************paginatio code END here**************************/
    
    
    
}