package com.tursinalabs.quranoffline.notifications

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.json.JSONArray

class PluginScheduledNotificationCacheTest {
    @Test
    fun emptyAndNullPassThrough() {
        assertNull(PluginScheduledNotificationCache.downgradeExactModes(null))
        assertEquals("[]", PluginScheduledNotificationCache.downgradeExactModes("[]"))
    }

    @Test
    fun exactAllowWhileIdleBecomesInexact() {
        val json =
            """[{"id":9001,"scheduleMode":"exactAllowWhileIdle","title":"Friday"}]"""
        val rewritten = PluginScheduledNotificationCache.downgradeExactModes(json)!!
        val item = JSONArray(rewritten).getJSONObject(0)
        assertEquals("inexactAllowWhileIdle", item.getString("scheduleMode"))
        assertEquals(9001, item.getInt("id"))
    }

    @Test
    fun exactAndAlarmClockBecomeInexact() {
        val json =
            """[{"id":1,"scheduleMode":"exact"},{"id":2,"scheduleMode":"alarmClock"}]"""
        val rewritten = PluginScheduledNotificationCache.downgradeExactModes(json)!!
        val array = JSONArray(rewritten)
        assertEquals("inexactAllowWhileIdle", array.getJSONObject(0).getString("scheduleMode"))
        assertEquals("inexactAllowWhileIdle", array.getJSONObject(1).getString("scheduleMode"))
    }

    @Test
    fun alreadyInexactIsUnchanged() {
        val json = """[{"id":9001,"scheduleMode":"inexactAllowWhileIdle"}]"""
        val rewritten = PluginScheduledNotificationCache.downgradeExactModes(json)!!
        assertEquals(
            "inexactAllowWhileIdle",
            JSONArray(rewritten).getJSONObject(0).getString("scheduleMode"),
        )
    }

    @Test
    fun booleanAllowWhileIdleLegacyBecomesInexact() {
        val json = """[{"id":9001,"allowWhileIdle":true}]"""
        val rewritten = PluginScheduledNotificationCache.downgradeExactModes(json)!!
        val item = JSONArray(rewritten).getJSONObject(0)
        assertEquals("inexactAllowWhileIdle", item.getString("scheduleMode"))
    }

    @Test
    fun containsWeeklyReminderId() {
        val with = """[{"id":9001},{"id":2}]"""
        val without = """[{"id":2}]"""
        assertTrue(PluginScheduledNotificationCache.containsNotificationId(with, 9001))
        assertFalse(PluginScheduledNotificationCache.containsNotificationId(without, 9001))
        assertFalse(PluginScheduledNotificationCache.containsNotificationId(null, 9001))
    }
}
