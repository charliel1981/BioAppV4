trigger BeforeInsertUpdateTrg on User (before update) 
{
    if(Trigger.isBefore && Trigger.isUpdate)
   {       
        BeforeInsertUpdateTrgHandler beforeHandler = new BeforeInsertUpdateTrgHandler();
        beforeHandler.onBeforeInsert(Trigger.new);
    }      
}