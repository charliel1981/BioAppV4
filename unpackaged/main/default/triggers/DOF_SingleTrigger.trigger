trigger DOF_SingleTrigger on DOF__c (
									after update,
		//							after delete, 
									after insert, 
		//							after undelete, 								 
									before delete, 
									before insert,
									before update
									) {
    
    DOF_TriggerHandler handler = new DOF_TriggerHandler(Trigger.isExecuting, Trigger.size);

  	if (Trigger.isInsert && Trigger.isBefore){
		handler.onBeforeInsert(Trigger.new);
  	} // end beforeInsert if
  	else {
	  	if (Trigger.isInsert && Trigger.isAfter){
			handler.onAfterInsert(Trigger.new);
	  	} // end afterInsert if  		
  	} // end beforeInsert else

  	if(Trigger.isUpdate && Trigger.isBefore){
  		handler.onBeforeUpdate(Trigger.new,Trigger.oldMap);
  	}

  	if(Trigger.isDelete && Trigger.isBefore){
  		handler.onBeforeDelete(Trigger.old);
  	}

  	if(Trigger.isUpdate && Trigger.isAfter){
  		handler.onAfterUpate((List<Dof__c>)Trigger.new,(Map<Id,Dof__c>)Trigger.oldMap);
  	}
} // end trigger