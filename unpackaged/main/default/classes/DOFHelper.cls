/**
*   @description : DOF Helper Class
**/
public without sharing class DOFHelper {

    /**
    *   @description : Method to create/update document records and updated the document id in dof record
    *   @param dofList List of dof records in trigger context
    *   @param oldDofMap Map of dof record by id
    */
    public static void upsertSignatureInDocuments(List<DOF__c> dofList, Map<Id, DOF__c> oldDofMap, Boolean dmlAction){
        try{
            // get the wrapper list
            List<DOFSignatureAsDocument> dofSignatureAsDocumentList = getDOFSignatureAsDocumentList(dofList,oldDofMap);

            // create/update documents
            upsertDocuments(dofSignatureAsDocumentList);

            // update dof record
            for(DOFSignatureAsDocument dofSignatureAsDocument : dofSignatureAsDocumentList){
                dofSignatureAsDocument.updateDocumentIdInDof();
            } 
            if(dmlAction) upsert dofList;  
        }catch(Exception ex){
            System.debug('Message is '+ex.getMessage());
        }
    }

    /**
    *   @description : Method to create/update document records and updated the document id in dof record
    *   @param dofList List of dof records in trigger context
    *   @param oldDofMap Map of dof record by id
    */
    public static void updateDistributors(List<DOF__c> dofList){
        try{
            Set<Id> userIds = new Set<Id>();

            // Loop through dof 
            for(DOF__c dof : dofList){
                userIds.add(dof.OwnerId);
            }

            // query users 
            Map<Id, User> usersMap = new Map<Id, User>([SELECT ID_of_linked_account__c FROM User WHERE Id IN: userIds AND ID_of_linked_account__c != null LIMIT 30000]);

            // set distributor
            for(DOF__c dof : dofList){
                if(usersMap.containsKey(dof.OwnerId)){
                    dof.Distributor__c = usersMap.get(dof.OwnerId).ID_of_linked_account__c;
                }
            }   
        }catch(Exception ex){
            System.debug('Message is '+ex.getMessage());
        }
    }

    /**
    *   @description : Method to create an instance of DOFSignatureAsDocument for each dof record if signature is captured in that record
    *   @param dofList List of dof records in trigger context
    *   @param oldDofMap Map of dof record by id
    */
    private static List<DOFSignatureAsDocument> getDOFSignatureAsDocumentList(List<DOF__c> dofList, Map<Id, DOF__c> oldDofMap){
        List<DOFSignatureAsDocument> dofSignatureAsDocumentList = new List<DOFSignatureAsDocument>();
        // Loop through dof list 
        for(DOF__c dof : dofList){
            if((dof.Signature_Capture__c != null && oldDofMap == null) || 
                    (oldDofMap != null && oldDofMap.containsKey(dof.Id) && dof.Signature_Capture__c != oldDofMap.get(dof.Id).Signature_Capture__c && dof.Signature_Capture_Document_Id__c != null) || 
                        (oldDofMap != null && dof.Signature_Capture_Document_Id__c == null && dof.Signature_Capture__c != null)){
                dofSignatureAsDocumentList.add(new DOFSignatureAsDocument(dof,getFolderId()));
            }
        }
        return dofSignatureAsDocumentList;
    }   

    /**
    *   @description : Method to create/update document records
    */
    private static void upsertDocuments(List<DOFSignatureAsDocument> dofSignatureAsDocumentList){
        List<Document> documentsList = new List<Document>();

        // Loop through wrapper list 
        for(DOFSignatureAsDocument dofSignatureAsDocument : dofSignatureAsDocumentList){
            documentsList.add(dofSignatureAsDocument.updateSignatureInDocument(dofSignatureAsDocument.dofRecord.Signature_Capture_Document_Id__c));
        }

        // upsert the document list
        if(!documentsList.isEmpty()) upsert documentsList;
    }

    /**
    *   @description : Method to delete document records when dof record is deleted
    *  	@param dofList List of dof records
    */
    public static void deleteDocuments(List<DOF__c> dofList){
        try{
            Set<Id> documentIds = new Set<Id>();

            // get document ids 
            for(DOF__c dof : dofList){
            	if(!String.isBlank(dof.Signature_Capture_Document_Id__c)){
            		documentIds.add(dof.Signature_Capture_Document_Id__c);
            	}
            }

            // if document ids is not empty
            if(!documentIds.isEmpty()){
            	delete [SELECT Id FROM Document WHERE Id IN: documentIds LIMIT 45000];
            }
        }catch(Exception ex){
            System.debug('Message is '+ex.getMessage());
        }
    }

    /**
    *   @description : Method to get the folder Id
    *   @return Id Folder Id
    */
    @testVisible
    private static Id getFolderId(){
        List<Folder> foldersList = [SELECT Id FROM Folder WHERE DeveloperName =: Constants.DOF_SIGNATURE_FOLDER_NAME LIMIT 1];
        // check if the folder exists
        if(!foldersList.isEmpty()){
            return foldersList[0].Id;
        }
        return null;
    }
}