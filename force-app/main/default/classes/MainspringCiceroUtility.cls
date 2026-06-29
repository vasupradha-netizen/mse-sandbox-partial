/**
 * Utility class to support Cicero API Integration for retrieving officials info.
 * Provides methods to connect to the Cicero endpoints and parses the response.
 * - When the refresh button is pressed or during the monthly refresh: we replace the Officials lookups with non-empty results from the Cicero call, 
 *      and do not clear out the lookups if the API does not return any results.
 * - When the site address changes we clear all lookups, and bring new data from cicero even if pieces are missing.
 * Created by DaizyLogik Nov 2023
 */
public class MainspringCiceroUtility {

    private static Cicero_Setting__c ciceroSetting = null;
    private static final String OFFICIAL = 'official';
    private static final String NATIONAL_LOWER = 'NATIONAL_LOWER';
    private static final String NATIONAL_UPPER = 'NATIONAL_UPPER';
    private static final String STATE_LOWER = 'STATE_LOWER';
    private static final String STATE_UPPER = 'STATE_UPPER';
    private static final String US_SENATE1 = 'USSENATE1';
    private static final String US_SENATE2 = 'USSENATE2';
    private static final String US_SENATE = 'USSENATE';
    private static final String US_HOUSE = 'USHOUSE';
    private static final String STATE_HOUSE = 'STATEHOUSE';
    private static final String STATE_SENATE = 'STATESENATE';
    private static final Map<String, String> DISTRICT_MAP = new Map<String, String>{STATE_LOWER=>'State House', 
                                                                                    STATE_UPPER=>'State Senate',
                                                                                    NATIONAL_LOWER=>'US House',
                                                                                    NATIONAL_UPPER=>'US Senate'};
    // Conversion map for full state names to abbreviations
    private static final Map<String, String> STATE_ABBREVIATION_MAP = new Map<String, String>{
    'Alabama' => 'AL', 'Alaska' => 'AK', 'Arizona' => 'AZ', 'Arkansas' => 'AR', 
    'California' => 'CA', 'Colorado' => 'CO', 'Connecticut' => 'CT', 'Delaware' => 'DE', 
    'Florida' => 'FL', 'Georgia' => 'GA', 'Hawaii' => 'HI', 'Idaho' => 'ID', 'Illinois' => 'IL', 
    'Indiana' => 'IN', 'Iowa' => 'IA', 'Kansas' => 'KS', 'Kentucky' => 'KY', 'Louisiana' => 'LA', 
    'Maine' => 'ME', 'Maryland' => 'MD', 'Massachusetts' => 'MA', 'Michigan' => 'MI', 'Minnesota' => 'MN', 
    'Mississippi' => 'MS', 'Missouri' => 'MO', 'Montana' => 'MT', 'Nebraska' => 'NE', 'Nevada' => 'NV', 
    'New Hampshire' => 'NH', 'New Jersey' => 'NJ', 'New Mexico' => 'NM', 'New York' => 'NY', 
    'North Carolina' => 'NC', 'North Dakota' => 'ND', 'Ohio' => 'OH', 'Oklahoma' => 'OK', 
    'Oregon' => 'OR', 'Pennsylvania' => 'PA', 'Rhode Island' => 'RI', 'South Carolina' => 'SC', 
    'South Dakota' => 'SD', 'Tennessee' => 'TN', 'Texas' => 'TX', 'Utah' => 'UT', 'Vermont' => 'VT', 
    'Virginia' => 'VA', 'Washington' => 'WA', 'West Virginia' => 'WV', 'Wisconsin' => 'WI', 'Wyoming' => 'WY'
      };
     private static final Map<String, String> STATE_FULL_NAME_MAP = new Map<String, String>{
    'AL' => 'Alabama', 'AK' => 'Alaska', 'AZ' => 'Arizona', 'AR' => 'Arkansas', 
    'CA' => 'California', 'CO' => 'Colorado', 'CT' => 'Connecticut', 'DE' => 'Delaware', 
    'FL' => 'Florida', 'GA' => 'Georgia', 'HI' => 'Hawaii', 'ID' => 'Idaho', 
    'IL' => 'Illinois', 'IN' => 'Indiana', 'IA' => 'Iowa', 'KS' => 'Kansas', 
    'KY' => 'Kentucky', 'LA' => 'Louisiana', 'ME' => 'Maine', 'MD' => 'Maryland', 
    'MA' => 'Massachusetts', 'MI' => 'Michigan', 'MN' => 'Minnesota', 'MS' => 'Mississippi', 
    'MO' => 'Missouri', 'MT' => 'Montana', 'NE' => 'Nebraska', 'NV' => 'Nevada', 
    'NH' => 'New Hampshire', 'NJ' => 'New Jersey', 'NM' => 'New Mexico', 'NY' => 'New York', 
    'NC' => 'North Carolina', 'ND' => 'North Dakota', 'OH' => 'Ohio', 'OK' => 'Oklahoma', 
    'OR' => 'Oregon', 'PA' => 'Pennsylvania', 'RI' => 'Rhode Island', 'SC' => 'South Carolina', 
    'SD' => 'South Dakota', 'TN' => 'Tennessee', 'TX' => 'Texas', 'UT' => 'Utah', 
    'VT' => 'Vermont', 'VA' => 'Virginia', 'WA' => 'Washington', 'WV' => 'West Virginia', 
    'WI' => 'Wisconsin', 'WY' => 'Wyoming'
};

    private static final Map<String, String> COUNTRY_ABBREVIATION_MAP = new Map<String, String>{
    'United States' => 'US', 'Canada' => 'CA', 'Mexico' => 'MX'
    };
                                                                                    

    //get custom settings with cicero connection string
    private static Cicero_Setting__c getCiceroSettings() {
        if (ciceroSetting == null) {
            ciceroSetting = Cicero_Setting__c.getOrgDefaults();
        }
        if (Test.isRunningTest()) {
            //unit tests only
            ciceroSetting = new Cicero_Setting__c();
            ciceroSetting.API_Key__c = 'abcdefg123456789';
            ciceroSetting.Endpoint_URL__c = 'https://test.url';
        }
        return ciceroSetting;
    }

    //make callout to get Officials information
    public static HttpResponse getOfficialsInfo(String searchLocation) {
        //get endpoint info to build URL
        getCiceroSettings();
        String endpointUrl = ciceroSetting.Endpoint_URL__c;
        String APIKey = ciceroSetting.API_Key__c;

        String encodedAddress = EncodingUtil.urlEncode(searchLocation, 'UTF-8');
        String officialURL = endpointUrl + '/' + OFFICIAL +'?format=JSON&key=' + 
                                APIkey + '&search_loc='+encodedAddress;
                         
        Httprequest request = new HttpRequest();
        Http http = new Http();
    
        request.setMethod('GET');
        request.setEndpoint(officialURL);  
        request.setHeader('Content-Type', 'application/json');   
            
        //Making call to external REST API
        HttpResponse response = http.send(request);  

// Check response code
System.debug('Response Status: ' + response.getStatusCode());
//System.debug('Response Headers: ' + response.getAllHeaders());
System.debug('Response Body: ' + response.getBody());

if (response.getStatusCode() != 200) {
    System.debug('Error from Cicero API: ' + response.getBody());
    throw new CalloutException('Error from Cicero API: ' + response.getStatusCode());
}

// Proceed with parsing only if the response is valid JSON
if (!response.getHeader('Content-Type').contains('application/json')) {
    System.debug('Invalid response format, expected JSON but received: ' + response.getHeader('Content-Type'));
    throw new CalloutException('Invalid response format');
}


 
        return response;    
    }

   //visible by flow button to update the Officials for a site, w/o clear functionality
   @invocableMethod
   public static void updateOfficialsInvocable(List<String> siteIds) {
        updateOfficials(siteIds, false);
   }

    //async call to parse and update the officials information
    //includes parameter flag to indicate if lookups should be cleared or not
    @Future(callout=true)
    public static void updateOfficials(List<String> siteIds, boolean clearOfficialLookups) {
        
        
        //get the Site address and related officials contact info
        List<Sites__c> sites = [select Id, Street_1__c, Street_2__c, City__c, State_Region__c, Postal_Code__c,
                                US_Senate_1__c, US_Senate_1__r.FirstName, US_Senate_1__r.LastName, US_Senate_1__r.MiddleName, 
                                US_Senate_2__c, US_Senate_2__r.FirstName, US_Senate_2__r.LastName, US_Senate_2__r.MiddleName, 
                                US_House__c, US_House__r.FirstName,
                                State_Senate__c, State_Senate__r.FirstName,
                                State_House__c, State_House__r.FirstName
                                from Sites__c where id in :siteIds];     

        if (!sites.isEmpty()) {
            Sites__c site = sites[0];
            //set up a map of official contacts
            Map<String, Contact> officialContactsMap = new Map<String, Contact>(); 
            Contact usSenate1Contact = (Contact)site.getSObject('US_Senate_1__r');
            Contact usSenate2Contact = (Contact)site.getSObject('US_Senate_2__r');
            Contact usHouseContact = (Contact)site.getSObject('US_House__r');
            Contact stateSenateContact = (Contact)site.getSObject('State_Senate__r');
            Contact stateHouseContact = (Contact)site.getSObject('State_House__r');
            //System.debug('DEBUG >>> what is the flag '+clearOfficialLookups);
            //store the existing lookup values in the map, if we're not supposed to clear the lookups
            if (!clearOfficialLookups) {
                officialContactsMap.put(US_SENATE1, usSenate1Contact);
                officialContactsMap.put(US_SENATE2, usSenate2Contact);
                officialContactsMap.put(US_HOUSE, usHouseContact);
                officialContactsMap.put(STATE_SENATE, stateSenateContact);
                officialContactsMap.put(STATE_HOUSE, stateHouseContact);
            }
            //clear the site official lookups so we don't keep stale data, if flag indicates that
            if (clearOfficialLookups) 
                clearSiteOfficialLookups(site); 

            Map<String,Contact> newContacts = new Map<String,Contact>();
            
            //build the http request
            String param = (site.Street_1__c != null ? site.Street_1__c+' ' : '')+
                           (site.Street_2__c != null ? site.Street_2__c+' ' : '')+
                           (site.City__c != null ? site.City__c+' ' : '')+
                           (site.State_Region__c != null ? site.State_Region__c+' ' : '')+
                           (site.Postal_Code__c != null ? site.Postal_Code__c : '');

            if (!String.isBlank(param)) {
                param = param.replaceAll(' ', '+'); //replace all spaces with + even in street names
                //System.debug('DEBUG >>> parameter is '+param);
                HttpResponse resp = getOfficialsInfo(param);
                List<OfficialInfo> officialList = parseOfficialInfo(resp, site.Id);
                if (officialList.isEmpty()) return; //if no officials were returned due to error just exit here
                Integer senator_index = 1;
                for (OfficialInfo o : officialList) {
                    if (o.office.district.district_type == STATE_LOWER) {
                        Contact c = newContact(o);
                        newContacts.put(o.first_name+o.last_name+DISTRICT_MAP.get(o.office.district.district_type), c);
                        officialContactsMap.put(STATE_HOUSE, c);
                    } else if (o.office.district.district_type == STATE_UPPER) {
                        Contact c = newContact(o);
                        newContacts.put(o.first_name+o.last_name+DISTRICT_MAP.get(o.office.district.district_type), c);
                        officialContactsMap.put(STATE_SENATE, c);
                    } else if (o.office.district.district_type == NATIONAL_LOWER) {
                        Contact c = newContact(o);
                        newContacts.put(o.first_name+o.last_name+DISTRICT_MAP.get(o.office.district.district_type), c);
                        officialContactsMap.put(US_HOUSE, c);
                    } else if (o.office.district.district_type == NATIONAL_UPPER) {
                        Contact c = newContact(o);
                        newContacts.put(o.first_name+o.last_name+DISTRICT_MAP.get(o.office.district.district_type), c);
                        officialContactsMap.put(US_SENATE+String.valueOf(senator_index), c);
                        senator_index++;
                    } 
                }
            }
            //look through existing contacts and see if any already exist based on firstname+lastname+district_type
            Set<String> keysForMatching = newContacts.keySet();
            //System.debug('DEBUG >>> keys for matching '+keysForMatching);
            //System.debug('DEBUG >>> newContacts '+newContacts);
            List<Contact> contactsToUpdate = new List<Contact>(); //this is the final list for update
            for (Contact existingCon : [select id, Official_FirstLastDistrict_Key__c 
                                            from Contact where Role__c = 'Legislator' and Official_FirstLastDistrict_Key__c in :keysForMatching]){
                //update the existing Officials detail information by copying the data from the response onto the existing Contact
                Contact updatedCon = newContacts.get(existingCon.Official_FirstLastDistrict_Key__c);
                if (updatedCon != null) {
                    updatedCon.Id = existingCon.Id;
                    contactsToUpdate.add(updatedCon);                                
                    //remove this contact from the new contact list
                    newContacts.remove(existingCon.Official_FirstLastDistrict_Key__c);
                }
            }
            //what's left can be inserted
            insert newContacts.values();    
            //update existing contacts
            update contactsToUpdate;
            //set the lookups on the site based on new Contacts
            site.State_House__c = ((Contact)officialContactsMap.get(STATE_HOUSE)) != null ? ((Contact)officialContactsMap.get(STATE_HOUSE)).Id : null;
            site.State_Senate__c = ((Contact)officialContactsMap.get(STATE_SENATE)) != null ? ((Contact)officialContactsMap.get(STATE_SENATE)).Id : null;
            site.US_House__c = ((Contact)officialContactsMap.get(US_HOUSE)) != null ? ((Contact)officialContactsMap.get(US_HOUSE)).Id : null;
            site.US_Senate_1__c = ((Contact)officialContactsMap.get(US_SENATE1)) != null ? ((Contact)officialContactsMap.get(US_SENATE1)).Id : null;
            site.US_Senate_2__c = ((Contact)officialContactsMap.get(US_SENATE2)) != null ? ((Contact)officialContactsMap.get(US_SENATE2)).Id : null;
            site.Cicero_API_Call_Response__c = 'Success';
            site.Cicero_API_Call_Last_Refresh__c = Datetime.now();
            update site;
        }             
              
    }

    //given the official info create a new contact
    private static Contact newContact(OfficialInfo officialInfo) {
        String committees = '';
        String identifiers = '';
        String notes = '';
        for (Committee com : officialInfo.committees) {
            committees += com.name+': '+com.position+', ';
        }
        for (IdentifierInfo idf : officialInfo.identifiers){
            identifiers += idf.identifier_type+': '+idf.identifier_value+', ';
        }
        for (String note : officialInfo.notes) {
            if (note != 'null')
                notes += note+', ';
        }
        system.debug('official info addresses' +officialInfo.addresses);
        
        return new Contact(FirstName = officialInfo.first_name, 
                            LastName = officialInfo.last_name, 
                            MiddleName = officialInfo.middle_initial, 
                            Preferred_Name__c = officialInfo.preferred_name,
                            Salutation = officialInfo.salutation, 
                            Suffix = officialInfo.name_suffix,
                            District_Type__c = DISTRICT_MAP.get(officialInfo.office.district.district_type), 
                            Legislative_District__c = officialInfo.office.district.label,
                            Representing_State__c = officialInfo.office.representing_state,
                            Title = officialInfo.office.title,
                            Valid_From__c = (!String.isBlank(officialInfo.valid_from) ? Date.valueOf(officialInfo.valid_from) : null), 
                            Valid_To__c = (!String.isBlank(officialInfo.valid_to) ? Date.valueOf(officialInfo.valid_to) : null),
                            MailingStreet = (!officialInfo.addresses.isEmpty() ? officialInfo.addresses[0].address_1 : null),
                            MailingCity = (!officialInfo.addresses.isEmpty() ? officialInfo.addresses[0].city : null),
                            //MailingState = (!officialInfo.addresses.isEmpty() ? officialInfo.addresses[0].state : null),
                            //MailingState = (!officialInfo.addresses.isEmpty() ? STATE_ABBREVIATION_MAP.get(officialInfo.addresses[0].state) : null),
                            MailingState = (!officialInfo.addresses.isEmpty() ? STATE_FULL_NAME_MAP.get(officialInfo.addresses[0].state) : null),
                            MailingPostalCode = (!officialInfo.addresses.isEmpty() ? officialInfo.addresses[0].postal_code : null),
                            OtherStreet = (officialInfo.addresses.size()>1 ? officialInfo.addresses[1].address_1 : null),
                            OtherCity = (officialInfo.addresses.size()>1 ? officialInfo.addresses[1].city : null),
                            //OtherState = (officialInfo.addresses.size()>1 ? STATE_ABBREVIATION_MAP.get(officialInfo.addresses[0].state) : null),
                            OtherState = (officialInfo.addresses.size() > 1 ? STATE_FULL_NAME_MAP.get(officialInfo.addresses[1].state) : null),
                            OtherPostalCode = (officialInfo.addresses.size()>1 ? officialInfo.addresses[1].postal_code : null),
                            Phone = (!officialInfo.addresses.isEmpty() ? officialInfo.addresses[0].phone_1 : null),
                            Email = (!officialInfo.email_addresses.isEmpty() ? officialInfo.email_addresses[0] : null),
                            Web_Form__c = officialInfo.web_form_url, 
                            Website__c = (!officialInfo.urls.isEmpty() ? officialInfo.urls[0] : null),
                            Photo_URL__c = officialInfo.photo_origin_url,
                            Legislator_Bio__c = notes.left(32000),
                            Political_Party__c = officialInfo.party,
                            Committees__c = committees,
                            External_Platforms__c = identifiers,
                            Role__c = 'Legislator');
    }

    //extracts the information from a callout to Official api
    public static List<OfficialInfo> parseOfficialInfo(HttpResponse response, Id siteId) {
        JSONParser parser = JSON.createParser(response.getBody());
        List<OfficialInfo> officialsList = new List<OfficialInfo>();
        boolean gotError = false;
        String error = '';
        while (parser.nextToken() != null) {
            if (parser.getText() == 'errors') {//errors
                parser.nextToken();
                parser.nextToken();
                error = parser.getText();
                if (error != null && error != ']') {
                    gotError = true;
                    break;
                } 
            }
            if (parser.getText() == 'officials') {//officials
                parser.nextToken();
                if (parser.getCurrentToken() == JSONToken.START_ARRAY) { 
                    while (parser.nextToken() != null) {
                        if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                            OfficialInfo linfo = (OfficialInfo)parser.readValueAs(OfficialInfo.class);
                            if (linfo != null && linfo.office != null && linfo.office.district != null && 
                                   (linfo.office.district.district_type == STATE_LOWER || 
                                    linfo.office.district.district_type == STATE_UPPER ||
                                    linfo.office.district.district_type == NATIONAL_LOWER || 
                                    linfo.office.district.district_type == NATIONAL_UPPER)) {
                                officialsList.add(linfo);
                            }
                            parser.skipChildren();
                        }
                    }
                }
            }
        }
        if (gotError) {//set the field on the site with the site, and clear the officials
            List<Sites__c> sites = [select id, Cicero_API_Call_Response__c, Cicero_API_Call_Last_Refresh__c 
                                        from Sites__c where Id = :siteId];
            if (!sites.isEmpty()) {
                sites[0].Cicero_API_Call_Response__c = error;
                sites[0].Cicero_API_Call_Last_Refresh__c = Datetime.now();
                // sites[0].State_House__c = null;
                // sites[0].State_Senate__c = null;   
                // sites[0].US_House__c = null;                
                // sites[0].US_Senate_1__c = null;                
                // sites[0].US_Senate_2__c = null;
                clearSiteOfficialLookups(sites[0]);
            }
            update sites;
        }
        return officialsList;
    }

    private static void clearSiteOfficialLookups(Sites__c site) {
        site.State_House__c = null;
        site.State_Senate__c = null;   
        site.US_House__c = null;                
        site.US_Senate_1__c = null;                
        site.US_Senate_2__c = null;
    }

    //data structures used to de-serialize the json from cicero
    public class Address {
        public String address_1;
        public String city;
        public String state;
        public String postal_code;
        public String phone_1;
    }

    public class Committee {
        public String name;
        public String position;
    }

    public class IdentifierInfo {
       public String identifier_type;
       public String identifier_value;
       public String official;
    }

    public class District {
        public String district_type;
        public String label;
    }

    public class Office {
        public District district;
        public String representing_state;
        public String title;
    }

    public class OfficialInfo {
        public String first_name;
        public String last_name;
        public String middle_initial;
        public String preferred_name;
        public String salutation;
        public String name_suffix;
        public Office office;
        public String valid_from;
        public String valid_to;
        public Address[] addresses;
        public String[] email_addresses; 
        public String web_form_url;
        public String[] urls; 
        public String photo_origin_url;
        public String[] notes;
        public Committee[] committees;
        public String party;
        public IdentifierInfo[] identifiers;
    }

}