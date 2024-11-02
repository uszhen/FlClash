package com.follow.clash

import android.app.Activity
import android.os.Bundle
import com.follow.clash.extensions.wrapAction

class TempActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        when (intent.action) {
            wrapAction("STOP") -> {
                GlobalState.handleStop(applicationContext)
            }

            wrapAction("CHANGE") -> {
                GlobalState.handleToggle(applicationContext)
            }
        }
        finishAndRemoveTask()
    }
}