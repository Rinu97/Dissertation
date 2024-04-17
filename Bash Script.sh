#!/bin/bash

######################################
# Webcam Activity Monitoring Script  #
######################################

# Email configuration
TO="rinuofficial97@gmail.com"
FROM="4monitorwebcam@gmail.com"
SUBJECT="Webcam Activity Detected"

# Function to send email using ssmtp
send_email() {
    local SUBJECT="$1"
    local BODY="$2"
    echo "Subject: $SUBJECT" > /tmp/email.txt
    echo "From: $FROM" >> /tmp/email.txt
    echo "To: $TO" >> /tmp/email.txt
    echo "" >> /tmp/email.txt
    echo "$BODY" >> /tmp/email.txt
    ssmtp "$TO" < /tmp/email.txt
}

# Function to monitor webcam activity
monitor_webcam() {
    echo "Monitoring webcam activity..."
    webcam_accessed=false
    while true; do
        # Get current timestamp with date
        timestamp=$(date +"%Y-%m-%d %T")
        # Check for processes accessing webcam device files
        webcam_processes=$(lsof /dev/video* 2>/dev/null)
        if [ -n "$webcam_processes" ]; then
            if [ "$webcam_accessed" != "true" ]; then
                # Webcam is accessed, store timestamp and notify
                webcam_accessed=true
                access_start_time=$(date +%s)
                # Send email notification and desktop notification
                send_email "$SUBJECT" "Webcam accessed by someone at $timestamp."
                notify-send -u critical "Webcam Accessed" "Webcam accessed by someone at $timestamp."
                # Log process details to forensic report
                echo -e "Time\t\t\tCommand\tPID\tUSER\tFD\tTYPE\tDEVICE\tNAME" > webcam_forensic_report.txt
                echo -e "[$timestamp] Webcam accessed by:" >> webcam_forensic_report.txt
                echo -e "$webcam_processes" | awk 'NR>1 {print $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 "\t" $7 "\t" $8}' >> webcam_forensic_report.txt
            fi
        else
            if [ "$webcam_accessed" = "true" ]; then
                # Webcam was previously accessed, calculate duration and notify
                access_end_time=$(date +%s)
                duration=$((access_end_time - access_start_time))
                access_duration=$(date -u -d @"$duration" +'%H:%M:%S')
                # Send email notification with forensic report
                send_email "Webcam Forensic Report" "Attached is the forensic report for webcam activity." < webcam_forensic_report.txt
                # Clear forensic report file
                > webcam_forensic_report.txt
                # Send desktop notification
                notify-send -u low "Webcam Not Accessed" "No processes currently accessing the webcam at $timestamp."
                webcam_accessed=false
            fi
        fi
        sleep 5 # Adjust the interval as needed
    done
}

# Check if lsof command is available
if ! command -v lsof &>/dev/null; then
    echo "Error: 'lsof' command not found. Please install lsof and try again."
    exit 1
fi

# Check if ssmtp command is available
if ! command -v ssmtp &>/dev/null; then
    echo "Error: 'ssmtp' command not found. Email notifications will not be available."
    exit 1
fi

# Check if notify-send command is available
if ! command -v notify-send &>/dev/null; then
    echo "Error: 'notify-send' command not found. Desktop notifications will not be available."
    exit 1
fi

# Start monitoring webcam activity
monitor_webcam

