@IsTest
public with sharing class MCLoginDistAppControllerTest {
    @IsTest(SeeAllData=true) public static void testSendEmail() {
        MCLoginDistAppController controller = new MCLoginDistAppController();
        controller.usernameToSendEmail = null;
        controller.sendEmailToUser();
        System.assert(true,'Success'); 

        controller.usernameToSendEmail = 'test@salesforce.com';
        controller.sendEmailToUser();
        System.assert(true,'Success'); 
    }

    @IsTest(SeeAllData=true) public static void testLogin() {
        MCLoginDistAppController controller = new MCLoginDistAppController();
        System.assertEquals(null,controller.login());
        
        controller.username = 'test@salesforce.com';
        controller.password = '123456';
        System.assertEquals(null,controller.login());
        
        System.currentPageReference().getParameters().put('startURL','zjhxbjfgakjgdsfygds');
        System.assertEquals(null,controller.login());
    }
}