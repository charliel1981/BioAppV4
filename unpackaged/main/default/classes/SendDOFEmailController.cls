/**
*   @description : Future method used to send dof email
**/
public without sharing class SendDOFEmailController {

	private static List<EmailTemplate> emailTemplatesList;
	private static List<OrgWideEmailAddress> orgWideEmailAddressList;
	@testVisible
	private static List<Dof__c> dofList;

	static{
		emailTemplatesList = [SELECT Id FROM EmailTemplate WHERE DeveloperName =: Constants.DOF_EMAIL_TEMPLATE_NAME LIMIT 1];
		orgWideEmailAddressList = [SELECT Id FROM OrgWideEmailAddress WHERE Address =: Constants.HUB_APP_EMAIL_ADDRESS LIMIT 1];
	}
	
	/**
	*   @description : Future method used to send dof email
	**/
	@future
	public static void sendEmail(Set<Id> recordIds){

		if(!Test.isRunningTest()){
			dofList = [SELECT Id, Dist_Email__c, Bio_Email_To_Send_To__c, Created_By_Email__c, Hospital_Email_Address__c, From_Field_for_Email__c FROM Dof__c
									WHERE Id IN :recordIds LIMIT 40000];
		}

		Savepoint dbSavePoint = Database.setSavepoint();

		try{
			List<Messaging.SingleEmailMessage> emailsList = new List<Messaging.SingleEmailMessage>();
			Map<String, Contact> contactsMap = createContactsMap(dofList);

			// create emails
			if(!emailTemplatesList.isEmpty()){
				for(Dof__c dof : dofList){
					if(!String.isBlank(dof.Dist_Email__c) && contactsMap.containsKey(dof.Dist_Email__c)){
						emailsList.add(createEmailMessage(dof,contactsMap.get(dof.Dist_Email__c)));
					}

					if(!String.isBlank(dof.Bio_Email_To_Send_To__c) && contactsMap.containsKey(dof.Bio_Email_To_Send_To__c)){
						emailsList.add(createEmailMessage(dof,contactsMap.get(dof.Bio_Email_To_Send_To__c)));
					}

					if(!String.isBlank(dof.Created_By_Email__c) && contactsMap.containsKey(dof.Created_By_Email__c)){
						emailsList.add(createEmailMessage(dof,contactsMap.get(dof.Created_By_Email__c)));
					}

					if(!String.isBlank(dof.Hospital_Email_Address__c) && contactsMap.containsKey(dof.Hospital_Email_Address__c)){
						emailsList.add(createEmailMessage(dof,contactsMap.get(dof.Hospital_Email_Address__c)));
					}
				}

				// if emails list is not empty
                if(!emailsList.isEmpty()) {
                  Messaging.sendEmail(emailsList);
                  // set timestamp on dof for email sent
                  for(Dof__c dof : dofList){
                    dof.Email_Sent__c = DateTime.now();
                  }
                  update dofList;   
                }

				delete contactsMap.values();
			}
		}catch(Exception ex){
			Database.rollback(dbSavePoint);
		}
	}

	/**
	*   @description : Method to create single email message
	**/
	private static Messaging.SingleEmailMessage createEmailMessage(Dof__c dof, Contact contact){
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setTemplateId(emailTemplatesList[0].Id);
		mail.setTargetObjectId(contact.Id);
		mail.setwhatId(dof.Id);
		mail.setOrgWideEmailAddressId(orgWideEmailAddressList[0].Id);
		return mail;
	}

	/**
	*   @description : Method used to create contacts
	**/
	private static Map<String, Contact> createContactsMap(List<Dof__c> dofList){
		Map<String, Contact> contactEmailByRecordsMap = new Map<String, Contact>();
		List<Contact> contactsList = new List<Contact>();

		// get dof
		for(String emailAddress : getEmails(dofList)){
			contactsList.add(new Contact(LastName='Test',Email=emailAddress));
		}

		// create contacts
		if(!contactsList.isEmpty()){
			insert contactsList;

			for(Contact contact : contactsList){
				if(!contactEmailByRecordsMap.containsKey(contact.Email)){
					contactEmailByRecordsMap.put(contact.Email,contact);
				}
			}	
		}
		return contactEmailByRecordsMap;
	}

	
	/**
	*   @description : Method get Emails list
	**/
	private static Set<String> getEmails(List<Dof__c> dofList){
		Set<String> emailsList = new Set<String>();


		for(Dof__c dof : dofList){

			if(!String.isBlank(dof.Dist_Email__c)){
				emailsList.add(dof.Dist_Email__c);
			}

			if(!String.isBlank(dof.Bio_Email_To_Send_To__c)){
				emailsList.add(dof.Bio_Email_To_Send_To__c);
			}

			if(!String.isBlank(dof.Created_By_Email__c)){
				emailsList.add(dof.Created_By_Email__c);
			}

			if(!String.isBlank(dof.Hospital_Email_Address__c)){
				emailsList.add(dof.Hospital_Email_Address__c);
			}
		}
		return emailsList;
	}
}