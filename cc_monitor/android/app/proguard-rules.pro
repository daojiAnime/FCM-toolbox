# Flutter 相关规则
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase 相关规则
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# 保留注解
-keepattributes *Annotation*
-keepattributes Signature

# 保留异常堆栈信息
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Kotlin 序列化
-keepclassmembers class kotlinx.serialization.json.** {
    *** Companion;
}
-keepclasseswithmembers class kotlinx.serialization.json.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# 保留模型类（如果有 Java/Kotlin 模型）
-keep class io.github.daojianime.ccmonitor.** { *; }
