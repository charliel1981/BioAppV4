@IsTest
public with sharing class MCChangePasswordDistAppControllerTest {
    @IsTest(SeeAllData=true)
    public static void testMCChangePasswordDistAppController() {
        // Instantiate a new controller with all parameters in the page
        MCChangePasswordDistAppController controller = new MCChangePasswordDistAppController();
        controller.newPassword = 'qwerty1'; 
        controller.verifyNewPassword = 'qwerty1';                
        
        System.assertEquals(controller.changePassword(),null);                           
    }
}