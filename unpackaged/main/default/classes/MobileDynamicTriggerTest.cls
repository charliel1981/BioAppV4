@isTest
private class MobileDynamicTriggerTest {
    
    static testMethod void testInsert()
    {
        Id recTypeId = [Select Id from RecordType where SObjectType = 'Mobile_Dynamic__c'and DeveloperName = 'Mobile_Lead'].Id;
        User u = createUser();
        insert u;
        
        Test.startTest();
        
		Mobile_Dynamic__c md;
		System.runAs(u) 
        {
            md = new Mobile_Dynamic__c(Event_Name__c = 'Test Event1', 
                                       Lead_Photo_Base64__c = 'Display Image', RecordTypeId = recTypeId);            
            insert md;        
        }
        
        Test.stopTest();
        
        List<Attachment> aList = [Select Id from Attachment where ParentId = :md.Id];
        System.assert(aList != null);
        System.assertEquals(1, aList.size());
    }
    
    static testMethod void testUpdate()
    {
        Id recTypeId = [Select Id from RecordType where SObjectType = 'Mobile_Dynamic__c'and DeveloperName = 'Mobile_Lead'].Id;
        User u = createUser();
        u.Territories__c = 'USA';
        insert u;
        
        Mobile_Dynamic__c md;
        Mobile_Dynamic__c md1;
        Mobile_Dynamic__c md2;
            
        System.runAs(u)
        {
            Test.startTest();
            
            md = new Mobile_Dynamic__c(Event_Name__c = 'Test Event1', RecordTypeId = recTypeId); 
            md1 = new Mobile_Dynamic__c(Event_Name__c = 'Test Event2', RecordTypeId = recTypeId); 
            md2 = new Mobile_Dynamic__c(Event_Name__c = 'Test Event3', RecordTypeId = recTypeId); 
            
            insert new List<Mobile_Dynamic__c>{md, md1, md2};
        
        
            List<Attachment> aList = [Select Id from Attachment where ParentId = :md.Id];
            System.assert(aList == null || aList.isEmpty());
            
            md.Lead_Photo_Base64__c = 'Display Image1';
            md1.Lead_Photo_Base64__c = 'Display Image2';
            md2.Lead_Photo_Base64__c = 'Display Image3';
            update new List<Mobile_Dynamic__c>{md, md1, md2};
        
            List<Attachment> aList1 = [Select Id from Attachment where ParentId = :md.Id];
            System.assert(aList1 != null);
            System.assertEquals(1, aList1.size());
            
            md.Lead_Photo_Base64__c = null;
            update md;
        }
        
        Test.stopTest();       
    }
    
    private static User createUser()
    {
        Profile pf= [Select Id from profile where Name='System Administrator']; 

		String orgId = UserInfo.getOrganizationId(); 
		String dateString=String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');

		Integer RandomId = Integer.valueOf(Math.rint(Math.random()*1000000)); 
		String uniqueName = orgId + dateString + RandomId; 

		User u = new User(firstname = 'ABC', 
        lastName = 'XYZ', 
        email = uniqueName + '@test' + orgId + '.org', 
        Username = uniqueName + '@test' + orgId + '.org', 
        EmailEncodingKey = 'ISO-8859-1', 
        Alias = uniqueName.substring(18, 23), 
        TimeZoneSidKey = 'America/Los_Angeles', 
        LocaleSidKey = 'en_US', 
        LanguageLocaleKey = 'en_US', 
        ProfileId = pf.Id, 
        Territories__c = 'UK'); 
        return u;
    }
}