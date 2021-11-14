/**
 * An apex page controller that exposes the site forgot password functionality
 */
public with sharing class MCForgotPasswordDistAppController {
    public String usernameToSendEmail {get; set;}
    
    public MCForgotPasswordDistAppController() {}

    public void sendEmailToUser() {
        if (String.isNotBlank(usernameToSendEmail)) {
            Boolean success = Site.forgotPassword(usernameToSendEmail);
        } else {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Enter a value in the User Name field.'); 
            ApexPages.addMessage(myMsg);
        }
    }
}