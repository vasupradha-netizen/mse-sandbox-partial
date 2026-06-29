public class GeocodeJob implements Queueable, Database.AllowsCallouts {
    
    private List<Id> siteIds;
    
    private final String GEOBASE   = 'https://maps.googleapis.com/maps/api/geocode/json?';
    private final String ELVBASE   = 'https://maps.googleapis.com/maps/api/elevation/json?';
    private final String KEY      = 'AIzaSyC0p_WScvHdaqKFzO-rBy9066INhsBB-DM';

    public GeocodeJob(List<Id> siteIds) {
        this.siteIds = siteIds;
    }
    
    public void execute(QueueableContext context) {
        List<Sites__c> sitesToUpdate = new List<Sites__c>();
        
        for (Sites__c site : getSites()) {
            Map<String, Double> newLatLng = getLatLng(site.Street_1__c + ' ' + (!String.isBlank(site.Street_2__c) ? site.Street_2__c + ' ' : '') + site.City__c + site.State_Region__c + ' ' + ' ' + site.Country__c);
            
            if (newLatLng == null) {
                continue;
            }
            
            Double newLat = newLatLng.get('lat');
            Double newLng = newLatLng.get('lng');
            
            if (site.Geolocation__Latitude__s == newLat && site.Geolocation__Longitude__s == newLng) {
                continue; // early exit; no change
            }
            
            Sites__c change = new Sites__c(
              Id               = site.Id,
                Geolocation__Latitude__s   = newLat,
                Geolocation__Longitude__s   = newLng
            );
            sitesToUpdate.add(change);
            
            Double newElv = getElevation(String.valueOf(newLat) + ',' + String.valueOf(newLng));
            if (newElv != null) {
                change.Elevation__c = newElv;
            }
        }

        UPDATE sitesToUpdate;
    }
    
    private List<Sites__c> getSites() {
        return [SELECT  Id, 
                    Street_1__c, 
                    Street_2__c, 
                    City__c, 
                    State_Region__c,
                    Country__c, 
                    Geolocation__Latitude__s, 
                    Geolocation__Longitude__s
                FROM    Sites__c 
                WHERE   Id IN :siteIds];
    }
    
    private Map<String, Double> getLatLng(String address) {
        Http h = new Http();
        
        HttpRequest req = new HttpRequest();
              req.setEndpoint(GEOBASE + 'address=' + EncodingUtil.urlEncode(address, 'UTF-8') + '&key=' + KEY);
              req.setMethod('GET');
        
        HttpResponse res = h.send(req);
        
        if (res.getStatusCode() != 200) {
            return null; // early exit - did not get a good response
        }
        
        GResponse g;
        try {
            g = (GResponse)JSON.deserialize(res.getBody(), GResponse.class);
        } catch (Exception ex) {
            System.debug('ISSUE DESERIALIZING GRESPONSE');
            System.debug(ex.getMessage());
        }
        
        if (g == null || g.results.isEmpty()) {
            return null;  // early exit - empty response or issue deserializing
        }
        
        return new Map<String, Double> {
            'lat' => g.results[0].geometry.location.lat,
            'lng' => g.results[0].geometry.location.lng
        };
    }
    
    private Double getElevation(String ip) {
        Http h = new Http();
        
        HttpRequest req = new HttpRequest();
              req.setEndpoint(ELVBASE + 'locations=' + ip + '&key=' + KEY);
              req.setMethod('GET');
        
        HttpResponse res = h.send(req);
        
        EResponse e;
        try {
            e = (EResponse)JSON.deserialize(res.getBody(), EResponse.class);
        } catch (Exception ex) {
            System.debug('ISSUE DESERIALIZING ERESPONSE');
            System.debug(ex.getMessage());
        }
        
        if (e == null || e.results.isEmpty()) {
            return null;  // early exit - empty response or issue deserializing
        }
        
        return e.results[0].elevation;
    }

    private class EResponse {
        private List<EResult> results;
    }
    
    private class EResult {
      private Double elevation;   
    }
    
    private class GResponse {
        private List<GResult> results;
    }
    
    private class GResult {
        private GGeometry geometry;
    }
    
    private class GGeometry {
        private GLocation location;
    }
    
    private class GLocation {
        private Double lat;
        private Double lng;
    }
}