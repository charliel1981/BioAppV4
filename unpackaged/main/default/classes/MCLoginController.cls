/**
 * An apex page controller that exposes the site login functionality
 */
global with sharing class MCLoginController {
    global String username {get; set;}
    global String password {get; set;}

    global MCLoginController () {
    }

    global PageReference login() {
        String startUrl = System.currentPageReference().getParameters().get('startURL');
        return Site.login(username, password, startUrl);
    }

    global PageReference selfReg() {
        String startUrl = System.currentPageReference().getParameters().get('startURL');
        return new PageReference(Site.getPathPrefix() + '/CommunitiesSelfRegMC?mcstartURL=' + EncodingUtil.urlEncode(startURL, 'UTF-8'));
    }

    global PageReference forgotPassword() {
        String startUrl = System.currentPageReference().getParameters().get('startURL');
        return new PageReference(Site.getPathPrefix() + '/ForgotPasswordMC?mcstartURL=' + EncodingUtil.urlEncode(startURL, 'UTF-8'));
    }

}