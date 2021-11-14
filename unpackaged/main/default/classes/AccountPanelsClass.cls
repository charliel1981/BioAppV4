public class AccountPanelsClass {

  // the record id
  @TestVisible private Key_Account_Plan__c record { get; set; }
  // the KAP's related Account id
  @TestVisible private String accountId { get; set; }
  // the KAP's related Sales_by_year__c record
  public List<Sales_by_year__c> sale { get; set; }
  // the KAP's Account's related Surgeons (Contact, via Person Accounts)
  @TestVisible private List<Contact> surgeons { get; set; }
  // the KAP's Account's related MBO_Activity__c
  @TestVisible private List<MBO_Activity__c> activity { get; set; }

  // constructor
  public AccountPanelsClass(ApexPages.StandardController controller) {
    // get KAP record
    record = (Key_Account_Plan__c)controller.getRecord();
    // get related Hospital (Account, via Person Accounts)
    accountId = getAccountId();
    System.debug('accountId:  '+accountId);
    // get related Sales_by_year__c
    // should only ever be one, only one record should be set to Active__c
    sale = getSale();
    // Surgeons linked to a hospital by the junction object Surgeon_in_Hospital__c
    surgeons = getSurgeons();
    // get related activity for the KAP's Account
    // restrict to the last 30 days
    activity = getActivity();
  }
    
  // get the account for the current record
  public String getAccountId() {
    String accountId = '';
    List<Key_Account_Plan__c> accounts = new List<Key_Account_Plan__c>();
     accounts = [
      SELECT Hospital__c 
      FROM Key_Account_Plan__c
      WHERE Id =: record.Id
      LIMIT 1
    ];
    if(accounts != null && accounts.size() > 0)
      accountId = accounts[0].Hospital__c;
    return accountId;
  }
    
  // get the sales for the current record's account
  public List<Sales_by_year__c> getSale() {      
    List<Sales_by_year__c> saleList = new List<Sales_by_year__c>();
    if(accountId != null && accountId != '') {
      saleList = [
        SELECT Q1_Sales_Actual__c, Q1_Sales_Target__c, Q2_Sales_Actual__c,
        Q2_Sales_Target__c, Q3_Sales_Actual__c, Q3_Sales_Target__c,
        Q4_Sales_Actual__c, Q4_Sales_Target__c, Year__c, X2017_Q1_Actual_Sales__c,
        X2017_Q2_Actual_Sales__c, X2017_Q3_Actual_Sales__c, X2017_Q4_Actual_Sales__c,
        Total_2017_Sales__c, Total_Actual__c, Total__c
        FROM Sales_by_year__c
        WHERE Active__c = true
        AND Account__c =: accountId
        LIMIT 1
      ];
    }
    return saleList;
  }
    
  // get the surgeons for the current record's account
  public List<Contact> getSurgeons() {
    List<Surgeon_in_Hospital__c> surgeonIds = new List<Surgeon_in_Hospital__c>();
    if(accountId != null && accountId != '') {
      surgeonIds =  [
        SELECT Surgeon__c
        FROM Surgeon_in_Hospital__c 
        WHERE Hospital__c =: accountId
      ];
    }
    // for each Surgeon, get their Ids
    List<Id> ids = new List<Id>();
    for (Integer i = 0; i < surgeonIds.size(); i++) {
      if (surgeonIds[i].Surgeon__c != null) {
        ids.add(surgeonIds[i].Surgeon__c);
      }
    }
    // finally get all fields for Surgeons we now know are related to the KAP
    List<Contact> surgeons = new List<Contact>();
    if(ids != null && ids.size() > 0) {
      surgeons =  [
        SELECT Id, CreatedDate, Name,
          Formats_Details__c, STIMULAN_Details__c, STIMULAN_User__c
        FROM Contact
        WHERE Id IN: ids
      ];
    }
    return surgeons;
  }
    
  // get the activity for the current record's account
  public List<MBO_Activity__c> getActivity() {
    List<MBO_Activity__c> activity = new List<MBO_Activity__c>();
    activity = [
      SELECT Name, Date__c, Type__c, Details__c
      FROM MBO_Activity__c
      WHERE Surgeon__c =: accountId
      AND Date__c <= LAST_N_DAYS:91
    ];
    return activity;
  }
  
}