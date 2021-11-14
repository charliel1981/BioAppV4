public class DOF_TriggerHandler {

    private boolean isExecuting = false;
    private integer batchSize = 0;
    
    // Constructor
    public DOF_TriggerHandler(boolean isExecuting, integer size){
        this.isExecuting = isExecuting;
        this.batchSize = size;
    } // end constructor
    
    // Because the Community Users cannot write to the Account or Contact lookups (rubbish permissions)
    // we move them to sister fields on the before insert and then move and update on the after insert
    public void onBeforeInsert(DOF__c[] insertedRecords){
    	if ((UserInfo.getUserType() == 'CspLitePortal') || Test.isRunningTest()) {
	    	for (DOF__c dof : insertedRecords) {
	    		dof.Hospital_Text_Id__c = dof.Hospital__c;
	    		dof.Hospital__c = null;
	    		dof.Surgeon_Text_Id__c = dof.Surgeon__c;
	    		dof.Surgeon__c = null;
	    	} // end loop through inserted records for
    	} // end community user check if
    } // end onBeforeInsert
    
    public void onAfterInsert(DOF__c[] insertedRecords){
        Set<Id> dofIdsList = new Set<Id>();
    	if ((UserInfo.getUserType() == 'CspLitePortal') || Test.isRunningTest()) {
	    	List<DOF__c> updatedDOFs = new List<DOF__c>();
	    	for (DOF__c dof : insertedRecords) {
	    		if ((dof.Hospital_Text_Id__c != null) || (dof.Surgeon_Text_Id__c != null)) {
	    			DOF__c updateDOF = new DOF__c(Id = dof.Id);
	    			updatedDOFs.add(updateDOF);
	    			updateDOF.Hospital__c = dof.Hospital_Text_Id__c;
	    			updateDOF.Hospital_Text_Id__c = null;
	    			updateDOF.Surgeon__c = dof.Surgeon_Text_Id__c;
	    			updateDOF.Surgeon_Text_Id__c = null;
	    		} // end check needs shifting if
	    	} // end loop through DOFs for
	    	
	    	// Update changed recs
	    	if (!updatedDOFs.isEmpty()) {
	    		update updatedDOFs;
	    	} // end check recs updated if

            // Loop through Dof
            for(DOF__c dof : insertedRecords){
                if(dof.Send_Process_Has_Completed__c){
                    dofIdsList.add(dof.Id);
                }
            }

            // if dof ids list is not empty
            if(!dofIdsList.isEmpty()){
                SendDOFEmailController.sendEmail(dofIdsList);
            }

    	} // end community user check if

        // create document records for signature
        List<Dof__c> dofList = [SELECT Id, Name, Signature_Capture_Document_Id__c, Signature_Capture__c FROM Dof__c WHERE Id IN: new Map<Id,Dof__c>(insertedRecords).keySet() LIMIT 500];
        DOFHelper.upsertSignatureInDocuments(dofList,null,true);
    } // end onBeforeInsert

    public void onBeforeUpdate(List<DOF__c> updatedRecords,Map<Id, DOF__c> oldUpdatedRecordsMap){
    	// capture signature in documents
    	DOFHelper.upsertSignatureInDocuments(updatedRecords,oldUpdatedRecordsMap,false);
        DOFHelper.updateDistributors(updatedRecords);
    } // end onBeforeInsert

    public void onBeforeDelete(List<DOF__c> deletedRecords){
    	// delete documents
    	DOFHelper.deleteDocuments(deletedRecords);

    } // end onBeforeInsert

    public void onAfterUpate(List<DOF__c> newRecords, Map<Id,Dof__c> oldRecordsMap){
        Set<Id> dofIdsList = new Set<Id>();

        // Loop through Dof
        for(DOF__c dof : newRecords){
            if(dof.Send_Process_Has_Completed__c && oldRecordsMap.containsKey(dof.Id) && !oldRecordsMap.get(dof.Id).Send_Process_Has_Completed__c){
                dofIdsList.add(dof.Id);
            }
        }

        // if dof ids list is not empty
        if(!dofIdsList.isEmpty()){
            SendDOFEmailController.sendEmail(dofIdsList);
        }
       
    }
} // end trigger handler