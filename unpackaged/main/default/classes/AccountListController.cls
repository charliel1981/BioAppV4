public with sharing class AccountListController {

    @AuraEnabled
    public static List<Account> findAll() {
        return [SELECT id, name, phone FROM Account LIMIT 0];  
    }

    @AuraEnabled
    public static List<Account> findByName(String searchKey) {
        String name = '%' + searchKey + '%';
        return [SELECT id, name, phone FROM Account WHERE name LIKE :name LIMIT 5];
    }

}