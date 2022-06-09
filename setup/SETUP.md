# Setup and Configuration
This script requires several elements to be set up and configured.


## Requirements and Assumptions
The script has a few requirements and assumptions.

Requirements and assumptions about the church's Teams Phone System:
- The church is using the PSTN calling features of Teams, and has Phone Numbers via Calling Plan, Direct Routing, or Operator Connect
- The church already has or can adapt to a similar Pastor on Call auto attendant and call queue as the example for Contoso Church in the [README](/README.md)

Requirements and assumptions about each person who is part of the Pastor on Call rotation:
- They have a Contact record in MinistryPlatform **with their church email address**
- They have a Microsoft 365 account with a Teams Phone Standard or another license which grants PSTN calling, an assigned phone number, and their sign-in address matches their church email address in their MinistryPlatform Contact record

Requirements and assumptions about the person implementing this project:
- They need to have access to System Setup and several Administration pages in MinistryPlatform
- They need to have access to the MinistryPlatform SQL server to create tables and stored procedures
- They are familiar with how to extend MinistryPlatform by creating custom tables in the database, configuring them as pages, and granting access to the new pages with Security Roles. Refer to the [MinistryPlatform Knowledge Base](https://www.ministryplatform.com/kb/ministryplatform/advanced-users/extending-the-platform/pages) for information.

Finally, this project requires a MinistryPlatform API Client, which needs to be created if it does not already exist using the [instructions](https://www.ministryplatform.com/kb/develop/giving-developers-access) on the MinistryPlatform Knowledge Base

## Extend MinistryPlatform with Care Schedules
Care Schedules[^1] consists of two custom tables, Care_Schedule_Types and Care_Schedules.

1. Create the custom tables using `create_Care_Schedule_Types_table.sql` and `create_Care_Schedules_table.sql`, in that order. Care_Schedules_Types must be created first since Care_Schedules has a foreign key to Care_Schedule_Types.
2. In MinistryPlatform, create the Care Schedule Types page with:
   - Display Name: `Care Schedule Types`
   - Singular Name: `Care Schedule Type`
   - View Order: `100` or other value as desired
   - Table Name: `Care_Schedule_Types`
   - Primary Key: `Care_Schedule_Type_ID`
   - Default Field List: `Care_Schedule_Types.Schedule_Type`
   - Selected Record Expression: `Care_Schedule_Types.Schedule_Type`
   - In Global Search: `No`
3. In MinistryPlatform, create the Care Schedules page with:
   - Display Name: `Care Schedules`
   - Singular Name: `Care Schedule`
   - View Order: `99` or other value as desired
   - Table Name: `Care_Schedules`
   - Primary Key: `Care_Schedule_ID`
   - Default Field List: 
   ```
   Contact_ID_Table.Display_Name
   ,Contact_ID_Table.Nickname
   ,Care_Schedules.[Schedule_Start]
   ,Care_Schedules.[Schedule_End]
   ,Care_Schedule_Type_ID_Table.Schedule_Type
   ,Location_ID_Table.Location_Name
   ,Care_Schedules.Cancelled
   ```
   - Selected Record Expression: `Contact_ID_Table.Display_Name`
   - Contact ID Field: `Care_Schedules.Contact_ID`
   - Start Date Field: `[Schedule_Start]`
   - End Date Field: `[Schedule_End]`
   - In Global Search: `No`
4. Recommended: Create a `Future Care Schedules` Page View to set as the Default View for Care Schedules:
   - View Title: `Future Care Schedules`
   - Page: `Care Schedules`
   - View Clause: `Care_Schedules.[Schedule_End] >= dp_DomainTime-1`
   - Order By: `Care_Schedules.[Schedule_Start]`
5. Add `Care Schedules` and `Care Schedule Types` to the `Care Cases` Page Section
6. Grant access to the two new pages using Security Roles
   - Recommendation: grant access to Care Schedules to the person who manages the Pastor on Call team

## Set up Care Schedules in MinistryPlatform
1. Navigate to Care Cases > Care Schedule Types
2. Add a new Care Schedule Type named `Pastor on Call` or similar
3. Make a note of the Care Schedule Type ID number - if this is your first one, it is `1`
4. Navigate to Care Cases > Care Schedules
5. Create your first Care Schedule record:
   - Contact: set to the Contact Record of the Pastor on Call
   - Schedule Start: set to the date and time when the person should start their Pastor on Call rotation
   - Schedule End: set to the date and time when the person should end their Pastor on Call rotation
   - Care Schedule Type: Pastor on Call (or the name entered in step 2)
   - Location: Recommended that this is set to the Location for the church's primary campus or central/administrative office
6. Repeat adding Care Schedules to build the rotation schedule for the Pastor on Call team

## Create the MinistryPlatform API procedure
1. Load `api_CUSTOM_GetPOCContactEmail.sql` in SQL Server Management Studio
2. Edit `@careScheduleTypeID` to match the Care Schedule Type ID
3. If the church's MinistryPlatform database name is not `MinistryPlatform`, then edit the database name in line 1
4. The stored procedure name can be customized if desired
5. Execute the script
6. In MinistryPlatform, navigate to System Setup > API Procedures and create a new API Procedure:
   - Procedure Name: `api_CUSTOM_GetPOCContactEmail` or the custom stored procedure name from step 4
7. Grant access to the new API Procedure to the desired API Client using a Security Role

## Configure Teams Phone System
The church should configure their Teams Phone System to fit their needs. This script is only designed to:
- Set the call routing destination for the after hours option of an Auto Attendant to redirect to the assigned Pastor on Call
- Set the Call overflow and Call timeout redirects to the assigned Pastor on Call

Feel free to use the example on the [README](/README.md) as a framework for designing the Pastor on Call workflow for the church's Teams Phone System. Once the Phone System is configured, please retrieve the Identity GUIDs of the call queue and auto attendant for configuring the script later. There are two ways to retrieve the GUIDs:
- In the Teams Admin Center:
  - Navigate to and click on the Call Queue or Auto Attendant
  - The GUID is displayed at the end of the URL in the address bar
- Using Teams PowerShell:
  - Call Queue: run `Get-CSCallQueue -Name "Name of the Call Queue"`
  - Auto Attendant: run `Get-CSAutoAttendant -Name "Name of the Auto Attendant"`

## Configure Variables in Script
### Authentication Variables

| Variable Name | Description |
| --- | --- |
| `$mpAPIClientId` | `Client ID` from a MinistryPlatform API Client ID Record |
| `$mpAPIClientSecret` | `Client Secret` from a MinistryPlatform API Client ID Record |
| `$teamsAdminUsername` | Full sign-in address of a Microsoft 365 user with sufficient permissions to configure Teams Auto Attendants and Call Queues |
| `$teamsAdminPassword` | Password for the Microsoft 365 user. Enter the password in double quotes after the `-string` flag |

### Control Variables

| Variable Name | Description |
| --- | --- |
| `$mpBaseDomain` | The base domain or subdomain of the church's MinistryPlatform system. Only include the fully qualified domain name, not any other parts of the URL. |
| `$mpAPIProcess` | The name of the API Procedure configured [above](#create-the-ministryplatform-api-procedure) |
| `$expectedStaffUPNSuffix` | This is an error checking variable. It should be set to the expected domain portion of the sign-in address for all Pastor on Call people. It is usually the domain part of the church's email addresses. |
| `$teamsCallQueueIdentityGUID` | The GUID of the Call Queue to be updated, from [Configure Teams Phone System](#configure-teams-phone-system). It can be left blank with `""` to skip updating a Call Queue. |
| `$teamsAutoAttendantIdentityGUID` | The GUID of the Auto Attendant to be updated, from [Configure Teams Phone System](#configure-teams-phone-system). It can be left blank with `""` to skip updating an Auto Attendant. |
| `$logFile` | The name of the log file can be customized if desired. The log file is overwritten with every execution. |

## Deploy the Script
The PowerShell script only requires the MicrosoftTeams PowerShell module, which can be installed in an administrative PowerShell session with `Install-Module MicrosoftTeams`, or updated if it is already installed with `Update-Module MicrosoftTeams`.

To deploy the script:
1. Copy the script with customized variables to the prepared computer
2. Create a new Task with these recommended settings:
   - Name: `Teams - Pastor on Call Automation`
   - Security options: this script can be run as `NT AUTHORITY\LOCAL SERVICE` or another user account
   - Trigger: Configure the script to run as often as needed. Recommended frequency of daily, repeat every 15 minutes for a duration of 1 day.
   - Action:
     - Start a program
     - Program/script: `powershell.exe`
     - Add arguments: `C:\path\to\script\POCAutomation.ps1`
     - Start in: `C:\path\to\script\`
3. Manually run the task to test. The log file should be created and updated with progress and indicators of what data is being updated. PowerShell errors will be written to the log file.


[^1]: Care Schedules is also used by Hospital Calling (not yet published)
