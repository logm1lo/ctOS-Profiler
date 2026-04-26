package com.logm1lo.ctos

import androidx.test.espresso.Espresso.onView
import androidx.test.espresso.Espresso.pressBack
import androidx.test.espresso.action.ViewActions.click
import androidx.test.espresso.matcher.ViewMatchers.withContentDescription
import androidx.test.ext.junit.rules.ActivityScenarioRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import tools.fastlane.screengrab.Screengrab
import tools.fastlane.screengrab.locale.LocaleTestRule

@RunWith(AndroidJUnit4::class)
class ScreenshotTest {
    @Rule
    @JvmField
    val localeTestRule = LocaleTestRule()

    @Rule
    @JvmField
    val activityRule = ActivityScenarioRule(MainActivity::class.java)

    @Test
    fun testTakeScreenshots() {
        // Wait for the app to load
        Thread.sleep(7000)
        
        Screengrab.screenshot("01_main_screen")
        
        // Navigate to PROFILES
        onView(withContentDescription("PROFILES")).perform(click())
        Thread.sleep(2000)
        Screengrab.screenshot("02_profiles_screen")
        
        // Go back to main
        pressBack()
        Thread.sleep(1000)
        
        // Navigate to SEARCH (Camera)
        onView(withContentDescription("SEARCH")).perform(click())
        Thread.sleep(5000) // Allow camera to initialize
        Screengrab.screenshot("03_camera_screen")
        
        // Go back to main
        pressBack()
        Thread.sleep(1000)
    }
}
