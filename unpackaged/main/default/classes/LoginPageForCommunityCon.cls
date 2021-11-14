/*
Author      : Uday/Ankush
Date        : 03-09-2014
Description : This controller for Bio-composit community login page.Its Manupulates the community logins.
*/
global class LoginPageForCommunityCon{
    global String username{get;set;}
    global String password{get;set;}
    global String username1{get;set;}
    global String password1{get;set;}
    global string usernameToSendEmail{set;get;}
    
    global LoginPageForCommunityCon(){      
    }
    
    //Login method
    global PageReference login() 
    {
        if(username != null && password != null) {
             String startURL = apexpages.currentpage().getparameters().get('startURL');
             system.debug('==startURL22222 ==>>'+startURL);
             if (startURL == null) {
                 //return Site.login(username, password, '/apex/biocomp');  //ru: start page
                 return Site.login(username, password, '/apex/CommunityHomePage');
             }
             else {
                 return Site.login(username, password, startURL);
             }
        }
             
      return null;
    }
    
    //Login method
    global PageReference loginError() 
    {
        if(username1 != null && password1 != null)
        {
             String startURL = apexpages.currentpage().getparameters().get('startURL');
             system.debug('==startURL1111 ==>>'+startURL);
             if (startURL == null) {
                 //return Site.login(username1, password1, '/apex/biocomp'); //ru: start page
                 return Site.login(username1, password1, '/apex/CommunityHomePage');
             }
             else {
                 return Site.login(username1, password1, startURL);
             }
        }
             //return Site.login(username1, password1, '/apex/biocomp');
             
      return null;
    }
    //Sends an mail while resetting the password.
    public void sendEmailToUser() 
    {
        if(usernameToSendEmail != null && usernameToSendEmail !='')
        {
            boolean success = Site.forgotPassword(usernameToSendEmail);
        }else
        {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Enter a value in the User Name field.'); 
            ApexPages.addMessage(myMsg);
        }
    }   
}