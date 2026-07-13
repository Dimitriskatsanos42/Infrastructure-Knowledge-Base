#!/usr/bin/env bash
# ============================================
#
# Script: linux_log_analyzer.sh
#
# Περιγραφή:
# Αναλύει Linux system logs και εντοπίζει
# errors, failed logins και ύποπτες δραστηριότητες.
#
# Author: Dimitris Katsanos
# Date: 2026
#
# ============================================


set -euo pipefail


REPORT="incident_report_$(date +%F_%H-%M-%S).txt"


LOGFILE="/var/log/auth.log"



{
echo "================================="
echo "       LINUX LOG ANALYZER"
echo "================================="

echo
echo "Date:"
date


echo
echo "===== FAILED LOGIN ANALYSIS ====="


if [ -f "$LOGFILE" ]
then


FAILED=$(grep "Failed password" "$LOGFILE" | wc -l)


echo "Failed SSH attempts:"
echo "$FAILED"


echo
echo "Top attacking IP addresses:"


grep "Failed password" "$LOGFILE" \
| awk '{print $(NF-3)}' \
| sort \
| uniq -c \
| sort -nr \
| head -10


else

echo "Authentication log not found"

fi



echo
echo "===== SYSTEM ERRORS ====="


journalctl -p err -n 20 --no-pager



echo
echo "===== KERNEL ERRORS ====="


dmesg --level=err,warn | tail -20



echo
echo "===== SECURITY SUMMARY ====="



if [ "${FAILED:-0}" -gt 50 ]
then

echo "Risk Level: HIGH"

elif [ "${FAILED:-0}" -gt 10 ]
then

echo "Risk Level: MEDIUM"

else

echo "Risk Level: LOW"

fi



echo
echo "Analysis completed"


} | tee "$REPORT"



echo
echo "Report saved:"
echo "$REPORT"
