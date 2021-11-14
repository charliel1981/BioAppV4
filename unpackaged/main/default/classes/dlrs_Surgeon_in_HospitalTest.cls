/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Surgeon_in_HospitalTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Surgeon_in_HospitalTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Surgeon_in_Hospital__c());
    }
}