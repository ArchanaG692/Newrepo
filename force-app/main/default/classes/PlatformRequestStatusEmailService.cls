public with sharing class PlatformRequestStatusEmailService {

    public static void handleAfterUpdate(
        List<Platform_Request__c> newList,
        Map<Id, Platform_Request__c> oldMap
    ) {
        List<Id> completedPRIds = new List<Id>();

        for (Platform_Request__c newPR : newList) {
            Platform_Request__c oldPR = oldMap.get(newPR.Id);

            if (
                newPR.Status__c == 'Complete' &&
                oldPR != null &&
                oldPR.Status__c != 'Complete'
            ) {
                completedPRIds.add(newPR.Id);
            }
        }

        if (!completedPRIds.isEmpty()) {
            sendCompletionEmail(completedPRIds);
        }
    }

    private static void sendCompletionEmail(List<Id> prIds) {

        List<Platform_Request__c> prList = [
            SELECT Id,
                   Name,
                   Status__c,
                   RecordType.Name,
                   Requester_Name__c,
                   Requester_Email__c,
                   Project_Name__c,
                   Application__c,
                   Review_Type__c,
                   Requested_Review_Date__c,
                   Comments__c
            FROM Platform_Request__c
            WHERE Id IN :prIds
        ];

        if (prList.isEmpty()) return;

        EmailTemplate tpl = [
            SELECT Id, Subject, HtmlValue
            FROM EmailTemplate
            WHERE DeveloperName = 'Platform_Request_Completion_Notification'
            LIMIT 1
        ];

        if (String.isBlank(tpl.HtmlValue)) return;

        Id owdId = getOrgWideEmailId();
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Platform_Request__c pr : prList) {

            if (String.isBlank(pr.Requester_Email__c)) continue;

            // ---------- SUBJECT BUILD ----------
            String reqNumber = !String.isBlank(pr.Name)
                ? pr.Name
                : String.valueOf(pr.Id);

            String recordTypeLabel =
                (pr.RecordType != null && !String.isBlank(pr.RecordType.Name))
                    ? pr.RecordType.Name
                    : 'Request';

            String statusLabel =
                !String.isBlank(pr.Status__c)
                    ? pr.Status__c
                    : 'Completed';

            String subject =
                'Platform Request - ' +
                reqNumber +
                ' - ' +
                recordTypeLabel +
                ' - ' +
                statusLabel;

            // ---------- HTML BODY ----------
            String safeComments = pr.Comments__c != null
                ? htmlEscape(pr.Comments__c).replace('\n', '<br/>')
                : 'N/A';

            String body = tpl.HtmlValue
                .replace('{{{RequesterName}}}', pr.Requester_Name__c != null ? pr.Requester_Name__c : '')
                .replace('{{{RequesterEmail}}}', pr.Requester_Email__c != null ? pr.Requester_Email__c : '')
                .replace('{{{ProjectName}}}', pr.Project_Name__c != null ? pr.Project_Name__c : '')
                .replace('{{{Application}}}', pr.Application__c != null ? pr.Application__c : '')
                .replace('{{{ReviewType}}}', pr.Review_Type__c != null ? pr.Review_Type__c : '')
                .replace('{{{RequestedReviewDate}}}',
                    pr.Requested_Review_Date__c != null
                        ? String.valueOf(pr.Requested_Review_Date__c)
                        : ''
                )
                .replace('{{{PlatformRequestNumber}}}', reqNumber)
                .replace('{{{DesignReview}}}', recordTypeLabel)
                .replace('{{{Status}}}', statusLabel)
                .replace('{{{Comments}}}', safeComments);

            Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
            msg.setToAddresses(new List<String>{ pr.Requester_Email__c });
            msg.setSubject(subject);
            msg.setHtmlBody(body);
            msg.setWhatId(pr.Id);
            msg.setSaveAsActivity(true);
            msg.setOrgWideEmailAddressId(owdId);

            emails.add(msg);
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }

    // ---------- HTML ESCAPE ----------
    private static String htmlEscape(String input) {
        if (input == null) return null;
        return input
            .replace('&', '&amp;')
            .replace('<', '&lt;')
            .replace('>', '&gt;')
            .replace('"', '&quot;')
            .replace('\'', '&#39;');
    }

    // ---------- ORG WIDE EMAIL ----------
    private static Id getOrgWideEmailId() {
        List<OrgWideEmailAddress> owdList = [
            SELECT Id
            FROM OrgWideEmailAddress
            WHERE IsAllowAllProfiles = true
            LIMIT 1
        ];
        return !owdList.isEmpty() ? owdList[0].Id : null;
    }
}
