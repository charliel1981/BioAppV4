global class Btach_SendHubNotifications implements Database.Batchable<sObject>,Database.Stateful
{
   global List<String> lstids = new List<String>();
   global Community_Items__c objcom = new Community_Items__c();
   global Set<string> rightvalues = new Set<string>();
   global Map<String,String> mapCampaignWithOrgEmail = new Map<String,String>();
   global String strID;
   global String strValues = '';
   global String Contactids = '';
   global String sendEmailId = '';
   //global Messaging.SingleEmailMessage messages = new Messaging.SingleEmailMessage();
   
   global Btach_SendHubNotifications(String strIDVal,List<String> lstCampaignids,Community_Items__c objcom1,Set<string> rightvaluesSet,Map<String,String> mapCampaignWithOrgEmailParm,String strValuesVal,String sendEmailIds)
   {
   	  objcom = objcom1;
      lstids = lstCampaignids;
      rightvaluesSet = rightvalues;
      strValues = strValuesVal;
      mapCampaignWithOrgEmail = mapCampaignWithOrgEmailParm;
      strID = strIDVal;
      sendEmailId = sendEmailIds;
      
      system.debug('==objcom %%%%====>>'+objcom);
      system.debug('==lstids %%%%====>>'+lstids);
      system.debug('==rightvaluesSet %%%%====>>'+rightvaluesSet);
      system.debug('==mapCampaignWithOrgEmail %%%%====>>'+mapCampaignWithOrgEmail);
      system.debug('==strID %%%%====>>'+strID);
      
   }

   global Database.QueryLocator start(Database.BatchableContext BC)
   {
   	  String query = 'select id,contactid,contact.Email,Lead.Ownerid,Contact.Ownerid,campaignid,Leadid,Lead.Email from CampaignMember where campaignid IN:lstids';
      
      system.debug('==query %%%%====>>'+query);
      
      return Database.getQueryLocator(query);
   }

   global void execute(Database.BatchableContext BC, List<CampaignMember> listCampMembers)
   { 
   	 system.debug('==listCampMembers %%%%====>>'+listCampMembers);
   	 try
   	 {
      if(!listCampMembers.isEmpty())
      {
        Map<String,String> mapOrgEmailIdWithOrgId = new Map<String,String>();
        Map<string,string> MapCustom = new Map<string,string>();
        map<string,id> MapTempId = new map<string,id>();
        list<Task> lstTaskInsert = new list<Task>();
        String result = '';
                 
        list<Emailtemplate> lstEt = [select id,name from Emailtemplate];
        
        if(lstEt != null && !lstEt.isEmpty())
        {
            for(Emailtemplate objTemplate : lstEt)
            {
                MapTempId.put(objTemplate.Name,objTemplate.id);
            }
        }
        
        map<string,string> mapCommunityRec = new map<string,string>(); 
        if(strID !=null)
        {
            objCom = [select id,Name,Title__c,Type__c,ALT_Tag__c,Brainshark_9_Digit_Number__c,Hub_Email_Subject__c,recordtypeid from Community_Items__c where id =: strID];
            system.debug('objCom :::'+objCom);
            mapCommunityRec.put(objCom.Type__c,objCom.Type__c);
        }
        
        for(OrgWideEmailAddress owea : [select Id,Address from OrgWideEmailAddress where Address IN:mapCampaignWithOrgEmail.values()])
        {
            mapOrgEmailIdWithOrgId.put(owea.address,owea.Id);
        }
        
        for (ComunityItemTypeTemplate__c ObjTemp : ComunityItemTypeTemplate__c.getAll().values())
        {
            MapCustom.put(ObjTemp.CommunityItemRecordType__c,ObjTemp.Template_Name__c);
        }
                 
      	for(Campaignmember objCmpMem : listCampMembers)
        {
        //system.debug('Lead Owner::'+objCmpMem.Lead.Ownerid);
        Task TaskObj = new Task();
        // TaskObj.Ownerid = objCmpMem.Lead.Ownerid;
        if(objCmpMem.Lead.Ownerid != null)
        {
            TaskObj.Ownerid = objCmpMem.Lead.Ownerid;
        }else if(objCmpMem.Contact.Ownerid != null)
        {
            TaskObj.Ownerid = objCmpMem.Contact.Ownerid;
        }
        TaskObj.Subject = ('Hub Push :'+' '+objCom.Hub_Email_Subject__c).length()> 255?('Hub Push :'+' '+objCom.Hub_Email_Subject__c).substring(0,252):('Hub Push :'+' '+objCom.Hub_Email_Subject__c);
        TaskObj.Status = 'Completed';
        //string str = rightvalues;
        string str = '';
        if(rightvalues != null && !rightvalues.isEmpty())
        {
            for(string s: rightvalues)
            {
                if(str == '')
                    str = s;
                else
                    str += ','+' '+s;
            }
        }
        if(str != null)
        {
            TaskObj.Description =   str;
        }

        if(objCmpMem.Leadid != null)
        {
            TaskObj.Whoid = objCmpMem.Leadid;
        }else if(objCmpMem.Contactid != null)
        {
            TaskObj.Whoid = objCmpMem.Contactid;
        }
        lstTaskInsert.add(TaskObj);

                                /**************************************************/
       list<string> lststr = new list<string>();
       if(objCmpMem.contact.Email != null)
       {
         system.debug('Emailssss::::'+objCmpMem.contact.Email);
         lststr.add(objCmpMem.contact.Email);
       }else if(objCmpMem.Lead != null && objCmpMem.Lead.Email != null)
	   {
	        lststr.add(objCmpMem.Lead.Email);
	   }
	   if(lstStr != null && !lstStr.isEmpty())
	   {
	        Messaging.SingleEmailMessage Mail = new Messaging.SingleEmailMessage();
	        //Mail.setToAddresses(lstStr);
	        
	        if(mapCampaignWithOrgEmail.get(objCmpMem.campaignid) != null && mapOrgEmailIdWithOrgId.get(mapCampaignWithOrgEmail.get(objCmpMem.campaignid)) != null)
	              Mail.setOrgWideEmailAddressId(mapOrgEmailIdWithOrgId.get(mapCampaignWithOrgEmail.get(objCmpMem.campaignid)));
	        
	        //mapCampaignWithOrgEmail
	        if(objCmpMem.contactid != null)
	        {
	            Mail.setTargetObjectId(objCmpMem.contactid );
	        }else if(objCmpMem.Leadid != null )
	        {
	            Mail.setTargetObjectId(objCmpMem.Leadid );
	        }else
	        {
	        	Mail.setToAddresses(lstStr);
	        }
        if(MapCustom != null && !MapCustom.isEmpty() &&  MapTempId != null && !MapTempId.isEmpty() && mapCommunityRec != null && !mapCommunityRec.isEmpty())
        {
            Mail.setTemplateId(MapTempId.get(MapCustom.get(mapCommunityRec.get(objCom.Type__c))));
        }

            Mail.setSaveAsActivity(false);    
            system.debug('strid:::::::::::'+strID);
            Mail.setWhatId(strID); 
            
            //messages = Mail;
               
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{Mail}); 
        }
      }
      
        if(lstTaskInsert != null && !lstTaskInsert.isEmpty())
        {
           insert lstTaskInsert;
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
	        Contactids = Contactids + ' \n ' +onlyId;
	    }
	    system.debug('===error onlyId==>>'+onlyId);
	 }
   }

   global void finish(Database.BatchableContext BC)
   {                   
   	    Boolean blnstatus = false;
   	    system.debug('==strValues===in finish===>>'+strValues);
   	    if(strValues != null)
         {
          String result= '';
          List<Task> listTasksToInsert = new List<Task>();
          //Task creation for Campaign 
           string strbody = '';
           //system.debug('messages size:::::::::::::'+messages.size());
            if(strValues != null)
            {
             
                string html= strValues; 
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

                for(string str : lstids)
                {
                    if(result != null && result !='')
                    {
                        Task objCampTask = new Task();
                        objCampTask.Subject = ('Hub Push :'+' '+objCom.Hub_Email_Subject__c).length()> 255?('Hub Push :'+' '+objCom.Hub_Email_Subject__c).substring(0,252):('Hub Push :'+' '+objCom.Hub_Email_Subject__c);
                        objCampTask.Status = 'Completed';
                        objCampTask.Description = result;
                        objCampTask.WhatId = str ;
                        listTasksToInsert.add(objCampTask);
                    }   
                }
                }

                system.debug('===listTasksToInsert==>>'+listTasksToInsert);
                if(!listTasksToInsert.isEmpty()){
                    insert listTasksToInsert;
                     blnstatus = true;
                }
                }//Messages over
                
                if(blnstatus == true)
                {
                    list<Task> lstTask = new list<Task>(); 
                    Task objTask = new Task();
                    objTask.Ownerid = UserInfo.getUserId();
                    objTask.Subject = ('Hub Push :'+' '+objCom.Hub_Email_Subject__c).length()> 255?('Hub Push :'+' '+objCom.Hub_Email_Subject__c).substring(0,252):('Hub Push :'+' '+objCom.Hub_Email_Subject__c);
                    objTask.Status = 'Completed';
                    string str = '';
                    if(rightvalues != null && !rightvalues.isEmpty())
                    {
                        for(string s: rightvalues){
                            if(str == '')
                                str = s;
                            else
                                str += ','+' '+s;
                        }
                    }
                                        
                    if(str != null){
                        objTask.Description =   str;
                    }
                    objTask.Whatid = strID;
                    lstTask.add(objTask);
                    if(lstTask != null && !lstTask.isEmpty())
                    {
                        insert lstTask;
                        system.debug('lstTask::::'+lstTask);
                    } 
                }
                
                system.debug('===Contactids===>>'+Contactids);
                //Sending Failure Emails
                if(Contactids != null && Contactids != '')
                {
               	    Messaging.SingleEmailMessage Mail = new Messaging.SingleEmailMessage();
               	    if(sendEmailId != null && sendEmailId !='')
			           Mail.setToAddresses(new list<String>{sendEmailId});
			        else
			           Mail.setToAddresses(new list<String>{'charlie@ceterna.com'});
			           
			        Mail.setPlainTextBody('Email sending failed to below contacts, invalid email ids \n \n '+Contactids);
		            Mail.setSaveAsActivity(false);  
		            Mail.setSubject('Biocomposite hub push - Email sent failed contacts list.');  
		            system.debug('strid:::::::::::'+strID);
		            Mail.setWhatId(strID); 
		            
		            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{Mail}); 
                }//
   }
}