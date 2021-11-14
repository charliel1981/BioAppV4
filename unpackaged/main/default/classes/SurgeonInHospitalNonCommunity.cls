public with sharing class SurgeonInHospitalNonCommunity {

  public static Set<Id> returnRestrictedIds() {
    // Get user record so we can check for sys admin
    User user = [SELECT Community_View__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

    // Get limits from labels
    String surgeonInHospitalAdminLimitLabel = Label.SurgeonInHospitalAdminLimit;
    Integer surgeonInHospitalAdminLimit = isInteger(surgeonInHospitalAdminLimitLabel) ? Integer.ValueOf(surgeonInHospitalAdminLimitLabel) : 2500;
    String surgeonInHospitalStandardUserLimitLabel = Label.SurgeonInHospitalStandardUserLimit;
    Integer surgeonInHospitalStandardUserLimit = isInteger(surgeonInHospitalStandardUserLimitLabel) ? Integer.ValueOf(surgeonInHospitalStandardUserLimitLabel) : 2500;

    // List for query results
    List<Surgeon_in_Hospital__c> queryResults = new List<Surgeon_in_Hospital__c>();

    // If sys admin, then return rows based on limit
    if (user.Community_View__c == 'System Administrator') {
      queryResults = [SELECT Id FROM Surgeon_in_Hospital__c WHERE Hospital__r.Name != NULL LIMIT :surgeonInHospitalAdminLimit];
    } else {
      // Standard user (not sys admin nor community)
      queryResults = [SELECT Id FROM Surgeon_in_Hospital__c WHERE Hospital__r.Name != NULL];

      // Raise an error if more records are to be returned than our limit
      if (queryResults.size() > surgeonInHospitalStandardUserLimit) {
        throw new mobilecaddy1.MC_001_mcException(mobilecaddy1.MC_001_mcException.MC_EXT_CLASS_LIMITS,'SurgeonInHospitalNonCommunity class - more than ' + surgeonInHospitalStandardUserLimit + ' Surgeon_in_Hospital__c records will be returned.');
      }
    }
    // Return the ids for surgeons in hospital with sharing on
  	return (new Map<Id,Surgeon_in_Hospital__c>(queryResults)).keySet();
  } // end returnRestrictedIds

  private static Boolean isInteger(String test) {
    try {
      Integer x = Integer.valueOf(test);
      return true;
    } catch(Exception e) {
      return false;
    }
  }

} // end class