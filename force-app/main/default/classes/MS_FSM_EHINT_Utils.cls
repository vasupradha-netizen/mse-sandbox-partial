/******************************************************************************
 * Name         : MS_FSM_EHINT_Utils
 * Author       : Nathan Ehrmann - nathan@empowherops.com
 * Created Date : 2024-11-01
 * Description  : utility class for all MS_FSM_EHINT_* classes
 *
 * Modification History:
 *   Date       | Author              | Change Description
 *   -----------|---------------------|------------------------------------------
 *   2024-11-01 | Nathan Ehrmann      | Initial write.
 *
 * Notes:
 * 
 * Tests:
 * MS_FSM_EHINT_Tests
 ******************************************************************************/
public class MS_FSM_EHINT_Utils {
    
    static Map<String, String> stateToStateCode;
    static Map<String, String> countryToCountryCode;
    
    static MS_FSM_EtaHub_Integration_Setting__c settings; 
    
    /********************************************************
	 * Purpose: create a usable map for EH Integration Definitions
	 * 			given a target EH table id
	 * Input:	t - EH table id (e.g. bnnfe2qf9 ==> Assembly)
	 * Output:	map from EH FID (integer) to EH Integration Definition Record
	 * 			e.g. 3 => [record corresponding to "Record Id" from EH]
	 ********************************************************/
    public static Map<Integer, MS_FSM_EtaHub_Integration_Definition__c> getIntDefs(String t) {
		Map<Integer, MS_FSM_EtaHub_Integration_Definition__c> r = new Map<Integer, MS_FSM_EtaHub_Integration_Definition__c>();                    
        for (MS_FSM_EtaHub_Integration_Definition__c def : [SELECT  MS_FSM_EH_Column_Number__c,
                                                     				MS_FSM_Target_Field__c,
                                                     				MS_FSM_Data_Type__c,
                                                     				MS_FSM_EH_Table_Id__c
                                                     		FROM 	MS_FSM_EtaHub_Integration_Definition__c
                                                     		WHERE 	MS_FSM_EH_Table_Id__c = :t]) {
            r.put(Integer.valueOf(def.MS_FSM_EH_Column_Number__c), def);
        }
        return r;
    }
    
    /********************************************************
	 * Purpose: builds and executes a query to EH
	 * Input:	defs 	- list of integration definitions (to target fields)
	 * 			filter 	- query filters in EH form
	 * 			top 	- top amt of records (to limit query results if necessary)
	 *          skip 	- offset if doing iterations
	 * Output:	list of EH returns, which for our purposes look like:
	 * 			[ 3 => { "value" => "432"} (for a record Id from EH)... ]
	 ********************************************************/
    public static List<Map<Integer, Map<String, String>>> getEHData(List<MS_FSM_EtaHub_Integration_Definition__c> defs,
                                                                    String 										  filter, 
                                                                    Integer 									  top, 
                                                                    Integer 									  skip) 
    {
        if (defs.isEmpty()) { 
            return null; 
        }
        
        List<Integer> selects = new List<Integer>();
        for (MS_FSM_EtaHub_Integration_Definition__c e : defs) { 
            selects.add(Integer.valueOf(e.MS_FSM_EH_Column_Number__c)); 
        }
        
        EHQuery q = new EHQuery(defs[0].MS_FSM_EH_Table_Id__c, selects, filter, top, skip);
        
        String 	b = JSON.serialize(q);
        		b = b.replace('from_x', 	'from');
        		b = b.replace('select_x', 	'select');
        		b = b.replace('where_x', 	'where');
        
        Http h = new Http();
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.quickbase.com/v1/records/query');
        req.setMethod('POST');
        
        req.setHeader('QB-Realm-Hostname', 'etagen.quickbase.com');
        req.setHeader('Authorization', 'QB-USER-TOKEN b9k5cc_kxgc_0_cdcvetccs2hxxguead2aduam54');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(60000);
        req.setBody(b);
        
        try {
            HTTPResponse r = h.send(req);
            EHReturn raw = (EHReturn)JSON.deserialize(r.getBody(), EHReturn.class);
            return raw.data;
        } catch (Exception ex) {
            return buildErrorReturn(ex.getMessage());
        }
    }
    
    /********************************************************
	 * Purpose: builds an object that mimics the EH return with an
	 * 			error message for later processing
	 * Input:	m - an error message
	 * Output:	object that mimics the EH return with an error message
	 ********************************************************/
    @TestVisible
    private static List<Map<Integer, Map<String, String>>> buildErrorReturn(String m) {
        List<Map<Integer, Map<String, String>>> x = new List<Map<Integer, Map<String, String>>>();
        Map<Integer, Map<String, String>> y = new Map<Integer, Map<String, String>>();
        Map<String, String> z = new Map<String, String>{'error' => m};
        y.put(0, z);
        x.add(y);
        return x;
    }
    
    /********************************************************
	 * Purpose: determines if the object currently handled is an
	 * 			error or not
	 * Input:	data  - the data object from EH
	 * Output:	true  - there is an error
	 * 			false - there is no error
	 ********************************************************/
    public static Boolean handleError(List<Map<Integer, Map<String, String>>> data) {
        if (data.size() > 1) {								// NO ERROR - returned data is
            return false;									// larger than 1
        }
        
        Map<Integer, Map<String, String>> m = data[0];		// NO ERROR
        Map<String, String> e = m.get(0);					// data does not have a 0 key
        if (e == null) {
            return false;
        }
        
        String x = e.get('error');							// NO ERROR
        if (String.isBlank(x)) {							// data does not have an error message
            return false;
        }
        
        return true;										      	
    }
    
    /********************************************************
	 * Purpose: creates an integration error record
	 * Input:	recName   - name for the error record
	 *          errMsg    - the received error message
	 * 			rec	      - the record id if available
	 *          className - the source class name
	 * Output:	NONE - one DML
	 ********************************************************/
    public static void createIntegrationError(String recName, String errMsg, String rec, String className) {
		INSERT new Integration_Error__c(
        	Name 				= recName,
            Date__c 			= System.today(),
            Origin_Class__c 	= className,
            Record_Id__c 		= rec,
            Error_Message__c 	= errMsg
        );
    }
    
    /********************************************************
	 * Purpose: takes mapping records from SF and EH data and
	 * 			maps values onto object fields
	 * Input:	dataInstance - EH data
	 * 			mappingDefs  - mapping definition records
	 * 			o			 - the target Object (e.g. an Asset)
	 * Output:	NONE
	 ********************************************************/
    public static void mapValues(Map<Integer, Map<String, String>> 						dataInstance, 
                                 Map<Integer, MS_FSM_EtaHub_Integration_Definition__c> 	mappingDefs, 
                                 Sobject 												o)
    {
        for (Integer k : dataInstance.keySet()) {   
            MS_FSM_EtaHub_Integration_Definition__c def = mappingDefs.get(k);
            if (String.isBlank(def.MS_FSM_Target_Field__c)) { 
                continue; 
            }
            
            Map<String, String> n = dataInstance.get(k);
             
            assignValue(o, def.MS_FSM_Target_Field__c, n.get('value'), def.MS_FSM_Data_Type__c); 
        }
    }
    
    /********************************************************
	 * Purpose: determines if the object currently handled is an
	 * 			error or not
	 * Input:	o 		 - the target object (e.g. an Asset)
	 * 			f 		 - the API name of the target field
	 * 			v 		 - the value from EH
	 * 			dataType - the data type, from our mapping record
	 * Output:	NONE
	 ********************************************************/
    public static void assignValue(sObject o, String f, String v, String dataType) {
        if (String.isEmpty(f) || String.isEmpty(v)) { 
            return; 
        }
        
        switch on dataType {
            when 'text' 	{  o.put(f, v); 					}
            when 'decimal' 	{  o.put(f, Decimal.valueOf(v)); 	}
            when 'date' 	{  o.put(f, datevalue(v)); 			}
            when 'datetime' {  o.put(f, datetimevalue(v));  	}
            when 'boolean' 	{  o.put(f, v == 'true'); 	  		}
        }
    }
    
    /********************************************************
	 * Purpose: converts a string to a DateTime
	 * Input:	s - string DateTime received from EH
	 * Output:	a converted DateTime
	 ********************************************************/
    public static DateTime datetimevalue(String s) {
        return Datetime.newInstanceGmt(Integer.valueOf(s.left(4)),
                                       Integer.valueOf(s.substring(5,7)),
                                       Integer.valueOf(s.substring(8,10)),
                                       Integer.valueOf(s.substring(11,13)),
                                       Integer.valueOf(s.substring(14,16)),
                                       Integer.valueOf(s.substring(17,19)));
    }
    
    /********************************************************
	 * Purpose: converts a string to a Date
	 * Input:	s - string Date received from EH
	 * Output:	a converted Date
	 ********************************************************/
    public static Date datevalue(String s) {
        return Date.newInstance(Integer.valueOf(s.left(4)),
                                Integer.valueOf(s.substring(5,7)),
                                Integer.valueOf(s.substring(8,10)));
    }
    
    /********************************************************
	 * Purpose: adds a nonblank string to a set for use in a query
	 * Input:	t - a set of Strings
	 * 			v - a string to be considered for adding
	 * Output:	NONE
	 ********************************************************/
    public static void addString(Set<String> t, String v) {
        if (!String.isBlank(v)) {
            t.add(v);
        }
    }
    
    /********************************************************
	 * Purpose: gets a standard time window filter for 15-minute
	 * 			inventory runs
	 * Input:	m 	 	 - the "mode" for running (we have used "all" once,
	 * 				   	   probably never again)
	 * 			fid 	 - the filtering ID field number in EH
	 * 			needsAnd - determines whether or not to add "AND"
	 * Output:	NONE
	 ********************************************************/
    public static String getStdDateFilter(String m, Integer fid, Boolean needsAnd) {
        Integer d = Integer.valueOf(minutesLookback());
        return (m == 'all' ? '' : ((needsAnd ? 'AND' : '') + '{' + String.valueOf(fid) + '.GT.' + String.valueOf(System.now().addMinutes(-d).getTime()) + '}'));
    }
    
    /********************************************************
	 * Purpose: gets a Map from composite id (Product Code + SN) --> Asset
	 * Input:	data 		 - return from EH
	 * 			checkFlagFid - field that determines if we should check at all 
	 * 			serialFid 	 - EH field id for serial (depends on source table)
	 * 			epnRevFid 	 - EH field id for rev
	 * Output:	Map from composite id to Asset
	 ********************************************************/
    public static Map<String, Asset> getAssetMap(List<Map<Integer, Map<String, String>>> 	data, 
                                                 Integer 									checkFlagFid, 
                                                 Integer 									serialFid, 
                                                 Integer 									epnRevFid) 
    {
        Map<String, Asset> assetMap 	= new Map<String, Asset>();
        Set<String> compIds				= new Set<String>();
        for (Map<Integer, Map<String, String>> d : data) {
            if (d.get(checkFlagFid).get('value') == 'true') {
                continue;
            }
            
            String s = d.get(serialFid).get('value');
            String r = d.get(epnRevFid).get('value');
            if (String.isBlank(s) || String.isBlank(r)) {
                continue;
            }
            compIds.add(r + s);
        }
        for (Asset a : [SELECT Id, 
                               MS_FSM_Composite_Id__c 
                        FROM   Asset 
                        WHERE  MS_FSM_Composite_Id__c != 'INVALID'
                        AND    MS_FSM_Composite_Id__c IN :compIds]) {
            assetMap.put(a.MS_FSM_Composite_Id__c, a);
        }
        return assetMap;
    }
    
    /********************************************************
	 * Purpose: builds a map from ProductCode (rev number) --> Product2
	 * Input:	prodMap - a map built with keys only from source class
	 * Output:	NONE (modifies input map)
	 ********************************************************/
    public static void buildProductMap(Map<String, Product2> prodMap) {
        for (Product2 p : [SELECT Id, ProductCode, MS_FSM_Product_Type__c FROM Product2 WHERE ProductCode IN :prodMap.keySet()]) { 
            prodMap.put(p.ProductCode, p);
        }
    }
    
    /********************************************************
	 * Purpose: builds a map from Name --> Node
	 * Input:	nodeMap - a map built with keys only from source class
	 * Output:	NONE (modifies input map)
	 ********************************************************/
    public static void buildNodeMap(Map<String, MS_FSM_Node__c> nodeMap) {
        for (MS_FSM_Node__c n : [SELECT Id, Name FROM MS_FSM_Node__c WHERE Name IN :nodeMap.keySet()]) {
            nodeMap.get(n.Name).Id = n.Id;
        }
        UPSERT nodeMap.values();
    }
    
    /********************************************************
	 * Purpose: builds a map from Name --> Location
	 * Input:	locMap - a map built with keys only from source class
	 * Output:	NONE (modifies input map)
	 * 			THIS MAY INSERT NEW LOCATION VALUES
	 ********************************************************/
    public static void buildLocationMap(Map<String, Schema.Location> locMap) {        
        Map<String, Schema.Location> exLocMap = new Map<String, Schema.Location>();
        for (Schema.Location l : [SELECT Id, Name FROM Location WHERE Name IN :locMap.keySet()]) {
            exLocMap.put(l.Name, l);
        }
        
        for (Schema.Location l : locMap.values()) {
            if (exLocMap.containsKey(l.Name)) {    
                l.Id = exLocMap.get(l.Name).Id;
            }
        }
        
        UPSERT locMap.values();
    }
    
    /********************************************************
	 * Purpose: gets a "top Asset" from a tree for fetching components
	 * Input:	aid - asset id
	 * Output:	Asset
	 ********************************************************/
    public static Asset getTopAsset(String aid) {
        return [SELECT 	Id, 
                		SerialNumber,
                		AccountId,
                		LocationId,
                		MS_FSM_LGen_SN_Short_Form__c,
                		MS_FSM_Node__c,
                		MS_FSM_Manufactured_By__c,
                		MS_FSM_EtaHub_Table_Id__c
                FROM 	Asset 
                WHERE 	Id = :aid];
    }
    
    /********************************************************
	 * Purpose: updates a EH record using a pre-built body
	 * Input:	JSON body
	 * Output:	NONE - 1 callout
	 ********************************************************/
    public static void updateEHData(String body) {
        Http h = new Http();
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.quickbase.com/v1/records');
        req.setMethod('POST');
        
        req.setHeader('QB-Realm-Hostname', 'etagen.quickbase.com');
        req.setHeader('Authorization', 'QB-USER-TOKEN b9k5cc_kxgc_0_cdcvetccs2hxxguead2aduam54');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(body);
        
        HTTPResponse r = h.send(req);
    }
    
    /********************************************************
	 * Purpose: gets a 2-character state code based on a full state name
	 * Input:	s - full state name
	 * Output:	2-character state code
	 ********************************************************/
    public static String getStateCode(String s) {
        if (stateToStateCode == null) {
            setStateCodeMap();
        }
        return stateToStateCode.get(s);
    }
    
    /********************************************************
	 * Purpose: sets the general use map for state codes
	 * Input:	NONE
	 * Output:	NONE - sets static variable
	 ********************************************************/
    private static void setStateCodeMap() {
        stateToStateCode = new Map<String, String>();
        Schema.DescribeFieldResult fieldResult = User.StateCode.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry p : ple) {
            stateToStateCode.put(p.getLabel(), p.getValue());
        }
    }
    
    /********************************************************
	 * Purpose: gets a country code based on a full country name
	 * Input:	s - full country name
	 * Output:	country code
	 ********************************************************/
    public static String getCountryCode(String s) {
        if (countryToCountryCode == null) {
            setCountryCodeMap();
        }
        return countryToCountryCode.get(s);
    }
    
    /********************************************************
	 * Purpose: sets the general use map for country codes
	 * Input:	NONE
	 * Output:	NONE - sets static variable
	 ********************************************************/
    private static void setCountryCodeMap() {
		countryToCountryCode = new Map<String, String>();        
        Schema.DescribeFieldResult fieldResult = User.CountryCode.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry p : ple) {
			countryToCountryCode.put(p.getLabel(), p.getValue());
        }
    }
    
    /********************************************************
	 * Purpose: retrieves number of minutes to lookback;
	 * 			the default is 15, but this may increase if reruns
	 * 			are necessitated
	 * Input:	NONE
	 * Output:	number of minutes to look back
	 ********************************************************/
    private static Decimal minutesLookback() {
        settings = [SELECT Id, Minutes_Lookback__c FROM MS_FSM_EtaHub_Integration_Setting__c LIMIT 1];
        return settings.Minutes_Lookback__c;
    }
    
    /********************************************************
	 * Purpose: updates / resets lookback minutes
	 * Input:	reset - will be set to true after successful run
	 * Output:	NONE
	 ********************************************************/
    public static void updateMinutes(Boolean reset) {
        if (settings == null) {
            return;
        }
        UPDATE new MS_FSM_EtaHub_Integration_Setting__c (
        	Id 					= settings.Id,
            Minutes_Lookback__c = reset ? 15 : (settings.Minutes_Lookback__c + 15)
        );
    }
    
    /* JSON SERIALIZING & DESERIALIZING CLASSES */
    
    private class EHQuery {
        private String 			from_x;
        private List<Integer> 	select_x;
        private String 			where_x;
        private EHOptions		options;
        
        public EHQuery(String t, List<Integer> f, String w, Integer p, Integer s) {
            from_x 		= t;
            select_x 	= f;
            where_x 	= w;
            options		= new EHOptions(p, s);
        }
    }
    
    private class EHOptions { 
        private Integer top;
        private Integer skip;
        
        public EHOptions(Integer t, Integer s) {
            top 	= t;
            skip 	= s;
        }
    }
    
    private class EHReturn {
        List<Map<Integer, Map<String, String>>> data;
    }
}