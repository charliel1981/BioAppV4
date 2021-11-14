@isTest
public class AccountPanelsTest {
  
    @isTest
    private static void runTest() {
        
        Test.startTest();
        AccountPanelsTest apt = new AccountPanelsTest();
        
        // insert test data
        Account acc = apt.getAccount();
        System.debug(acc);
        insert acc;
        Key_Account_Plan__c kap = apt.getKeyAccountPlan(acc.Id);
        System.debug(kap);
        insert kap;
        Sales_by_year__c sby = apt.getSalesByYear(acc.Id);
        insert sby;
        Contact con = apt.getSurgeon();
        insert con;
        Surgeon_in_Hospital__c sih = apt.getSurgeonInHospital(acc.Id, con.Id);
        insert sih;
        
        // set page parameter
        PageReference page = Page.AccountPanels;
        page.getParameters().put('Id', String.valueOf(kap.Id));
        Test.setCurrentPage(page);
        
        // initiate controller
        ApexPages.StandardController sc = new ApexPages.StandardController(kap);
        AccountPanelsClass apc = new AccountPanelsClass(sc);
        
        System.debug(apc.accountId);
        
        
    }
    
    // create fake account
    public Account getAccount() {
      String recordTypeId = [
        SELECT Id
        FROM RecordType
        WHERE DeveloperName = 'Hospital'
        AND SobjectType = 'Account'
      ].Id;
      Account acc = new Account(
        Name = 'Test', 
        Account_Alias__c = 'Test', 
        CurrencyIsoCode = 'GBP', 
        Territory__c = 'International',
        RecordTypeId = recordTypeId
      );
      return acc;
    }
    
    // create fake key account plan
    public Key_Account_Plan__c getKeyAccountPlan(String id) {
      Key_Account_Plan__c kap = new Key_Account_Plan__c(
        Hospital__c = id
      );
      return kap;
    }
    
    //create fake sales
    public Sales_by_year__c getSalesByYear(String id) {
      Sales_by_year__c sby = new Sales_by_year__c(
        Account__c = id,
        Active__c = true,
        CurrencyIsoCode = 'GBP',
        Q1_Sales_Target__c = 10,
        Q2_Sales_Target__c = 10,
        Q3_Sales_Target__c = 10,
        Q4_Sales_Target__c = 10,
        Q1_Sales_Actual__c = 10,
        Q2_Sales_Actual__c = 10,
        Q3_Sales_Actual__c = 10,
        Q4_Sales_Actual__c = 10
      );
      return sby;
    }
    
    // create fake surgeon
    public Contact getSurgeon() {
      Contact con = new Contact(
        LastName = 'Test',
        CurrencyIsoCode = 'GBP',
        Territory__c = 'International'
      );
      return con;
    }
    
    // create fake junction object
    public Surgeon_in_Hospital__c getSurgeonInHospital(String accountId, String contactId) {
      Surgeon_in_Hospital__c sih = new Surgeon_in_Hospital__c(
        Hospital__c = accountId,
        Surgeon__c = contactId
      );
      return sih;
    }
    
}