/**
 * Mock class to simulate Cicero API Integration for retrieving officials info.
 * Used to test the Cicero API call.
 * Created by DaizyLogik Dec 2023
 */
global class MainspringCiceroMockImpl implements HttpCalloutMock {
    private String json;

    public MainspringCiceroMockImpl() {
    }

    public MainspringCiceroMockImpl(String jsonStr){
        json = jsonStr;
    }

    global HTTPResponse respond(HTTPRequest req) {
       // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(json);
        res.setStatusCode(200);
        return res;
    }
}