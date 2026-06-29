@isTest
public class MockHttpCallout implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"success": true, "message": "Mock callout successful"}');
        response.setStatusCode(200);
        return response;
    }
}