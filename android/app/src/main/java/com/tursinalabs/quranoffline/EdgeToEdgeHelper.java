package com.tursinalabs.quranoffline;

import androidx.activity.ComponentActivity;
import androidx.activity.EdgeToEdge;

/** Thin Java bridge so EdgeToEdge resolves on the Java compile classpath. */
public final class EdgeToEdgeHelper {
    private EdgeToEdgeHelper() {}

    public static void enable(ComponentActivity activity) {
        EdgeToEdge.enable(activity);
    }
}
