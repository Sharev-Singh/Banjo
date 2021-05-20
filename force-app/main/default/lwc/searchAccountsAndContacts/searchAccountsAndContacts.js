import { LightningElement, track, wire} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent'
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import getContactsAndAccounts from '@salesforce/apex/SearchAccountsAndContacts.getContactsAndAccounts';
import incrementCounter from '@salesforce/apex/SearchAccountsAndContacts.incrementCounter';
const INCREMENT_COUNTER_TXT = 'Increment Counter';
export default class searchAccountsAndContacts extends NavigationMixin(LightningElement) {
    @wire(CurrentPageReference) pageRef;
    searchValue = '';
    @track showRecords = false;
    @track records = [];
    @track loadingText = ''; //indicating if search is going on

    // update searchValue and loadingText when input field value change
    searchKeyword(event) {
        this.searchValue = event.target.value;
        if(this.loadingText.length > 0) this.loadingText = '';
    }

    // call apex method on button clicking Search
    handleSearchKeyword() {
        //set variables
        this.loadingText = 'Searching...';
        this.showRecords = false;
        this.records = [];

        //allowing search for more than 2 characters
        if (this.searchValue.length > 2) {
            getContactsAndAccounts({
                    searchKey: this.searchValue
                })
                .then(result => {
                    let contactRecords = result.contactList;
                    let accountRecords = result.accountList;

                    //Add all the contacts retrieved to the record object
                    for(const contact in contactRecords) {
                        console.log(contactRecords[contact].Counter__c);
                        this.records = [...this.records, {name: contactRecords[contact].FirstName + ' ' + contactRecords[contact].LastName,
                                                            type: "Contact", recordId: contactRecords[contact].Id, counter : contactRecords[contact].Counter__c}];
                    }

                    //Add all the accounts retrieved to the record object
                    for(const account in accountRecords) {
                        this.records = [...this.records, {name: accountRecords[account].Name, type: "Account", recordId: accountRecords[account].Id,
                                                            counter : accountRecords[account].Counter__c}];

                    }

                    if(result) {
                        this.showRecords = true;
                    }
                    this.loadingText = '';
                })
                .catch(error => {
                    // fire toast event if there's an error
                    const event = new ShowToastEvent({
                        title: 'Error',
                        variant: 'error',
                        message: error.body.message,
                    });
                    this.dispatchEvent(event);

                    // reset variables
                    this.records = [];
                    this.loadingText ='';
                    this.showRecords = false;
                });
        } else {
            // fire toast event if input field is blank
            const event = new ShowToastEvent({
                variant: 'error',
                message: 'Search text should have at least 3 characters.',
            });
            this.dispatchEvent(event);
            this.loadingText ='';
        }
    }

    //call apex method on clicking Increment Counter
    incCounter(event) {
        //set variables
        let id = event.target.dataset.id;

        //call apex to update counter
        incrementCounter({
                counter: event.target.dataset.counter,
                recordId: id,
                objectName: event.target.dataset.type
            })
            .then(result => {
                //find the object and increment it for UI
                for(let i = 0; i < this.records.length; i++) {
                    if(this.records[i].recordId === id) {
                        this.records[i].counter = result;
                        break;
                    }
                }
             })
            .catch(error => {
                // fire toast event if there's an error
                const event = new ShowToastEvent({
                    title: 'Error Incrementing Counter',
                    variant: 'error',
                    message: error.body.message,
                });
                this.dispatchEvent(event);
            });
    }

    // Navigate to the record page
    viewContactRecord(event) {
        console.log(event.target.dataset.id);
        console.log(event.target.dataset.type);
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId:  event.target.dataset.id,
                objectApiName: event.target.dataset.type,
                actionName: 'view'
            }
        }).then(url => {
              window.open(url, "_blank");
         });
    }
}