global with sharing class MCLoginDistAppController {
    global String username {get; set;}
    global String password {get; set;}
    global string usernameToSendEmail {set; get;}
    global Boolean isGuestUser {get; set;}
    
    global MCLoginDistAppController() {
        this.isGuestUser = Auth.CommunitiesUtil.isGuestUser();
    }
    
    global PageReference login() {
        if (String.isNotBlank(username) && String.isNotBlank(password)) {
            String startUrl = System.currentPageReference().getParameters().get('startURL');
            // system.debug('@@@ startUrl:'+startUrl);
            if (String.isNotBlank(startUrl)) {
                return Site.login(username, password, startUrl);
            }
            return null;
        }
        return null;
    }
    
    public void sendEmailToUser() {
        if (String.isNotBlank(usernameToSendEmail)) {
            Boolean success = Site.forgotPassword(usernameToSendEmail);
        } else {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Enter a value in the User Name field.'); 
            ApexPages.addMessage(myMsg);
        }
    }
}