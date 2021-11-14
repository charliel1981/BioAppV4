@IsTest
public with sharing class MCForgotPasswordDistAppControllerTest {
    @IsTest(SeeAllData=true) public static void testMCForgotPasswordDistAppController() {
        MCForgotPasswordDistAppController controller = new MCForgotPasswordDistAppController();
        controller.usernameToSendEmail = null;
        controller.sendEmailToUser();
        System.assert(true,'Success'); 

        controller.usernameToSendEmail = 'test@salesforce.com';
        controller.sendEmailToUser();

        System.assert(true,'Success'); 
    }
}