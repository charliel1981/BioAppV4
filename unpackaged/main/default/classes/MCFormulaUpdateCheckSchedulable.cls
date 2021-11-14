/**
 * @description This is used to schedule the batch update job that updates records if a formula value changes
 **/
global with sharing class MCFormulaUpdateCheckSchedulable implements Schedulable {

	global void execute(SchedulableContext ctx) {
		MCFormulaUpdateCheckBatch formulaUpdateBatch = new MCFormulaUpdateCheckBatch(null);
       	ID batchId = Database.executeBatch(formulaUpdateBatch, 2000);
	}
}