/**
 * Utility class to support Cicero API Integration for retrieving officials info from the record 
 * triggered Flow. Provides invocable method that supports clearing the official lookups.
 * This class was created because SF does not allow for two invocable methods in the same class.
 * Added this per request from Dan D. to support different clearing vs non-clearing functionality.
 * Created by DaizyLogik Nov 2023
 */
public class MainspringCiceroFlowUtility {
    //visible by record triggered flow to update the Officials for a site, with clear functionality
    @invocableMethod
    public static void updateOfficialsClearLookupsInvocable(List<String> siteIds) {
         MainspringCiceroUtility.updateOfficials(siteIds, true);
    }
}