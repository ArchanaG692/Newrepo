public with sharing class AccountClass {
    @AuraEnabled
    public static Id createAccount(
        String Name,
        String Phone,
        String Type,
        String Rating,
        Date DOB,
        String Email,
        String BillingStreet,
        String BillingCity,
        String BillingState,
        String BillingPostalCode,
        String BillingCountry,
        String ShippingStreet,
        String ShippingCity,
        String ShippingState,
        String ShippingPostalCode,
        String ShippingCountry,
        String CustomerPriority,
        String SLA,
        Date SLAExpirationDate
    ) {
        // Create the Account instance
        Account acc = new Account();
        acc.Name = Name;
        acc.Phone = Phone;
        acc.Type = Type;
        acc.Rating = Rating;
        
        // Set additional fields
        // acc.DOB__c = DOB;
        // acc.Email__c = Email;

        // Set Billing Address fields
        acc.BillingStreet = BillingStreet;
        acc.BillingCity = BillingCity;
        acc.BillingState = BillingState;
        acc.BillingPostalCode = BillingPostalCode;
        acc.BillingCountry = BillingCountry;

        // Set Shipping Address fields
        acc.ShippingStreet = ShippingStreet;
        acc.ShippingCity = ShippingCity;
        acc.ShippingState = ShippingState;
        acc.ShippingPostalCode = ShippingPostalCode;
        acc.ShippingCountry = ShippingCountry;

        // Set other custom fields
        acc.CustomerPriority__c = CustomerPriority;
        acc.SLA__c = SLA;
        acc.SLAExpirationDate__c = SLAExpirationDate;

        try {
            insert acc;  // Insert the Account record
            return acc.Id;  // Return the ID of the new Account
        } catch (Exception ex) {
            System.debug('Error1: ' + ex.getMessage());
            throw new AuraHandledException('Account creation failed: ' + ex.getMessage());
        }
    }
}