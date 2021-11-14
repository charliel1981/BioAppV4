/**
 * An apex page controller that exposes the MC mobile app login functionality
 */
@IsTest global with sharing class MCLoginControllerTest {
    @IsTest(SeeAllData=true) global static void testMCLoginController() {
        // Instantiate a new controller with all parameters in the page
        MCLoginController controller = new MCLoginController();
        controller.username = 'test@salesforce.com';
        controller.password = '123456';

        System.assertEquals(controller.login(),null);
    }

    @IsTest(SeeAllData=true) global static void testMCLoginControllerSelfReg () {
        System.currentPageReference().getParameters().put('startURL','');
        // Instantiate a new controller
        MCLoginController controller = new MCLoginController();

        System.assertNotEquals(controller.selfReg(),null);
    }

    @IsTest(SeeAllData=true) global static void testMCLoginControllerForgotPassword () {
        System.currentPageReference().getParameters().put('startURL','');
        // Instantiate a new controller
        MCLoginController controller = new MCLoginController();

        System.assertNotEquals(controller.forgotPassword(),null);
    }

}