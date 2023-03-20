public class ContactTriggerHandler {
    public static User createUser(Contact con,Database.DMLOptions dmo,Id profileId){
        string nick = con.email!=null?con.email.substring(0, con.email.indexOf('@')):'';
        nick += Datetime.now().getTime();
        User usr1 = new User();
        usr1.alias = con.firstName != null ? con.firstName.left(8) : con.lastname.left(8);
        usr1.email = con.email;
        usr1.emailencodingkey = 'UTF-8'; 
        usr1.firstname = con.firstName; 
        usr1.lastname = con.lastname; 
        usr1.languagelocalekey = 'en_US';
        usr1.localesidkey = 'en_US';
        usr1.contactId = con.Id;
        usr1.timezonesidkey = 'Asia/Dubai'; 
        Integer randomNumber = Math.abs(Crypto.getRandomInteger());
        randomNumber = Math.mod(randomNumber, 100000);
        string randomString = string.valueOf(randomNumber);
        while(randomString.length()<5){
            randomString = '0'+randomString;
        }
        usr1.username = con.Email + randomString;
        //usr1.username = con.email+'.1';
        usr1.CommunityNickname = nick;
        usr1.ProfileId = profileId;
        usr1.IsActive = true;
        //usr1.UserRoleId = userrole;
        usr1.setOptions(dmo);
        return usr1;
    }
    @future
    public static void updatePartnerUser(Set<Id> conIdSet){
        Map<Id, Lead> partnerMap = new Map<Id, Lead>();
        Map<Id, Lead> sponsorMap = new Map<Id, Lead>();
        for(Lead lead : [SELECT ConvertedContactId,Custom_Type__c,Id FROM Lead WHERE Custom_Type__c!=null and ConvertedContactId in :conIdSet]){
            System.debug(lead);
            System.debug(lead.Custom_Type__c);
            if(lead.Custom_Type__c == 'Sponsor'){
                sponsorMap.put(lead.ConvertedContactId,lead);
            }else{
                partnerMap.put(lead.ConvertedContactId,lead);
            }
        }
        System.debug(' updatePartnerUser sponsorMap '+sponsorMap);
        System.debug(' updatePartnerUser partnerMap '+partnerMap);
        List<User> updateUsers = new List<User>();
        Profile sponsorpf = [SELECT Id,Name FROM Profile WHERE Name = 'Idhini Sponsor User'];
        Profile partnerpf = [SELECT Id,Name FROM Profile WHERE Name = 'Idhini Partner User'];
       	Profile patientpf = [SELECT Id,Name FROM Profile WHERE Name = 'Idhini Patient User'];
        for(User user : [Select id, ProfileId,username from User where ContactId in :sponsorMap.keyset()]){
            user.username = user.username + '.sponsor';
            user.ProfileId = sponsorpf.id;
            updateUsers.add(user);
        }
        for(User user : [Select id, ProfileId,username from User where ContactId in :partnerMap.keyset()]){
            user.username = user.username + '.partner'; 
            user.ProfileId = partnerpf.id;
            updateUsers.add(user);
        }
        
        for(User user : [Select id, ProfileId,username from User where Profile.Name ='Idhini Patient User' AND ContactId in :conIdSet]){
            user.username = user.username + '.patient';
            user.ProfileId = patientpf.id;
            updateUsers.add(user);
        } 
        try{
            if(updateUsers.size() > 0){
                update updateUsers; 
                  
            }
            // for(User usr : updateUsers){
            //     System.resetPassword(usr.Id, true);

            // }

        }catch(Exception e){
            System.debug(e);
        }
    }
            
                                            //---------> for baton integration batch class


public static void contactBatchClass(Set<Id> conIdSet){
    System.debug('trigger handler enterred--->'+conIdSet);
    Database.executeBatch(new BatchClass(conIdSet),100);
  }

}