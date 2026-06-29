global class CustomerDbMock implements HttpCalloutMock {
    
    global HttpResponse respond(HttpRequest req) {
        HttpResponse r = new HttpResponse();
        r.setHeader('Content-Type', 'application/json');
        r.setBody('{"url":"https://www.testdb.fake"}');
        r.setStatusCode(200);
        return r;
    }
}