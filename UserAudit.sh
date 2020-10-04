#!/bin/bash\
  \
#variable assignments\
#====================\
setFlagvalue="1"\
path="/root"\
logDir="/var/log"\
logPath="$logDir/useraudit"\
flagFile="$logPath/flagfile"\
dateTime="$logPath/datetime"\
arrFilename=(passwd group sudoers)\
fileDifferences="$logPath/filedifferences"\
logFile="$logPath/auditUserchange.log"\
executionLogs="$logPath/executions.log"\
\
#get the current timestamp and hostname\
#======================================\
host=`cat /proc/sys/kernel/hostname`\
hostName="$host"\
currentDate=`date`\
\
#First time - creating directory useraudit under /var/log and create file executionLogs and print start of log in it\
#===================================================================================================================\
if [[ -d "$logPath" ]]; then\
   if [[ -e "$executionLogs" ]]; then\
         printf "$currentDate - Start of log\\n" >> "$executionLogs"\
         printf "$currentDate - directory $logPath exists under - $logDir\\n" >> "$executionLogs"\
   else\
         printf "$currentDate - Start of log\\n" >> "$executionLogs"\
         printf "$currentDate - directory $logPath exists under - $logDir\\n" >> "$executionLogs"\
   fi\
else\
      `mkdir $logPath`\
      printf "$currentDate - Start of log\\n" >> "$executionLogs"\
      printf "$currentDate - creating $logPath under - $logDir\\n" >> "$executionLogs"\
fi\
\
\
#First time - creating the initial datetime file and setting up a flag\
#=====================================================================\
if [[ -e "$flagFile" ]]; then\
      printf "$currentDate - $flagFile - flagfile exists\\n" >> "$executionLogs"\
      checkFlagvalue=`cat $flagFile`\
   if [[ $checkFlagvalue == $setFlagvalue ]]; then\
         printf "$currentDate - $flagFile exists with value $checkFlagvalue\\n" >> "$executionLogs"\
         :\
   else\
         echo "$setFlagvalue" > "$flagFile"\
         sudo chmod u=rw "$flagFile"\
   fi\
else\
   printf "$currentDate - $flagFile does not exists\\n" >> "$executionLogs"\
   printf "$currentDate - creating $flagFile - flagfile\\n" >> "$executionLogs"\
   echo "$setFlagvalue" > "$flagFile"\
   sudo chmod u=rw "$flagFile"\
   datetimeCreate=`ls -ltr $path/group $path/sudoers $path/passwd`\
   echo "$datetimeCreate" > "$dateTime"\
   sudo chmod u=rw "$dateTime"\
fi\
\
#First time - creating the temp [passwd, group & sudoers] file in /var/log/useraudit/\
#===================================================================================\
for (( i=0; i<$\{#arrFilename[@]\}; i++ )); do\
    tempFile=$logPath/$\{arrFilename[i]\} \
    if [[ -e "$tempFile" ]]; then\
          printf "$currentDate - $tempFile - tempfile exists\\n" >> "$executionLogs"\
          :\
    else\
          printf "$currentDate - $tempFile tempfile does not exists\\n" >> "$executionLogs"\
          printf "$currentDate - creating $tempFile - tempfile\\n" >> "$executionLogs"\
          readFile=`cat $path/$\{arrFilename[i]\}`\
          echo "$readFile" > "$tempFile"\
    fi\
done\
\
#Get the values for past & current month date & time for each file\
#=================================================================\
while IFS= read -r line; do\
      savedFilename=`echo "$line" | awk '\{print $9\}' | cut -c7-`\
      savedMonthDateTime=`echo "$line" | awk '\{print $6" "$7" "$8\}'`  \
      currentFilename=`ls -ltr $path/$savedFilename | awk '\{print $9\}' | cut -c7-`\
      currentMonthDateTime=`ls -ltr $path/$savedFilename | awk '\{print $6" "$7" "$8\}'`\
\
      if [[ $currentFilename == $savedFilename ]]; then\
         printf "$currentDate - currentFilename: $currentFilename is equal to savedFilename: $savedFilename\\n" >> "$executionLogs"\
         printf "$currentDate - going for the next check ....\\n" >> "$executionLogs"\
         if [[ $currentMonthDateTime != $savedMonthDateTime ]]; then\
               printf "$currentDate - currentMonthDateTime: $currentMonthDateTime is not equal to savedMonthDateTime: $savedMonthDateTime\\n" >> "$executionLogs"\
\
               #find the diff between the current & saved files [/etc/[passwd, group, sudoers]] & [/var/log/useraudit/[passwd, group, sudoers]]\
               #===============================================================================================================================\
               differences=`diff "$path/$currentFilename" "$logPath/$savedFilename"`\
               echo "$differences" >> "$fileDifferences"\
\
               #copy the current files [/etc/[passwd, group, sudoers]] to the saved temp [/var/log/useraudit/[passwd, group, sudoers]]\
               #======================================================================================================================\
               readFile=`cat $path/$currentFilename`\
               echo "$readFile" > "$logPath/$savedFilename"\
\
               #write the output to logFile, which will then be read by Splunk\
               #==============================================================\
               printf "$currentDate - changeFile:$savedFilename changeTimestamp:$currentMonthDateTime host:$hostName difference:$differences\\n" >> $logFile\
         else\
               printf "$currentDate - currentMonthDateTime: $currentMonthDateTime is equal to savedMonthDateTime: $savedMonthDateTime\\n" >> "$executionLogs"\
               printf "$currentDate - No change needed\\n" >> "$executionLogs"\
               printf "$currentDate - exiting ....\\n" >> "$executionLogs"\
               : \
         fi  \
      else              \
          printf "$currentDate - currentFilename: $currentFilename is not equal to savedFilename: $savedFilename\\n" >> "$executionLogs"\
          printf "$currentDate - exiting ....\\n" >> "$executionLogs"\
          : \
      fi\
done < "$dateTime"\
\
#when the current datetime is not equal to the saved datetime, copy the new date & time values to /var/log/useraudit/datetime file\
#=================================================================================================================================\
datetimeCreate=`ls -ltr $path/group $path/sudoers $path/passwd`\
echo "$datetimeCreate" > "$dateTime"\
sudo chmod u=rw "$dateTime"   \
\
#printing the start log in executionLogs\
#=======================================\
printf "$currentDate - End of log\\n" >> "$executionLogs"\
printf " \\n" }
