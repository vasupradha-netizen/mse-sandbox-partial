public class BusinessHoursHelper {

    @InvocableMethod(label='Calculate Business Hours Difference' description='Calculate the business hours difference between two datetime fields')
    public static List<Decimal> calculateBusinessHoursDifference(List<Request> requestList) {
        // Get the default Business Hours
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];
        
        List<Decimal> results = new List<Decimal>();
        
        for (Request req : requestList) {
            if (req.startDateTime != null && req.endDateTime != null) {
                System.debug('startDateTime: ' + req.startDateTime);
                System.debug('endDateTime: ' + req.endDateTime);

                // Calculate the difference in milliseconds between the two datetimes
                Long diffMilliseconds = BusinessHours.diff(bh.Id, req.startDateTime, req.endDateTime);

                if (diffMilliseconds != null && diffMilliseconds > 0) {
                    // Convert the result from milliseconds to minutes
                    Decimal diffMinutes = (Decimal)diffMilliseconds / (1000 * 60);
                    
                    // Convert minutes to hours in decimals (e.g., 15 minutes = 0.25 hours)
                    Decimal diffHours = diffMinutes / 60;
                    
                    // Round to two decimal places
                    Decimal roundedDiffHours = diffHours.setScale(2, RoundingMode.HALF_UP);
                    System.debug('Rounded Hours Difference: ' + roundedDiffHours);

                    results.add(roundedDiffHours);
                } else {
                    results.add(0);
                }
            } else {
                results.add(0);
            }
        }
        
        return results;
    }

    public class Request {
        @InvocableVariable
        public Datetime startDateTime;
        
        @InvocableVariable
        public Datetime endDateTime;
    }
}