/**
* @description Class used to restrict data returned to app via mc utils syncMobileTable.
*              Restricts object Surgeon_in_Hospital__c records for a user.
*
*   To implement in Salesforce:
*     - Create a MobileCaddy 'Support Component' record with field mobilecaddy1__Name__c = SurgeonInHospitalRestriction
*     - On the MobileCaddy 'Mobile Table' record, set field 'Platform Object Support' to record created above
**/
global without sharing class SurgeonInHospitalRestriction implements mobilecaddy1.RestrictionInterface001_mc {

  global Set<Id> returnRestrictedIds(String jsonParams) {

    // Get running user record
    User user = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

    // Run different code if NOT community user (runs with sharing)
    if (user.ContactId == null) return SurgeonInHospitalNonCommunity.returnRestrictedIds();

    // Community users - gets data without sharing
    //============================================

    // Get limit from label
    String surgeonInHospitalCommunityUserLimitLabel = Label.SurgeonInHospitalCommunityUserLimit;
    Integer surgeonInHospitalCommunityUserLimit = isInteger(surgeonInHospitalCommunityUserLimitLabel) ? Integer.ValueOf(surgeonInHospitalCommunityUserLimitLabel) : 2500;

    // List of surgeons/hospitals we'll return Ids for
    List<Surgeon_in_Hospital__c> queryResults = new List<Surgeon_in_Hospital__c>();
    // Distributor Id used to restrict hospitals, which are then used to restrict surgeon/hospitals
    Set<Id> distributorId = new Set<Id>();

    // Community user will have an associated Contact record. Get the contact's distributor id from this record
    List<Contact> contact = [SELECT AccountId FROM Contact WHERE Id = :user.ContactId LIMIT 1];
    if (contact.size() > 0) {
      if (contact[0].AccountId != null) {
        distributorId.add(contact[0].AccountId);
      }
    }

  	// Use distributor id to select surgeons/hospitals
  	if (distributorId.size() > 0) {
  		queryResults = [SELECT Id
  						FROM Surgeon_in_Hospital__c
  						WHERE Hospital__c IN (SELECT Hospital__c FROM Hospital_in_a_Distributor__c WHERE Distributor__c IN :distributorId)];
  	} // end distributors found check if

    // Raise an error if more records are to be returned than our limit
    if (queryResults.size() > surgeonInHospitalCommunityUserLimit) {
      throw new mobilecaddy1.MC_001_mcException(mobilecaddy1.MC_001_mcException.MC_EXT_CLASS_LIMITS,'SurgeonInHospitalRestriction class - more than ' + surgeonInHospitalCommunityUserLimit + ' Surgeon_in_Hospital__c records will be returned.');
    }

    // Return set of ids
    if (queryResults.isEmpty()) {
      return new Set<Id>();
    } else {
      return (new Map<Id,SObject>(queryResults)).keySet();
    }
  } // end

  private static Boolean isInteger(String test) {
    try {
      Integer x = Integer.valueOf(test);
      return true;
    } catch(Exception e) {
      return false;
    }
  }

} // end class