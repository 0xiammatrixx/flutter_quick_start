# Keep BouncyCastle SSL classes
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**

# Keep Conscrypt classes
-keep class org.conscrypt.** { *; }
-dontwarn org.conscrypt.**

# Keep OpenJSSE classes
-keep class org.openjsse.** { *; }
-dontwarn org.openjsse.**

# Keep SLF4J binding
-keep class org.slf4j.impl.** { *; }
-dontwarn org.slf4j.impl.**

-keep class com.web3auth.** { *; }
-keep class org.json.** { *; }
-dontwarn com.web3auth.**
