@isTest
private class Test_UserCommunityViewValCon {

    static testMethod void myUnitTest() {
        // TO DO: implement unit test
   
       
        
           string strName;
           string strType;
           
            Account objA1 = new Account();
            objA1.Name = 'testAcc';
            objA1.Update_date__c = system.today();
            insert objA1;
            
            Contact objC1 = new Contact();
            objC1.LastName = 'testCom';
            objC1.Accountid = objA1.id;
            objC1.Email = 'test@gmail.com';
            insert objC1;        
            
            Contact objC22 = new Contact();
            objC22.LastName = 'testCom';
            objC22.Accountid = objA1.id;
            objC22.Email = 'test@gmail.com';
            insert objC22;        
                 
            Campaign objCmp1 = new Campaign();
            objCmp1.Name = 'testCampName';
            objCmp1.Show_In_Hub_Push__c = true;
            objCmp1.IsActive = true;
            objCmp1.Standard_User_Profile__c = true;
            insert objCmp1;
            
            Campaign objCmp2 = new Campaign();
            objCmp2.Name = 'testCampName2';
            objCmp2.Show_In_Hub_Push__c = true;
            objCmp2.IsActive = true;
            objCmp2.Standard_User_Profile__c = true;
            insert objCmp2;
            
            
            /*list<CampaignMember> lstMem = new list<CampaignMember>();
            CampaignMember objMem2 = new CampaignMember();
            objMem2.CampaignId = objCmp1.id;
            objMem2.ContactId = objC1.id;
            insert objMem2;*/
            
            /*CampaignMember objMem3 = new CampaignMember();
            objMem3.CampaignId = objCmp1.id;
            objMem3.ContactId = objC22.id;
            insert objMem3;*/
            
            
            //lstMem.add(objMem2);
            //lstMem.add(objMem3);
            
            
            list<CampaignMember> lstCampmem = new list<CampaignMember>();
            CampaignMember objMem4 = new CampaignMember();
            objMem4.CampaignId = objCmp2.id;
            objMem4.ContactId = objC22.id;
            insert objMem4;
            lstCampmem.add(objMem4);
            
            
       
        list<Recordtype > lstRec = [SELECT ID,Name, SobjectType from Recordtype WHERE SobjectType='Community_Items__c' ];
           Community_Items__c objCus = new Community_Items__c();
           objCus.Type__c  ='Marketing collateral';
           objCus.Title__c = 'testitle';
           objCus.URL_For_Image__c =  'testIMG';
           objCus.Profile__c = 'Management';
           if(lstRec[0].id != null){
                  objCus.RecordTypeId = lstRec[0].id;
           }
           insert objCus;
           
           strName = objCus.id;
           strType = objCus.Title__c;
           ApexPages.StandardController sc = new ApexPages.standardController(objCus);
           UserCommunityViewValCon objCon = new UserCommunityViewValCon(sc);
           ApexPages.currentPage().getParameters().put('id',objCus.id);
           objCon.getItems();
           //string strFName = objCmp1.Name+' '+'(' + lstMem.size() +')';
           string strSName = objCmp2.Name+' '+'('+lstCampmem.size() +')';
           objCon.leftselected = new list<String>{strSName};
           objCon.rightselected = new list<String>{strSName};
           objCon.rightvalues = new Set<String>{strSName};
           objCon.selectedValues();
           objCon.getSelectedValues();
           objCon.unselectclick();
           objCon.getUnSelectedValues();
          
          
          
           User thisUser4 = [ Select Id from User where Id = :UserInfo.getUserId() ];
           System.runAs(thisUser4){
           ComunityItemTypeTemplate__c  mycs2 = ComunityItemTypeTemplate__c.getValues('Test');
           if(mycs2 == null) {
           mycs2 = new ComunityItemTypeTemplate__c();
           mycs2.Name = '1';
           mycs2.CommunityItemRecordType__c = 'Test';
           mycs2.Template_Name__c = 'testTemp';
           insert mycs2;
           }
           }
           
            objCon.Preparedata();
            objCon.SendMail();
            
            Account objA = new Account();
            objA.Name = 'testAcc';
            objA.Update_date__c = system.today();
            insert objA;
            
            Contact objC = new Contact();
            objC.LastName = 'testCom';
            objC.Accountid = objA.id;
            objC.Email = 'test@gmail.com';
            insert objc;        
            
             Contact objC2 = new Contact();
            objC2.LastName = 'testCom';
            objC2.Accountid = objA.id;
            objC2.Email = 'test@gmail.com';
            insert objc2;        
            
                 
            Campaign objCmp = new Campaign();
            objCmp.Name = 'testCampName';
            insert objCmp;
            
             Campaign objCmp22 = new Campaign();
            objCmp22.Name = 'testCampName2';
            insert objCmp22;
            
            /*CampaignMember objMem = new CampaignMember();
            objMem.CampaignId = objCmp.id;
            objMem.ContactId = objc.id;
            insert objMem;*/
            
            /*CampaignMember objMem1 = new CampaignMember();
            objMem1.CampaignId = objCmp.id;
            objMem1.ContactId = objc2.id;
            insert objMem1;*/
            
            
      
    }
    
    static testMethod void myUnitTest2(){
       
            Community_Items__c objCus = new Community_Items__c();
            objCus.Type__c  ='Marketing collateral';
            objCus.Title__c = 'testitle';
            objCus.URL_For_Image__c =  'testIMG';
            objCus.Profile__c = 'Management';
           
            insert objCus;
            User thisUser = [ Select Id from User where Id = :UserInfo.getUserId() ];
            System.runAs( thisUser ){
            CustomProfilePermissions__c  mycs = CustomProfilePermissions__c.getValues('System Administrator');
            if(mycs == null) {
            mycs = new CustomProfilePermissions__c(Name= 'System Administrator');
            insert mycs;
            }
            }    
            EmailToComunityTypeCon.SendNotification(objCus.id);
            Community_Items__c objCus1 = new Community_Items__c();
            objCus1.Title__c = 'testitle';
            objCus1.URL_For_Image__c =  'testIMG';
            objCus1.Profile__c = 'Management';
            insert objCus1;
            User thisUser1 = [ Select Id from User where Id = :UserInfo.getUserId() ];
            System.runAs( thisUser1 ){
            CustomProfilePermissions__c  mycs1 = CustomProfilePermissions__c.getValues('System Administrator');
            if(mycs1 == null) {
            mycs1 = new CustomProfilePermissions__c(Name= 'System Administrator');
            insert mycs1 ;
            }
            }
        
            EmailToComunityTypeCon.SendNotification(objCus1.id);
            Community_Items__c objCus2 = new Community_Items__c();
            objCus2.Title__c = 'testitle';
            objCus2.Type__c = 'test';
            objCus2.URL_For_Image__c =  'testIMG';
            objCus2.Profile__c = 'Management';
            insert objCus2;
             User thisUser2 = [ Select Id from User where Id = :UserInfo.getUserId() ];
            System.runAs( thisUser1 ){
            ComunityItemTypeTemplate__c  mycs2 = ComunityItemTypeTemplate__c.getValues('Test');

            if(mycs2 == null) {
            mycs2 = new ComunityItemTypeTemplate__c();
            mycs2.Name = '1';
            mycs2.CommunityItemRecordType__c = 'test';
            mycs2.Template_Name__c = 'testTemp';
            insert mycs2;
            }
            }
            EmailToComunityTypeCon.SendNotification(objCus2.id);
      
    }
     
}