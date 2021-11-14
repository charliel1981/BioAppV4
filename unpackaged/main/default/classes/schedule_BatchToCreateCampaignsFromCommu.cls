global class schedule_BatchToCreateCampaignsFromCommu implements Schedulable{

       global void execute( SchedulableContext SC )
        {        

          BatchToCreateCampaignsFromCommunityViews b = new BatchToCreateCampaignsFromCommunityViews();
          database.executebatch(b);
          
          if(!Test.isRunningTest())
          {
            schedule_BatchToCreateCampaignsFromCommu.start();
            System.abortJob( SC.getTriggerId() );
          }

        }

        public static void start()
        {
            Datetime sysTime = System.now().addSeconds(21600);      
            String chronExpression = '' + sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();
            System.schedule( 'Create campaign Scheduler ' + sysTime, chronExpression, new schedule_BatchToCreateCampaignsFromCommu() );
        }
    }