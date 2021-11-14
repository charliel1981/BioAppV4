public class MobileDynamicUtil 
{
    @future
	public static void sendEmailForMobileLead(string ops, List<Id> mdIds, Map<Id, Boolean> oldMdIdToSenEmailValMap)
    {
        Id recTypeId = [Select Id from RecordType where SObjectType = 'Mobile_Dynamic__c'and DeveloperName = 'Mobile_Lead'].Id;        
        if(mdIds != null && mdIds.size() > 0)
        {
            List<Mobile_Dynamic__c> mdList = new List<Mobile_Dynamic__c>();
            List<Mobile_Dynamic__c> mdSendEmailList = new List<Mobile_Dynamic__c>();
            List<Attachment> attachmentList = new List<Attachment>();
            Map<Id, Attachment> mdIdToAttachmentMap = new Map<Id, Attachment>();
            List<Id> mdSEList = new List<Id>();
            Map<Id, Messaging.EmailFileAttachment> mdIdToEmailAttachmentMap = new Map<Id, Messaging.EmailFileAttachment>();
            
            mdList = [Select Id, Send_Email__c, Lead_name__c, App_User_Email_Address__c, Lead_Email_Address__c, RecordtypeId, Lead_Photo_Base64__c, OwnerId 
                      	from Mobile_Dynamic__c where Id In :mdIds and RecordTypeId = :recTypeId];
            
            if(mdList != null && mdList.size() > 0)
            {
                for(Mobile_Dynamic__c md : mdList)
                {
                    if(md.Send_Email__c)
                    {
                        mdSendEmailList.add(md);
                        mdSEList.add(md.Id);
                    }                        
                }
                
                attachmentList = [Select Id, Body, Name, ParentId from Attachment where ParentId In :mdSEList order by ParentId, CreatedDate desc];                
                if(attachmentList != null && attachmentList.size() > 0)
                {
                    for(Attachment attach : attachmentList)
                    {
                        if(mdIdToAttachmentMap.isEmpty() || (!mdIdToAttachmentMap.isEmpty() && mdIdToAttachmentMap.size() > 0 
                                                                        && !mdIdToAttachmentMap.containsKey(attach.ParentId)))
                        {
                            mdIdToAttachmentMap.put(attach.ParentId, attach);
                        }
                    }
                }  
                
                if(mdIdToAttachmentMap != null && mdIdToAttachmentMap.size() > 0)
                {
                    for(Id mdId : mdIdToAttachmentMap.keySet())
                    {               
                        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                        efa.setBody(mdIdToAttachmentMap.get(mdId).Body);
                        efa.setFileName(mdIdToAttachmentMap.get(mdId).Name);
                        mdIdToEmailAttachmentMap.put(mdId, efa);
                    }
                }  
                
                List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
                EmailTemplate et = [SELECT Id, Name  FROM EmailTemplate WHERE DeveloperName = 'Hub_App_Lead_capture1'];
                OrgWideEmailAddress owa  =  [select Id, Address, IsAllowAllProfiles from OrgWideEmailAddress where DisplayName = 'Biocomposites' limit 1];
                List<Task> taskList = new List<Task>();  
                
                for(Mobile_Dynamic__c md : mdSendEmailList)
                {                    
                    if((ops == 'Insert' && md.Send_Email__c) || (ops == 'Update' && md.Send_Email__c
                                                                 && (oldMdIdToSenEmailValMap != null && oldMdIdToSenEmailValMap.size() > 0 && oldMdIdToSenEmailValMap.containsKey(md.Id))
                                                                 && md.Send_Email__c != oldMdIdToSenEmailValMap.get(md.Id)))
                    {       
                        Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(et.Id, UserInfo.getUserId(), md.Id);
                        List<string> toAddress = new List<string>{md.App_User_Email_Address__c,md.Lead_Email_Address__c};
                        mail.setToAddresses(toAddress);
                        mail.setSubject('Lead for '+((md.Lead_name__c != null) ? md.Lead_name__c : ''));
                        mail.setOrgWideEmailAddressId(owa.Id);
                        mail.setSaveAsActivity(false);
                        mail.setUseSignature(false); 
                        
                        if((ops == 'Insert' && md.Lead_Photo_Base64__c != null) || (ops == 'Update' && md.Lead_Photo_Base64__c != null && 
                                                                                    (mdIdToEmailAttachmentMap != null && mdIdToEmailAttachmentMap.size() > 0 && mdIdToEmailAttachmentMap.containsKey(md.Id))))
                        {
                           mail.setFileAttachments(new Messaging.EmailFileAttachment[]{mdIdToEmailAttachmentMap.get(md.Id)}); 
                        }
                        
                        allmsg.add(mail); 
                        
                        String descStr = 'Email sent to \''+md.App_User_Email_Address__c+ '\' and \''+md.Lead_Email_Address__c+'\'. \r\n Content of the email is from template: '+et.Name;
                        Task emailTask = new Task(WhatId = md.Id, Subject = 'Email', Status = 'Completed', 
                                                  Priority = 'Normal', OwnerId = md.OwnerId, ActivityDate = System.today(),
                                                 Description = descStr);
                        taskList.add(emailTask);    
                                      
                    }
                }      
                
                if(taskList.size() > 0)
                	insert(taskList);
           
                if(!Test.isRunningTest())
                {
                   Messaging.SendEmailResult[] emailList = Messaging.sendEmail(allmsg,false);
                }
            }
        }
    }
}