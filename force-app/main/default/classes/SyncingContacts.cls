/**
 *@description This class updates salesforce contacts with front-end
 */
@RestResource(UrlMapping = '/contacts/')
global with sharing class SyncingContacts {
    @TestVisible final static Integer TOTAL_API_CALLS = 2000;//Limiting the api based on CPU timeout (currently at 60%).
    @TestVisible final static Map<String, String> MESSAGE_TO_USER = new Map<String, String> {
            'success' => 'All records updated successfully.',
            'recordNumber' => 'Make sure you add more than 1 and less than ' + TOTAL_API_CALLS + ' records',
            'failed' => 'All other records updated successfully, failed to update for: ',
            'missingRequiredField' => 'All other records updated successfully, Missing email for: ',
            'formatError' => 'Please make sure birthdate and counter are in correct format. '};
    /**
     * @description Updating contacts based on the payload.<br><br>
     * To call make request to https://yourinstance.salesforce.com/services/apexrest/contacts/ using Patch
     * Expecting parameters eg -<br>
     * {"contacts": [{"FirstName":"apple", "LastName":"juice", "Email":"test@test.com"},{"FirstName":"orange", "LastName":"crush"}]}
     *
     *
     * @return message
     */
    @HttpPatch
    global static String patchContacts(List<ContactWrapper> contacts) {
        String message = '';
        String firstName;
        String lastName;
        String mobilePhone;
        String email;
        Date birthdate;
        String street;
        String city;
        String state;
        Decimal counter;
        Map<String, ContactWrapper> contactWrapperMap = new Map<String, ContactWrapper>();

        if(contacts.size() > 0  && contacts.size() <= TOTAL_API_CALLS) {
            for(ContactWrapper contact: contacts) {
                if(!String.isBlank(contact.Email)) {
                    contactWrapperMap.put(contact.Email, new ContactWrapper(contact.FirstName, contact.LastName, contact.MobilePhone, contact.Email,
                                            contact.Birthdate, contact.Street, contact.City, contact.State, contact.Counter));
                }
                else {//all fields are combined to prevent unnecessary if statements, in case a field is not available in the payload
                    message += MESSAGE_TO_USER.get('missingRequiredField') + contact.FirstName + ' ' + contact.LastName + ' ' + contact.MobilePhone + ' ' +
                            contact.Birthdate + ' ' + contact.Street + ' ' + contact.City + ' ' + contact.State + ' ' + contact.Counter + '\n';
                }
                message = message.replaceAll('null','');
            }

            Map<String, Contact> contactsToUpdate = new Map<String, Contact>();
            //check if a field needs to be updated from the retrieved list
            for(Contact contact : [SELECT FirstName, LastName, MobilePhone, Email, Birthdate, MailingStreet, OtherStreet,
                                    MailingCity, OtherCity, MailingState, OtherState, Counter__c
                                    FROM Contact
                                    WHERE Email IN :contactWrapperMap.keySet()
                                    LIMIT :TOTAL_API_CALLS]) {
                firstName = String.isBlank(contactWrapperMap.get(contact.Email).FirstName) ? contact.FirstName : contactWrapperMap.get(contact.Email).FirstName;
                lastName = String.isBlank(contactWrapperMap.get(contact.Email).LastName) ? contact.LastName : contactWrapperMap.get(contact.Email).LastName;
                mobilePhone = String.isBlank(contactWrapperMap.get(contact.Email).MobilePhone) ? contact.MobilePhone : contactWrapperMap.get(contact.Email).MobilePhone;
                email = contact.Email; //Email is the required field
                street = String.isBlank(contactWrapperMap.get(contact.Email).Street) ? contact.MailingStreet : contactWrapperMap.get(contact.Email).Street;
                city = String.isBlank(contactWrapperMap.get(contact.Email).City) ? contact.MailingCity : contactWrapperMap.get(contact.Email).City;
                state = String.isBlank(contactWrapperMap.get(contact.Email).State) ? contact.MailingState : contactWrapperMap.get(contact.Email).State;

                try {
                    birthdate = String.isBlank(contactWrapperMap.get(contact.Email).Birthdate) ? contact.Birthdate : Date.parse(contactWrapperMap.get(contact.Email).Birthdate);
                    counter = String.isBlank(contactWrapperMap.get(contact.Email).Counter) ? contact.Counter__c : Decimal.valueOf(contactWrapperMap.get(contact.Email).Counter);
                    contactsToUpdate.put(email, new Contact(Id = contact.Id, FirstName = firstName, LastName = lastName, MobilePhone = mobilePhone, Email = email, Birthdate = birthdate,
                            MailingStreet = street, OtherStreet = street, MailingCity = city, OtherCity = city, MailingState = state, OtherState = state, Counter__c = counter));
                }
                catch(TypeException ex) {
                    message += MESSAGE_TO_USER.get('formatError') + email + '\n';
                }
            }

            //get the emails not found in the system
            for(String emailKey : contactWrapperMap.keySet()) {
                if(!contactsToUpdate.keySet().contains(emailKey)) {
                    message += MESSAGE_TO_USER.get('failed') + emailKey + '\n';
                }
            }

            if(contactsToUpdate.size() > 0) {
                List<Contact> contactsList = contactsToUpdate.values();
                List<Database.SaveResult> updateResults = Database.update(contactsList, false);
                for(Integer i = 0; i < updateResults.size(); i++){
                    //record any errors on failure to update
                    if (!updateResults.get(i).isSuccess()){
                        Database.Error error = updateResults.get(i).getErrors().get(0);
                        String failedDML = error.getMessage();
                        message += MESSAGE_TO_USER.get('failed') + contactsList.get(i).Email + ', ' + failedDML + '\n';
                    }
                    else if(message == '') {
                        message = MESSAGE_TO_USER.get('success');
                    }
                }
            }
        }
        else {
            message = MESSAGE_TO_USER.get('recordNumber');
        }

        return message;
    }

    /**
     * @description Contact Wrapper class for expected fields in payload
     */
    global class ContactWrapper {
        public String FirstName;
        public String LastName;
        public String MobilePhone;
        public String Email;
        public String Birthdate;
        public String Street;
        public String City;
        public String State;
        public String Counter;

        public ContactWrapper(String firstName, String lastName, String mobilePhone, String email, String birthDate, String street, String city, String state, String counter) {
            this.FirstName = firstName;
            this.LastName = lastName;
            this.MobilePhone = mobilePhone;
            this.Email = email;
            this.Birthdate = birthDate;
            this.Street = street;
            this.City = city;
            this.State = state;
            this.Counter = counter;
        }
    }

}



