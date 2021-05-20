@IsTest
public with sharing class SyncingContactsTest {
    @TestSetup
    public static void testSetup() {
        List<Contact> contacts = new List<Contact>();
        for(Integer i = 0; i < 100; i++) {
            Contact contact = new Contact(LastName = 'Lastname Test ' + i, FirstName  = 'Firstname Test ' + i, Email = 'test' + i + '@test.com');
            contacts.add(contact);
        }

        insert contacts;
    }

    /**
     * @description Test - successful call
     */
    @IsTest
    public static void patchContactsTestSuccess() {
        List<SyncingContacts.ContactWrapper> contactWrapperList = new List<SyncingContacts.ContactWrapper>();
        List<Contact> contacts = [SELECT Id, Email FROM Contact LIMIT 100];

        //try updating different combinations
        for(Integer i = 0; i < 50; i++) {
            SyncingContacts.ContactWrapper contactWrapper = new SyncingContacts.ContactWrapper('fin ' + i, 'ln ' + i, '+61400000000',
                    contacts[i].Email, null, null, null, null, null);
            contactWrapperList.add(contactWrapper);
        }

        for(Integer i = 0; i < 50; i++) {
            SyncingContacts.ContactWrapper contactWrapper = new SyncingContacts.ContactWrapper('fin ' + i, 'ln ' + i, '+61400000001',
                    contacts[i+50].Email, '01/01/20', 'Street '+i, 'City '+i, 'State', '5');
            contactWrapperList.add(contactWrapper);
        }
        Test.startTest();
        String message = makeRequest(contactWrapperList);
        Test.stopTest();
        System.assertEquals(SyncingContacts.MESSAGE_TO_USER.get('success'), message, 'All contacts should be updated successfully');

        //test some updated values
        List<Contact> contactList = [SELECT Id FROM Contact WHERE MobilePhone = '+61400000000' OR MailingState = 'State'];
        System.assertEquals(100, contactList.size(), 'Total contacts updated should be 100');
    }

    /**
     * @description Test - Record fails to update if email is not found in salesforce
     */
    @IsTest
    public static void patchContactsTestFailed() {
        List<SyncingContacts.ContactWrapper> contactWrapperList = new List<SyncingContacts.ContactWrapper>();
        List<Contact> contacts = [SELECT Id, Email FROM Contact LIMIT 100];
        Integer totalContactsToUpdate = 50;
        for(Integer i = 0; i < totalContactsToUpdate; i++) {
            SyncingContacts.ContactWrapper contactWrapper = new SyncingContacts.ContactWrapper('fin ' + i, 'ln ' + i, '+61400000001',
                    contacts[i].Email, null, null, null, null, null);
            contactWrapperList.add(contactWrapper);
        }
        contactWrapperList[1].Email = 'changeEmailToFail@test.com';//this record should fail to update

        Test.startTest();
        String message = makeRequest(contactWrapperList);
        Test.stopTest();

        System.assert(message.contains(SyncingContacts.MESSAGE_TO_USER.get('failed')), 'There should be a failed record');

        List<Contact> contactList = [SELECT Id FROM Contact WHERE MobilePhone = '+61400000001'];
        System.assertEquals(totalContactsToUpdate - 1, contactList.size(), 'Total contacts updated should be 50');
    }

    /**
     * @description Test - payload missing email
     */
    @IsTest
    public static void patchContactsTestMissingRequiredField() {
        List<SyncingContacts.ContactWrapper> contactWrapperList = new List<SyncingContacts.ContactWrapper>();
        for(Integer i = 0; i < 10; i++) {
            SyncingContacts.ContactWrapper contactWrapper = new SyncingContacts.ContactWrapper('fin ' + i, 'ln ' + i, '+61400000001',
                    null, null, null, null, null, null);
            contactWrapperList.add(contactWrapper);
        }

        Test.startTest();
        String message = makeRequest(contactWrapperList);
        Test.stopTest();
        System.assert(message.contains(SyncingContacts.MESSAGE_TO_USER.get('missingRequiredField')), 'Missing required fieldemails');
    }

    /**
     * @description Test - payload should be more than 0 and less than TOTAL_API_CALLS=2000 object long
     */
    @IsTest
    public static void patchContactsTestRecordNumber() {
        List<SyncingContacts.ContactWrapper> contactWrapperList = new List<SyncingContacts.ContactWrapper>();
        for(Integer i = 0; i < SyncingContacts.TOTAL_API_CALLS + 1; i++) {
            SyncingContacts.ContactWrapper contactWrapper = new SyncingContacts.ContactWrapper('fin ' + i, 'ln ' + i, '+61400000001',
                    null, null, null, null, null, null);
            contactWrapperList.add(contactWrapper);
        }
        Test.startTest();
        String message = makeRequest(contactWrapperList);
        Test.stopTest();
        System.assertEquals(SyncingContacts.MESSAGE_TO_USER.get('recordNumber'), message, 'Missing required fieldemails');
    }

    /**
     * @description Test - format of dateOfBirth is incorrect
     */
    @IsTest
    public static void patchContactsTestFormatError() {
        List<SyncingContacts.ContactWrapper> contactWrapperList = new List<SyncingContacts.ContactWrapper>();
        List<Contact> contacts = [SELECT Id, Email FROM Contact LIMIT 2];
        for(Integer i = 0; i < 2; i++) {
            SyncingContacts.ContactWrapper contactWrapper = new SyncingContacts.ContactWrapper('fin ' + i, 'ln ' + i, '+61400000001',
                    contacts[i].Email, 'ss', null, null, null, null);
            contactWrapperList.add(contactWrapper);
        }
        Test.startTest();
        String message = makeRequest(contactWrapperList);
        System.assert(message.contains(SyncingContacts.MESSAGE_TO_USER.get('formatError')), 'For birthdate and counter are not in correct format');
        Test.stopTest();
    }

    /**
     * @description helper method to make dummy request
     * @param contactWrapperList List of contact wrapper class
     *
     * @return message returned by service
     */
    public static String makeRequest(List<SyncingContacts.ContactWrapper> contactWrapperList) {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestURI = '/services/apexrest/SyncingContacts/';
        request.httpMethod = 'POST';
        RestContext.request = request;
        RestContext.response= response;
        String message = SyncingContacts.patchContacts(contactWrapperList);
        return message;
    }
}