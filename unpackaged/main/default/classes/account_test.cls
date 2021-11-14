@isTest
public class account_test {
    
    static testMethod void testAccount() {
	
   
   Account acc1 = new Account(Name='AccTest1');  
   insert acc1;
   Account acc2 = new Account(Name='AccTest2');  
   insert acc2;
   Account acc3 = new Account(Name='AccTest3');  
   insert acc3;
  
   //AccountListController account123 = new AccountListController();
   //AccountListController.findAll();
   //system.debug(AccountListController.findAll());
   //AccountListController.findByName('AccTest3');
        
   
   DistributorsSearchController.findAll();
   DistributorsSearchController.findByName('AccTest3');
        
   
   SurgeonsSearchListController.findAll();
   SurgeonsSearchListController.findByName('Acctest3');
        
   HospitalsSearchController.findAll();
   HospitalsSearchController.findByName('Acctest3');
   
     
   }
    
}