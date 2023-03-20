public without sharing class AppointmentSchedulerController {
    public static String className = 'AppointmentSchedulerController';
    
    @AuraEnabled
    public static List<MenuWrapper> getAppointmentTypes()
    {
        List<MenuWrapper> menuList = new List<MenuWrapper>();
        try{
            for(Appointment_Template__c at : [SELECT Id, Name,IsSchedulable__c,Template_Message__c,Convey_Tumor__c
                                              FROM Appointment_Template__c WHERE isActive__c=true  ORDER BY Name ASC NULLS LAST])
            {
                menuList.add(new MenuWrapper(at.Name, at.Id,at.IsSchedulable__c,at.Template_Message__c,at.Convey_Tumor__c));
            }
        }catch(exception ex){
            System.debug('ex-->'+ex);
        AMOExceptionHandler.logException(ex,className,'getAppointmentTypes','','Apex');

    }
        
        return menuList;
    }
    
    @AuraEnabled
    public static List<WeekWrapper> getAppointmentDates(date dt)
    {  
        List<WeekWrapper> weekList = new List<WeekWrapper>();
        try{
            System.debug('dt-->'+dt);
            Date weekStartDate = dt.toStartofWeek().addDays(1);
            System.debug('weekStartDate-->'+weekStartDate);
            for(Integer i=0; i < 5; i++)
            {
                weekList.add(new WeekWrapper(getDateFormat(weekStartDate.addDays(i)), weekStartDate.addDays(i)));
            }
            System.debug('weekList-->'+weekList);
        }catch(exception ex){
            System.debug('ex-->'+ex);
            AMOExceptionHandler.logException(ex,className,'getAppointmentDates','','Apex');

        }
        
        return weekList;
    }
    
    public static String getDateFormat(Date dt)
    {
        DateTime myDateTime = (DateTime) dt;
        String dayOfWeek = myDateTime.format('EEEEEE, MMMM dd');
        
        return dayOfWeek;
    }
    
    @AuraEnabled
    public static List<WeekWrapper> getAppointmentDatesNew(date currentDate)
    {  
        List<WeekWrapper> weekList = new List<WeekWrapper>();
        try{
            System.debug('dt-->'+currentDate);
            String dayOfWeek = getDateFormat(currentDate);
            System.debug('dayOfWeek-->'+dayOfWeek);
            Date weekStartDate;
            if(dayOfWeek.SubStringBefore(',')=='Saturday') {
                currentDate=currentDate.addDays(1);
                weekStartDate= currentDate.toStartofWeek().addDays(1);
            }
            else {
                weekStartDate= currentDate.toStartofWeek().addDays(1);
            }
            //Date weekStartDate = currentDate.toStartofWeek().addDays(1);
            System.debug('weekStartDate-->'+weekStartDate);
            for(Integer i=0; i < 5; i++)
            {
                weekList.add(new WeekWrapper(getDateFormat(weekStartDate.addDays(i)), weekStartDate.addDays(i)));
            }
            System.debug('weekList-->'+weekList);
        }catch(exception ex){
            System.debug('ex-->'+ex);
            AMOExceptionHandler.logException(ex,className,'getAppointmentDatesNew','','Apex');
        }
        
        return weekList;
    }
    
    
    public class MenuWrapper
    {
        @AuraEnabled public String label {get;set;}
        @AuraEnabled public String value {get;set;}
        @AuraEnabled public Boolean isSchedulable {get;set;}
        @AuraEnabled public String templateMessage {get;set;}
        @AuraEnabled public Integer order {get;set;}
        @AuraEnabled public Boolean conveyTumor {get;set;}
        
        public MenuWrapper(String label,String value,
                           Boolean isSchedulable,String templateMessage,Boolean conveyTumor)
        {
            this.label = label;
            this.value = value;
            this.isSchedulable = isSchedulable;
            this.templateMessage = templateMessage;
            this.conveyTumor = conveyTumor;
            if(label =='Clinical Study Information'){
                this.order =1;
            }
            else if(label =='General Adverse Event Management'){
                this.order =2;
            }
            else if(label =='Patient Education'){
                this.order =3;
            }
            else if(label =='Product Access Inquires: Coverage and Reimbursement; Coding and Billing'){
                this.order =4;
            }
            else{
                this.order =5;
            }
        }
    }
    
    public class WeekWrapper
    {
        @AuraEnabled public String dateLabel {get;set;}
        @AuraEnabled public Date dateValue {get;set;}
        @AuraEnabled public Boolean showdate {get;set;}
        
        public WeekWrapper(String dateLabel,
                           Date dateValue)
        {
            this.dateLabel = dateLabel;
            this.dateValue = dateValue;
            date currDate = System.today();
            this.showdate = (currDate<=dateValue)?true:false;
        }
    }
    
    @AuraEnabled
    Public static Map<String,Object> saveAppointmetScheduleDetails(Map<String, Object> scheduleDetails){
        Map<String,Object> appointmentDetailsMap = new Map<String,Object>();
        try{
            Event scheduleEvent = new Event();
            System.debug('scheduleDetails->'+scheduleDetails);
            scheduleEvent.Subject = String.valueOf(scheduleDetails.get('templateLabel'));
            scheduleEvent.Schedule_Status__c = 'InProgress';
            String contactDateTime;
            String myDate;
            String dateString = Datetime.now().format('ddMMYYYYHHmmss');
            String randomInteger = String.valueOf(Crypto.getRandomInteger()).substring(1,5);
            if(scheduleDetails.get('isCallMeNow')==false){
                String tempLocalDate = String.valueOf(scheduleDetails.get('localDateValue')).subString(11,15) + '-' + monthVal(String.valueOf(scheduleDetails.get('localDateValue')).subString(4,7)) + '-' + String.valueOf(scheduleDetails.get('localDateValue')).subString(8,10) + ' ' + String.valueOf(scheduleDetails.get('localHour')).substringBefore('.') + ':' + String.valueOf(scheduleDetails.get('localMinute')).substringBefore('.') + ':00';
                system.debug('[[[[[[[[['+tempLocalDate);
                DateTime localDateTime = DateTime.valueOf(tempLocalDate);
                scheduleDetails.put('finalLocalDateTime',localDateTime);
                contactDateTime = scheduleDetails.get('dateValue')+' '+scheduleDetails.get('timeSlotValue');
                //scheduleEvent.StartDateTime = DateTime.valueOf(contactDateTime);
                List<String> dateLst = String.valueOf(scheduleDetails.get('dateValue')).split('-');
                List<String> timeLst = String.valueOf(scheduleDetails.get('timeSlotValue')).split(':');

                Datetime GMTDate = Datetime.newInstanceGmt(integer.valueOf(dateLst[0]),integer.valueOf(dateLst[1]),integer.valueOf(dateLst[2]),integer.valueOf(timeLst[0]),integer.valueOf(timeLst[1]),integer.valueOf(timeLst[2]));
                System.debug('GMTDate '+GMTDate);
                scheduleEvent.StartDateTime = DateTime.valueOf(GMTDate);
                scheduleEvent.EndDateTime = DateTime.valueOf(GMTDate).addMinutes(15);
                
            }
            else{
                //scheduleEvent.StartDateTime = System.now();
                //scheduleEvent.EndDateTime = system.now().addMinutes(15);
                contactDateTime = scheduleDetails.get('currESTDate')+' '+scheduleDetails.get('currESTTime');
                scheduleEvent.StartDateTime = DateTime.valueOf(contactDateTime);
                scheduleEvent.EndDateTime = DateTime.valueOf(contactDateTime).addMinutes(15);
            }
            scheduleEvent.DurationInMinutes = 15;
            scheduleEvent.Communication_Mode__c = String.valueOf(scheduleDetails.get('communicationMode'));
            scheduleEvent.Appointment_Template__c = String.valueOf(scheduleDetails.get('templateId'));
            scheduleEvent.Scheduling_Group__c = String.valueOf(scheduleDetails.get('schedulingGroupId'));
            
            scheduleEvent.Professional_Designation__c = String.valueOf(scheduleDetails.get('professionalDesgination'));
            if (scheduleDetails.get('tumorIndication')!=null){
                scheduleEvent.Tumor_Indication__c = String.valueOf(scheduleDetails.get('tumorIndication'));
            }
            
            if (scheduleDetails.get('FirstName')!=null){
                scheduleEvent.First_Name__c = String.valueOf(scheduleDetails.get('FirstName'));
            }
            scheduleEvent.Last_Name__c = String.valueOf(scheduleDetails.get('LastName'));
            scheduleEvent.Phone__c = String.valueOf(scheduleDetails.get('Phone'));
            if (scheduleDetails.get('Extension')!=null){
                scheduleEvent.Extension__c = String.valueOf(scheduleDetails.get('Extension'));
            }
            if (scheduleDetails.get('schedulerOwner')!=null){
                scheduleEvent.OwnerId = String.valueOf(scheduleDetails.get('schedulerOwner'));
            }
            if (scheduleDetails.get('Email')!=null){
                scheduleEvent.Email__c = String.valueOf(scheduleDetails.get('Email'));
            }
            if (scheduleDetails.get('productEnquiryValue')!=null){
                scheduleEvent.Product_Enquiry__c = String.valueOf(scheduleDetails.get('productEnquiryValue'));
            }
            if(Boolean.valueOf(scheduleDetails.get('isCallMeNow'))){
                Map <String,Object> getAgentAvilability = NiceInContactController.getAgentAvilability(scheduleDetails);
                appointmentDetailsMap.put('agentAvilability',getAgentAvilability);
            }
            if(Boolean.valueOf(scheduleDetails.get('isCallMeNow'))){
                Map <String,Object>calloutResponse = NiceInContactController.callMeNowHttpRequest(JSON.serialize(scheduleDetails),dateString+randomInteger);
                scheduleEvent.Schedule_Status__c = String.valueOf(calloutResponse.get('scheduleStatus'));
                if (String.valueOf(calloutResponse.get('spawnId'))!=null){
                    scheduleEvent.NIC_External_Id__c = String.valueOf(calloutResponse.get('spawnId'));
                }
                appointmentDetailsMap.put('calloutResponse',calloutResponse);
            }
            else{
                Map <String,Object>calloutResponse= NiceInContactController.scheduleCallbackHttpRequest(JSON.serialize(scheduleDetails), dateString+randomInteger);
                System.debug('calloutResponse-->');
                System.debug(calloutResponse);
                scheduleEvent.Schedule_Status__c = String.valueOf(calloutResponse.get('scheduleStatus'));
                if (String.valueOf(calloutResponse.get('spawnId'))!=null){
                    scheduleEvent.NIC_External_Id__c = String.valueOf(calloutResponse.get('spawnId'));
                }
                appointmentDetailsMap.put('calloutResponse',calloutResponse);
            }
            scheduleEvent.Scheduler_Unique_Id__c = dateString+randomInteger;
            insert scheduleEvent;
            
            if(scheduleDetails.get('isCallMeNow')==false && String.isNotBlank(String.valueOf(scheduleDetails.get('Email'))) && String.isNotBlank(scheduleEvent.NIC_External_Id__c)){
                //sendEmailInvite(String.valueOf(scheduleDetails.get('templateLabel')),myDate,String.valueOf(scheduleDetails.get('Email')),scheduleEvent);
                sendEmailInvite(scheduleDetails,scheduleEvent);
            }
            
            appointmentDetailsMap.put('scheduledEvent',scheduleEvent);
            
            //insert scheduleEvent;
        }catch(Exception ex){System.debug('saveschedular Exception-->'+ex);
        AMOExceptionHandler.logException(ex,className,'saveAppointmetScheduleDetails','','Apex');

    }
        return appointmentDetailsMap;
    }
  
    @testVisible
    private static String monthVal(String monthAbb){
        switch on monthAbb {
            when 'Jan' {
                return '1';
            }when 'Feb' {
                return '2';
            }when 'Mar'{
                return '3';
            }when 'Apr'{
                return '4';
            }when 'May'{
                return '5';
            }when 'Jun'{
                return '6';
            }when 'Jul'{
                return '7';
            }when 'Aug'{
                return '8';
            }when 'Sep'{
                return '9';
            }when 'Oct'{
                return '10';
            }when 'Nov'{
                return '11';
            }when 'Dec'{
                return '12';
            }
        }
        return '';
    }
    
    Public static Datetime formatDateTime(String scheduleDate,String scheduleTime){
        Datetime formattedDate;
        try{   
            String contactDateTime = scheduleDate+' '+scheduleTime;
            System.debug('contactDateTime->'+contactDateTime);
            formattedDate = Datetime.parse( contactDateTime );
            System.debug('formattedDate->'+formattedDate);
        }
        catch(Exception ex){
            System.debug('ex-->'+ex);
        AMOExceptionHandler.logException(ex,className,'formatDateTime','','Apex');

    }
        return formattedDate;
    } 
    
    @AuraEnabled
    Public static Map<String,Object> getHCPDataStrucuture(date currDate){
        System.debug('currDate->'+currDate);
        Map<String,Object> hcpDataStructure = new Map<String,Object>();
        try{
            List<Object> appointmentTemplatesMap =  getAppointmentTypes();
            /*for(Object templateObj: appointmentTemplatesMap){
                Map<String,Object> templateObjMap = new Map<String,Object>();
                templateObjMap = JSON.deserialize(templateObj);
                System.debug('templateObj-->'+templateObjMap);
            }*/
            // Map<String,List<Object>> appointmentTemplates = new Map<String,List<Object>>{'templates' => appointmentTemplatesMap};
            //   System.debug('appointmentTemplates->'+appointmentTemplates);
            List<Object> communcationObjList = new List<Object>();
            List<String> communcationList = new List<String>{'Call me now','Schedule a callback'};
                for(Integer i=0;i<communcationList.size();i++){
                    Map<String, String> obj = new Map<String, String>();
                    obj.put('label',communcationList[i]);
                    obj.put('value',communcationList[i]);
                    communcationObjList.add(obj);
                }
            System.debug('appointmentTemplates->'+communcationObjList);
            // Map<String,List<Object>> communicationModesMap = new Map<String,List<Object>>{'communicateModes' => communcationObjList};
            List<String> weekList = new List<String>{'Monday','Tuesday','Wednesday','Thursday','Friday'};
                List<Object> businessHoursObjList = new List<Object>();
            for(Integer i=0;i<weekList.size();i++){
                Map<String, String> obj = new Map<String, String>();
                obj.put('startTime','8:00 AM');
                obj.put('endTime','8:00 PM');
                obj.put('weekName',weekList[i]);
                businessHoursObjList.add(obj);
            }
            List<String> designationList = new List<String>{'MD','DO','Pharmacist(PharmD)','CRNP','PA','RN','Medical Assistant','Office Manager','Billing Coordinator','Other'};
                List<Object> designationListObjList = new List<Object>();
            for(Integer i=0;i<designationList.size();i++){
                Map<String, Object> obj = new Map<String, Object>();
                obj.put('label',designationList[i]);
                obj.put('value',designationList[i]);
                obj.put('order',i);
                designationListObjList.add(obj);
            }
            // Map<String,List<Object>> businessHoursMap = new Map<String,List<Object>>{'businessHours' => businessHoursObjList};
            List<String> assignmentGroupList = new List<String>{'OREG','NE'};
                List<Object> assignmentGroupObjList = new List<Object>();
            for(Integer i=0;i<assignmentGroupList.size();i++){
                Map<String, Object> obj = new Map<String, Object>();
                if(assignmentGroupList[i] == 'OREG'){
                    obj.put('appointmentTemplate',new List<String>{'Clinical Study Information','General Adverse Event Management','Patient Education','Product Access Inquires: Coverage and Reimbursement; Coding and Billing','Others'});
                    obj.put('professionalDesgination',new List<String>{'MD','DO','Pharmacist(PharmD)','PA','Medical Assistant','Office Manager','Billing Coordinator','Other'});
                    obj.put('groupId','a7x7j0000004ZeJAAU');
                }
                else{
                    obj.put('appointmentTemplate',new List<String>{'General Adverse Event Management','Patient Education'});
                    obj.put('professionalDesgination',new List<String>{'CRNP','RN'});
                    obj.put('groupId','a7x7j0000004ZlFAAU');
                }
                obj.put('groupName',assignmentGroupList[i]);
                assignmentGroupObjList.add(obj);
            }
            
            List<Object> holidaysByGroupObjList = new List<Object>();
            for(Integer i=0;i<assignmentGroupList.size();i++){
                Map<String, Object> obj = new Map<String, Object>();
                if(assignmentGroupList[i] == 'OREG'){
                    obj.put('holidays',new List<String>{'2021-08-26','2021-09-06','2021-09-09'});
                    obj.put('groupId','a7x7j0000004ZeJAAU');
                }
                else{
                    obj.put('holidays',new List<String>{'2021-08-26','2021-09-06','2021-09-09'});
                    obj.put('groupId','a7x7j0000004ZlFAAU');
                }
                obj.put('groupName',assignmentGroupList[i]);
                holidaysByGroupObjList.add(obj);
            }
            
            List<Object> getDates = getAppointmentDatesNew(currDate);
            
            hcpDataStructure.put('uiCss',new Map<String,String>{'bgColor'=>'white','fgColor'=>'white'});
            hcpDataStructure.put('templates',appointmentTemplatesMap);
            hcpDataStructure.put('communicationModes',communcationObjList);
            hcpDataStructure.put('businessHours',businessHoursObjList);
            hcpDataStructure.put('scheduleDates',getDates);
            hcpDataStructure.put('assignmentGroups',assignmentGroupObjList);
            hcpDataStructure.put('professionalDesignation',designationListObjList);
            hcpDataStructure.put('holidaysByGroup',holidaysByGroupObjList);
            System.debug('hcpDataStructure->'+hcpDataStructure);
        }catch(exception ex){
            System.debug('getHCPDataStrucuture ex-->'+ex +ex.getLineNumber());
        AMOExceptionHandler.logException(ex,className,'getHCPDataStrucuture','','Apex');

    }
        return hcpDataStructure;
    }
    
    @AuraEnabled
    Public static List<Event> getScheduledSlots(String schedulingGroupName,String scheduleDate){
        /*  MAMMET COMMENTED AS PART OF PERFORMANCE ISSUES
        * List<Event> scheduledSlots = new List<Event>();
            String tempGroup = schedulingGroupName;
            date tmpScheduleDate = Date.valueOf(scheduleDate);
            try{
                for(Event evt:[SELECT Id,Subject,Appointment_Template__r.Name,Scheduling_Group__r.Name,ActivityDate,StartDateTime,EndDateTime From Event
                    Where ActivityDate=:tmpScheduleDate AND Scheduling_Group__r.Name=:tempGroup AND Schedule_Status__c = 'Scheduled'])
            {
                scheduledSlots.add(evt);
            }
            }catch(exception ex){System.debug('ex-->'+ex);}
            return scheduledSlots;
            */
        Date tmpScheduleDate = Date.valueOf(scheduleDate);
        return ([SELECT Id,Subject,Appointment_Template__r.Name,Scheduling_Group__r.Name,ActivityDate,StartDateTime,EndDateTime FROM Event
                 WHERE ActivityDate=: tmpScheduleDate AND Scheduling_Group__r.Name=: schedulingGroupName AND Schedule_Status__c = 'Scheduled']);
    }

    @AuraEnabled(cacheable=true)
    Public static Map<String,Object> getHCPData(String href,date currDate){
        if(href!=null && href.contains('schedulerId=')){
            return getHCPDataStructurebyId(href.split('schedulerId=')[1],currDate);
        }
        else if(href!=null){
            return getHCPDataStructurebyId(href,currDate);
        }
        else{
            return getHCPDataStructureAMO(currDate);
        }
    }
    
    @AuraEnabled
    Public static Map<String,Object> getHCPDataStructurebyId(String schedulerId,date currDate){
        Map<String,Object> schedulerDataStructure = new Map<String,Object>();
        try{
            String tmpSchedulerId = schedulerId;
            Scheduler_Configuration__c schedulerconfig = [SELECT Id,Name,JSON_Payload__c,CreatedbyId From Scheduler_Configuration__c
                                                          WHERE Id =:tmpSchedulerId LIMIT 1];
            schedulerDataStructure = (Map<String,Object>)JSON.deserializeUntyped(schedulerconfig.JSON_Payload__c);
            List<Object> getScheduleDates = getAppointmentDatesNew(currDate);
            schedulerDataStructure.put('scheduleDates',getScheduleDates);
            schedulerDataStructure.put('schedulerOwner',schedulerconfig.CreatedbyId);
        }catch(Exception ex){System.debug('ex-->'+ex);
        AMOExceptionHandler.logException(ex,className,'getHCPDataStructurebyId','','Apex');
    }
        return schedulerDataStructure;
    }
    
    
    @AuraEnabled
    Public static void sendEmailInvite(Map<String,Object> scheduleDetails, Event eventdetails){
        try{
            //String urlHeader = 'https://msdlogin--hhusd4.my.salesforce.com/servlet/servlet.ImageServer?id=0157j00000075K0&amp;oid=00D7j0000004asF';
            EmailTemplate emailTemp = [SELECT id, body, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'MOD_Schedule_Call_Back_V2' LIMIT 1];
            String htmlBody = emailTemp.HtmlValue;
            String dt;
            if(scheduleDetails.get('isCallMeNow')==false){
                dt = String.valueOf(scheduleDetails.get('dateLabel')).split(',')[1];
                htmlBody = htmlBody.replace('{!Event.StartDateTime}', dt +' at '+String.valueOf(scheduleDetails.get('timeSlotLabel'))+ ' ET') ;
            }
            else{
                String dtString = String.valueOf(scheduleDetails.get('currESTDate'))+' '+ String.valueOf(scheduleDetails.get('currESTTime'));
                DateTime formattedTime = DateTime.valueOf(dtString);
                dt = formattedTime.format();
                System.debug('dt-->'+dt);
                String tempESTDate = formattedTime.format('EEEEEE, MMMM dd');
                htmlBody = htmlBody.replace('{!Event.StartDateTime}', tempESTDate.split(',')[1] +' at '+ dt.split(' ')[1]+' '+ dt.split(' ')[2]+ ' ET') ;
            }
            htmlBody = htmlBody.replace('{!Event.Subject}', String.valueOf(scheduleDetails.get('templateLabel')));
           // htmlBody = htmlBody.replace('{!SiteDetail.SecureURL}', getFeedbackLink(eventdetails.Id,String.valueOf(scheduleDetails.get('schedulerId'))));
            OrgWideEmailAddress owea = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = 'Ask Merck' LIMIT 1];
            Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(emailTemp.id,null,UserInfo.getUserId()); 
            mail.setToAddresses(new List<String>{String.valueOf(scheduleDetails.get('Email'))});
            
            mail.setOrgWideEmailAddressId(owea.Id);
            
            //mail.setSubject(templateLabel);
            mail.setSubject('Your Ask Merck callback is confirmed');
            System.debug('----'+htmlBody);
            mail.setHtmlBody(htmlBody);
            mail.setTemplateId(emailTemp.Id);
            mail.setSaveAsActivity(false);
            Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();   
            attach.filename = 'reminder.ics'; 
            attach.ContentType = 'text/calendar';     
            attach.inline = true;     
            //attach.body = invite(String.valueOf(scheduleDetails.get('templateLabel')),String.valueOf(scheduleDetails.get('dateValue'))+' '+String.valueOf(scheduleDetails.get('timeSlotValue')));   
            attach.body = invite(scheduleDetails,eventdetails);
            mail.setFileAttachments(new Messaging.EmailFileAttachment[] {attach});   
            Messaging.SendEmailResult[] er = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
        catch(Exception ex){
            System.debug('ex-->'+ex);
            AMOExceptionHandler.logException(ex,className,'sendEmailInvite','','Apex');

        }
    }
    
    @AuraEnabled
    Public static Blob invite(Map<String,Object> scheduleDetails, Event eventdetails) {
        String txtInvite = ''; 
        try{
            String templateLabel = String.valueOf(scheduleDetails.get('templateLabel'));
            String scheduledDateTime;
            if(scheduleDetails.get('isCallMeNow')==false){
                scheduledDateTime = String.valueOf(scheduleDetails.get('finalLocalDateTime'));
            }
            else {
                scheduledDateTime = String.valueOf(scheduleDetails.get('currESTDate'))+' '+ String.valueOf(scheduleDetails.get('currESTTime'));
            }
            String body = '<h1> This is a calendar hold for your scheduled call with a Merck Associate. </h1><br/><hr size="3" width="100%" color="#00857C">  <br/>';
            body += '<b style="color: rgb(0, 133, 124); font-family: Invention, sans-serif; font-size: medium;">The associate will reach out to you directly.</b>';
            body += '<br/><br/>This service is for US health care professionals only.';//<br/><br/>To report and Adverse Event or Product Quality complaint, ';
            //body += 'please call ';
            //body += '<b style="color: rgb(0, 133, 124); font-family: Invention, sans-serif; font-size: small;">&nbsp;1-800-627-6372.</b>';
            body += '<br/><br/>This meeting is automatically generated. <br/>';
            body +='<br/><br/><p style="color:rgb(128,128,128); font-family: Invention,sans-serif;font-size: small;"> Copyright © 2022 Merck & Co., Inc., Rahway, NJ, USA and its affiliates. All rights reserved.  <br/>US-NON-11392 09/22</p>';
            String subject = 'Call with an Ask Merck Associate';
            String dt = String.valueOfGmt(dateTime.now());
            dt = dt.replace(' ','T');
            dt = dt.replaceAll('-','');
            dt = dt.replaceAll(':','');
            scheduledDateTime = scheduledDateTime.replace(' ','T');
            scheduledDateTime = scheduledDateTime.replaceAll('-','');
            scheduledDateTime = scheduledDateTime.replaceAll(':','');
            System.debug('dt-->'+dt);
            System.debug('scheduledDateTime-->'+scheduledDateTime);
            //body = body.replace('{!SiteDetail.SecureURL}', getFeedbackLink(eventdetails.Id,String.valueOf(scheduleDetails.get('schedulerId'))));
            txtInvite = 'BEGIN:VCALENDAR\nVERSION:2.0\nPRODID:-//salesforce.com//Calendar//EN\nBEGIN:VEVENT\n';
            txtInvite += 'DTSTAMP:' + dt;
            txtInvite += '\nSUMMARY:' + subject + '\nCATEGORIES:salesforce.com\n';
            txtInvite += 'DESCRIPTION: This is a calendar hold for your scheduled call with a Merck Associate.\n';
            txtInvite += 'X-ALT-DESC;FMTTYPE=text/html:'+body+'\n';
            txtInvite += 'CREATED:' + dt;
            txtInvite += '\nLAST-MODIFIED:' + dt;
            txtInvite += '\nSTATUS:CONFIRMED\n';
            txtInvite += 'DTSTART:' + scheduledDateTime;
            txtInvite += '\nDURATION:PT15M\nEND:VEVENT\nEND:VCALENDAR'; 
        }
        catch(Exception ex){
            System.debug('ex-->'+ex);
            AMOExceptionHandler.logException(ex,className,'invite','','Apex');

        }
        return Blob.valueOf(txtInvite);
    }
    
    @AuraEnabled
    Public static Map<String,Object> getHCPDataStructureAMO(date currDate){
        Map<String,Object> schedulerDataStructure = new Map<String,Object>();
        try{
            System.debug('schedulerconfigschedulerconfig');
            Scheduler_Configuration__c schedulerconfig = [SELECT Id,Name,JSON_Payload__c,CreatedbyId From Scheduler_Configuration__c
                                                          WHERE Name='AMO' LIMIT 1];
            System.debug('schedulerconfig Id-->'+schedulerconfig.Id);
            schedulerDataStructure = (Map<String,Object>)JSON.deserializeUntyped(schedulerconfig.JSON_Payload__c);
            List<Object> getScheduleDates = getAppointmentDatesNew(currDate);
            schedulerDataStructure.put('scheduleDates',getScheduleDates);
            schedulerDataStructure.put('schedulerOwner',schedulerconfig.CreatedbyId);
        }catch(Exception ex){
            System.debug('ex-->'+ex);
        AMOExceptionHandler.logException(ex,className,'getHCPDataStructureAMO','','Apex');

    }
        return schedulerDataStructure;
    }
    
   /* @AuraEnabled // commenting as moved feedback out of scope for R2.
    Public static Event saveFeedback(Map<String,Object> feedbackResponse,String eventId){
        Event evt = new Event();
        try {
            System.debug('feedback res-->'+feedbackResponse);
            System.debug('eventId-->'+eventId);
            evt.Id = eventId;
            evt.AMO_Scheduler_Satisfaction_Feedback__c = String.valueOf(feedbackResponse.get('AMO_Scheduler_Satisfaction_Feedback__c'));
            evt.AMO_Was_Original_Issue_Resolved__c = String.valueOf(feedbackResponse.get('AMO_Was_Original_Issue_Resolved__c'));
            evt.AMO_Would_you_recommend_this_experience__c = String.valueOf(feedbackResponse.get('AMO_Would_you_recommend_this_experience__c'));
            evt.AMO_Would_you_use_this_tool_again__c = String.valueOf(feedbackResponse.get('AMO_Would_you_use_this_tool_again__c'));
            update evt;
        } catch (Exception e) {
            System.debug('feedback ex--->'+e);
        }
        return evt;
    } */
    
  /*  @AuraEnabled
    public static string getFeedbackLink(String eventId,String schedulerId) {
        String feedbackLink = '';
        try {
            Site sObj = [SELECT Id FROM Site where Name = 'MOD_HCP_Scheduler' LIMIT 1];
            SiteDetail sdObj = [SELECT SecureURL FROM SiteDetail where DurableId =: sObj.Id LIMIT 1];
            feedbackLink = sdObj.SecureURL+'#feedback'+'?eventId='+eventId+'&schedulerId='+schedulerId;
            system.debug('feedbackLink-->'+feedbackLink);
        } catch (Exception e) {
            System.debug('getFeedbackLink ex-->'+e);
        }
        return feedbackLink;
    } */
    
    
}