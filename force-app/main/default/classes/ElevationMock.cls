@isTest
public class ElevationMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"results":[{"elevation":50.0}]}');
        res.setStatusCode(200);
         System.debug('Elevationmock is being called');

        return res;
    }
}