global class BatchToRemoveInactCampMemScheduler implements Schedulable
{
    public static String sched = '0 00 00 * * ?';  //Every Day at Midnight
    
    global static String batchScheduler() {
        BatchToRemoveInactCampMemScheduler scheduler = new BatchToRemoveInactCampMemScheduler(); 
        return System.schedule('Remove Inactive campaign members', sched, scheduler);
    }
    
    global void execute (SchedulableContext SC){
         BatchToRemoveInactCampMem campMemBatch = new  BatchToRemoveInactCampMem();
       	 ID batchprocessid = Database.executeBatch(campMemBatch,200);
    }
}