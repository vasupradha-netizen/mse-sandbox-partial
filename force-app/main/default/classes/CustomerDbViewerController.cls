public without sharing class CustomerDbViewerController {

    private static final String BASE_URL	= 'https://app.hex.tech/api/v1';
    private static final String TOKEN		= 'df47290fe0c981c5e73315817bb008f7ca9132660ddd72bb4a654a852947e620d88f6db6c844697c1067efc6a2222271';
    
    @AuraEnabled
    public static String getUrl(String dbid) {
        String project;
        try {
            project = [SELECT Project_Id__c FROM Customer_Dashboard_Setting__c WHERE Id = :dbid].Project_Id__c;
        } catch (Exception ex) {
            return '';
        }
        
        String a = getAccountId();
        if (String.isBlank(a)) {
            return 'ERROR';
        }
        
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setBody(JSON.serialize(new HexBody(a)));
        req.setHeader('Authorization', 'Bearer ' + TOKEN);
        req.setHeader('Content-Type', 'application/json');
        req.setEndpoint(BASE_URL + '/embedding/createPresignedUrl/' + project);
        
        try {
            HttpResponse res = h.send(req);
            Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            return String.valueOf(body.get('url'));
        } catch (Exception ex) {
            return '';
        }
    }
    
    private static String getAccountId() {
        try {
            User u = [SELECT Id, Contact.AccountId FROM User WHERE Id = :UserInfo.getUserId()];
            return u.Contact.AccountId;
        } catch (Exception ex) {
            return '';
        }
    }
    
    private class HexBody {
        private HexUserAttr 	hexUserAttributes;
        private List<String> 	scope;
        private Decimal			expiresIn;
        private DisplayOpts		displayOptions;
        public HexBody(String a) {
            hexUserAttributes 	= new HexUserAttr(a);
            scope			 	= new List<String>{'EXPORT_PDF', 'EXPORT_CSV'};
            expiresIn			= 30000;
            displayOptions		= new DisplayOpts(true, true, true);
        }
    }
    
    private class HexUserAttr {
        private String account_id;
        public HexUserAttr(String a) {
            account_id = a;
        }
    }
    
    private class DisplayOpts {
        private Boolean noEmbedFooter;
        private Boolean noEmbedOutline;
        private Boolean noEmbedBasePadding;
        public DisplayOpts(Boolean f, Boolean o, Boolean p) {
            noEmbedFooter 		= f;
            noEmbedOutline 		= o;
            noEmbedBasePadding 	= p;
        }
    }
}