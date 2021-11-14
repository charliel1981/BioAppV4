public with sharing class DistributorsSearchController {

    @AuraEnabled
    public static List<Account> findAll() {
        return [SELECT id, name, phone FROM Account LIMIT 0];  
    }

    @AuraEnabled
    public static List<Account> findByName(String searchKey) {
        String name = '%' + searchKey + '%';
        
        RecordType record = [SELECT id FROM RecordType WHERE SobjectType='Account' AND Name = 'Distributors'];
        String recordId = record.id;
        return [SELECT id, name, phone FROM Account WHERE name LIKE :name AND RecordTypeId =:recordId LIMIT 100];
    }

}