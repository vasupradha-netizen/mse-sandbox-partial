@isTest
public class GeocodeMock implements HttpCalloutMock {
    
    private final String GEOBODY = '{"results":[{"geometry":{"location":{"lat":37.4224764,"lng":-122.0842499}}}]}';
    private final String ELVBODY = '{"results":[{"elevation":100}]}';
    
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(req.getEndpoint().contains('elevation') ? ELVBODY : GEOBODY);
        res.setStatusCode(200);
        return res;
    }
}