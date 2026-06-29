public without sharing class PartnerApplicationUpdateHandler {
    
    public static void handleAfterInsert(List<Partner_Application_Update_Event__e> newEvents) {
        List<Partner_Application__c> recordsToUpdate = new List<Partner_Application__c>();
        
        // Cache the field map to optimize performance inside loops
        Map<String, Schema.SObjectField> fieldMapDescribe = Schema.SObjectType.Partner_Application__c.fields.getMap();

        for (Partner_Application_Update_Event__e event : newEvents) {
            if (String.isNotBlank(event.Payload__c) && String.isNotBlank(event.Record_ID__c)) {
                
                Partner_Application__c appToUpdate = new Partner_Application__c(Id = event.Record_ID__c);
                Map<String, Object> incomingFieldMap = (Map<String, Object>) JSON.deserializeUntyped(event.Payload__c);
                
                for (String fieldName : incomingFieldMap.keySet()) {
                    if (fieldName.equalsIgnoreCase('Id')) { 
                        continue; 
                    }
                    
                    Schema.SObjectField fieldToken = fieldMapDescribe.get(fieldName);
                    
                    if (fieldToken != null) {
                        Schema.DescribeFieldResult fDescribe = fieldToken.getDescribe();
                        Schema.DisplayType fieldType = fDescribe.getType();
                        
                        // RESTORED: Skip compound parent fields
                        if (fieldType == Schema.DisplayType.ADDRESS || fieldType == Schema.DisplayType.LOCATION) {
                            continue;
                        }
                        
                        if (fDescribe.isUpdateable()) {
                            Object rawValue = incomingFieldMap.get(fieldName);
                            
                            // RESTORED: Explicit null / empty string handling
                            if (rawValue == null || String.valueOf(rawValue).trim() == '') {
                                appToUpdate.put(fieldName, null);
                            } 
                            else {
                                String stringValue = String.valueOf(rawValue).trim();
                                
                                if (fieldType == Schema.DisplayType.DATE) {
                                    // RESTORED: Safe Date parsing
                                    String datePart = stringValue.contains('T') ? stringValue.substringBefore('T') : stringValue;
                                    appToUpdate.put(fieldName, Date.valueOf(datePart));
                                } 
                                else if (fieldType == Schema.DisplayType.DATETIME) {
                                    Datetime parsedDt = (Datetime)JSON.deserialize('"' + stringValue + '"', Datetime.class);
                                    appToUpdate.put(fieldName, parsedDt);
                                }
                                else if (fieldType == Schema.DisplayType.CURRENCY || fieldType == Schema.DisplayType.DOUBLE || fieldType == Schema.DisplayType.PERCENT) {
                                    appToUpdate.put(fieldName, Decimal.valueOf(stringValue));
                                }
                                else if (fieldType == Schema.DisplayType.BOOLEAN) {
                                    // RESTORED: Safe boolean checking
                                    Boolean bVal = (stringValue.equalsIgnoreCase('true') || stringValue == '1' || stringValue.equalsIgnoreCase('on'));
                                    appToUpdate.put(fieldName, bVal);
                                }
                                else if (fieldType == Schema.DisplayType.PICKLIST || fieldType == Schema.DisplayType.MULTIPICKLIST) {
                                    // RESTORED: The critical picklist resolution!
                                    String resolvedValue = resolvePicklistValue(fDescribe, stringValue);
                                    appToUpdate.put(fieldName, resolvedValue);
                                }
                                else {
                                    appToUpdate.put(fieldName, stringValue); 
                                }
                            }
                        }
                    }
                }
                
                recordsToUpdate.add(appToUpdate);
            } 
        } 

        if (!recordsToUpdate.isEmpty()) {
            update recordsToUpdate;
        }
    }

    // RESTORED: Helper method to safely translate Picklist Labels to Codes
    private static String resolvePicklistValue(Schema.DescribeFieldResult fDescribe, String input) {
        List<Schema.PicklistEntry> entries = fDescribe.getPicklistValues();

        // First pass: exact match on code/value (most common case)
        for (Schema.PicklistEntry pe : entries) {
            if (pe.isActive() && pe.getValue().equalsIgnoreCase(input)) {
                return pe.getValue();
            }
        }

        // Second pass: match on label (handles "United States" → "US")
        for (Schema.PicklistEntry pe : entries) {
            if (pe.isActive() && pe.getLabel().equalsIgnoreCase(input)) {
                return pe.getValue(); // return the CODE, not the label
            }
        }

        // No match — return as-is and let DML surface the error clearly
        return input;
    }
}