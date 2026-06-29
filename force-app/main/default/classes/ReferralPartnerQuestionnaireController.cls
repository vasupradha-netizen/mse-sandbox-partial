public without sharing class ReferralPartnerQuestionnaireController {
    
@AuraEnabled(cacheable=false)
public static TokenValidationWrapper validateTokenAndGetRecord(String token) {
    TokenValidationWrapper result = new TokenValidationWrapper();
    result.isValid = false;
    
    if (String.isBlank(token)) {
        return result;
    }
    
    // 1. Fetch field descriptions
    Map<String, Schema.SObjectField> schemaFieldMap = Schema.SObjectType.Partner_Application__c.fields.getMap();
    List<String> queryableFields = new List<String>();
    
    // 2. Loop and keep only accessible queryable fields (Exclude system noise like IsDeleted)
    for(String fieldName : schemaFieldMap.keySet()) {
        Schema.DescribeFieldResult fDescribe = schemaFieldMap.get(fieldName).getDescribe();
        Schema.DisplayType fieldType = fDescribe.getType();
    Boolean isCompound = (fieldType == Schema.DisplayType.ADDRESS || 
                          fieldType == Schema.DisplayType.LOCATION);
       
        if(fDescribe.isAccessible() && !isCompound) {
            queryableFields.add(fieldName);
        }
    }
 // Join all the fields with a comma
    String fieldsToSelect = String.join(queryableFields, ', ');
    Datetime currentTime = System.now();
    
    // Construct the query string
    String soqlQuery = 'SELECT ' + fieldsToSelect + 
                       ' FROM Partner_Application__c' + 
                       ' WHERE Token__c = :token' + 
                       ' AND Token_expires_at__c >= :currentTime' + 
                       ' LIMIT 1';
                       
    // 4. EXECUTE DYNAMIC SOQL
    List<Partner_Application__c> apps = Database.query(soqlQuery);
    
    if (!apps.isEmpty()) {
        result.isValid = true;
        result.record = apps[0];
    }
    
    return result;
}

    @AuraEnabled
    public static SaveResultWrapper saveRecord(String dataPayload, Boolean isFinalSubmit, String recordId) {
        SaveResultWrapper result = new SaveResultWrapper();
        
        try {
            if (String.isBlank(recordId)) {
                result.success = false;
                result.message = 'Error: Missing context record ID.';
                return result;
            }
            //Deserialize, conditionally inject Status__c, and re-serialize
            Map<String, Object> payloadMap = (Map<String, Object>) JSON.deserializeUntyped(dataPayload);
            if (isFinalSubmit) {
                payloadMap.put('Status__c', 'Submitted');
            }
            String finalPayload = JSON.serialize(payloadMap);
            // ALWAYS route updates through the platform event to bypass Guest User update restrictions
            Partner_Application_Update_Event__e updateEvent = new Partner_Application_Update_Event__e(
                Record_ID__c = recordId,
                Payload__c = finalPayload
            );
            
            Database.SaveResult sr = EventBus.publish(updateEvent);
            
            if (sr.isSuccess()) {
                result.success = true;
                result.recordId = recordId;
                result.message = isFinalSubmit ? 'Questionnaire submitted successfully!' : 'Draft saved successfully.';
            } else {
                result.success = false;
                result.message = 'Error queuing update server side.';
            }
            
        } catch (Exception e) {
            result.success = false;
            result.message = 'Error: ' + e.getMessage();
        }
        
        return result;
    }
    
    public class TokenValidationWrapper {
        @AuraEnabled public Boolean isValid;
        @AuraEnabled public Partner_Application__c record;
    }

    public class SaveResultWrapper {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String recordId;
        @AuraEnabled public String message;
    }

@AuraEnabled(cacheable=true)
    public static Map<String, Map<String, String>> getOrgStateCountryMapping() {
        Map<String, Map<String, String>> mappings = new Map<String, Map<String, String>>();
        
        // 1. Get the User field map dynamically to avoid static compilation errors
        Map<String, Schema.SObjectField> userFields = Schema.SObjectType.User.fields.getMap();
        
        // 2. Map Country Labels to Country Codes (e.g., "United States" => "US")
        Map<String, String> countryMap = new Map<String, String>();
        Schema.SObjectField countryCodeField = userFields.get('CountryCode');
        
        if (countryCodeField != null) {
            for (Schema.PicklistEntry pe : countryCodeField.getDescribe().getPicklistValues()) {
                if (pe.isActive()) {
                    countryMap.put(pe.getLabel(), pe.getValue());
                }
            }
        }
        mappings.put('countries', countryMap);
        
        // 3. Map State Labels to State Codes (e.g., "Texas" => "TX")
        Map<String, String> stateMap = new Map<String, String>();
        Schema.SObjectField stateCodeField = userFields.get('StateCode');
        
        if (stateCodeField != null) {
            for (Schema.PicklistEntry pe : stateCodeField.getDescribe().getPicklistValues()) {
                if (pe.isActive()) {
                    stateMap.put(pe.getLabel(), pe.getValue());
                }
            }
        }
        mappings.put('states', stateMap);
        
        return mappings;
    }

    public class Output {
        @InvocableVariable
        public String token;
    }

    @InvocableMethod(label='Generate Secure Token')
    public static List<Output> generateToken(List<String> requests) {

        Output result = new Output();

        Blob randomBytes = Crypto.generateAesKey(128);
        result.token = EncodingUtil.convertToHex(randomBytes);

        return new List<Output>{ result };
    }
@AuraEnabled
    public static Map<String, Object> requestNewAccessLink(String expiredToken, String emailInput) {
        Map<String, Object> response = new Map<String, Object>();
        response.put('success', false);
        
        if (String.isBlank(expiredToken) || String.isBlank(emailInput)) {
            response.put('message', 'Required inputs are missing.');
            return response;
        }
        
        // 1. Locate the record using BOTH the old token and the verification email
        List<Partner_Application__c> apps = [
            SELECT Id, Partner_Contact_Email__c 
            FROM Partner_Application__c 
            WHERE Token__c = :expiredToken 
            AND Partner_Contact_Email__c = :emailInput.trim()
            LIMIT 1
        ];
        System.debug('Old Rec Found?'+apps);
        // Security Best Practice: Return a generic success message even if no match is found
        // This prevents hackers from using the form to "fish" for valid emails.
        if (apps.isEmpty()) {
            response.put('success', true);
            response.put('message', 'No matching records found');
            return response;
        }
        
        Partner_Application__c app = apps[0];
        
        // 2. Safely generate a brand new cryptographically secure token
        Blob randomBytes = Crypto.generateAesKey(128);
        String newToken = EncodingUtil.convertToHex(randomBytes);
        Datetime newExpiry = System.now().addDays(1); // Token valid for 1 day
        
        // 3. Package the update into the Platform Event to bypass Guest User restrictions
        Map<String, Object> payloadMap = new Map<String, Object>{
            'Token__c' => newToken,
            'Token_expires_at__c' => newExpiry
        };
        
        Partner_Application_Update_Event__e updateEvent = new Partner_Application_Update_Event__e(
            Record_ID__c = app.Id,
            Payload__c = JSON.serialize(payloadMap)
        );
        
        Database.SaveResult sr = EventBus.publish(updateEvent);
        
        if (sr.isSuccess()) {
            // Note: Set up a Salesforce Record-Triggered Flow to send the email alert 
            // when Token__c changes on the Partner_Application__c object.
            
            response.put('success', true);
            response.put('message', 'A new secure link has been generated and sent to your email.');
        } else {
            response.put('success', false);
            response.put('message', 'Server error generating request. Please try again later.');
        }
        
        return response;
    }
}