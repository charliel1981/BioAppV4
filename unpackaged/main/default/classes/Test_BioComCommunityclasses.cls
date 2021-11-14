/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest(seeAllData = true)
private class Test_BioComCommunityclasses {

    static testMethod void myUnitTest() {
        
        List<RecordType> recs =[select id,Name from RecordType where SobjectType='Community_Items__c' and name='Topics Of Interest'];
        
        Community_Items__c  com = new Community_Items__c();
            com.ALT_Tag__c = 'Test';
            com.Content__c ='test content';
            com.Profile__c ='system administrator';
            com.Title__c ='test title';
            com.Type__c = 'Topic of Interest / Notices';
            com.URL_For_Image__c ='www.google.com';
            com.RecordTypeId = recs[0].id;
        insert com;
        
        Community_Item_Permission_Link__c link = new Community_Item_Permission_Link__c();
        link.Profile__c = 'system administrator';
        link.Button_Link_URL__c ='www.google.com';
        link.Community_Item__c = com.id;
        insert link;
        
        List<RecordType> recs1 =[select id,Name from RecordType where SobjectType='Community_Items__c' and name='Left Panel'];
        
        Community_Items__c  com1 = new Community_Items__c();
            com1.ALT_Tag__c = 'Test';
            com1.Content__c ='test content';
            com1.Profile__c ='system administrator';
            com1.Title__c ='test title';
            com1.Type__c = 'Topic of Interest / Notices';
            com1.URL_For_Image__c ='www.google.com';
            com1.RecordTypeId = recs1[0].id;
            com1.Sort_Number__c = 1;
        insert com1;
        
        Community_Item_Permission_Link__c link1 = new Community_Item_Permission_Link__c();
        link1.Profile__c = 'system administrator';
        link1.Button_Link_URL__c ='www.google.com';
        link1.Community_Item__c = com1.id;
        insert link1;
        
        List<RecordType> recs11 =[select id,Name from RecordType where SobjectType='Community_Items__c' and name='Logo'];
        
        Community_Items__c  com11 = new Community_Items__c();
            com11.ALT_Tag__c = 'Test';
            com11.Content__c ='test content';
            com11.Profile__c ='system administrator';
            com11.Title__c ='test title';
            com11.Type__c = 'Topic of Interest / Notices';
            com11.URL_For_Image__c ='www.google.com';
            com11.RecordTypeId = recs11[0].id;
            com11.Sort_Number__c = 2;
        insert com11;
        
         Community_Item_Permission_Link__c link11 = new Community_Item_Permission_Link__c();
        link11.Profile__c = 'system administrator';
        link11.Button_Link_URL__c ='www.google.com'; 
        link11.Community_Item__c = com11.id;
        insert link11;
        
        List<RecordType> recs111 =[select id,Name from RecordType where SobjectType='Community_Items__c' and name='Header Image'];
        
        Community_Items__c  com111 = new Community_Items__c();
            com111.ALT_Tag__c = 'Test';
            com111.Content__c ='test content';
            com111.Profile__c ='system administrator';
            com111.Title__c ='test title';
            com111.Type__c = 'Topic of Interest / Notices';
            com111.URL_For_Image__c ='www.google.com';
            com111.RecordTypeId = recs111[0].id;
            com111.Sort_Number__c = 3;
        insert com111;
        
         Community_Item_Permission_Link__c link111 = new Community_Item_Permission_Link__c();
        link111.Profile__c = 'system administrator';
        link111.Button_Link_URL__c ='www.google.com';
        link111.Community_Item__c = com111.id;
        insert link111;
        
        BiocompController obj = new BiocompController();
        obj.CommBannerLogoURL ='www.google.com';
        obj.CommLogoURL ='www.google.com';
        //obj.getlistMember();
        obj.getlistleftPanels();
        obj.ViewData();
        obj.indexAssigned = com111.id;
        obj.EmailSubject = 'test';
        obj.EmailText = 'test';
        obj.SendMessage();
        obj.leftPanelRecordId =com111.id;
        obj.elernid = com111.id; 
        obj.createLeftRecord();
        obj.createlinkRecord();
        obj.createElearnRecord();
        obj.TotalSize = 1;
        obj.nextBtnClick();
        obj.getPreviousButtonEnabled();
        obj.previousBtnClick();
        obj.getNextButtonDisabled();
        obj.selectedPage = '1';
        obj.getlistleftPanelsRes();
        obj.getlistleftPanelsInternalOnly();
        obj.showPopup();
        obj.closePopup();
        obj.svaeUserDetails();
        obj.getMapleftPanelsVideos();
        
        LoginPageForCommunityCon con = new LoginPageForCommunityCon();
        con.login();
        con.loginError();
        
        con.username ='chandu3@ceterna.com';
        con.password ='appshark@2014';
        con.username1 ='chandu3@ceterna.com';
        con.password1 ='appshark@2014';
        con.usernameToSendEmail ='chandu3@ceterna.com';
        con.login();
        con.loginError();
        con.sendEmailToUser();
        
    }
}