/*
Developed by : Ankush/Uday
Date         : 23-Nov-2015
Description : To sync contact detials with respective User details.
*/
trigger SyncUserWithContactDetails on Contact (after update) 
{
  Map<String,Contact> mapIdWithContact = new Map<String,Contact>();
  Set<String> setAccountIds = new Set<String>();
  
  for(Contact con : trigger.new)
  {
    if(
           (con.FirstName != null && con.FirstName != trigger.oldMap.get(con.id).FirstName)
        || (con.LastName != null && con.LastName != trigger.oldMap.get(con.id).LastName)    
        || (con.AccountId != null && con.AccountId != trigger.oldMap.get(con.id).AccountId) 
        || (con.Email != null && con.Email != trigger.oldMap.get(con.id).Email)
        || (con.Job_Title__c != null && con.Job_Title__c != trigger.oldMap.get(con.id).Job_Title__c)
        
        
        || (con.MailingStreet!= null && con.MailingStreet!= trigger.oldMap.get(con.id).MailingStreet)
        || (con.MailingState!= null && con.MailingState != trigger.oldMap.get(con.id).MailingState)
        || (con.MailingPostalCode!= null && con.MailingPostalCode!= trigger.oldMap.get(con.id).MailingPostalCode)
        || (con.MailingCountry!= null && con.MailingCountry!= trigger.oldMap.get(con.id).MailingCountry)
        || (con.MailingCity!= null && con.MailingCity!= trigger.oldMap.get(con.id).MailingCity)
      )
    {
        mapIdWithContact.put(con.id,con);
        setAccountIds.add(con.AccountId);
    }
  }
  
  if(!mapIdWithContact.isEmpty())
  {
    List<User> listUsersToUpdate = new List<User>();
    Map<String,string> mapAccWithNames = new Map<String,string>();
    
    for(Account acc : [select Name from Account where id IN:setAccountIds])
    {
       mapAccWithNames.put(acc.id,acc.name);    
    }
    
    for(User userObj : [SELECT id,Email,CompanyName,FirstName,LastName,ContactId,country,state,City,street,PostalCode,Title FROM User WHERE contactId IN:mapIdWithContact.keySet() and IsActive = true])
    {
        if(mapIdWithContact.get(userObj.ContactId) != null)
         {
             if(mapIdWithContact.get(userObj.ContactId).FirstName != null)
               userObj.FirstName = mapIdWithContact.get(userObj.ContactId).FirstName;
                            
             
             if(mapIdWithContact.get(userObj.ContactId).MailingStreet!= null)
               userObj.street = mapIdWithContact.get(userObj.ContactId).MailingStreet;
               
               if(mapIdWithContact.get(userObj.ContactId).MailingState!= null)
               userObj.state= mapIdWithContact.get(userObj.ContactId).MailingState;
               
               if(mapIdWithContact.get(userObj.ContactId).MailingPostalCode!= null)
               userObj.PostalCode = mapIdWithContact.get(userObj.ContactId).MailingPostalCode;
               
               if(mapIdWithContact.get(userObj.ContactId).MailingCountry!= null)
               userObj.country= mapIdWithContact.get(userObj.ContactId).MailingCountry;
               
               
              if(mapIdWithContact.get(userObj.ContactId).MailingCity!= null)
               userObj.City= mapIdWithContact.get(userObj.ContactId).MailingCity; 
               
               
               if(mapIdWithContact.get(userObj.ContactId).LastName != null)
               userObj.LastName = mapIdWithContact.get(userObj.ContactId).LastName;
               
               
               
             if(mapIdWithContact.get(userObj.ContactId).Email != null)
               userObj.Email = mapIdWithContact.get(userObj.ContactId).Email;
            
             if(mapIdWithContact.get(userObj.ContactId).AccountId != null && mapAccWithNames.get(mapIdWithContact.get(userObj.ContactId).AccountId) != null)
               userObj.CompanyName = mapAccWithNames.get(mapIdWithContact.get(userObj.ContactId).AccountId); 
             
             if(mapIdWithContact.get(userObj.ContactId).Job_Title__c != null)
               userObj.Title = mapIdWithContact.get(userObj.ContactId).Job_Title__c;
         
             listUsersToUpdate.add(userObj);
         }
    }
    
    
    if(!listUsersToUpdate.isEmpty())
       update listUsersToUpdate;
  }
  
}