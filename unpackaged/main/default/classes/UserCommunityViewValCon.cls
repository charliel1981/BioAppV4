/***
 * Author : Uday/ Prasannanjaneyulu 
 * Date:  20-MAR-2015
 * changes : 29-4-2015
 * Description :  
 ***/
public with sharing class UserCommunityViewValCon {
    public string strBocy{get;set;}
    public string responceMessage{get;set;}
    public string result{get;set;}
    public boolean blnstatus{get;set;}
    public map<string,string> MapCustom = new map<string,string>();
    map<string,id> MapTempId = new map<string,id>();
    public string ErrorMessage{get;set;}
    public Set<string> leftvalues = new Set<string>();
    Public List<string> leftselected{get;set;}
    Public List<string> rightselected{get;set;}
    public Set<string> rightvalues = new Set<string>();
    public list<id> lstids = new list<id>();
    public map<string,string> mapRightVals = new map<string,string>();
    public EmailTemplate et;
    string strValues = '';
    map<id,list<CampaignMember>> mapCamCamMems = new map<id,list<CampaignMember>>();  
    public UserCommunityViewValCon(){

    }
    public UserCommunityViewValCon(ApexPages.StandardController controller) 
    {
        responceMessage = '';
        blnstatus = false;
        ErrorMessage = '';
        leftselected = new List<String>();
        rightselected = new List<String>();
        List<SelectOption> options = new List<SelectOption>();
        et = [SELECT id FROM EmailTemplate WHERE Name = 'Communtiy Hub Notification Template' limit 1];
        set<string> strProfiles = new set<string>();
        list<Community_Items__c> lstComItem = [select id,Name,Profile__c from Community_Items__c where Profile__c != null];
        for(Community_Items__c objCitem : lstComItem)
        {
            strProfiles.add(objCitem.Profile__c);
        }
        system.debug('strProfiles:::::::'+strProfiles);
        list<Campaign> lstCamps = [select id,Name,Show_In_Hub_Push__c,Standard_User_Profile__c,IsActive  from Campaign where isActive =true and Show_In_Hub_Push__c =true ];
        system.debug('Campaigns::::'+lstCamps);
        set<id> setCamsids = new set<id>();
        for(Campaign objCamps : lstCamps){
            setCamsids.add(objCamps.id);    
        } 
        list<CampaignMember> lstCamMems = [select id,contactid,contact.Email,Lead.Ownerid,Contact.Ownerid,campaignid,Leadid,Lead.Email from CampaignMember where campaignid IN:setCamsids];
        mapCamCamMems = new map<id,list<CampaignMember>>();    
        for(CampaignMember objCamsMembes : lstCamMems){
            if(mapCamCamMems.get(objCamsMembes.campaignid) == null){
                list<CampaignMember> lstMems = new list<CampaignMember>();
                lstMems.add(objCamsMembes);
                mapCamCamMems.put(objCamsMembes.campaignid,lstMems);
            }else{
                list<CampaignMember> lstCampmembers = new list<CampaignMember>();
                lstCampmembers = mapCamCamMems.get(objCamsMembes.campaignid);
                lstCampmembers.add(objCamsMembes);
                mapCamCamMems.put(objCamsMembes.campaignid,lstCampmembers);
            }
        }

        for(Campaign objCamps : lstCamps)
        {

            string strCamnames;
            if(mapCamCamMems.get(objCamps.id) != null){
                strCamnames = objCamps.Name+' '+'('+mapCamCamMems.get(objCamps.id).size()+')';
                system.debug('strCamnames:::::'+strCamnames);                   
            }else {

                strCamnames = objCamps.Name+' '+'('+'0'+')';
                system.debug('strCamnames:::::'+strCamnames);      
            }
            mapRightVals.put(strCamnames,objCamps.Name);
            system.debug('mapRightVals:::::'+mapRightVals);
            leftvalues.add(strCamnames);
        }

        for (ComunityItemTypeTemplate__c ObjTemp : ComunityItemTypeTemplate__c.getAll().values())
        {
            MapCustom.put(ObjTemp.CommunityItemRecordType__c,ObjTemp.Template_Name__c);
        }
        //map<string,id> MapTempId = new map<string,id>();
        list<Emailtemplate> lstEt = [select id,name from Emailtemplate];
        if(lstEt != null && !lstEt.isEmpty())
        {
            for(Emailtemplate objTemplate : lstEt)
            {
                MapTempId.put(objTemplate.Name,objTemplate.id);
            }
        }
        
        getItems();
    }
    public List<SelectOption> getItems() 
    {
        List<SelectOption> options = new List<SelectOption>();
        List<string> tempList = new List<String>();
        system.debug('leftvalues:::::'+leftvalues);
        tempList.addAll(leftvalues);
        tempList.sort();
        system.debug('tempList:::::'+tempList);
        for(string s : tempList)
            options.add(new SelectOption(s,s));
        return options;
    }

    public PageReference selectedValues()
    {
        rightselected.clear();
        system.debug('leftselected:::::'+leftselected);
        for(String s : leftselected)
        {
            leftvalues.remove(s);
            rightvalues.add(s);
        }
        return null;
    }

    public List<SelectOption> getSelectedValues()
    {

        system.debug('rightvalues::::::::'+rightvalues);
        List<SelectOption> options1 = new List<SelectOption>();
        List<string> tempList = new List<String>();
        tempList.addAll(rightvalues);
        tempList.sort();
        for(String s : tempList)
            options1.add(new SelectOption(s,s));
        return options1;
    }

    public PageReference unselectclick()
    {
        leftselected.clear();
        for(String s : rightselected)
        {
            rightvalues.remove(s);
            leftvalues.add(s);
        }
        return null;
    }

    public List<SelectOption> getUnSelectedValues()
    {
        List<SelectOption> options1 = new List<SelectOption>();
        List<string> tempList = new List<String>();
        tempList.addAll(rightvalues);
        tempList.sort();
        for(String s : tempList)
            options1.add(new SelectOption(s,s));
        return options1;

    }

    /**************** To show tamplate preview************************/

    public pageReference Preparedata()
    {
        Community_Items__c objcom;
        string strID = ApexPages.currentPage().getParameters().get('id');
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        system.debug('strID::::'+strID);
        system.debug('rightvalues:::::'+rightvalues);
        /*for (ComunityItemTypeTemplate__c ObjTemp : ComunityItemTypeTemplate__c.getAll().values())
        {
            MapCustom.put(ObjTemp.CommunityItemRecordType__c,ObjTemp.Template_Name__c);
        }
        //map<string,id> MapTempId = new map<string,id>();
        list<Emailtemplate> lstEt = [select id,name from Emailtemplate];
        if(lstEt != null && lstEt.size()>0)
        {
            for(Emailtemplate objTemplate : lstEt)
            {
                MapTempId.put(objTemplate.Name,objTemplate.id);
            }
        }*/
        map<string,string> mapCommunityRec = new map<string,string>(); 
        if(strID !=null)
        {
            objCom = [select id,Name,Title__c,Type__c,ALT_Tag__c,Brainshark_9_Digit_Number__c,Hub_Email_Subject__c,recordtypeid from Community_Items__c where id =: strID];
            system.debug('objCom :::'+objCom);
            mapCommunityRec.put(objCom.Type__c,objCom.Type__c);
        }

        if(rightvalues.isEmpty())
        {
            system.debug('rightvalue::::'+rightvalues);
            ErrorMessage = 'Please select atleast one Community View.';
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please select atleast one Community View.'));
            return null;
            system.debug('ErrorMessage:::::::::: '+ErrorMessage );
        }else if(!rightvalues.isEmpty())
        {
            ErrorMessage = '';
            system.debug('rightvalues**********'+rightvalues);
            system.debug('mapRightVals**********'+mapRightVals);
            list<string> lststrFalueres = new list<string>();

            for(string str : rightvalues){

                if(mapRightVals.get(str) != null){

                    lststrFalueres.add(mapRightVals.get(str));
                    system.debug('Selected::::::::::'+lststrFalueres);
                }
            }

            list<Campaign> lstCamp = [select id,name from Campaign where Name IN:lststrFalueres ]; 
            system.debug('lstCamp::::'+lstCamp);
            set<id> setIds = new set<id>();
            List<id> listcmpIds = new List<id>();
            for(Campaign objCap : lstCamp)
            {
                setIds.add(objCap.id);
            }
            listcmpIds.addAll(setIds);
            //lstids.addall(setIds);
            system.debug('listcmpIds:::::'+listcmpIds);
            system.debug('setIds:::::'+setIds);
            if(listcmpIds != null && !listcmpIds.isEmpty())
            {
                /*map<id,list<Campaignmember>> mapCampMembers = new map<id,list<Campaignmember>>();
                list<Campaignmember> lstMember = [select id,contactid,contact.Email,Lead.Ownerid,Contact.Ownerid,campaignid,Leadid,Lead.Email from Campaignmember where campaignid IN:setIds];
                for(Campaignmember objMem : lstMember)
                {
                    if( mapCampMembers.get(objMem.campaignid) ==  null )
                    {
                        list<Campaignmember> lstCMember = new list<Campaignmember>();
                        lstCMember.add(objMem);
                        mapCampMembers.put(objMem.campaignid,lstCMember);
                    }else
                    {
                        list<Campaignmember> lstCampMem = mapCampMembers.get(objMem.campaignid);
                        lstCampMem.add(objMem);
                        mapCampMembers.put(objMem.campaignid,lstCampMem);
                    }
                }
                system.debug('mapCampMembers:::'+mapCampMembers);
                system.debug('CampaignMembers:::'+lstMember);
                */
                list<Task> lstTaskInsert = new list<Task>();
                if(mapCamCamMems != null && !mapCamCamMems.isEmpty())
                { 
                    for(id objids : listcmpIds)
                    {
                        if(mapCamCamMems.get(objids) != null &&  !mapCamCamMems.get(objids).isEmpty())
                        {
                            for(Campaignmember objCmpMem : mapCamCamMems.get(objids))
                            {
                                /**************************************************/
                                list<string> lststr = new list<string>();
                                if(objCmpMem.contact.Email != null)
                                {
                                    system.debug('Emailssss::::'+objCmpMem.contact.Email);
                                    lststr.add(objCmpMem.contact.Email);
                                }else if(objCmpMem.Lead.Email != null)
                                {
                                    lststr.add(objCmpMem.Lead.Email);
                                }
                                if(lstStr != null && !lstStr.isEmpty())
                                {
                                    Messaging.SingleEmailMessage Mail = new Messaging.SingleEmailMessage();
                                    Mail.setToAddresses(lstStr);
                                    if(objCmpMem.contactid != null)
                                    {
                                        Mail.setTargetObjectId(objCmpMem.contactid );
                                    }else if(objCmpMem.Leadid != null )
                                    {
                                        Mail.setTargetObjectId(objCmpMem.Leadid );
                                    }
                                    if(MapCustom != null && !MapCustom.isEmpty() &&  MapTempId != null && !MapTempId.isEmpty() && mapCommunityRec != null && !mapCommunityRec.isEmpty())
                                    {
                                        Mail.setTemplateId(MapTempId.get(MapCustom.get(mapCommunityRec.get(objCom.Type__c))));
                                    }

                                    Mail.setSaveAsActivity(false);    
                                    system.debug('strid:::::::::::'+strID);
                                    Mail.setWhatId(strID);    
                                    messages.add(Mail);  
                                    break;
                                }
                            }
                        }
                        break;
                    } 
                }else
                {
                    ErrorMessage = 'No Campaign Members found.';
                }
                if(messages != null && !messages.isEmpty()){
                    try{

                        Savepoint sp = Database.setSavepoint();
                        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{messages[0]});
                        Database.rollback(sp);

                        string strbody = '';
                        for(Messaging.Email obj:messages)
                        {
                            system.debug('Email body:::::::::::::'+obj);
                            if(obj != null){
                                strbody = String.valueOf(obj).split('getHtmlBody=')[1].split('getTargetObjectId')[0].split('getInReplyTo')[0];
                                string strTarget  = String.valueOf(obj).split('getTargetObjectId=')[1].split(';getTemplateId')[0];
                                system.debug('targetid::::::::'+strTarget);
                                string html= strbody;  
                                result = html.replaceAll('<br/>', '\n');
                                result = result.replaceAll('<br />', '\n');
                                result = result.replaceAll('&lt;br&gt;&lt;', '');
                                result = result.replaceAll('&quot;', '');
                                result = result.replaceAll('&#39;', '');
                                string HTML_TAG_PATTERN = '<.*?>';
                                pattern myPattern = pattern.compile(HTML_TAG_PATTERN);
                                matcher myMatcher = myPattern.matcher(result);
                                result = myMatcher.replaceAll('');
                                system.debug('####'+result);
                                if(result != ''){                                        
                                    strValues = String.valueOf(obj).split('getHtmlBody=')[1].split('getTargetObjectId')[0].split(';getInReplyTo')[0];
                                    system.debug('strValues:::::'+String.valueOf(obj).split('getHtmlBody=')[1].split('getTargetObjectId')[0].split(';getInReplyTo')[0]);
                                    Showonpage(strValues);
                                }
                            }
                        }

                    }Catch(Exception e){
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,e.getMessage()));
                        system.debug('Exception::::'+e.getMessage());
                    }   
                }  
            
            }
        }
        return null;
    }

    public void Showonpage(string strData){
        system.debug('Mail body::::::::::::'+strData);
        strBocy = strData;
    }

    /****************This Method is used to send email ********************************/
    public pageReference SendMail()
    {
        try{
        	
        Community_Items__c objcom;
        string strID = ApexPages.currentPage().getParameters().get('id');
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        system.debug('strID::::'+strID);
        system.debug('rightvalues:::::'+rightvalues);
        
        map<string,string> mapCommunityRec = new map<string,string>(); 
        if(strID !=null)
        {
            objCom = [select id,Name,Title__c,Type__c,ALT_Tag__c,Brainshark_9_Digit_Number__c,recordtypeid,Hub_Email_Subject__c from Community_Items__c where id =: strID];
            system.debug('objCom :::'+objCom);
            mapCommunityRec.put(objCom.Type__c,objCom.Type__c);
        }

        if(rightvalues.isEmpty())
        {
            system.debug('rightvalue::::'+rightvalues);
            ErrorMessage = 'Please select atleast one Community View.';
            system.debug('ErrorMessage:::::::::: '+ErrorMessage );
        }else if(!rightvalues.isEmpty())
        {
            ErrorMessage = '';
            system.debug('rightvalues**********'+rightvalues);
            list<string> lststrFalueres = new list<string>();

            for(string str : rightvalues)
            {
                if(mapRightVals.get(str) != null)
                {
                    lststrFalueres.add(mapRightVals.get(str));
                }
            }
            
            system.debug('Selected::::::::::'+lststrFalueres);
            
            list<Campaign> lstCamp = [select id,name,Orgwide_Email_addresess__c from Campaign where Name IN:lststrFalueres ];
             
            system.debug('lstCamp::::'+lstCamp);
            //system.debug('lstCamp size::::'+lstCamp.size());
            
            set<id> setIds = new set<id>();
            Map<String,String> mapCampaignWithOrgEmail = new Map<String,String>();
            for(Campaign objCap : lstCamp)
            {
                setIds.add(objCap.id);
                
                if(objCap.Orgwide_Email_addresess__c != null)
                    mapCampaignWithOrgEmail.put(objCap.id,objCap.Orgwide_Email_addresess__c);
            }
            
            lstids = new list<id>();
            
            lstids.addall(setIds);
            system.debug('lstids:::::'+lstids);
            system.debug('setIds:::::'+setIds);
            system.debug('mapCampaignWithOrgEmail:::::'+mapCampaignWithOrgEmail);
             
            if(setIds != null && !setIds.isEmpty())
            {
                system.debug('mapCamCamMems:::'+mapCamCamMems);
                //system.debug('CampaignMembers:::'+lstMember);
                if(mapCamCamMems != null && !mapCamCamMems.isEmpty())
                {
                	List<user> lstUsers = [select id,Email from User where isActive = true and id=:Userinfo.getUserId()];
                	String emailId = '';
                	if(lstUsers != null && !lstUsers.isEmpty())
                	    emailId = lstUsers[0].Email;
                	
                	Btach_SendHubNotifications obj = new Btach_SendHubNotifications(strID,lstids,objcom,rightvalues,mapCampaignWithOrgEmail,strValues,emailId);
                	Database.executeBatch(obj,1);
                	responceMessage = 'Success';
                	ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Job initiated successfully'));
                }
                }
            }
       
      }Catch(Exception ex) 
      {
        string onlyId = '';
        system.debug('===error message==>>'+ex.getMessage());
        if(ex.getMessage() != null && (ex.getMessage()).indexOf('id : ')>-1)
        {
            system.debug('===error entered==>>');
            string withId = (ex.getMessage()).split('id : ')[1];
            system.debug('===error withId==>>'+withId);
            onlyId = withId.indexOf(':')>-1?(withId.split(':')[0]).trim():withId.trim();
        }
        system.debug('===error onlyId==>>'+onlyId);
        if(onlyId != '' && onlyId !=null){           
           string str= System.URL.getSalesforceBaseUrl().toExternalForm()+'/'+onlyId+'\'';           
           ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getMessage()+'.\n  <a onclick="window.top.location.href=\''+str+'\"><b><font color="red"> Click here </font></b></a> to go that record.'));
        }else
          ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getMessage()));
          
        responceMessage = 'Got error while sending email. i.e.,-->'+ex.getMessage();
        return null;
      }
        return null;
    }

}