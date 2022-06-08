# MinistryPlatform Care Schedule to Teams voice app Connector
Powershell scripts and supporting documentation to automate setting Teams Call Queue and Auto Attendant destinations based on a MinistryPlatform Care Schedule. This is intended to automate a "Pastor on Call" rotation that some churches have.

## Narrative Problem Description
"Contoso Church" is a multi-campus church which receives calls from church attendees and community members seeking help and counseling in crisis situations. During office hours, each campus has a team or campus pastor who answers these calls. Outside of office hours, or if the campus team does not answer, calls are forwarded to a Pastor on Call. The Pastor on Call is a rotation managed by a Care Schedule in [MinistryPlatform](https://www.ministryplatform.com/home). The assigned Pastor on Call receives calls for all campuses. Contoso Church wants to automate changing several elements of the Teams Phone System based on the Care Schedule.

Callers can reach someone who can help:
- During church office hours: the receptionist forwards the call to the Pastor on Call call queue for their campus
- During church office hours if the receptionist does not answer: the caller selects the Pastor on Call option from the auto attendant
- Outside of church office hourse: the caller selects the Pastor on Call option from the auto attendant

There are six configured elements of the Teams Phone System involved:
- Redmond Campus Auto Attendant
  - The Redmond Campus phone number is assigned to this Auto Attendant via Resource Account
  - During office hours, this Auto Attendant forwards to "Redmond Reception" Call Queue
  - Outside office hours, this Auto Attendant forwards to "Main" Auto Attendant
- Redmond Reception Call Queue
  - This call queue contains several receptionist staff
  - The call queue times out after 60 seconds
  - The Overflow and Timeout target for this call queue is "Main" Auto Attendant
- Main Auto Attendant
  - Presents a menu to the caller with several options, one of which is Pastor on Call
  - Pastor on Call option forwards to "Pastor on Call" Auto Attendant
- Pastor on Call Auto Attendant
  - The caller picks their preferred campus, eg. Redmond
  - During office hours, the Redmond option forwards to "Redmond Pastor on Call" Call Queue
  - Outside of Office hours, the caller is forwarded to the assigned Pastor on Call person
- Redmond Pastor on Call Call Queue
  - This call queue contains several selected pastoral staff who answer these calls during office hours
  - The call queue times out after 60 seconds
  - The Overflow and Timeout target for this call queue is the assigned Pastor on Call person
- Pastor on Call person
  - Each person who is a member of the Pastor on Call rotation has a Teams account with the Teams Phone System license and a phone number assigned, which they use for all other calling, chat, and collaboration

![POC Call Flow](https://user-images.githubusercontent.com/6819003/172669296-3aa83bb4-c18a-4b25-970f-8b71c7ac382a.png)

***To Summarize:*** Contoso Church wants to automatically change:
- Redmond Pastor on Call Call Queue
  - Set the Overflow target to the assigned Pastor on Call
  - Set the Timeout target to the assigned Pastor on call
- Pastor on Call Auto Attendant
  - Set the After Hours target to the assigned Pastor on Call

The assigned Pastor on Call is set using the Care Schedule in MinistryPlatform, with Care Schedule Type "POC."

## Solution
