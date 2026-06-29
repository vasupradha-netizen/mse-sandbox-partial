/**
 * Queueable class to query for active sites and call the Cicero API to refresh officials info.
 * Created by DaizyLogik Nov 2023
 */
public class MainspringCiceroQueueable implements Queueable {
    private List<Sites__c> sites;
    @testVisible
    private Integer numberOfSites;
    private Integer siteCounter = 0;

    public MainspringCiceroQueueable(List<Sites__c> sitesParam, Integer numSites, Integer siteCount) {
        sites = sitesParam;
        numberOfSites =  numSites;
        siteCounter = siteCount;
    }

    //execute the enqueued record and enqueue the next 
    public void execute(QueueableContext context) {
        if (siteCounter < numberOfSites) {
            Sites__c currentSite = sites.get(siteCounter);
            siteCounter++;
            MainspringCiceroUtility.updateOfficials(new List<String>{currentSite.Id}, false);
            if (siteCounter < numberOfSites) {
                System.enqueueJob(new MainspringCiceroQueueable(sites, sites.size(), siteCounter));
            }
        }
    }
    
    //start the processing
    public static void getAllActiveSites(){
        List<Sites__c> allActiveSites = [select Id from Sites__c where 
                                            Active_Sale__c = true];
        System.enqueueJob(new MainspringCiceroQueueable(allActiveSites, allActiveSites.size(), 0));
    }
}