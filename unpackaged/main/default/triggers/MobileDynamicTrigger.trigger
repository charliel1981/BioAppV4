trigger MobileDynamicTrigger on Mobile_Dynamic__c (before insert, before update, after insert, after update) 
{
    if(Trigger.isAfter)
    {
        List<Attachment> attachments = new List<Attachment>();  
        Map<Id, Boolean> oldMdIdToSendEmailValMap = new Map<Id, Boolean>();
        List<Id> mdIds = new List<Id>();
                    
        for(Mobile_Dynamic__c md : Trigger.new)
        {
            if(md.Send_Email__c)
                mdIds.add(md.Id);
            
            Mobile_Dynamic__c oldMd;
            if(Trigger.isUpdate)
            {
                oldMd = Trigger.oldMap.get(md.Id);
                oldMdIdToSendEmailValMap.put(oldMd.Id, oldMd.Send_Email__c);
            }                
            
            if((Trigger.isInsert && md.Lead_Photo_Base64__c != null) ||
               (Trigger.isUpdate && md.Lead_Photo_Base64__c != null && md.Lead_Photo_Base64__c != oldMd.Lead_Photo_Base64__c))
            {
                Attachment attach = new Attachment();
                attach.contentType = 'image/png';
                attach.name = 'LeadPhoto.png';
                attach.parentId = md.Id;
                try
                {
                    attach.body = EncodingUtil.base64Decode(md.Lead_Photo_Base64__c);
                }
                catch(Exception e)
                {
                    md.Lead_Photo_Base64__c.addError('Could not convert base64 in to Attachment.');
                }
                
                attachments.add(attach);
            }            
        }
            
		try
        { 
            if(attachments.size() > 0) insert attachments;
        }
        catch(Exception e)
        {
            throw new CustomException('Could not save Base64 to attachment.');
        }
        
        if(Trigger.isInsert)
        	MobileDynamicUtil.sendEmailForMobileLead('Insert', mdIds, new Map<Id, Boolean>());
        else if(Trigger.isUpdate)
            MobileDynamicUtil.sendEmailForMobileLead('Update', mdIds, oldMdIdToSendEmailValMap);
    }
}