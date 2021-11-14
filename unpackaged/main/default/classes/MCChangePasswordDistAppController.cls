/**
 * An apex page controller that exposes the change password functionality
 */
public with sharing class MCChangePasswordDistAppController {
    public String newPassword {get; set;}
    public String verifyNewPassword {get; set;}        
    
    public PageReference changePassword() {
        return Site.changePassword(newPassword, verifyNewPassword, null);    
    }     
    
    public MCChangePasswordDistAppController() {}
}