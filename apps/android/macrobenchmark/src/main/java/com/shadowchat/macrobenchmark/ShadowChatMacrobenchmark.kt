package com.shadowchat.macrobenchmark

import androidx.benchmark.macro.CompilationMode
import androidx.benchmark.macro.FrameTimingMetric
import androidx.benchmark.macro.StartupMode
import androidx.benchmark.macro.StartupTimingMetric
import androidx.benchmark.macro.junit4.MacrobenchmarkRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.filters.LargeTest
import androidx.test.uiautomator.By
import androidx.test.uiautomator.Direction
import androidx.test.uiautomator.Until
import org.junit.Assert.assertNotNull
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@LargeTest
@RunWith(AndroidJUnit4::class)
class ShadowChatMacrobenchmark {
    @get:Rule
    val benchmarkRule = MacrobenchmarkRule()

    @Test
    fun coldStartup() = measureStartup(StartupMode.COLD)

    @Test
    fun warmStartup() = measureStartup(StartupMode.WARM)

    @Test
    fun chatListScroll() = benchmarkRule.measureRepeated(
        packageName = PACKAGE_NAME,
        metrics = listOf(FrameTimingMetric()),
        compilationMode = CompilationMode.None(),
        iterations = SCROLL_ITERATIONS,
        setupBlock = {
            killProcess()
            pressHome()
            startActivityAndWait()

            assertNotNull(
                "Chat list did not become visible before the benchmark.",
                device.wait(Until.findObject(By.res(CHAT_LIST_TAG)), UI_TIMEOUT_MILLIS),
            )
        },
    ) {
        val chatList = requireNotNull(device.findObject(By.res(CHAT_LIST_TAG))) {
            "Chat list is missing during the measured scroll."
        }
        chatList.setGestureMargin(device.displayWidth / 5)

        repeat(SCROLL_CYCLES_PER_ITERATION) {
            chatList.fling(Direction.DOWN)
            chatList.fling(Direction.UP)
        }
        device.waitForIdle()
    }

    private fun measureStartup(startupMode: StartupMode) = benchmarkRule.measureRepeated(
        packageName = PACKAGE_NAME,
        metrics = listOf(StartupTimingMetric()),
        compilationMode = CompilationMode.None(),
        iterations = STARTUP_ITERATIONS,
        startupMode = startupMode,
        setupBlock = {
            pressHome()
        },
    ) {
        startActivityAndWait()
    }

    private companion object {
        const val PACKAGE_NAME = "com.shadowchat"
        const val CHAT_LIST_TAG = "shadow_chat_list"
        const val STARTUP_ITERATIONS = 10
        const val SCROLL_ITERATIONS = 10
        const val SCROLL_CYCLES_PER_ITERATION = 3
        const val UI_TIMEOUT_MILLIS = 5_000L
    }
}
