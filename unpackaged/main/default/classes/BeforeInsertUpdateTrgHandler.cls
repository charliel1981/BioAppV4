/*
 * To update the territories after assigning the user, the user has to be explicitly 
 * saved to update the territory names on user record.
 */
public with sharing class BeforeInsertUpdateTrgHandler 
{
    //This method is called from user trigger
    public void onBeforeInsert(list<user> triggerNew){}
  
}