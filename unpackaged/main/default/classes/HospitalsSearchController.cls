public with sharing class HospitalsSearchController {

    @AuraEnabled
    public static List<Account> findAll() {
        return [SELECT id, name, phone FROM Account LIMIT 0];  
    }

    @AuraEnabled
    public static List<Account> findByName(String searchKey) {
        String name = '%' + searchKey + '%';
        
        RecordType record = [SELECT id FROM RecordType WHERE SobjectType='Account' AND Name = 'Hospital'];
        String recordId = record.id;
        return [SELECT id, name, phone FROM Account WHERE name LIKE :name AND RecordTypeId =:recordId LIMIT 100];
    }

}