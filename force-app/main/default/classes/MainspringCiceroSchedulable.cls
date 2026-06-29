public with sharing class MainspringCiceroSchedulable implements Schedulable{
    public MainspringCiceroSchedulable() {

    }
    //allow for scheduling
    public void execute(SchedulableContext sc){
        MainspringCiceroQueueable.getAllActiveSites();
    }
}