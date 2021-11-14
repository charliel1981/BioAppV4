@isTest
public class contact_test {
    
    static testMethod void testContact() {
	
   
   Contact cont1 = new Contact(LastName='ContTest1', Email='test1contact@duptest.com');  
   insert cont1;
   Contact cont2 = new Contact(LastName='ContTest2', Email='test2contact@duptest.com'); 
   insert cont2; 
   Contact cont3 = new Contact(LastName='ContTest3', Email='test3contact@duptest.com'); 
   insert cont3;
        
   ContactListController contact123 = new ContactListController();
   ContactListController.findAll();
   system.debug(ContactListController.findAll());
   ContactListController.findByName('ContTest3');
     
   }
    
}